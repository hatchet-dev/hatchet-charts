# AGENTS

## CI

- Any CI surface that boots a Hatchet server instance (helm install/upgrade of `hatchet-api`/`hatchet-stack`/`hatchet-ha`, `ct install`, kind loadtests, or a pre-created `hatchet-config` secret) must set `SERVER_SECURITY_CHECK_ENABLED=false`. The check defaults to enabled and phones home to `security.hatchet.run`; CI must never do that. Set it via `sharedConfig.env.SERVER_SECURITY_CHECK_ENABLED` (or `env.` for the standalone `hatchet-api` chart) in the relevant `ci/ct-values.yaml`, `--set`, or secret literal.
