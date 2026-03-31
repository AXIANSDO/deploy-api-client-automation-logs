# Deploy API Client Automation Logs

This repository is the customer-facing deployment package for the AXIANS Automation Logs client stack.

It is meant to be shared with customers so they can:

- deploy the local Automation Logs API with Docker Compose
- configure the connection to the AXIANS central platform
- register approved automations locally
- push execution logs from their automation tools into the local API

Customer tools should call only the local API exposed by this stack. They should not send logs directly to the AXIANS central endpoint.

The repository does not build images locally. It consumes prebuilt images published by AXIANS in the private registry.

## Product purpose

The purpose of this product is to register automation executions and execution times.

The local API exists to:

- receive execution records from customer automation tools
- persist execution history locally
- expose local execution history for troubleshooting and observability
- forward execution data to the AXIANS central platform

The automation registration step is only supporting metadata. It exists so each execution can be associated with a local `automation_id`.

## What this stack provides

- a local API that receives automation execution logs over HTTP
- a local PostgreSQL database for persistence
- a local Redis instance for retry queueing
- a preconfigured Grafana instance for local visibility
- automatic forwarding of execution logs to the AXIANS corporate gateway

The forwarding endpoint is:

- `https://api-corp.axiansms.pt/v1/automation-logs`

## Stack

- API: `registry.agc.local/automation-logs/api-client-automation-logs:latest`
- Grafana: `registry.agc.local/automation-logs/api-client-grafana:latest`
- PostgreSQL: `postgres:16-alpine`
- Redis: `redis:7-alpine`

## Customer prerequisites

- a Linux host with Docker Engine and Docker Compose plugin
- access to `registry.agc.local`
- outbound HTTPS access to `https://api-corp.axiansms.pt`
- the AXIANS-issued `CLIENT_ID`
- the AXIANS-issued `AUTOMATION_TOKEN`
- the AXIANS-issued `automation_id` for each approved automation

## Files in this repository

- [docker-compose.yml](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/docker-compose.yml): runtime stack for the customer environment
- [.env.example](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/.env.example): template for customer-specific secrets and configuration
- [examples/README.md](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/README.md): example index and usage notes
- [examples/curl/create-automation.sh](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/curl/create-automation.sh): register a local automation with `curl`
- [examples/curl/send-execution.sh](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/curl/send-execution.sh): send an execution log with `curl`
- [examples/bash/automation-logs.sh](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/bash/automation-logs.sh): reusable Bash wrapper
- [examples/python/automation_logs_client.py](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/python/automation_logs_client.py): Python wrapper
- [examples/javascript/automation-logs-client.mjs](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/javascript/automation-logs-client.mjs): JavaScript wrapper
- [examples/ansible/playbook.yml](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/ansible/playbook.yml): Ansible example
- [examples/powershell/send-execution.ps1](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/powershell/send-execution.ps1): PowerShell example
- [examples/n8n/http-request-create-automation.json](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/n8n/http-request-create-automation.json): importable n8n workflow to create a local automation
- [examples/n8n/http-request-create-execution.json](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/n8n/http-request-create-execution.json): importable n8n workflow to send a local execution

## Sensitive configuration

Copy `.env.example` to `.env` and replace the placeholder values before the first deployment.

The following values are sensitive or customer-specific:

- `POSTGRES_PASSWORD`
- `GF_SECURITY_ADMIN_PASSWORD`
- `CLIENT_ID`
- `AUTOMATION_TOKEN`

Do not commit `.env`.

## How local tools authenticate

Customer automation tools do not need to send `CLIENT_ID` or `AUTOMATION_TOKEN` when calling the local API.

Those values are configured once in `.env` and injected by the local API when it forwards execution logs to the AXIANS central platform.

## First deployment

1. Log in to the private registry:

```bash
docker login registry.agc.local
```

2. Create the runtime environment file:

```bash
cp .env.example .env
```

3. Edit `.env` with the final values.

