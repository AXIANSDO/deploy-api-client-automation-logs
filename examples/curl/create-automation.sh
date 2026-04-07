#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3001}"
AUTOMATION_ID="${AUTOMATION_ID:-replace-with-approved-automation-id}"

if [ "${AUTOMATION_ID}" = "replace-with-approved-automation-id" ]; then
  echo "Set AUTOMATION_ID to the AXIANS-approved automation ID before running this script." >&2
  exit 1
fi

curl -sS -X POST "${BASE_URL}/automations" \
  -H 'Content-Type: application/json' \
  -d '{
    "id": "'"${AUTOMATION_ID}"'",
    "name": "Backup Firewall",
    "type": "ansible",
    "version": "1.0.0",
    "manualExecutionEffortMinutes": 30
  }'
