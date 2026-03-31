# Examples

This directory contains ready-to-adapt examples for the most common customer-side automation tools.

All examples call the local Automation Logs API exposed by this stack:

- base URL: `http://localhost:3001`
- no local authentication header required
- `CLIENT_ID` and `AUTOMATION_TOKEN` stay in the Docker Compose `.env` file

## Recommended usage sequence

1. Create the automation once in the local API.
2. Save the returned `automation_id` in the tool configuration.
3. Send one execution event after each run.
4. Reuse the same `execution_uuid` only when retrying the same execution.

## Included examples

- [curl/create-automation.sh](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/curl/create-automation.sh): one-off registration script
- [curl/send-execution.sh](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/curl/send-execution.sh): one-off execution sender
- [bash/automation-logs.sh](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/bash/automation-logs.sh): reusable Bash wrapper with subcommands
- [python/automation_logs_client.py](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/python/automation_logs_client.py): Python wrapper using the standard library
- [javascript/automation-logs-client.mjs](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/javascript/automation-logs-client.mjs): Node.js wrapper using native `fetch`
- [ansible/playbook.yml](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/ansible/playbook.yml): idempotent Ansible example
- [n8n/http-request-create-automation.json](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/n8n/http-request-create-automation.json): importable n8n workflow for local automation creation
- [n8n/http-request-create-execution.json](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/n8n/http-request-create-execution.json): importable n8n workflow for local execution submission
- [powershell/send-execution.ps1](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/powershell/send-execution.ps1): Windows/PowerShell execution sender

## HTTP behavior to expect

- `POST /automations` returns `201` when the automation is created
- `POST /automations` returns `409` if the same automation already exists
- `POST /automations/{automationId}/executions` returns `201` when the log is stored and forwarded immediately
- `POST /automations/{automationId}/executions` returns `202` when the log is queued locally for retry

Treat both `201` and `202` as successful execution submissions.
