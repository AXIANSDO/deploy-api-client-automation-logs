#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3001}"
AUTOMATION_ID="${AUTOMATION_ID:-replace-with-approved-automation-id}"

curl -sS -X POST "${BASE_URL}/automations" \
  -H 'Content-Type: application/json' \
  -d '{
    "id": "'"${AUTOMATION_ID}"'",
    "name": "Backup Firewall",
    "type": "ansible",
    "version": "1.0.0",
    "manualExecutionEffortMinutes": 30
  }'
