#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3001}"

usage() {
  cat <<'EOF'
Usage:
  bash examples/bash/automation-logs.sh register-automation <automation_id> <name> [type] [version] [manual_minutes]
  bash examples/bash/automation-logs.sh send-execution <automation_id> [status] [duration_ms]

Environment variables:
  BASE_URL        Local API base URL. Default: http://localhost:3001
  EXECUTION_UUID  Optional execution UUID override
  STARTED_AT      Optional ISO-8601 start timestamp
  FINISHED_AT     Optional ISO-8601 finish timestamp
EOF
}

register_automation() {
  local automation_id="${1:?automation_id is required}"
  local name="${2:?name is required}"
  local type="${3:-bash}"
  local version="${4:-1.0.0}"
  local manual_minutes="${5:-15}"

  curl -sS -X POST "${BASE_URL}/automations" \
    -H 'Content-Type: application/json' \
    -d "{
      \"id\": \"${automation_id}\",
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

  curl -sS -X POST "${BASE_URL}/executions" \
    -H 'Content-Type: application/json' \
    -d "{
      \"automation_id\": \"${automation_id}\",
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
    register-automation)
      shift
      register_automation "$@"
      ;;
    create-automation)
      shift
      register_automation "$@"
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
