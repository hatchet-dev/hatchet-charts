# Loadtest observability

The kind-based loadtests (`kind-stack-loadtest.sh`, `kind-ha-loadtest.sh`, run by
the `loadtest-stack` / `loadtest-ha` jobs in `.github/workflows/test.yaml`) capture
engine-side OpenTelemetry traces and a KPI summary from each run so a slow or
failing run can be inspected after the fact and compared across runs.

## How it works

1. `loadtest-otel.yaml` deploys a throwaway **Jaeger all-in-one** (in-memory) into
   the loadtest namespace as an OTLP sink.
2. The released Hatchet engine is pointed at it purely through Helm values —
   `--set sharedConfig.env.SERVER_OTEL_COLLECTOR_URL=jaeger:4317` (plus
   `SERVER_OTEL_INSECURE`, `SERVER_OTEL_SERVICE_NAME=hatchet`,
   `SERVER_OTEL_TRACE_ID_RATIO=1`). The chart range-renders `sharedConfig.env` into
   the shared-config Secret every backend loads via `envFrom`, so no chart change
   is needed. This captures engine-internal spans: `ingest-event` → scheduler
   `handle-check-queue` → dispatcher `send-to-worker` → `otelpgx` DB queries,
   stitched across services via the message-queue `otel_carrier`.
3. After the loadtest pod completes, the script exports the traces and KPIs to the
   runner filesystem **before** the namespace is torn down, and the workflow
   uploads them as artifacts (`loadtest-stack-<version>` / `loadtest-ha-<version>`).

## Artifacts

- `loadtest-traces.json` — Jaeger-native trace export (engine service `hatchet`).
- `loadtest-summary.json` — parsed KPIs: `averageDuration` (avg task execution
  duration — the gated metric), `averageScheduling` (avg per-event scheduling
  time), `counts` (pushed/executed/uniques), `result`, `version`, `scenario`.
- `loadtest-logs.txt` — full loadtest pod logs.

Each run's KPI row is also written to the GitHub Actions job summary for an
at-a-glance comparison.

## Viewing the traces

Download `loadtest-traces.json` from the run's artifacts, then:

```sh
docker run --rm -p16686:16686 jaegertracing/all-in-one
```

Open <http://localhost:16686>, click **Upload** (JSON File) on the search page, and
select `loadtest-traces.json`. The engine spans render as a waterfall showing where
scheduling/execution latency was spent.

## Analyzing regressions

Download the `loadtest-*-<version>` artifacts from two runs and compare
`loadtest-summary.json` (KPI drift) and the trace waterfalls (where the added
latency lives). See the "Later / natural evolution" notes in the plan for pushing
summaries to a persistent backend to trend KPIs by version over time.
