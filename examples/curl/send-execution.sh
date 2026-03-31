#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3001}"
AUTOMATION_ID="${AUTOMATION_ID:-replace-with-local-automation-id}"
EXECUTION_UUID="${EXECUTION_UUID:-$(uuidgen | tr '[:upper:]' '[:lower:]')}"
STARTED_AT="${STARTED_AT:-2026-03-31T19:00:00.000Z}"
FINISHED_AT="${FINISHED_AT:-2026-03-31T19:01:23.000Z}"

curl -sS -X POST "${BASE_URL}/automations/${AUTOMATION_ID}/executions" \
  -H 'Content-Type: application/json' \
  -d "{
    \"execution_uuid\": \"${EXECUTION_UUID}\",
    \"trigger_type\": \"schedule\",
    \"status\": \"success\",
    \"started_at\": \"${STARTED_AT}\",
    \"finished_at\": \"${FINISHED_AT}\",
    \"duration_ms\": 83000,
    \"host\": \"runner-01\",
    \"runtime\": \"bash\",
    \"error_code\": null,
    \"error_message\": null
  }"
