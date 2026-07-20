# Changelog - Hatchet Stack

All notable changes to the Hatchet Stack Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-07-16

### Changed (BREAKING)

- **Replaced the Bitnami PostgreSQL and RabbitMQ subcharts with operator-managed datastores.**
  The bundled `postgres` now renders a [CloudNativePG](https://cloudnative-pg.io) `Cluster`
  and `rabbitmq` renders a [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview)
  `RabbitmqCluster`. This removes the unmaintained `bitnamilegacy/*` images.
- **New prerequisite:** when the bundled datastores are enabled (the default), the CloudNativePG
  and RabbitMQ Cluster operators must be installed in the cluster first. Use `hack/install-operators.sh`.
- **New `postgres` / `rabbitmq` value schema.** Bitnami-specific keys (`postgres.image.repository`,
  `postgres.tls`, `postgres.primary.*`, `postgres.global.security`, `rabbitmq.image.repository`,
  `rabbitmq.service.ports.*`, `global.security.allowInsecureImages`) are gone. See the chart README
  for the new keys (`postgres.instances`, `postgres.storage.size`, `postgres.image`,
  `rabbitmq.replicas`, `rabbitmq.persistence.storage`, `rabbitmq.image`, …). `postgres.auth.*` and
  `rabbitmq.auth.*` are retained.
- `DATABASE_URL` now targets the CloudNativePG read-write service (`<release>-postgres-rw`).

### Migration

- The bundled datastore is **not** migrated in place: a `helm upgrade` removes the old Bitnami
  PostgreSQL StatefulSet and bootstraps a fresh, empty CloudNativePG cluster. Back up
  (`pg_dump`) before upgrading and restore afterwards — see "Migrating from a pre-1.0 (Bitnami)
  release" in the chart README. Users on external datastores (`postgres.enabled=false` /
  `rabbitmq.enabled=false`) are unaffected.

## [0.13.3] - 2026-07-17

- Add `caddy.address` to configure the Caddy site address (the top line of the generated Caddyfile). Defaults to `http://localhost:8080`, unchanged from previous releases, which serves only requests with `Host: localhost` and matches the documented `kubectl port-forward` workflow. Set it to `":8080"` to serve any `Host` instead, e.g. when fronting Caddy with an ingress, service mesh or VPN overlay such as Tailscale.
- Add `caddy.service.type` to configure the Caddy Service type. Defaults to `LoadBalancer`, unchanged from previous releases. Set it to `ClusterIP` to front Caddy with your own ingress instead of provisioning a cloud load balancer.
- Bump the bundled `hatchet-api` and `hatchet-frontend` subcharts to `0.13.3`: the PodDisruptionBudget moves to the `policy/v1` API version so it installs on Kubernetes 1.25+, and `image.pullSecrets` now reach the bootstrap Job pod specs. See those charts' changelogs for details.
- Raise the documented Kubernetes prerequisite from 1.18+ to 1.30+. The chart already depended on APIs newer than 1.18, so the previous floor was inaccurate.

## [0.13.2] - 2026-07-16

- The bundled `hatchet-api` subcharts now clean up their setup and `create-worker-token` Jobs automatically via `jobTTLSecondsAfterFinished` (default `600`), so Completed bootstrap pods no longer accumulate. See the `hatchet-api` changelog for details.
- Bump the bundled `hatchet-api` and `hatchet-frontend` subcharts to `0.13.2`.

## [0.13.1] - 2026-07-16

- Remove the hardcoded `SERVER_DEFAULT_ENGINE_VERSION` key from the rendered `hatchet-shared-config` Secret.
- Bump the bundled `hatchet-api` and `hatchet-frontend` subcharts to `0.13.1`.

## [0.13.0] - 2026-07-14

