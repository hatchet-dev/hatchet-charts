## `hatchet-lite`

A Helm chart that deploys a lite version of Hatchet on Kubernetes. This bundles a number of different Hatchet components into a single application, including:

- `hatchet-server`: the primary Hatchet API server.
- `hatchet-temporal`: the custom build of Temporal deployed by Hatchet.
- `hatchet-background-worker`: a background worker that processes queues and notifications for Hatchet.
