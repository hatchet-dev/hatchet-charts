# hatchet-stack

A Helm chart that deploys [Hatchet](https://hatchet.run) on Kubernetes. This is the main umbrella chart and the recommended starting point for self-hosting Hatchet.

For a horizontally-scaled, high-available deployment, use [`hatchet-ha`](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-ha) instead.

## Getting started

To view the docs for setting up this chart, see [Kubernetes Quickstart](https://docs.hatchet.run/self-hosting/kubernetes-quickstart).

## Prerequisites

- Kubernetes 1.30+
- Helm 3.8+
- If you use the **bundled** datastores (the default), the operators that manage them
  must be installed in the cluster first (once per cluster):
  - [CloudNativePG](https://cloudnative-pg.io) — manages the bundled PostgreSQL.
  - [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview) — manages the bundled RabbitMQ.

  Install both with the helper script:

  ```bash
  curl -fsSL https://raw.githubusercontent.com/hatchet-dev/hatchet-charts/main/scripts/install-operators.sh | bash
  ```

  You do **not** need these operators if you run your own external PostgreSQL and
  RabbitMQ (`postgres.enabled=false` / `rabbitmq.enabled=false`).

## Installing the chart

```bash
helm repo add hatchet https://hatchet-dev.github.io/hatchet-charts
helm repo update
helm install my-hatchet-stack hatchet/hatchet-stack
```

## Uninstalling the chart

```bash
helm uninstall my-hatchet-stack
```

## Dependencies

| Component | Subchart | Alias | Condition |
|-----------|----------|-------|-----------|
| API | [hatchet-api](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-api) | `api` | `api.enabled` |
| Engine | [hatchet-api](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-api) | `engine` | `engine.enabled` |
| Frontend | [hatchet-frontend](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-frontend) | `frontend` | `frontend.enabled` |
| PostgreSQL | [CloudNativePG](https://cloudnative-pg.io) `Cluster` (operator-managed) | `postgres` | `postgres.enabled` |
| RabbitMQ | [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview) `RabbitmqCluster` | `rabbitmq` | `rabbitmq.enabled` |

Each Hatchet component accepts the full set of [`hatchet-api`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-api/README.md#parameters) or [`hatchet-frontend`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-frontend/README.md#parameters) values under its alias key (e.g. `api.resources`, `engine.replicaCount`). The `postgres` and `rabbitmq` sections render a CloudNativePG `Cluster` and a `RabbitmqCluster` respectively; their operators must be installed in the cluster (see [Prerequisites](#prerequisites)).

Values flow into the components two ways:

1. **Per-component overrides** are passed straight through by Helm — anything under `api.*`, `engine.*` or `frontend.*` overrides the corresponding subchart value.
2. **`sharedConfig`** is rendered by this chart into a `hatchet-shared-config` Secret (rename via `global.sharedConfigSecretName`), which every backend component loads via `envFrom`. This is how settings like the server URL, gRPC address and admin credentials reach all components at once.

## Values validation

This chart ships a [`values.schema.json`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-stack/values.schema.json). Helm validates your supplied values against it on `install`, `upgrade`, `template` and `lint`.

## Parameters

### Global

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `global.sharedConfigSecretName` | string | `"hatchet-shared-config"` | Name of the Secret rendered from `sharedConfig` and loaded by every backend component via `envFrom`. The value is passed through `tpl`, so set it to something release-scoped such as `'{{ .Release.Name }}-shared-config'` to run multiple releases in the same namespace without a name collision. |

### Shared config

Inherited by all backend services (`api`, `engine`).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `sharedConfig.enabled` | bool | `true` | Enable shared config. |
| `sharedConfig.image.tag` | string | [latest Hatchet release](https://github.com/hatchet-dev/hatchet/releases/latest) | Image tag applied to all Hatchet components (fallback to per-component `image.tag`). |
| `sharedConfig.serverUrl` | string | `"http://localhost:8080"` | Public server URL. |
| `sharedConfig.serverAuthCookieDomain` | string | `"localhost:8080"` | Domain for the auth cookie. |
| `sharedConfig.serverAuthCookieInsecure` | string | `"t"` | Allow cookies to be set over http. |
| `sharedConfig.serverAuthSetEmailVerified` | string | `"t"` | Automatically set `email_verified` for all users. |
| `sharedConfig.serverAuthBasicAuthEnabled` | string | `"t"` | Allow login via basic auth (email/password). |
| `sharedConfig.grpcBroadcastAddress` | string | `"localhost:7070"` | gRPC server endpoint exposed via the `grpc` service. |
| `sharedConfig.grpcInsecure` | string | `"t"` | Allow gRPC to be served over http. |
| `sharedConfig.defaultAdminEmail` | string | `"admin@example.com"` | Default admin email — change in production. |
| `sharedConfig.defaultAdminPassword` | string | `"Admin123!!"` | Default admin password — change in production. |
| `sharedConfig.env` | object | `{}` | Additional environment variables (override defaults). |

### Components

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `api.enabled` | bool | `true` | Enable the API component. |
| `api.replicaCount` | int | `2` | API replicas. |
| `api.image.repository` | string | `"ghcr.io/hatchet-dev/hatchet/hatchet-api"` | API image repository. |
| `api.migrationJob.enabled` | bool | `true` | Run DB migrations (only enabled on the `api` component). |
| `engine.enabled` | bool | `true` | Enable the engine component (gRPC, controllers, scheduler). |
| `engine.replicaCount` | int | `1` | Engine replicas. |
| `engine.image.repository` | string | `"ghcr.io/hatchet-dev/hatchet/hatchet-engine"` | Engine image repository. |
| `frontend.enabled` | bool | `true` | Enable the frontend component. |
| `frontend.image.repository` | string | `"ghcr.io/hatchet-dev/hatchet/hatchet-frontend"` | Frontend image repository. |

> See [`hatchet-api`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-api/README.md#parameters) for the full set of values available under `api` and `engine`, and [`hatchet-frontend`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-frontend/README.md#parameters) for `frontend`.

> The `envFrom` (and `deploymentEnvFrom`) values on each backend component are rendered through `tpl`, so you can reference release values inside secret/configmap names — e.g. `name: '{{ .Release.Name }}-postgres-secret'`.

### Bundled PostgreSQL & RabbitMQ

The bundled `postgres` renders a [CloudNativePG](https://cloudnative-pg.io) `Cluster` and
`rabbitmq` renders a [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview)
`RabbitmqCluster`. **Both operators must be installed in the cluster first** — see
[Prerequisites](#prerequisites).

> ⚠️ **The bundled `postgres` and `rabbitmq` are intended for development and staging environments only.** The defaults store data on default storage and are not configured for backups or monitoring. **For production, run PostgreSQL and RabbitMQ yourself** (a managed service, or a self-hosted deployment you own end-to-end), then disable the bundled ones:
>
> ```bash
> helm install my-hatchet-stack hatchet/hatchet-stack \
>   --set postgres.enabled=false \
>   --set rabbitmq.enabled=false \
>   --set sharedConfig.env.DATABASE_URL='postgres://user:pass@my-db:5432/hatchet?sslmode=require' \
>   --set sharedConfig.env.SERVER_MSGQUEUE_RABBITMQ_URL='amqp://user:pass@my-broker:5672/'
> ```
>
> When `postgres`/`rabbitmq` are disabled, the chart no longer renders `DATABASE_URL` / `SERVER_MSGQUEUE_RABBITMQ_URL` into the `hatchet-shared-config` Secret, so you must supply them yourself (via `sharedConfig.env` as above, or your own Secret referenced through each component's `envFrom`).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `postgres.enabled` | bool | `true` | Deploy the bundled CloudNativePG `Cluster` (requires the CloudNativePG operator). |
| `postgres.auth.username` | string | `"hatchet"` | Application role/owner name. |
| `postgres.auth.password` | string | `"hatchet"` | Application role password. |
| `postgres.auth.database` | string | `"hatchet"` | Application database name. |
| `postgres.image` | string | `"ghcr.io/cloudnative-pg/postgresql:17.6"` | CloudNativePG-compatible PostgreSQL image. |
| `postgres.instances` | int | `1` | Number of PostgreSQL instances (1 = single primary). |
| `postgres.storage.size` | string | `"8Gi"` | PersistentVolume size per instance. |
| `postgres.storage.storageClass` | string | `""` | StorageClass (empty = cluster default). |
| `postgres.resources` | object | `{}` | Pod resource requests/limits. |
| `postgres.port` | int | `5432` | Read-write service port (used in `DATABASE_URL`). |
| `postgres.sslmode` | string | `"require"` | sslmode used in the composed `DATABASE_URL`. |
| `postgres.parameters` | object | `{}` | Extra `postgresql.conf` parameters (`timezone=UTC` is always forced). |
| `postgres.initExtensions` | list | `[]` | SQL run once as superuser after bootstrap, e.g. `["CREATE EXTENSION IF NOT EXISTS pgcrypto;"]`. |
| `rabbitmq.enabled` | bool | `true` | Deploy the bundled `RabbitmqCluster` (requires the RabbitMQ Cluster Operator). |
| `rabbitmq.auth.username` | string | `"hatchet"` | Default user name (provisioned via the operator's default-user Secret). |
| `rabbitmq.auth.password` | string | `"hatchet"` | Default user password. |
| `rabbitmq.image` | string | `"rabbitmq:4.1-management"` | RabbitMQ image. |
| `rabbitmq.replicas` | int | `1` | Number of RabbitMQ nodes. |
| `rabbitmq.port` | int | `5672` | AMQP service port (used in `SERVER_MSGQUEUE_RABBITMQ_URL`). |
| `rabbitmq.persistence.storage` | string | `"8Gi"` | PersistentVolume size per node. |
| `rabbitmq.persistence.storageClassName` | string | `""` | StorageClass (empty = cluster default). |
| `rabbitmq.resources` | object | `{}` | Pod resource requests/limits. |

> The `postgres`/`rabbitmq` sections also accept any additional keys, which are passed through to the rendered `Cluster` / `RabbitmqCluster`. See the [CloudNativePG](https://cloudnative-pg.io/docs/) and [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/using-operator) docs for the full spec.

### Migrating from a pre-1.0 (Bitnami) release

`1.0.0` replaces the Bitnami PostgreSQL/RabbitMQ subcharts with the CloudNativePG and
RabbitMQ Cluster operators — a deliberate move to actively-maintained, operator-managed
datastores (the Bitnami catalog deprecation set the deadline, not the direction). This is a
**breaking change for the bundled datastores**: data is not migrated in place, and the
operators must be installed before upgrading.

See **[MIGRATION.md](https://github.com/hatchet-dev/hatchet-charts/blob/main/MIGRATION.md)**
for the rationale and step-by-step guide. Users on external datastores
(`postgres.enabled=false` / `rabbitmq.enabled=false`) are unaffected.

### Caddy (optional)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `caddy.enabled` | bool | `false` | Enable the optional Caddy reverse proxy. |
| `caddy.address` | string | `"http://localhost:8080"` | Caddy site address (the top line of the generated Caddyfile block). The default serves only requests with `Host: localhost`, matching the `kubectl port-forward` workflow. Set to `":8080"` to serve any `Host`, e.g. when fronting Caddy with an ingress. |
| `caddy.service.type` | string | `"LoadBalancer"` | Service type for the Caddy reverse proxy. Set to `ClusterIP` to front Caddy with your own ingress instead of provisioning a cloud load balancer. |
| `caddy.image.repository` | string | `"caddy"` | Caddy image repository. |
| `caddy.image.tag` | string | `"2.7.6-alpine"` | Caddy image tag. |
| `caddy.image.pullPolicy` | string | `"IfNotPresent"` | Caddy image pull policy. |

## License

MIT. See [LICENSE](https://github.com/hatchet-dev/hatchet-charts/blob/main/LICENSE).