- Updates the default Hatchet image to [`v0.94.10`](https://github.com/hatchet-dev/hatchet/releases/tag/v0.94.10).

## [0.12.4] - 2026-07-09

- Add `global.sharedConfigSecretName` to rename the `hatchet-shared-config` Secret (defaults to `hatchet-shared-config`). The value is passed through `tpl`, so a release-scoped name such as `'{{ .Release.Name }}-shared-config'` lets multiple releases run in the same namespace without a name collision.
- Render each backend component's `envFrom` (and `deploymentEnvFrom`) through `tpl`, so secret/configmap names can reference release values.

## [0.12.3] - 2026-07-07

- Chart version bump only; no template changes in this release.

## [0.12.2] - 2026-07-06

- Add icon for chart
- Enable signing of chart

## [0.12.1] - 2026-07-05

- Added JSON schema for values
- Added NOTES.txt

## [0.12.0] - 2026-06-30

- Updates the default Hatchet image to [`v0.90.13`](https://github.com/hatchet-dev/hatchet/releases/tag/v0.90.13).

## [0.11.0] - 2026-05-19

- Run API database migrations as a Helm pre-upgrade hook so failed migrations block new application pods from rolling out.

## [0.10.5] - 2026-05-01

- Updates the default Hatchet image to [`v0.84.0`](https://github.com/hatchet-dev/hatchet/releases/tag/v0.84.0).

## [0.10.4] - 2026-03-11

- Updates the default Hatchet image to [`v0.79.12`](https://github.com/hatchet-dev/hatchet/releases/tag/v0.79.12).

## [0.10.3] - 2026-01-13

- Updates the default Hatchet image to [`v0.74.14`](https://github.com/hatchet-dev/hatchet/releases/tag/v0.74.14).

## [0.10.2] - 2026-01-09

- Updates the default Hatchet image to [`v0.74.9`](https://github.com/hatchet-dev/hatchet/releases/tag/v0.74.9).

## [0.10.1] - 2025-11-01

- Introduce `sharedConfig.image.tag` variable to set the same tag for all Hatchet images
- Fix Caddy's image tag value
- Set `postgres.primary.resourcesPreset` to `"medium"`

## [0.10.0] - 2025-09-22

- Use image tag `v0.71.0` for all Hatchet services
- Change default image `pullPolicy` to be `IfNotPresent` from `Always`
- Allow option to set custom Caddy image
- Use `bitnamilegacy` repository for Bitnami charts
- Upgrade Bitnami `postgresql` chart to `16.7.27`
- Upgrade Bitnami `rabbitmq` chart to `16.0.14`

## [0.9.2] - 2025-04-03

## [0.9.1] - 2025-04-03

## [0.9.0] - 2025-04-01

## [0.8.0] - 2024-11-25

## [0.7.0] - 2024-11-22

## [0.6.6] - 2024-09-26

## [0.6.5] - 2024-09-26

## [0.6.3] - 2024-08-23

## [0.6.2] - 2024-08-23

## [0.6.1] - 2024-08-22

## [0.6.0] - 2024-08-22

## [0.5.0] - 2024-08-20

## [0.4.0] - 2024-06-18

## [0.3.0] - 2024-06-13

## [0.2.0] - 2024-03-02

## [0.1.0] - 2024-02-21

[Unreleased]: https://github.com/hatchet-dev/hatchet-charts/compare/hatchet-stack-0.13.3...HEAD
[0.13.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.13.3
[0.13.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.13.2
[0.13.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.13.1
[0.13.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.13.0
[0.12.4]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.12.4
[0.12.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.12.3
[0.12.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.12.2
[0.12.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.12.1
[0.12.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.12.0
[0.11.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.11.0
[0.10.5]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.10.5
[0.10.4]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.10.4
[0.10.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.10.3
[0.10.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.10.2
[0.10.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.10.1
[0.10.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.10.0
[0.9.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.9.2
[0.9.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.9.1
[0.9.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.9.0
[0.8.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.8.0
[0.7.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.7.0
[0.6.6]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.6.6
[0.6.5]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.6.5
[0.6.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.6.3
[0.6.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.6.2
[0.6.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.6.1
[0.6.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.6.0
[0.5.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.5.0
[0.4.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.4.0
[0.3.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.3.0
[0.2.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.2.0
[0.1.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-stack-0.1.0
