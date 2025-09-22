# Changelog - Hatchet API

All notable changes to the Hatchet API Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.10.0] - 2025-09-22

- Use image tag `v0.71.0` for all Hatchet services
- Change default image `pullPolicy` to be `IfNotPresent` from `Always`
- Allow new Helm value option `deployment.extraPorts` to expose extra ports such as the Prometheus metrics server
- Add a new `initContainer` called `check-db-connection` for the setup job to check if the database is live and reachable as a first step

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

## [0.6.1] - 2024-08-22

## [0.6.0] - 2024-08-22

## [0.5.0] - 2024-08-20

## [0.4.0] - 2024-06-18

## [0.3.0] - 2024-06-13

## [0.2.0] - 2024-03-02

## [0.1.0] - 2024-02-21

[Unreleased]: https://github.com/hatchet-dev/hatchet-charts/compare/hatchet-api-0.10.0...HEAD
[0.10.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.10.0
[0.9.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.9.2
[0.9.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.9.1
[0.9.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.9.0
[0.8.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.8.0
[0.7.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.7.0
[0.6.6]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.6.6
[0.6.5]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.6.5
[0.6.4]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.6.4
[0.6.3]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.6.3
[0.6.2]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.6.2
[0.6.1]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.6.1
[0.6.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.6.0
[0.5.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.5.0
[0.4.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.4.0
[0.3.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.3.0
[0.2.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.2.0
[0.1.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/hatchet-api-0.1.0