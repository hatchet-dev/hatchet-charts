# Loadtest observability

The kind-based loadtests (`kind-stack-loadtest.sh`, `kind-ha-loadtest.sh`, run by
the `loadtest-stack` / `loadtest-ha` jobs in `.github/workflows/test.yaml`) export
engine-side OpenTelemetry traces to **ClickStack Cloud** and write a KPI summary from
each run, so a slow or failing run can be inspected after the fact and compared
across runs.

## How it works

1. `loadtest-otel.yaml` deploys an in-cluster **ClickStack OTel collector**
   (`clickhouse/clickstack-otel-collector`) into the loadtest namespace as the OTLP
   sink. It receives spans on `otel-collector:4317` and forwards them to ClickHouse
   Cloud over TLS using the credentials in the `clickstack-otel` Secret (which the
   scripts create from GitHub secrets).
2. The released Hatchet engine is pointed at the collector purely through Helm values —
   `SERVER_OTEL_COLLECTOR_URL=otel-collector:4317` with `SERVER_OTEL_INSECURE=true`
   (in-cluster, plaintext — the collector, not the engine, holds the ClickHouse
   credentials). Traces are head-sampled at 50% (`SERVER_OTEL_TRACE_ID_RATIO=0.5`) so
   they stay complete while halving the volume the engine emits, and each scenario
   reports under its own service name (`hatchet-loadtest-stack` / `hatchet-loadtest-ha`)
   so runs are separable in the ClickStack UI. The chart range-renders
   `sharedConfig.env` into the shared-config Secret every backend loads via `envFrom`,
   so no chart change is needed. This captures engine-internal spans: `ingest-event` →
   scheduler `handle-check-queue` → dispatcher `send-to-worker` → `otelpgx` DB queries,
   stitched across services via the message-queue `otel_carrier`.
3. The collector's ClickHouse Cloud credentials come from the `CLICKHOUSE_ENDPOINT`,
   `CLICKHOUSE_USER`, and `CLICKHOUSE_PASSWORD` GitHub secrets, passed to the scripts as
   env vars. When any is unset the collector is skipped and the engine's OTLP export is
   a no-op, so local runs work without any secrets (you just get no traces).
4. Traces flush asynchronously to ClickHouse Cloud during and shortly after the run;
   there is nothing to export from the cluster, so the namespace is torn down as soon as
   the run finishes. In the ClickStack (HyperDX) UI, add a source pointing at the same
   ClickHouse Cloud instance to query them.

## Artifacts

- `loadtest-summary.json` — parsed KPIs: `averageDuration` (avg task execution
  duration — the gated metric), `averageScheduling` (avg per-event scheduling
  time), `counts` (pushed/executed/uniques), `result`, `version`, `scenario`.
- `loadtest-logs.txt` — full loadtest pod logs.

Each run's KPI row is also written to the GitHub Actions job summary for an
at-a-glance comparison.

## Viewing the traces

Open the ClickStack Cloud UI and search for the run's service
(`hatchet-loadtest-stack` or `hatchet-loadtest-ha`), narrowed to the run's time
window. The engine spans render as a waterfall showing where scheduling/execution
latency was spent.

## Analyzing regressions

Compare `loadtest-summary.json` across two runs' `loadtest-*-<version>` artifacts
(KPI drift), then open the corresponding trace waterfalls in ClickStack Cloud to see
where the added latency lives.
