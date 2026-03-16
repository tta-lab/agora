#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${TUWUNEL_URL:-http://tuwunel.matrix.svc.orb.local:8008}"
REG_TOKEN="${TUWUNEL_REGISTRATION_TOKEN:?Set TUWUNEL_REGISTRATION_TOKEN}"
PASSWORD="${TUWUNEL_AGENT_PASSWORD:-$(openssl rand -hex 16)}"

AGENTS=(yuki kestrel athena inke eve lyra neil)
FAILED=0

for user in "${AGENTS[@]}"; do
  echo -n "Creating $user... "
  HTTP_STATUS=0
  HTTP_BODY=$(curl -s --max-time 30 --connect-timeout 10 \
    -X POST "$BASE_URL/_matrix/client/v3/register" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"$user\",
      \"password\": \"$PASSWORD\",
      \"auth\": {
        \"type\": \"m.login.registration_token\",
        \"token\": \"$REG_TOKEN\"
      }
    }") || HTTP_STATUS=$?
  if [[ $HTTP_STATUS -ne 0 ]]; then
    echo "FAILED: curl error (exit $HTTP_STATUS)"
    FAILED=1
  elif echo "$HTTP_BODY" | grep -q "user_id"; then
    echo "OK"
  else
    echo "FAILED: $HTTP_BODY"
    FAILED=1
  fi
done

[[ "$FAILED" -eq 0 ]] || exit 1
