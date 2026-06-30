# hatchet-api

A Helm chart for deploying the [Hatchet](https://hatchet.run) API on Kubernetes.

This chart deploys the `hatchet-api` Deployment together with the helper Jobs that
bootstrap the database (setup, migration, seed, quickstart and worker-token Jobs).
It is also used as a building block by the [`hatchet-stack`](../hatchet-stack) and
[`hatchet-ha`](../hatchet-ha) umbrella charts, where it is aliased as the `api`,
`grpc`, `controllers`, `scheduler` and `engine` components.

## TL;DR

```bash
helm install hatchet-api ./charts/hatchet-api
```

> The bare command above does **not** provide the Postgres connection and server
> secrets the API needs to actually start. See the
> [repository README](../../README.md#local-validation) for a complete, runnable
> single-chart install recipe.

## Prerequisites

- Kubernetes 1.18+
- Helm 3.8+
- A reachable PostgreSQL database (timezone **must** be `UTC`)
- A `hatchet-config` Secret with server-level config (or override `deploymentEnvFrom`)

## Installing the chart

```bash
helm install my-release ./charts/hatchet-api
```

## Uninstalling the chart

```bash
helm uninstall my-release
```

## Long-running migrations

The chart runs schema migrations both as an init container in the setup Job (on
install) and as a `pre-upgrade` hook Job (on upgrade), controlled by `migrationJob`.
Both default to a 15-minute timeout. See the
[repository README](../../README.md#long-running-migrations) for tuning
`migrationJob.activeDeadlineSeconds`, `migrationJob.backoffLimit` and the Helm
`--timeout` flag.

## Values validation

This chart ships a [`values.schema.json`](values.schema.json). Helm validates your
supplied values against it on `install`, `upgrade`, `template` and `lint`, so type
errors (e.g. a string where an integer is expected) are caught before anything is
applied to the cluster.

## Parameters

### Images

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `sharedConfig.image.tag` | string | `"v0.84.0"` | Image tag inherited from a parent chart. |
| `image.repository` | string | `"ghcr.io/hatchet-dev/hatchet/hatchet-api"` | API image repository. |
| `image.tag` | string | `"v0.84.0"` | API image tag. |
| `image.pullPolicy` | string | `"IfNotPresent"` | API image pull policy. |
| `postgresImage.repository` | string | `"postgres"` | Postgres client image repository (used by helper Jobs). |
| `postgresImage.tag` | string | `"latest"` | Postgres client image tag. |
| `postgresImage.pullPolicy` | string | `"IfNotPresent"` | Postgres client image pull policy. |

### Bootstrap Jobs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `setupJob.enabled` | bool | `true` | Enable the setup Job that bootstraps the database and configuration. |
| `setupJob.image.repository` | string | `"ghcr.io/hatchet-dev/hatchet/hatchet-admin"` | Setup Job image repository. |
| `setupJob.image.tag` | string | `"v0.84.0"` | Setup Job image tag. |
| `setupJob.image.pullPolicy` | string | `"IfNotPresent"` | Setup Job image pull policy. |
| `migrationJob.enabled` | bool | `true` | Enable database migrations (init container on install, `pre-upgrade` hook on upgrade). |
| `migrationJob.backoffLimit` | int | `1` | Number of retries before the migration Job is marked failed. |
| `migrationJob.activeDeadlineSeconds` | int | `900` | Hard timeout (seconds) for the migration Job; raise for long-running schema changes. |
| `migrationJob.image.repository` | string | `"ghcr.io/hatchet-dev/hatchet/hatchet-migrate"` | Migration Job image repository. |
| `migrationJob.image.tag` | string | `"v0.84.0"` | Migration Job image tag. |
| `migrationJob.image.pullPolicy` | string | `"IfNotPresent"` | Migration Job image pull policy. |
| `seedJob.enabled` | bool | `true` | Enable the Job that seeds the database with default data. |
| `seedJob.image.repository` | string | `"ghcr.io/hatchet-dev/hatchet/hatchet-admin"` | Seed Job image repository. |
| `seedJob.image.tag` | string | `"v0.84.0"` | Seed Job image tag. |
| `seedJob.image.pullPolicy` | string | `"IfNotPresent"` | Seed Job image pull policy. |
| `quickstartJob.enabled` | bool | `true` | Enable the Job that generates cookie/encryption secrets via `hatchet-admin quickstart`. |
| `workerTokenJob.enabled` | bool | `true` | Enable the Job that generates a worker API token. |
| `retainFailedHooks` | bool | `true` | Retain failed Helm hook Jobs (e.g. the pre-upgrade migration hook) so logs survive for debugging. |

### Container runtime

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `commandline.command` | list | `["/hatchet/hatchet-api"]` | Container entrypoint command. |
| `commandline.args` | list | `[]` | Container entrypoint arguments. |
| `env` | object | `{}` | Additional environment variables injected into the Deployment. |
| `deploymentEnvFrom` | list | `[{secretRef: {name: hatchet-config}}]` | `envFrom` sources wired into the Deployment only. |
| `envFrom` | list | `[]` | `envFrom` sources wired into both the Deployment and helper Jobs. |
| `files` | object | `{}` | Files mounted into the container via a ConfigMap. |
| `extraContainers` | list | `[]` | Additional sidecar containers. |
| `initContainers` | list | `[]` | Additional init containers. |
| `extraVolumes` | list | `[]` | Additional volumes. |
| `extraVolumeMounts` | list | `[]` | Additional volume mounts. |
| `extraConfigMapMounts` | list | `[]` | Additional ConfigMap mounts. |
| `extraManifests` | list | `[]` | Additional raw Kubernetes manifests to render. |

### Cloud SQL sidecar

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `cloudSQLSidecar.enabled` | bool | `false` | Enable the Google Cloud SQL Auth Proxy sidecar. |
| `cloudSQLSidecar.address` | string | `""` | Cloud SQL instance connection address. |
| `cloudSQLSidecar.resources` | object | see `values.yaml` | Resources for the Cloud SQL sidecar. |

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `replicaCount` | int | `1` | Number of replicas. |
| `revisionHistoryLimit` | int | `3` | Number of old ReplicaSets to retain. |
| `deployment.annotations` | object | `{app.kubernetes.io/name: hatchet-api}` | Deployment annotations. |
| `deployment.labels` | object | `{}` | Deployment labels. |
| `deployment.extraPorts` | list | `[]` | Extra container ports. |
| `podAnnotations` | object | `{}` | Common annotations for all pods. |
| `priorityClassName` | string | `""` | Pod priority class name. |
| `nodeSelector` | object | `{}` | Node labels for pod assignment. |
| `tolerations` | list | `[]` | Tolerations for pod assignment. |
| `affinity` | object | _unset_ | Affinity rules for pod assignment. |
| `resources.limits.memory` | string | `1024Mi` | Memory limit for the main container. |
| `resources.requests.cpu` | string | `250m` | CPU request for the main container. |
| `resources.requests.memory` | string | `1024Mi` | Memory request for the main container. |
| `persistence.size` | string | `5Gi` | Size of the persistent volume. |
| `podDisruptionBudget` | object | _unset_ | Pod disruption budget configuration. |

### Service & Ingress

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `service.type` | string | `ClusterIP` | Service type. |
| `service.externalPort` | int | `8080` | Service external port. |
| `service.internalPort` | int | `8080` | Service (container) internal port. |
| `service.annotations` | object | `{}` | Service annotations. |
| `service.labels` | object | `{}` | Service labels. |
| `service.selector` | object | `{}` | Extra service selector labels. |
| `service.extraPorts` | list | `[]` | Extra service ports. |
| `ingress.enabled` | bool | `true` | Enable an Ingress resource. |
| `ingress.annotations` | object | `{}` | Ingress annotations. |
| `ingress.labels` | object | `{}` | Ingress labels. |
| `ingress.hosts` | list | `[]` | Ingress hosts and paths. |
| `ingress.tls` | list | `[]` | Ingress TLS configuration. |
| `ingress.pathType` | string | `ImplementationSpecific` | Ingress path type. |

### Service account & security

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `serviceAccount.create` | bool | `true` | Create a service account. |
| `serviceAccount.name` | string | `null` | Service account name (generated if unset and `create` is true). |
| `serviceAccount.annotations` | object | `{}` | Service account annotations. |
| `securityContext.enabled` | bool | `false` | Enable the pod/container security context. |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Allow privilege escalation. |
| `securityContext.runAsUser` | int | `1000` | UID to run the container as. |
| `securityContext.fsGroup` | int | `2000` | Filesystem group. |
| `securityGroupPolicy.enabled` | bool | `false` | Enable AWS security groups for pods. |
| `securityGroupPolicy.groupIds` | list | `[]` | AWS security group IDs. |

### Health checks

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `health.enabled` | bool | `false` | Enable liveness/readiness probes. |
| `health.spec` | object | _unset_ | Probe specification (set when `health.enabled` is true). |

## License

Apache-2.0. See [LICENSE](../../LICENSE).
