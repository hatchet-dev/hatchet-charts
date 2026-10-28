# Brickie Helm chart

One chart installs everything brickie needs on a cluster:

- the brickie provider, a Deployment that connects to Hatchet as a gRPC operator;
- agent-sandbox v1.0.8 (kubernetes-sigs), the controller for sandbox pods and warm pools, as a bundled subchart;
- Kata Containers with Cloud Hypervisor, the default sandbox runtime, as a bundled kata-deploy subchart;
- gVisor, an optional alternative runtime, as a DaemonSet installer;
- an optional egress allow-list for sandbox pods, on top of the NetworkPolicy the provider gives every sandbox.

No external chart repositories are needed. All subcharts are vendored under `charts/`.

## Install

```bash
helm repo add hatchet https://hatchet-dev.github.io/hatchet-charts
helm upgrade --install brickie hatchet/brickie \
  --namespace brickie --create-namespace \
  --set hatchet.token=$HATCHET_CLIENT_TOKEN \
  --set store='s3://my-bucket?prefix=brickie/' \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::123456789012:role/brickie-provider
```

Then use the SDK with the same `HATCHET_CLIENT_TOKEN`. The provider in the cluster runs the turns.

## What you set up before the install

### 1. A Hatchet tenant with gRPC operators

- Hatchet v0.110 or newer, with `SERVER_GRPC_OPERATORS_ENABLED=true` on the engine if self-hosting.
- A client token for the tenant. Pass it as `hatchet.token`, or create a Secret with the key `HATCHET_CLIENT_TOKEN` and pass its name as `hatchet.existingSecret`.
- The provider makes one outbound gRPC connection to Hatchet. Allow egress from the provider pod to the Hatchet gRPC address. Nothing inbound is needed.

### 2. Nodes that can run the sandbox runtime

The chart defaults to Kata Containers (`sandbox.runtime: kata`). Kata runs each sandbox in a micro-VM and needs KVM on the node:

- **EKS:** a managed nodegroup of bare-metal x86 instances (`m5.metal`, `c5.metal`, `m6i.metal`, `c6i.metal`). Cloud Hypervisor is amd64-only, so no Graviton.
- The kata-deploy DaemonSet is privileged, writes the Kata runtime to each node, and configures containerd. Use `kata-deploy.nodeSelector` to limit it to the sandbox nodes.

To use gVisor instead: `--set sandbox.runtime=gvisor --set gvisor.install=true --set kata-deploy.enabled=false`. gVisor runs on any instance type. Its installer is also a privileged DaemonSet; `gvisor.nodeSelector` limits it to the sandbox nodes and makes the `gvisor` RuntimeClass schedule only there.

If your cluster already provides a runtime class, disable both installers and set `sandbox.runtime` to `kata`, `gvisor`, or `none`. The provider looks for the classes `kata-clh` and `gvisor`.

### 3. An object store

Sandbox snapshots, sandbox metadata, and files larger than 2 MiB go to a bucket. Without one the provider keeps them on its pod's emptyDir: snapshots are lost on restart, `connect` cannot resume a sandbox, and files over 2 MiB fail because your application cannot reach the pod's disk. Development only.

