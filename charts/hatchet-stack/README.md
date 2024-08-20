## `hatchet-stack`

A Helm chart that deploys Hatchet on Kubernetes along with RabbitMQ and Postgres.

### Getting Started

There are 4 encryption secrets required for Hatchet to run which can be generated via the following bash script (requires `docker` and `openssl`):

```sh
#!/bin/bash

# Define an alias for generating random strings. This needs to be a function in a script.
randstring() {
    openssl rand -base64 69 | tr -d "\n=+/" | cut -c1-$1
}

# Create keys directory
mkdir -p ./keys

# Generate keysets using Docker
docker run -v $(pwd)/keys:/hatchet/keys ghcr.io/hatchet-dev/hatchet/hatchet-admin:latest /hatchet/hatchet-admin keyset create-local-keys --key-dir /hatchet/keys

# Read keysets from files
SERVER_ENCRYPTION_MASTER_KEYSET=$(<./keys/master.key)
SERVER_ENCRYPTION_JWT_PRIVATE_KEYSET=$(<./keys/private_ec256.key)
SERVER_ENCRYPTION_JWT_PUBLIC_KEYSET=$(<./keys/public_ec256.key)

# Generate the random strings for SERVER_AUTH_COOKIE_SECRETS
SERVER_AUTH_COOKIE_SECRET1=$(randstring 16)
SERVER_AUTH_COOKIE_SECRET2=$(randstring 16)

# Create the YAML file
cat > hatchet-values.yaml <<EOF
api:
  enabled: true
  env:
    SERVER_AUTH_COOKIE_SECRETS: "$SERVER_AUTH_COOKIE_SECRET1 $SERVER_AUTH_COOKIE_SECRET2"
    SERVER_ENCRYPTION_MASTER_KEYSET: "$SERVER_ENCRYPTION_MASTER_KEYSET"
    SERVER_ENCRYPTION_JWT_PRIVATE_KEYSET: "$SERVER_ENCRYPTION_JWT_PRIVATE_KEYSET"
    SERVER_ENCRYPTION_JWT_PUBLIC_KEYSET: "$SERVER_ENCRYPTION_JWT_PUBLIC_KEYSET"

engine:
  enabled: true
  env:
    SERVER_AUTH_COOKIE_SECRETS: "$SERVER_AUTH_COOKIE_SECRET1 $SERVER_AUTH_COOKIE_SECRET2"
    SERVER_ENCRYPTION_MASTER_KEYSET: "$SERVER_ENCRYPTION_MASTER_KEYSET"
    SERVER_ENCRYPTION_JWT_PRIVATE_KEYSET: "$SERVER_ENCRYPTION_JWT_PRIVATE_KEYSET"
    SERVER_ENCRYPTION_JWT_PUBLIC_KEYSET: "$SERVER_ENCRYPTION_JWT_PUBLIC_KEYSET"
EOF

# Cleanup key directory
rm -rf ./keys
```

**Warning:** do not commit these keys to your Git repository, use `api.envFrom` or `engine.envFrom` to pull in values from a secret.

To deploy `hatchet-stack`, run the following commands:

```sh
helm repo add hatchet https://hatchet-dev.github.io/hatchet-charts
helm install hatchet-stack hatchet/hatchet-stack --values hatchet-values.yaml --set api.replicaCount=0 --set engine.replicaCount=0 --set caddy.enabled=true
helm upgrade hatchet-stack hatchet/hatchet-stack --values hatchet-values.yaml --set caddy.enabled=true
```

This default installation will run the Hatchet server as an internal service in the cluster and spins up a reverse proxy via `Caddy` to get local access. To view the Hatchet server, run the following command:

```sh
export NAMESPACE=default # TODO: replace with your namespace
export POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app=caddy" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod --namespace $NAMESPACE $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
kubectl --namespace $NAMESPACE port-forward $POD_NAME 8080:$CONTAINER_PORT
```

And then navigate to `http://localhost:8080` to see the Hatchet frontend running.

You can run a similar command to connect to the Hatchet engine:

```sh
export NAMESPACE=default # TODO: replace with your namespace
export POD_NAME=$(kubectl get pods --namespace $NAMESPACE -l "app.kubernetes.io/name=hatchet-engine,app.kubernetes.io/instance=hatchet" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod --namespace $NAMESPACE $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
kubectl --namespace $NAMESPACE port-forward $POD_NAME 7070:$CONTAINER_PORT
```

This will spin up the Hatchet GRPC service on `localhost:7070`.
