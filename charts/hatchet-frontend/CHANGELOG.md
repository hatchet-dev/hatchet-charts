# Changelog - Hatchet Frontend

All notable changes to the Hatchet Frontend Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.13.3] - 2026-07-17

- Move the PodDisruptionBudget out of `deployment.yaml` into its own `pdb.yaml` template, and bump it from the removed `policy/v1beta1` API version to `policy/v1`. Setting `podDisruptionBudget` previously failed to install on Kubernetes 1.25+, where `policy/v1beta1` no longer exists.
- Fix the PodDisruptionBudget template rendering invalid YAML when `podDisruptionBudget` sets more than one key (for example `maxUnavailable` together with `unhealthyPodEvictionPolicy`).

## [0.13.2] - 2026-07-16

- Chart version bump only; no template changes in this release.

## [0.13.1] - 2026-07-16

- Chart version bump only; no template changes in this release.

## [0.13.0] - 2026-07-14

- Updates the default Hatchet image to [`v0.94.10`](https://github.com/hatchet-dev/hatchet/releases/tag/v0.94.10).

## [0.12.4] - 2026-07-09

- Chart version bump only; no template changes in this release.

## [0.12.3] - 2026-07-07

- Chart version bump only; no template changes in this release.

## [0.12.2] - 2026-07-06

- Add icon for chart
- Enable signing of chart

## [0.12.1] - 2026-07-05

- Added JSON schema for values

## [0.12.0] - 2026-06-30

- Updates the default Hatchet image to [`v0.90.13`](https://github.com/hatchet-dev/hatchet/releases/tag/v0.90.13).

## [0.11.0] - 2026-05-19

- Chart version bump only; no template changes in this release.

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

## [0.10.0] - 2025-09-22

- Use image tag `v0.71.0` for all Hatchet services
- Change default image `pullPolicy` to be `IfNotPresent` from `Always`

## [0.9.2] - 2025-04-03

## [0.9.1] - 2025-04-03

## [0.9.0] - 2025-04-01

## [0.8.0] - 2024-11-25

## [0.7.0] - 2024-11-22

## [0.6.6] - 2024-09-26

## [0.6.5] - 2024-09-26

## [0.6.4] - 2024-09-26

## [0.6.3] - 2024-08-23

## [0.6.2] - 2024-08-23

## [0.6.0] - 2024-08-22

## [0.5.0] - 2024-08-20

## [0.4.0] - 2024-06-18

## [0.3.0] - 2024-06-13

## [0.2.0] - 2024-03-02

## [0.1.0] - 2024-02-21

[Unreleased]: https://github.com/hatchet-dev/hatchet-charts/compare/hatchet-frontend-0.13.3...HEAD
[0.13.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.13.3
[0.13.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.13.2
[0.13.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.13.1
[0.13.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.13.0
[0.12.4]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.12.4
[0.12.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.12.3
[0.12.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.12.2
[0.12.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.12.1
[0.12.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.12.0
[0.11.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.11.0
[0.10.5]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.10.5
[0.10.4]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.10.4
[0.10.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.10.3
[0.10.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.10.2
[0.10.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.10.1
[0.10.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.10.0
[0.9.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.9.2
[0.9.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.9.1
[0.9.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.9.0
[0.8.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.8.0
[0.7.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.7.0
[0.6.6]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.6.6
[0.6.5]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.6.5
[0.6.4]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.6.4
[0.6.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.6.3
[0.6.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.6.2
[0.6.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.6.0
[0.5.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.5.0
[0.4.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.4.0
[0.3.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.3.0
[0.2.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.2.0
[0.1.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-frontend-0.1.0
