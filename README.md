# Hatchet Helm Charts

This repository contains Helm charts for [Hatchet](https://hatchet.run).

To view the docs for setting up these charts, see [Kubernetes Quickstart](https://docs.hatchet.run/self-hosting/kubernetes-quickstart). 

For detailed changes to individual charts, see:

- **[Hatchet Stack](charts/hatchet-stack/CHANGELOG.md)** - Main umbrella chart containing all components
- **[Hatchet API](charts/hatchet-api/CHANGELOG.md)** - API service chart
- **[Hatchet Frontend](charts/hatchet-frontend/CHANGELOG.md)** - Frontend service chart
- **[Hatchet HA](charts/hatchet-ha/CHANGELOG.md)** - High availability deployment chart

## Local validation

Unit tests use the [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin, pinned to the same version CI runs:

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest --version 1.1.0
helm unittest charts/hatchet-api
```
