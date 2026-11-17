# Changelog - brickie

All notable changes to the brickie Helm chart will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.5] - 2026-11-17

- Sandbox guest kernels boot in FIPS mode: the chart installs a Kata drop-in that adds `fips=1` to the `kata-clh` kernel parameters. `/proc/sys/crypto/fips_enabled` reads `1` inside every sandbox. Set `kata-deploy.shims.clh.dropIn` to `""` to turn it off.
- `sandbox.initContainers`: Kubernetes container specs run as init containers in every sandbox pod before the sandbox starts, for operator checks such as a FIPS verification script. Needs brickie 0.1.7.
- The agent-sandbox controller image is `ghcr.io/hatchet-dev/agent-sandbox-controller`, a FIPS 140-3 build of the upstream release, instead of the upstream image.
- Update the default brickie image to [`0.1.7`](https://github.com/hatchet-dev/brickie/releases/tag/v0.1.7): JSON logs, a clean shutdown, and sandboxd from our FIPS build `ghcr.io/hatchet-dev/sandboxd:v1.0.8`.

## [0.1.4] - 2026-11-17

- Update the default brickie image to [`0.1.6`](https://github.com/hatchet-dev/brickie/releases/tag/v0.1.6), which fixes snapshot restore for sandbox images that run as a non-root user.

## [0.1.3] - 2026-11-10

- `sandbox.runtime` accepts any RuntimeClass name and the alias `nitro` for EKS `isolated-sandbox`; `auto` tries `kata-clh`, `gvisor`, then `isolated-sandbox`. Needs brickie 0.1.5.
- Update the default brickie image to [`0.1.5`](https://github.com/hatchet-dev/brickie/releases/tag/v0.1.5).

## [0.1.2] - 2026-10-30

- `sandbox.nodeSelector` and `sandbox.tolerations` place sandbox pods on labelled or tainted nodes, on top of what the runtime class adds.
- Update the default brickie image to [`0.1.4`](https://github.com/hatchet-dev/brickie/releases/tag/v0.1.4).

## [0.1.1] - 2026-10-30

- `extraEnv` and `extraEnvFrom` add environment to the provider container, for cloud settings such as `AWS_USE_FIPS_ENDPOINT`. Nothing in them reaches sandbox pods.
- Update the default brickie image to [`0.1.3`](https://github.com/hatchet-dev/brickie/releases/tag/v0.1.3).

## [0.1.0] - 2026-10-28

- First release: the brickie provider with the bundled agent-sandbox controller, the kata-deploy chart (Cloud Hypervisor shim) and an optional gVisor installer. Default brickie image [`0.1.2`](https://github.com/hatchet-dev/brickie/releases/tag/v0.1.2).
