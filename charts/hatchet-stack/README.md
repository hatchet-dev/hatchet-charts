# hatchet-stack

A Helm chart that deploys [Hatchet](https://hatchet.run) on Kubernetes together with
a PostgreSQL database and RabbitMQ. This is the main umbrella chart and the
recommended starting point for self-hosting Hatchet.

The backend runs as two components — `api` and `engine` (the engine bundles the gRPC
server, controllers and scheduler). For a horizontally-scaled split of those engine roles, use
[`hatchet-ha`](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-ha) instead.

## Getting started

To view the docs for setting up this chart, see
[Kubernetes Quickstart](https://docs.hatchet.run/self-hosting/kubernetes-quickstart).

## TL;DR

```bash
helm install hatchet ./charts/hatchet-stack
```

## Prerequisites

- Kubernetes 1.18+
- Helm 3.8+

## Installing the chart

```bash
helm install my-release ./charts/hatchet-stack
```

## Uninstalling the chart

```bash
helm uninstall my-release
```

## Dependencies

| Component | Subchart | Alias | Condition |
|-----------|----------|-------|-----------|
| API | [hatchet-api](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-api) | `api` | `api.enabled` |
| Engine | [hatchet-api](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-api) | `engine` | `engine.enabled` |
| Frontend | [hatchet-frontend](https://github.com/hatchet-dev/hatchet-charts/tree/main/charts/hatchet-frontend) | `frontend` | `frontend.enabled` |
| PostgreSQL | [bitnami/postgresql](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) | `postgres` | `postgres.enabled` |
| RabbitMQ | [bitnami/rabbitmq](https://github.com/bitnami/charts/tree/main/bitnami/rabbitmq) | `rabbitmq` | `rabbitmq.enabled` |

Each Hatchet component accepts the full set of [`hatchet-api`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-api/README.md#parameters)
or [`hatchet-frontend`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-frontend/README.md#parameters) values under its alias key
(e.g. `api.resources`, `engine.replicaCount`). The `postgres` and `rabbitmq` sections
accept all values of their respective Bitnami subcharts.

Values flow into the components two ways:

1. **Per-component overrides** are passed straight through by Helm — anything under
   `api.*`, `engine.*` or `frontend.*` overrides the corresponding subchart value.
2. **`sharedConfig`** is rendered by this chart into a `hatchet-shared-config` Secret,
   which every backend component loads via `envFrom`. This is how settings like the
   server URL, gRPC address and admin credentials reach all components at once.

## Values validation

This chart ships a [`values.schema.json`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-stack/values.schema.json). Helm validates your
supplied values against it on `install`, `upgrade`, `template` and `lint`.

## Parameters

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

> See [`hatchet-api`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-api/README.md#parameters) for the full set of values available
> under `api` and `engine`, and [`hatchet-frontend`](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-frontend/README.md#parameters)
> for `frontend`.

### Bundled PostgreSQL & RabbitMQ

> ⚠️ **The bundled `postgres` and `rabbitmq` subcharts are intended for development
> and staging only.** They are single-instance, store data on default storage, and
> are not configured for backups, high availability or monitoring. **For production,
> run PostgreSQL and RabbitMQ yourself** (a managed service, or a self-hosted
> deployment you own end-to-end), then disable the bundled ones:
>
> ```bash
> helm install my-release ./charts/hatchet-stack \
>   --set postgres.enabled=false \
>   --set rabbitmq.enabled=false \
>   --set sharedConfig.env.DATABASE_URL='postgres://user:pass@my-db:5432/hatchet?sslmode=require' \
>   --set sharedConfig.env.SERVER_MSGQUEUE_RABBITMQ_URL='amqp://user:pass@my-broker:5672/'
> ```
>
> When `postgres`/`rabbitmq` are disabled, the chart no longer renders `DATABASE_URL`
> / `SERVER_MSGQUEUE_RABBITMQ_URL` into the `hatchet-shared-config` Secret, so you
> must supply them yourself (via `sharedConfig.env` as above, or your own Secret
> referenced through each component's `envFrom`).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `postgres.enabled` | bool | `true` | Deploy the bundled Bitnami PostgreSQL. |
| `postgres.image.repository` | string | `"bitnamilegacy/postgresql"` | PostgreSQL image repository. |
| `postgres.auth.username` | string | `"hatchet"` | PostgreSQL username. |
| `postgres.auth.password` | string | `"hatchet"` | PostgreSQL password. |
| `postgres.auth.database` | string | `"hatchet"` | PostgreSQL database name. |
| `postgres.tls.enabled` | bool | `false` | Enable PostgreSQL TLS. |
| `postgres.primary.resourcesPreset` | string | `"medium"` | PostgreSQL resources preset. |
| `postgres.primary.service.ports.postgresql` | int | `5432` | PostgreSQL service port. |
| `rabbitmq.enabled` | bool | `true` | Deploy the bundled Bitnami RabbitMQ. |
| `rabbitmq.image.repository` | string | `"bitnamilegacy/rabbitmq"` | RabbitMQ image repository. |
| `rabbitmq.auth.username` | string | `"hatchet"` | RabbitMQ username. |
| `rabbitmq.auth.password` | string | `"hatchet"` | RabbitMQ password. |
| `rabbitmq.service.ports.amqp` | int | `5672` | RabbitMQ AMQP service port. |

> Both sections accept the full set of values for the upstream Bitnami
> [postgresql](https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml)
> and [rabbitmq](https://github.com/bitnami/charts/blob/main/bitnami/rabbitmq/values.yaml)
> charts.

### Caddy (optional)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `caddy.enabled` | bool | `false` | Enable the optional Caddy reverse proxy. |
| `caddy.image.repository` | string | `"caddy"` | Caddy image repository. |
| `caddy.image.tag` | string | `"2.7.6-alpine"` | Caddy image tag. |
| `caddy.image.pullPolicy` | string | `"IfNotPresent"` | Caddy image pull policy. |

## License

MIT. See [LICENSE](https://github.com/hatchet-dev/hatchet-charts/blob/main/LICENSE).
