# Changelog - Hatchet HA

All notable changes to the Hatchet HA (High Availability) Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/hatchet-dev/hatchet-charts/compare/hatchet-ha-0.10.1...HEAD
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