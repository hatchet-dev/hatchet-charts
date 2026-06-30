# hatchet-frontend

A Helm chart for deploying the [Hatchet](https://hatchet.run) frontend static file
server on Kubernetes.

> **⚠️ Important — this is an internal building block, not a chart you install directly.**
>
> It is a dependency of the [`hatchet-stack`](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-stack)
> and [`hatchet-ha`](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-ha)
> umbrella charts, where it is aliased as the `frontend` component. **To
> self-host Hatchet, install
> [`hatchet-stack`](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-stack)
> (single-node) or [`hatchet-ha`](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-ha)
> (high-availability) instead.** On its own this chart only serves the static
> frontend assets — it needs the Hatchet API and engine to be useful — so the
> rest of this document is reference material for the umbrella charts.

## Values validation

This chart ships a [`values.schema.json`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-frontend/values.schema.json). Helm validates your
supplied values against it on `install`, `upgrade`, `template` and `lint`.

## Parameters

### Image

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `sharedConfig.image.tag` | string | [latest Hatchet release](https://github.com/hatchet-dev/hatchet/releases/latest) | Image tag inherited from a parent chart. |
| `image.repository` | string | `"ghcr.io/hatchet-dev/hatchet/hatchet-frontend"` | Frontend image repository. |
| `image.tag` | string | [latest Hatchet release](https://github.com/hatchet-dev/hatchet/releases/latest) | Frontend image tag. |
| `image.pullPolicy` | string | `"IfNotPresent"` | Frontend image pull policy. |

### Container runtime

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `commandline.args` | list | `[]` | Container entrypoint arguments. |
| `retainFailedHooks` | bool | `false` | Retain failed Helm hook Jobs so logs survive for debugging. |
| `env` | object | `{}` | Additional environment variables injected into the Deployment. |
| `files` | object | `{}` | Files mounted into the container via a ConfigMap. |
| `extraContainers` | list | `[]` | Additional sidecar containers. |
| `initContainers` | list | `[]` | Additional init containers. |
| `extraVolumes` | list | `[]` | Additional volumes. |
| `extraVolumeMounts` | list | `[]` | Additional volume mounts. |
| `extraConfigMapMounts` | list | `[]` | Additional ConfigMap mounts. |
| `extraManifests` | list | `[]` | Additional raw Kubernetes manifests to render. |

### Deployment

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `replicaCount` | int | `1` | Number of replicas. |
| `revisionHistoryLimit` | int | `3` | Number of old ReplicaSets to retain. |
| `deployment.annotations` | object | `{app.kubernetes.io/name: hatchet-frontend}` | Deployment annotations. |
| `deployment.labels` | object | `{}` | Deployment labels. |
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
| `service.internalPort` | int | `80` | Service (container) internal port. |
| `service.annotations` | object | `{}` | Service annotations. |
| `service.labels` | object | `{}` | Service labels. |
| `service.selector` | object | `{}` | Extra service selector labels. |
| `ingress.enabled` | bool | `true` | Enable an Ingress resource. |
| `ingress.annotations` | object | `{}` | Ingress annotations. |
| `ingress.labels` | object | `{}` | Ingress labels. |
| `ingress.hosts` | list | `null` | Ingress hosts and paths. |
| `ingress.tls` | list | `null` | Ingress TLS configuration. |
| `ingress.pathType` | string | `ImplementationSpecific` | Ingress path type. |

### Service account & security

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `serviceAccount.create` | bool | `true` | Create a service account. |
| `securityContext.enabled` | bool | `false` | Enable the pod/container security context. |
| `securityContext.allowPrivilegeEscalation` | bool | `false` | Allow privilege escalation. |
| `securityContext.runAsUser` | int | `1000` | UID to run the container as. |
| `securityContext.fsGroup` | int | `2000` | Filesystem group. |
| `securityGroupPolicy.enabled` | bool | `false` | Enable AWS security groups for pods. |
| `securityGroupPolicy.groupIds` | list | `[]` | AWS security group IDs. |

## License

MIT. See [LICENSE](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-frontend/LICENSE).
