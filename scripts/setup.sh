#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="matrix"
CTX="orbstack"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Prerequisites check
for cmd in tk jb kubectl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd not found. Install with:"
    case "$cmd" in
      tk) echo "  brew install tanka" ;;
      jb) echo "  brew install jsonnet-bundler" ;;
      kubectl) echo "  brew install kubectl" ;;
    esac
    exit 1
  fi
done

# Verify OrbStack k3s is reachable
echo "==> Checking OrbStack k3s connectivity..."
if ! kubectl cluster-info --context "$CTX" &>/dev/null; then
  echo "ERROR: Cannot reach OrbStack k3s. Is OrbStack running with k3s enabled?"
  exit 1
fi

# Install Jsonnet dependencies
echo "==> Installing Jsonnet dependencies..."
cd "$ROOT_DIR"
jb install

# Create secret if it doesn't exist
if ! kubectl --context "$CTX" get secret tuwunel-secrets -n "$NAMESPACE" >/dev/null; then
  # Create namespace first so secret can land in it
  kubectl --context "$CTX" create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl --context "$CTX" apply -f -
  TOKEN="${TUWUNEL_REGISTRATION_TOKEN:-$(openssl rand -hex 16)}"
  echo "==> Creating tuwunel-secrets..."
  kubectl --context "$CTX" create secret generic tuwunel-secrets -n "$NAMESPACE" \
    --from-literal=TUWUNEL_REGISTRATION_TOKEN="$TOKEN"
  echo "    Registration token: $TOKEN"
  echo "    (save this — needed for user creation)"
else
  echo "==> Secret tuwunel-secrets already exists, skipping"
fi

# Apply with Tanka (resolves cluster from spec.apiServer automatically)
echo "==> Applying Tanka environment..."
tk apply "$ROOT_DIR/environments/matrix-tuwunel" --auto-approve=always

echo "==> Waiting for rollout..."
kubectl --context "$CTX" rollout status deployment/tuwunel -n "$NAMESPACE" --timeout=120s

echo ""
echo "==> Tuwunel is running!"
echo "    OrbStack DNS: http://tuwunel.matrix.svc.orb.local:8008"
echo "    Verify:       curl http://tuwunel.matrix.svc.orb.local:8008/_matrix/client/versions"
