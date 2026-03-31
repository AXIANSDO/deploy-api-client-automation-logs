#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3001}"

curl -sS -X POST "${BASE_URL}/automations" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Backup Firewall",
    "type": "ansible",
    "version": "1.0.0",
    "manualExecutionEffortMinutes": 30
  }'