4. Pull the images:

```bash
docker compose pull
```

5. Start the stack:

```bash
docker compose up -d
```

6. Validate the API:

```bash
curl http://localhost:3001/healthz
curl http://localhost:3001/readyz
```

## Services and ports

- API: `http://<host>:3001`
- Grafana: `http://<host>:3000`
- PostgreSQL: `tcp/<host>:5432`
- Redis: `tcp/<host>:6379`

If PostgreSQL and Redis do not need to be reachable externally, remove or restrict the published ports according to the customer's network policy.

## Persistent data

The stack stores persistent data in Docker volumes:

- `postgres_data`
- `grafana_data`
- `redis_data`

These volumes should be preserved across upgrades and host restarts.

## Operational flow

The expected client-side flow is:

1. register the approved automation locally in the client API using the `automation_id` issued by AXIANS
2. keep the returned `automation_id`
3. send execution logs to `POST /automations/{automationId}/executions`
4. let the API persist locally and forward centrally

If the central endpoint is temporarily unavailable, the local API stores the log locally and retries automatically through Redis/BullMQ.

## Important contract detail

When a customer tool sends an execution to the local API, the `automation_id` is not sent inside the JSON body.

It is sent in the URL path:

- `POST /automations/{automationId}/executions`

The JSON body sent by the customer tool contains only execution data such as:

- `execution_uuid`
- `trigger_type`
- `status`
- `started_at`
- `finished_at`
- `duration_ms`
- `host`
- `runtime`
- `error_code`
- `error_message`

The local API then injects the local `automation_id` and the configured `CLIENT_ID` when forwarding the execution to AXIANS.

## API quick reference

Base URL:

- `http://localhost:3001`

Main endpoints:

- `GET /healthz`
- `GET /readyz`
- `POST /automations`
- `GET /automations`
- `GET /automations/{automationId}`
- `POST /automations/{automationId}/executions`
- `GET /automations/{automationId}/executions`

### Register an approved automation locally

Use this once for each automation approved by AXIANS.

This does not create a new automation in the AXIANS central catalog.
It creates the local record required by the customer-side API so execution logs can be stored and sent using the returned `automation_id`.

Use the `automation_id` issued by AXIANS in this request so the local identifier and the central identifier remain the same.

Request:

```json
{
  "id": "8c81036f-7db4-4c53-992f-5670fa76f7aa",
  "name": "Backup Firewall",
  "type": "ansible",
  "version": "1.0.0",
  "manualExecutionEffortMinutes": 30
}
```

### Send an execution

The customer integration must call:

- `POST /automations/{automationId}/executions`

where `{automationId}` is the local identifier returned by the registration step above.

Do not include `automation_id`, `CLIENT_ID`, or `AUTOMATION_TOKEN` in the JSON body sent by the automation tool.

Request:

```json
{
  "execution_uuid": "a7b1f570-85fb-4b4d-bb63-19ce0d75dfe4",
  "trigger_type": "schedule",
  "status": "success",
  "started_at": "2026-03-31T19:00:00.000Z",
  "finished_at": "2026-03-31T19:01:23.000Z",
  "duration_ms": 83000,
  "host": "runner-01",
  "runtime": "python3.11",
  "error_code": null,
  "error_message": null
}
```

Important notes:

- `execution_uuid` must be unique per execution
- use the same `execution_uuid` on retries to preserve idempotency
- `status` must be `success` or `error`
- timestamps must be valid ISO-8601 values
- successful immediate persistence returns `201 Created`
- accepted-for-retry responses return `202 Accepted`

### Duplicate automation registration

Creating the same automation twice returns `409 AUTOMATION_ALREADY_EXISTS`.

For repeated or idempotent integrations, prefer wrappers that:

- register the automation once and save `automation_id`
- or look up the automation first and reuse the existing `automation_id`

## Integration examples

The repository includes working examples in the [examples](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples) directory.

