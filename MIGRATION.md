# Migrating to v1.0.0 (operator-managed datastores)

`hatchet-stack` and `hatchet-ha` `1.0.0` replace the bundled **Bitnami** PostgreSQL and
RabbitMQ subcharts with operator-managed datastores:

| Before (`0.x`) | After (`1.0.0`) |
|----------------|-----------------|
| Bitnami `postgresql` subchart (`bitnamilegacy/postgresql`) | [CloudNativePG](https://cloudnative-pg.io) `Cluster` |
| Bitnami `rabbitmq` subchart (`bitnamilegacy/rabbitmq`) | [RabbitMQ Cluster Operator](https://www.rabbitmq.com/kubernetes/operator/operator-overview) `RabbitmqCluster` |

## Why we changed this

Not just because of the Bitnami catalog changes — that was the deadline, not the reason.

Bitnami [froze its free images into an unmaintained `bitnamilegacy/*` catalog on 28 August
2025](https://github.com/bitnami/charts/issues/35164) (deletion later pushed to 29 September),
so staying put meant shipping a database and broker that receive **no further security
patches**. That set the timeline. But the destination is a genuine upgrade, not a like-for-like
swap to dodge the rug-pull:

- **Actively maintained.** CloudNativePG and the RabbitMQ Cluster Operator are CNCF/community
  projects with regular releases and security fixes — the thing the frozen Bitnami images can
  no longer offer.
- **Purpose-built, declarative operators.** They manage the full lifecycle — provisioning,
  configuration, and version upgrades — instead of a static StatefulSet.
- **Real high availability.** CloudNativePG does streaming replication with automated failover;
  the RabbitMQ operator runs a proper clustered broker. `hatchet-ha` defaults to 3 instances of
  each.
- **A backup/recovery story.** CloudNativePG has first-class backups and point-in-time recovery
  (opt-in), which the bundled Bitnami setup never provided.

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

> **The bundled database is not migrated in place.** A `helm upgrade` removes the old Bitnami
> StatefulSet and CloudNativePG bootstraps a **fresh, empty** cluster; Hatchet re-runs its
> schema migrations against it. Choose one of the paths below.

### Option A — start clean (most dev/staging installs)

If the bundled data is disposable:

```bash
curl -fsSL https://raw.githubusercontent.com/hatchet-dev/hatchet-charts/main/scripts/install-operators.sh | bash
helm upgrade my-hatchet hatchet/hatchet-stack --version 1.0.0
```

Hatchet re-creates its schema on the empty cluster. Done.

### Option B — preserve data (dump & restore)

Dump **before** upgrading, while the old Bitnami pod still exists (adjust namespace/release):

```bash
kubectl exec -n <ns> <release>-postgres-0 -- \
  env PGPASSWORD=hatchet pg_dump -U hatchet -d hatchet --clean --if-exists \
  > hatchet-backup.sql
```

Install the operators and upgrade:

```bash
curl -fsSL https://raw.githubusercontent.com/hatchet-dev/hatchet-charts/main/scripts/install-operators.sh | bash
helm upgrade my-hatchet hatchet/hatchet-stack --version 1.0.0
```

Wait for the new cluster to be healthy, then restore into the primary:

```bash
kubectl wait --for=condition=Ready cluster/<release>-postgres -n <ns> --timeout=5m
kubectl exec -i -n <ns> <release>-postgres-1 -- \
  env PGPASSWORD=hatchet psql -U hatchet -d hatchet < hatchet-backup.sql
```

`--clean --if-exists` makes the restore overwrite the schema Hatchet re-created on the empty
cluster, so the dump becomes the source of truth. Restart the Hatchet components afterwards
(`kubectl rollout restart deploy -n <ns>`).

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
