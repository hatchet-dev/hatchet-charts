# Migrating to v1.0.0 (moving away from Bitnami)

`hatchet-stack` and `hatchet-ha` `1.0.0` replace the bundled **Bitnami** PostgreSQL and
RabbitMQ subcharts with operator-managed datastores:

| Before (`0.x`) | After (`1.0.0`) |
|----------------|-----------------|
| Bitnami `postgresql` subchart (`bitnamilegacy/postgresql`) | [CloudNativePG](https://cloudnative-pg.io) `Cluster` |
| Bitnami `rabbitmq` subchart (`bitnamilegacy/rabbitmq`) | [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview) `RabbitmqCluster` |

## Why we changed this

Bitnami [froze its free images into an unmaintained `bitnamilegacy/*` catalog on 29 September
2025](https://github.com/bitnami/charts/issues/35164). We want to move towards alternatives that are actively maintained and receive regular security updates.

This is also the direction the wider ecosystem took when Bitnami deprecated its catalog — see
[goauthentik/helm#371](https://github.com/goauthentik/helm/issues/371) and the community
[Bitnami → CloudNativePG](https://k8scockpit.tech/posts/cloudnative-pg/) migration guides.

The bundled datastores remain **development/staging only**. For production you should still run
PostgreSQL and RabbitMQ you operate yourself (`postgres.enabled=false` / `rabbitmq.enabled=false`).

## Am I affected?

- **Using the bundled datastores (the default)?** Yes — read on.
- **Already on external datastores** (`postgres.enabled=false` / `rabbitmq.enabled=false`)?
  No. Your `DATABASE_URL` / `SERVER_MSGQUEUE_RABBITMQ_URL` are untouched. Just be aware of the
  [changed value schema](#value-schema-changes) if you set any `postgres.*` / `rabbitmq.*` keys.

## What changed

- The bundled datastores are now **custom resources**, so their operators (CRDs + controller)
  must exist in the cluster **before** you install/upgrade the chart. Install both once per
  cluster:

  ```bash
  curl -fsSL https://raw.githubusercontent.com/hatchet-dev/hatchet-charts/main/scripts/install-operators.sh | bash
  ```

- `DATABASE_URL` now targets the CloudNativePG read-write service `<release>-postgres-rw`
  (was `<release>-postgres`). This is handled for you when the bundled Postgres is enabled.

### Value schema changes

Bitnami-specific keys are gone; the datastore sections now describe the operator resources:

| Removed (Bitnami) | Replacement (`1.0.0`) |
|-------------------|------------------------|
| `postgres.image.repository`, `postgres.global.security.allowInsecureImages` | `postgres.image` |
| `postgres.primary.*`, `postgres.tls` | `postgres.instances`, `postgres.storage.size`, `postgres.resources`, `postgres.sslmode`, `postgres.parameters` |
| `rabbitmq.image.repository`, `rabbitmq.global.security.allowInsecureImages` | `rabbitmq.image` |
| `rabbitmq.service.ports.amqp` | `rabbitmq.port` |
| Bitnami subchart RabbitMQ persistence keys | `rabbitmq.replicas`, `rabbitmq.persistence.storage` |

`postgres.auth.{username,password,database}` and `rabbitmq.auth.{username,password}` are kept.

## Migrating the data

> **A plain `helm upgrade` does not initialize the new database.** The upgrade removes the old
> Bitnami StatefulSet and CloudNativePG bootstraps a **fresh, empty** cluster. Hatchet's
> bundled migration runs as a `pre-upgrade` hook against the *pre-upgrade* database, so it does
> **not** run against the new CloudNativePG database — the Hatchet workloads stay unready until
> you initialize it with one of the paths below.

### Option A — start clean (most dev/staging installs)

If the bundled data is disposable, do a fresh install rather than an in-place upgrade — a
fresh install runs the migrations against the new CloudNativePG database automatically:

```bash
curl -fsSL https://raw.githubusercontent.com/hatchet-dev/hatchet-charts/main/scripts/install-operators.sh | bash
helm uninstall my-hatchet
helm install my-hatchet hatchet/hatchet-stack --version 1.0.0
```

### Option B — preserve data (dump & restore)

Stop the writers first so nothing changes after the snapshot (keep Postgres running):

```bash
kubectl scale deploy -n <ns> -l app.kubernetes.io/instance=<release> --replicas=0
```

Dump the old bundled database (its pod is still up):

```bash
kubectl exec -n <ns> <release>-postgres-0 -- \
  env PGPASSWORD=hatchet pg_dump -U hatchet -d hatchet --clean --if-exists \
  > hatchet-backup.sql
```

Install the operators and upgrade (no `--wait`; the new database is empty until the restore,
so the workloads intentionally stay unready):

```bash
curl -fsSL https://raw.githubusercontent.com/hatchet-dev/hatchet-charts/main/scripts/install-operators.sh | bash
helm upgrade my-hatchet hatchet/hatchet-stack --version 1.0.0
```

Wait for the new cluster, then restore. Inside the pod the local socket uses peer auth, so
connect over TCP (`-h 127.0.0.1`) to authenticate the `hatchet` role by password:

```bash
kubectl wait --for=condition=Ready cluster/<release>-postgres -n <ns> --timeout=5m
kubectl exec -i -n <ns> <release>-postgres-1 -- \
  env PGPASSWORD=hatchet psql -h 127.0.0.1 -U hatchet -d hatchet < hatchet-backup.sql
```

Then bring the workloads back up against the restored database:

```bash
kubectl rollout restart deploy -n <ns>
```

> Advanced: CloudNativePG can also import from a still-running source database at bootstrap via
> [`bootstrap.import`](https://cloudnative-pg.io/docs/database_import/), avoiding the manual
> dump/restore. Overkill for dev/staging, useful for larger datasets.

### RabbitMQ

RabbitMQ holds no durable state worth migrating for dev/staging — let clients reconnect and
redeclare their queues against the new broker.

## References

- [Bitnami catalog changes (Aug 28, 2025)](https://github.com/bitnami/charts/issues/35164)
- [CloudNativePG](https://cloudnative-pg.io/docs/) · [migration guide](https://k8scockpit.tech/posts/cloudnative-pg/)
- [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview)