Start with [examples/README.md](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/README.md) if you want a quick tool-by-tool guide.

### curl

Register approved automation locally:

```bash
bash examples/curl/create-automation.sh
```

Send execution:

```bash
bash examples/curl/send-execution.sh
```

### Bash

The Bash wrapper is useful for cron jobs, shell scripts, and lightweight Linux automation hosts.

Register an approved automation locally:

```bash
bash examples/bash/automation-logs.sh register-automation "<approved-automation-id>" "Backup Firewall" "bash" "1.0.0" "30"
```

Send an execution:

```bash
bash examples/bash/automation-logs.sh send-execution "<automation-id>" "success" "83000"
```

### Python

The Python wrapper exposes helpers for:

- `get_automation(...)`
- `ensure_automation(...)`
- `send_execution(...)`

Run the example:

```bash
python3 examples/python/automation_logs_client.py
```

### JavaScript

The JavaScript wrapper uses native `fetch` in Node.js 20+.

It includes:

- `getAutomation(...)`
- `ensureAutomation(...)`
- `sendExecution(...)`

Run the example:

```bash
node examples/javascript/automation-logs-client.mjs
```

### Ansible

The Ansible example uses the `uri` module to:

- look up an existing automation
- create it only when missing
- capture `automation_id`
- submit one execution event

Run:

```bash
ansible-playbook examples/ansible/playbook.yml
```

### n8n

Import the example workflow JSON in:

- [examples/n8n/http-request-create-automation.json](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/n8n/http-request-create-automation.json)
- [examples/n8n/http-request-create-execution.json](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples/n8n/http-request-create-execution.json)

They create importable `Manual Trigger -> Set -> HTTP Request` flows calling the local API.

### PowerShell

The PowerShell example is useful for Windows-based automation hosts:

```powershell
./examples/powershell/send-execution.ps1
```

## Recommended client-side integration pattern

For each approved automation:

1. register the automation once in the local API
2. save the returned `automation_id` in the automation platform or script configuration
3. send one execution record at the end of each run
4. for failures, send `status=error` plus `error_code` and `error_message`

This gives the customer:

- local observability in Grafana
- durable local persistence
- automatic forwarding to AXIANS

## Example customer implementation sequence

1. AXIANS provides `CLIENT_ID`, `AUTOMATION_TOKEN`, and one `automation_id` per approved automation
2. customer deploys this stack
3. customer registers the approved automation in the local API using the AXIANS-issued `automation_id`
4. customer stores the resulting `automation_id`
5. customer updates scripts, playbooks, jobs, or workflows to post executions to the local API

## Upgrade procedure

When AXIANS publishes a new release:

1. update image tags in [docker-compose.yml](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/docker-compose.yml)
2. pull new images:

```bash
docker compose pull
```

3. recreate the services:

```bash
docker compose up -d
```

## Operational notes

- `AUTOMATION_TOKEN` is sent by the API to the AXIANS KrakenD gateway as `Authorization: Bearer <token>`
- `CLIENT_ID` is injected into the forwarded payload to identify the customer
- Grafana provisioning is baked into the published Grafana image
- the local API is the only endpoint customer tools should call directly

## Troubleshooting

### API is up but `/readyz` returns `503`

The API could not connect to PostgreSQL yet. Check:

- `docker compose ps`
- PostgreSQL credentials in `.env`
- container logs:

```bash
docker compose logs api
docker compose logs postgres
```

### Executions are accepted locally but not visible centrally

Check:

- `CLIENT_ID`
- `AUTOMATION_TOKEN`
- outbound HTTPS access to `api-corp.axiansms.pt`
- API logs:

```bash
docker compose logs api
```

### A customer automation tool needs a ready-made wrapper

Start from the examples in the [examples](/Users/rmarquesa/Documents/automation-logs/deploy-api-client-automation-logs/examples) directory and adapt only:

- base URL
- automation metadata
- execution payload fields
- any platform-specific scheduling or orchestration logic