- Create a bucket. Set `store` to `s3://bucket?prefix=brickie/`; the prefix goes in the query, not the path. S3-compatible stores: `s3://bucket?prefix=brickie/&endpoint=https://host&use_path_style=true&region=us-east-1`.
- Give the provider access. On EKS, create an IAM role with this policy and annotate the ServiceAccount with its ARN through `serviceAccount.annotations` (IRSA). The role needs the `sts:AssumeRoleWithWebIdentity` trust for the cluster's OIDC provider and the ServiceAccount `system:serviceaccount:<namespace>:brickie-brickie`.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": ["s3:ListBucket"], "Resource": "arn:aws:s3:::my-bucket" },
    { "Effect": "Allow", "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"], "Resource": "arn:aws:s3:::my-bucket/brickie/*" }
  ]
}
```

- Alternatively, put static credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) in a Secret and pass its name as `storeSecret`.
- Add a lifecycle rule that expires the `brickie/staging/` prefix after one day. The provider keeps staged files so a retried call can still read its input, and removes its own objects older than seven days at each start, except the metadata and current snapshot of any sandbox used within those seven days.
- Your application also reaches the bucket for files over 2 MiB, by presigned URLs the provider mints. It needs network access to the bucket endpoint but no credentials.

### 4. A CNI that enforces NetworkPolicy

Every sandbox pod gets a NetworkPolicy from the provider, kept by the agent-sandbox controller: ingress only from the provider pod on the sandbox's TLS ports (9443 and 8443), and egress by `sandbox.egress`: `internet` allows public addresses and cluster DNS and blocks private ranges and the cloud metadata endpoint; `none` allows nothing. With `none`, `networkPolicy.egressCIDRs` (for example your LLM provider's ranges) plus DNS become the allow-list, as a second policy the chart renders. Policies only take effect if the CNI enforces them:

- **EKS:** the default VPC CNI enforces policies only when network policy is enabled on the add-on (`enableNetworkPolicy: true`), or use Cilium or Calico.
- **kind and most managed clusters with Cilium or Calico:** enforced by default.

Without an enforcing CNI, any pod on the cluster can reach a sandbox pod's ports. The connection is still mutual TLS with certificates only the provider issues, and the daemon behind it still requires the provider's bearer token, so the policy is a second layer, not the only one. See `docs/SECURITY.md`.

### 5. Images

- The provider image: `ghcr.io/hatchet-dev/brickie`, tagged with each release; `image.tag` empty means the chart's `appVersion`. The same image runs in every sandbox pod as the TLS proxy in front of the sandbox daemon, so sandbox nodes pull it as well. For a private registry, build from the repository `Dockerfile`, push, and set `image.repository` and `image.tag`.
- The sandbox daemon: `ghcr.io/hatchet-dev/sandboxd`, pinned by digest in the provider; sandbox nodes pull it.
- Sandbox images: any image with `sh` and `tar`. Set the default with `sandbox.image`; the SDK can pick another per sandbox. Pull secrets go in `imagePullSecrets` for the provider, and on the sandbox namespace's default ServiceAccount for sandbox pods.
- The nodes pull `quay.io/kata-containers/kata-deploy` (Kata) or `alpine` plus `storage.googleapis.com/gvisor` (gVisor) during install.

### 6. Namespaces

The provider runs in the release namespace. Sandbox pods run there too by default; set `sandbox.namespace` to put them in a separate namespace that your policies and quotas can target. The chart creates the Role and RoleBinding in that namespace, and a second Role in the release namespace for the provider's own Secret.

## What the chart creates

| Resource | Namespace | Purpose |
| --- | --- | --- |
| Deployment `brickie-brickie` | release | The provider, one replica |
| ServiceAccount `brickie-brickie` | release | Identity of the provider; carries the IRSA annotation |
| Role and RoleBinding `brickie-brickie` | sandbox | Get, list, create, patch, delete on `sandboxclaims`; get, create, update on `sandboxtemplates` and `sandboxwarmpools`; create on `secrets` and get, update on the one Secret `brickie-sandbox-tls` |
| Role and RoleBinding `brickie-brickie-provider` | release | Create on `secrets` and get, update on the one Secret `brickie-sandboxd` |
| ClusterRole and binding | cluster | Get on `runtimeclasses`, to detect the runtime at startup |
| Secret `brickie-brickie` | release | The Hatchet token, when given inline |
| Secret `brickie-sandboxd` | release | Created by the provider at first start: the bearer token every sandbox daemon requires and the CA behind the sandbox TLS |
| Secret `brickie-sandbox-tls` | sandbox | Created by the provider: the server certificate the TLS proxy in each sandbox pod presents, renewed before it expires |
| NetworkPolicy per sandbox template | sandbox | Written by the provider, kept by the controller: ingress from the provider only, egress by `sandbox.egress` |
| NetworkPolicy `brickie-brickie-sandbox-egress` | sandbox | The `networkPolicy.egressCIDRs` allow-list, when set |
| RuntimeClass `kata-clh` + kata-deploy DaemonSet | release | Kata runtime on every selected node |
| RuntimeClass `gvisor` + installer DaemonSet | release | gVisor runtime (release pinned in `gvisor.release`), when `gvisor.install` is true |
| agent-sandbox controller and CRDs (v1.0.8) | `agent-sandbox-system` | Sandbox pods, warm pools, claims, idle expiry |

The provider never needs cluster-admin. It cannot create pods, exec into pods, or read any Secret other than its own two.

## Values

| Value | Default | Meaning |
| --- | --- | --- |
| `hatchet.token` / `hatchet.existingSecret` | required | Hatchet client token |
| `image.repository`, `image.tag` | `ghcr.io/hatchet-dev/brickie`, `appVersion` | Provider image, also the TLS proxy in every sandbox pod |
| `serviceAccount.annotations` | `{}` | For example the IRSA role ARN |
| `sandbox.namespace` | release namespace | Where sandbox pods run |
| `sandbox.image` | `alpine:3` | Default sandbox image |
| `sandbox.runtime` | `kata` | `kata`, `gvisor`, `auto`, or `none` |
| `sandbox.idleTTL` | `30m` | Remove a sandbox after this long without a call |
| `sandbox.maxIdleTTL` | `24h` | Largest `idleTimeoutMs` a create may ask for |
| `sandbox.maxFileBytes` | `2097152` | Largest file carried inside a Hatchet task; larger files use the object store |
| `sandbox.warmReplicas` | `2` | Ready pods each warm pool keeps |
| `sandbox.egress` | `internet` | `internet` or `none`: what sandboxes may reach |
| `sandbox.resources.cpu`, `memory`, `disk` | `1`, `2Gi`, `10Gi` | Limits on every sandbox pod; the workspace volume has the disk limit |
| `store`, `storeSecret` | none | Bucket URL and, if not using workload identity, a Secret with its credentials |
| `networkPolicy.egressCIDRs`, `allowDNS` | `[]`, `true` | Extra egress allow-list for sandbox pods, rendered when CIDRs are listed |
| `kata-deploy.*` | Cloud Hypervisor only, DaemonSet mode | Passed to the bundled kata-deploy chart |
| `gvisor.install`, `gvisor.release`, `gvisor.nodeSelector` | `false`, `20261005.0`, `{}` | gVisor installer and where it runs |
| `agent-sandbox.enabled` | `true` | Set to `false` if agent-sandbox is already on the cluster |
| `slots` | `10` | Concurrent turns the provider accepts |

`values.schema.json` rejects unknown keys, so a typo fails at install time.
