# Hatchet Helm Charts

This repository contains Helm charts for [Hatchet](https://hatchet.run).

To view the docs for setting up these charts, see [Kubernetes Quickstart](https://docs.hatchet.run/self-hosting/kubernetes-quickstart).

For detailed changes to individual charts, see:

- **[Hatchet Stack](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-stack/CHANGELOG.md)** - Main umbrella chart containing all components
- **[Hatchet HA](https://github.com/hatchet-dev/hatchet-charts/blob/main/charts/hatchet-ha/CHANGELOG.md)** - High availability deployment chart

## Long-running migrations

The `hatchet-api` chart runs schema migrations in two places, both controlled by the same value:

- On `helm install` — as an init container inside the setup Job.
- On `helm upgrade` — as a dedicated `pre-upgrade` hook Job. If the hook fails, the upgrade fails before any new application pods roll out.

Both Jobs default to `migrationJob.activeDeadlineSeconds: 900` (15 minutes). If you expect a migration to take longer (e.g. a large table rewrite on an established database), raise the value **and** raise the Helm client `--timeout` so it covers migration time plus the rollout that follows. A safe margin is `--timeout` ≈ `activeDeadlineSeconds / 60 + 5` minutes.

Standalone `hatchet-api` chart:

```bash
helm upgrade hatchet-api charts/hatchet-api \
  --set migrationJob.activeDeadlineSeconds=1800 \
  --wait --timeout=35m
```

Umbrella `hatchet-stack` / `hatchet-ha` charts (the value is nested under `api.`):

```bash
helm upgrade hatchet charts/hatchet-stack \
  --set api.migrationJob.activeDeadlineSeconds=1800 \
  --wait --timeout=35m
```

Related knobs:

- `migrationJob.backoffLimit` (default `1`) — retries before the migration Job is marked failed.
- `retainFailedHooks` (default `true`) — keeps the failed pre-upgrade hook Job around so you can `kubectl logs job/<release>-migration` to debug.

## Local validation

Unit tests use the [helm-unittest](https://github.com/helm-unittest/helm-unittest) plugin, pinned to the same version CI runs:

```bash
helm plugin install https://github.com/helm-unittest/helm-unittest --version 1.1.0
helm unittest charts/hatchet-api
```

End-to-end test on [kind](https://kind.sigs.k8s.io/) installing only the `hatchet-api` chart against an external Postgres (mirrors the `migration-e2e` CI job). Verifies that:

- migrations run on install (as an init container in the setup Job),
- the API Deployment becomes Ready against a fresh DB,
- the `pre-upgrade` hook Job completes on upgrade.

Two things the bare `helm install hatchet-api ...` recipe in the API chart's README does not cover that you need for the Deployment to actually come up:

1. **Postgres timezone must be UTC.** Hatchet refuses to start against a DB whose `TIMEZONE` setting is anything else (the bitnami chart defaults to `GMT`). We set it via `primary.extendedConfiguration` on the `pg` install below.
2. **A `hatchet-config` Secret with server-level config.** The chart's `deploymentEnvFrom` default points at a Secret named `hatchet-config`, and `setupJob` (`quickstartJob.enabled=true` by default) runs `hatchet-admin k8s quickstart` which generates `SERVER_AUTH_COOKIE_SECRETS` + the `SERVER_ENCRYPTION_*` Tink keysets into that Secret. We pre-create the Secret with the non-generated values (`DATABASE_URL`, cookie domain, gRPC, admin user). When installed via `hatchet-stack` this Secret is rendered for you (`hatchet-shared-config`); standalone we need to provide it ourselves. We also set `SERVER_MSGQUEUE_KIND=postgres` to use the Postgres-backed message queue instead of the default RabbitMQ (we don't install RabbitMQ here).

```bash
kind create cluster
helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo update

helm install pg bitnami/postgresql \
  --set image.repository=bitnamilegacy/postgresql \
  --set global.security.allowInsecureImages=true \
  --set auth.username=hatchet --set auth.password=hatchet --set auth.database=hatchet \
  --set tls.enabled=false \
  --set primary.extendedConfiguration="timezone = 'UTC'" \
  --wait --timeout=5m

# Pre-create the hatchet-config Secret. The chart's setup Job will UPDATE this
# Secret in-place with the generated cookie/encryption keys via hatchet-admin.
kubectl create secret generic hatchet-config \
  --from-literal=DATABASE_URL='postgres://hatchet:hatchet@pg-postgresql:5432/hatchet?sslmode=disable' \
  --from-literal=SERVER_URL='http://localhost:8080' \
  --from-literal=SERVER_AUTH_COOKIE_DOMAIN='localhost' \
  --from-literal=SERVER_AUTH_COOKIE_INSECURE='t' \
  --from-literal=SERVER_AUTH_SET_EMAIL_VERIFIED='t' \
  --from-literal=SERVER_AUTH_BASIC_AUTH_ENABLED='t' \
  --from-literal=SERVER_GRPC_BROADCAST_ADDRESS='localhost:7070' \
  --from-literal=SERVER_GRPC_INSECURE='t' \
  --from-literal=SERVER_MSGQUEUE_KIND='postgres' \
  --from-literal=ADMIN_EMAIL='admin@example.com' \
  --from-literal=ADMIN_PASSWORD='Admin123!!'

# Reusable values. We point envFrom at hatchet-config too so the migration
# init container can resolve DATABASE_URL (deploymentEnvFrom is only wired
# into the Deployment, not the Jobs).
API_ARGS=(
  --set-json 'envFrom=[{"secretRef":{"name":"hatchet-config"}}]'
  --set seedJob.enabled=false
  --set workerTokenJob.enabled=false
  --set ingress.enabled=false
)

# Install (runs migrations as an init container in the setup Job; --wait blocks until the Deployment is Ready).
helm install hatchet-api-test charts/hatchet-api "${API_ARGS[@]}" --wait --timeout=10m

kubectl wait --for=condition=complete \
  job -l app.kubernetes.io/instance=hatchet-api-test --timeout=5m
kubectl rollout status deploy/hatchet-api-test --timeout=5m

# Upgrade. `helm upgrade --wait` synchronously runs the pre-upgrade
# migration hook Job; if it fails, the upgrade fails. On success the Job
# is deleted per its hook-delete-policy (hook-succeeded), so we don't
# `kubectl wait` for it afterward — the upgrade returning 0 is the
# assertion.
helm upgrade hatchet-api-test charts/hatchet-api "${API_ARGS[@]}" --wait --timeout=10m
kubectl rollout status deploy/hatchet-api-test --timeout=5m
```
