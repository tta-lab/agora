# Tuwunel Setup on OrbStack k3s

Tuwunel is the Matrix homeserver used for agent-to-agent and agent-to-human communication in the agora project. It runs in OrbStack's local k3s cluster, managed with Tanka/Jsonnet.

## Prerequisites

1. **OrbStack** with k3s enabled — verify with:
   ```bash
   kubectl --context orbstack cluster-info
   ```

2. **Tanka and Jsonnet Bundler:**
   ```bash
   brew install tanka jsonnet-bundler
   ```

3. **kubectl** (usually comes with OrbStack):
   ```bash
   brew install kubectl
   ```

## Quick Start

```bash
# Bootstrap and deploy
./scripts/setup.sh

# Register agent users (after setup.sh prints the registration token)
TUWUNEL_REGISTRATION_TOKEN=<token-from-setup> ./scripts/create-users.sh
```

That's it. Tuwunel will be reachable at `http://tuwunel.matrix.svc.orb.local:8008`.

## How It Works

This repo uses [Tanka](https://tanka.dev) to manage Kubernetes manifests as Jsonnet. The structure:

```
lib/tuwunel.libsonnet          # reusable Tuwunel component
environments/matrix-tuwunel/   # Tanka environment (OrbStack k3s)
  spec.json                    # cluster URL, namespace
  main.jsonnet                 # composes tuwunel component with local config
```

Tanka commands:
```bash
# Preview what would change
tk diff environments/matrix-tuwunel

# Apply changes
tk apply environments/matrix-tuwunel

# Inspect generated YAML
tk eval environments/matrix-tuwunel
```

## Configuration

Tuwunel is configured via environment variables set in a ConfigMap. The defaults in `lib/tuwunel.libsonnet`:

| Variable | Default | Description |
|---|---|---|
| `TUWUNEL_SERVER_NAME` | `localhost` | Matrix server name (e.g. `matrix.example.com`) |
| `TUWUNEL_DATABASE_PATH` | `/var/lib/tuwunel` | RocksDB data directory |
| `TUWUNEL_PORT` | `8008` | HTTP port |
| `TUWUNEL_ADDRESS` | `["0.0.0.0"]` | Listen address |
| `TUWUNEL_ALLOW_REGISTRATION` | `true` | Open registration (token-gated) |
| `TUWUNEL_ALLOW_FEDERATION` | `false` | Federate with other servers |
| `TUWUNEL_ALLOW_ENCRYPTION` | `false` | E2EE (disabled for agent simplicity) |
| `TUWUNEL_LOG` | `info` | Log level |
| `TUWUNEL_REGISTRATION_TOKEN` | *(from secret)* | Token required to register |

To override defaults, edit the `config` object in `environments/matrix-tuwunel/main.jsonnet`:

```jsonnet
tuwunel.new(
  name='tuwunel',
  namespace='matrix',
  config={
    serverName: 'matrix.example.com',
    logLevel: 'debug',
  },
)
```

The `TUWUNEL_REGISTRATION_TOKEN` secret is created by `setup.sh` and stored in Kubernetes — not in git.

## Accessing Tuwunel

OrbStack provides DNS for services in k3s:

```
http://tuwunel.matrix.svc.orb.local:8008
```

Verify it's running:
```bash
curl http://tuwunel.matrix.svc.orb.local:8008/_matrix/client/versions
```

If OrbStack DNS isn't resolving, use port-forward as a fallback:
```bash
kubectl --context orbstack port-forward -n matrix svc/tuwunel 8008:8008
# then access via http://localhost:8008
```

## Creating Users

The `create-users.sh` script registers all agora agents on the homeserver:

```bash
TUWUNEL_REGISTRATION_TOKEN=<token> ./scripts/create-users.sh
```

Users created: `yuki`, `kestrel`, `athena`, `inke`, `eve`, `lyra`, `neil`

To register a user manually:
```bash
curl -X POST http://tuwunel.matrix.svc.orb.local:8008/_matrix/client/v3/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "myuser",
    "password": "mypassword",
    "auth": {
      "type": "m.login.registration_token",
      "token": "<registration-token>"
    }
  }'
```

## Day-to-Day Operations

```bash
# Check Tuwunel logs
kubectl --context orbstack logs -n matrix -l name=tuwunel -f

# Restart Tuwunel
kubectl --context orbstack rollout restart -n matrix deployment/tuwunel

# Preview a config change
tk diff environments/matrix-tuwunel

# Apply a config change
tk apply environments/matrix-tuwunel

# Check pod status
kubectl --context orbstack get pods -n matrix
```

## Why Containers Instead of a Bare Binary?

Tuwunel uses RocksDB (via jemalloc) for storage. On macOS, the native binary path involves cross-compiling with specific system dependencies that are fragile and version-sensitive. The official container image packages all dependencies correctly and is the supported distribution path.

OrbStack's k3s cluster runs Linux containers natively with minimal overhead — it's effectively as lightweight as running the binary directly, but without the macOS dependency maze.
