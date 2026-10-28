# brickie

A Helm chart that deploys [brickie](https://github.com/hatchet-dev/brickie), the Hatchet sandbox provider, on Kubernetes. The provider connects to a Hatchet tenant as a gRPC operator and runs agent sandboxes as Hatchet tasks, one isolated pod per sandbox.

## Prerequisites

- Kubernetes 1.30+
- Helm 3.8+
- A Hatchet tenant on Hatchet Cloud or a self-hosted Hatchet v0.110+ with `SERVER_GRPC_OPERATORS_ENABLED=true`, and a client token for it
- For Kata Containers (the default runtime), x86 nodes with `/dev/kvm`
- An object store the provider can read and write (S3, GCS, Azure Blob, or an S3-compatible endpoint) for anything beyond development

## Installing the chart

```bash
helm repo add hatchet https://hatchet-dev.github.io/hatchet-charts
helm repo update
helm install brickie hatchet/brickie \
  --set hatchet.token=$HATCHET_CLIENT_TOKEN \
  --set store='s3://my-bucket?prefix=brickie/'
```

## Uninstalling the chart

```bash
helm uninstall brickie
```

## Dependencies

| Component | Subchart | Condition |
|-----------|----------|-----------|
| agent-sandbox controller | [agent-sandbox](https://github.com/kubernetes-sigs/agent-sandbox) v1.0.8 (bundled) | `agent-sandbox.enabled` |
| Kata Containers | [kata-deploy](https://github.com/kata-containers/kata-containers/tree/main/tools/packaging/kata-deploy/helm-chart) 4.2.0 (bundled) | `kata-deploy.enabled` |

Both sections accept all values of their respective subcharts. Set a condition to `false` when the component is already on the cluster.

## Values validation

This chart ships a [`values.schema.json`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/brickie/values.schema.json). Helm validates your supplied values against it on `install`, `upgrade`, `template` and `lint`. Unknown keys are rejected.

## Parameters

### Hatchet

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `hatchet.token` | string | `""` | Hatchet client token. Stored by the chart in a Secret. One of `hatchet.token` or `hatchet.existingSecret` is required. |
| `hatchet.existingSecret` | string | `""` | Name of an existing Secret with the key `HATCHET_CLIENT_TOKEN`. |

### Provider

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `image.repository` | string | `"ghcr.io/hatchet-dev/brickie"` | Provider image repository. The same image runs in every sandbox pod as the TLS proxy in front of the sandbox daemon. |
| `image.tag` | string | chart `appVersion` | Provider image tag. |
| `image.pullPolicy` | string | `"IfNotPresent"` | Provider image pull policy. |
| `imagePullSecrets` | list | `[]` | Pull secrets for the provider image. |
| `replicaCount` | int | `1` | Provider replicas. Keep at 1: calls on one sandbox are serialized inside the provider. |
| `slots` | int | `10` | Sandbox calls the provider runs at the same time. |
| `serviceAccount.annotations` | object | `{}` | Annotations on the provider ServiceAccount, for example an IRSA role ARN for the object store. |
| `resources` | object | `{}` | Provider pod resources. |
| `nodeSelector` | object | `{}` | Provider pod node selector. |
| `tolerations` | list | `[]` | Provider pod tolerations. |

### Store

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `store` | string | `""` | Bucket for snapshots, sandbox metadata, and files larger than `sandbox.maxFileBytes`: `s3://bucket?prefix=p/&region=r`, `gs://bucket?prefix=p/`, `azblob://container?prefix=p/`, or `s3://bucket?prefix=p/&endpoint=https://host&use_path_style=true`. Empty keeps everything on the pod's emptyDir; development only. |
| `storeSecret` | string | `""` | Name of a Secret with the store credentials (`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`, or the GCP and Azure equivalents), when not using workload identity. |

### Sandboxes

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `sandbox.namespace` | string | release namespace | Namespace for sandbox pods and claims. |
| `sandbox.image` | string | `"alpine:3"` | Default sandbox image. Needs `sh` and `tar`. |
| `sandbox.runtime` | string | `"kata"` | Runtime class for sandbox pods: `kata` (`kata-clh`), `gvisor`, `auto` (kata, then gvisor, then the default runtime), or `none`. |
| `sandbox.warmReplicas` | int | `2` | Ready pods each warm pool keeps. |
| `sandbox.idleTTL` | string | `"30m"` | Remove a sandbox after this long without a call. |
| `sandbox.maxIdleTTL` | string | `"24h"` | Largest idle timeout a sandbox may ask for at create. |
| `sandbox.maxFileBytes` | int | `2097152` | Largest file carried inside a Hatchet task; larger files go through `store`. |
| `sandbox.egress` | string | `"internet"` | What sandboxes may reach: `internet` (public addresses and cluster DNS) or `none`. Enforced by the sandbox NetworkPolicy where the CNI supports it. |
| `sandbox.resources.cpu` | string | `"1"` | CPU limit per sandbox pod. |
| `sandbox.resources.memory` | string | `"2Gi"` | Memory limit per sandbox pod. |
| `sandbox.resources.disk` | string | `"10Gi"` | Ephemeral-storage limit per sandbox pod, also the workspace volume size limit. |

### Network policy

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `networkPolicy.egressCIDRs` | list | `[]` | CIDRs sandboxes may reach in addition to `sandbox.egress`. Rendered as a second NetworkPolicy when set. |
| `networkPolicy.allowDNS` | bool | `true` | Include cluster DNS in that policy. |

### Runtimes

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `kata-deploy.enabled` | bool | `true` | Install Kata Containers with the bundled kata-deploy chart (Cloud Hypervisor shim, DaemonSet mode). |
| `kata-deploy.nodeSelector` | object | _unset_ | Limit the Kata installer to selected nodes. |
| `gvisor.install` | bool | `false` | Install gVisor with a DaemonSet and create the `gvisor` RuntimeClass. |
| `gvisor.release` | string | `"20261005.0"` | gVisor release to install. |
| `gvisor.nodeSelector` | object | `{}` | Limit the gVisor installer and RuntimeClass to selected nodes. |
| `agent-sandbox.enabled` | bool | `true` | Install the agent-sandbox controller with the bundled chart. |

## License

MIT. See [LICENSE](https://github.com/hatchet-dev/hatchet-charts/blob/main/LICENSE).
