#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3001}"

usage() {
  cat <<'EOF'
Usage:
  bash examples/bash/automation-logs.sh create-automation <name> [type] [version] [manual_minutes]
  bash examples/bash/automation-logs.sh send-execution <automation_id> [status] [duration_ms]

Environment variables:
  BASE_URL        Local API base URL. Default: http://localhost:3001
  EXECUTION_UUID  Optional execution UUID override
  STARTED_AT      Optional ISO-8601 start timestamp
  FINISHED_AT     Optional ISO-8601 finish timestamp
EOF
}

create_automation() {
  local name="${1:?name is required}"
  local type="${2:-bash}"
  local version="${3:-1.0.0}"
  local manual_minutes="${4:-15}"

  curl -sS -X POST "${BASE_URL}/automations" \
    -H 'Content-Type: application/json' \
    -d "{
      \"name\": \"${name}\",
      \"type\": \"${type}\",
      \"version\": \"${version}\",
      \"manualExecutionEffortMinutes\": ${manual_minutes}
    }"
}

send_execution() {
  local automation_id="${1:?automation_id is required}"
  local status="${2:-success}"
  local duration_ms="${3:-0}"
  local execution_uuid="${EXECUTION_UUID:-$(uuidgen | tr '[:upper:]' '[:lower:]')}"
  local started_at="${STARTED_AT:-$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")}"
  local finished_at="${FINISHED_AT:-$started_at}"

  curl -sS -X POST "${BASE_URL}/automations/${automation_id}/executions" \
    -H 'Content-Type: application/json' \
    -d "{
      \"execution_uuid\": \"${execution_uuid}\",
      \"trigger_type\": \"manual\",
      \"status\": \"${status}\",
      \"started_at\": \"${started_at}\",
      \"finished_at\": \"${finished_at}\",
      \"duration_ms\": ${duration_ms},
      \"host\": \"$(hostname)\",
      \"runtime\": \"bash\",
      \"error_code\": null,
      \"error_message\": null
    }"
}

main() {
  local command="${1:-}"

  case "${command}" in
    create-automation)
      shift
      create_automation "$@"
      ;;
    send-execution)
      shift
      send_execution "$@"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
