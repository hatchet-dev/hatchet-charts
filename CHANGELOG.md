# Changelog

All notable changes to this Helm charts repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.71.0] - 2025-09-18

### Changed
- Chart versions are now in sync with the release image tags
- Updated Hatchet components from v0.58.0 to v0.71.0 across all charts
- Changed image pull policy from "Always" to "IfNotPresent" for improved performance
- Standardized version references in Chart.yaml files

### Added
- Added `update-version.sh` script for automated version updates across Helm charts
- Added explicit pull policy configuration for migration and setup jobs

### Fixed
- Updated dependencies in Chart.lock files

---

## Chart Versions Included

This release includes the following chart versions:

- **hatchet-stack**: 0.71.0
- **hatchet-api**: 0.71.0
- **hatchet-frontend**: 0.71.0
- **hatchet-ha**: 0.71.0

[Unreleased]: https://github.com/hatchet-dev/hatchet-charts/compare/v0.71.0...HEAD
[0.71.0]: https://github.com/hatchet-dev/hatchet-charts/releases/tag/v0.71.0