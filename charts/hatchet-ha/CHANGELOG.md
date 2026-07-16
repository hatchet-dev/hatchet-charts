# Changelog - Hatchet HA

All notable changes to the Hatchet HA (High Availability) Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.13.2] - 2026-07-16

- The bundled `hatchet-api` subcharts now run all bootstrap work (migration, seed, quickstart, create-worker-token) through Helm install/upgrade hooks: completed bootstrap pods are cleaned up automatically and a failed bootstrap step aborts the release. Bootstrap Jobs also move to stable names (`<release>-migration`, `-seed`, `-quickstart`, `-worker-token`). See the `hatchet-api` changelog for details.

## [0.13.1] - 2026-07-16

- Bump the bundled `hatchet-api` and `hatchet-frontend` subcharts to `0.13.1`.

## [0.13.0] - 2026-07-14

- Updates the default Hatchet image to [`v0.94.10`](https://github.com/hatchet-dev/hatchet/releases/tag/v0.94.10).

## [0.12.4] - 2026-07-09

- Add `global.sharedConfigSecretName` to rename the `hatchet-shared-config` Secret (defaults to `hatchet-shared-config`). The value is passed through `tpl`, so a release-scoped name such as `'{{ .Release.Name }}-shared-config'` lets multiple releases run in the same namespace without a name collision.
- Render each backend component's `envFrom` (and `deploymentEnvFrom`) through `tpl`, so secret/configmap names can reference release values.

## [0.12.3] - 2026-07-07

- Pin `SERVER_SERVICES` per component: `grpc-api` for `grpc`, `controllers` for `controllers`, and `scheduler` for `scheduler`.

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

## [0.7.3] - 2024-11-22

## [0.7.2] - 2024-11-22

## [0.7.1] - 2024-11-22

## [0.7.0] - 2024-11-22

[Unreleased]: https://github.com/hatchet-dev/hatchet-charts/compare/hatchet-ha-0.13.2...HEAD
[0.13.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.13.2
[0.13.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.13.1
[0.13.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.13.0
[0.12.4]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.12.4
[0.12.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.12.3
[0.12.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.12.2
[0.12.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.12.1
[0.12.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.12.0
[0.11.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.11.0
[0.10.5]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.10.5
[0.10.4]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.10.4
[0.10.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.10.3
[0.10.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.10.2
[0.10.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.10.1
[0.10.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.10.0
[0.9.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.9.2
[0.9.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.9.1
[0.9.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.9.0
[0.8.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.8.0
[0.7.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.7.3
[0.7.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.7.2
[0.7.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.7.1
[0.7.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-ha-0.7.0
