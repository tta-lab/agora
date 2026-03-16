#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${TUWUNEL_URL:-http://tuwunel.matrix.svc.orb.local:8008}"
REG_TOKEN="${TUWUNEL_REGISTRATION_TOKEN:?Set TUWUNEL_REGISTRATION_TOKEN}"

AGENTS=(yuki kestrel athena inke eve lyra neil)

for user in "${AGENTS[@]}"; do
  echo -n "Creating $user... "
  RESULT=$(curl -s -X POST "$BASE_URL/_matrix/client/v3/register" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"$user\",
      \"password\": \"agent-$user\",
      \"auth\": {
        \"type\": \"m.login.registration_token\",
        \"token\": \"$REG_TOKEN\"
      }
    }")
  if echo "$RESULT" | grep -q "user_id"; then
    echo "OK"
  else
    echo "FAILED: $RESULT"
  fi
done
