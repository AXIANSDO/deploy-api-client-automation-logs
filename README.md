# Deploy API Client Automation Logs

This repository contains the customer-facing Docker Compose deployment for the Automation Logs client stack.

It is intended to be used in the customer's infrastructure as a runtime deployment artifact only. It does not build images locally. The compose file consumes prebuilt images published by AXIANS in the private registry.

## Stack

- API: `registry.agc.local/automation-logs/api-client-automation-logs:1.0.0`
- Grafana: `registry.agc.local/automation-logs/api-client-grafana:1.0.0`
- PostgreSQL: `postgres:16-alpine`
- Redis: `redis:7-alpine`

The API forwards execution logs to the AXIANS corporate API gateway through KrakenD at `https://api-corp.axiansms.pt/v1/automation-logs`.

## What the customer must provide

- A Linux host with Docker Engine and Docker Compose plugin installed
- Access to `registry.agc.local`
- Outbound HTTPS access to `https://api-corp.axiansms.pt`
- A `.env` file created from `.env.example`
- The `CLIENT_ID` and `AUTOMATION_TOKEN` provided by AXIANS

## Sensitive configuration

Copy `.env.example` to `.env` and replace the placeholder values before the first deployment.

The following values are customer-specific or sensitive:

- `POSTGRES_PASSWORD`
- `GF_SECURITY_ADMIN_PASSWORD`
- `CLIENT_ID`
- `AUTOMATION_TOKEN`

Do not commit the `.env` file. It is ignored by Git on purpose.

## First deployment

1. Log in to the private registry:

```bash
docker login registry.agc.local
```

2. Create the runtime environment file:

```bash
cp .env.example .env
```

3. Edit `.env` with the final customer values.

4. Pull the images:

```bash
docker compose pull
```

5. Start the stack:

```bash
docker compose up -d
```

## Services and ports

- API: `http://<host>:3001`
- Grafana: `http://<host>:3000`
- PostgreSQL: `tcp/<host>:5432`
- Redis: `tcp/<host>:6379`

If PostgreSQL and Redis do not need to be reachable from outside the host, the published ports can be removed or restricted according to the customer's network policy.

## Persistent data

The stack stores data in named Docker volumes:

- `postgres_data`
- `grafana_data`
- `redis_data`

These volumes must be preserved across restarts and upgrades.

## Upgrade procedure

When AXIANS publishes a new release:

1. Update the image tags in `docker-compose.yml`
2. Pull the new images:

```bash
docker compose pull
```

3. Recreate the services:

```bash
docker compose up -d
```

## Operational notes

- The API persists execution logs locally and retries delivery through Redis/BullMQ if the corporate endpoint is temporarily unavailable.
- `AUTOMATION_TOKEN` is sent as `Authorization: Bearer <token>` to KrakenD.
- `CLIENT_ID` is injected into the forwarded execution payload so the central platform can identify the customer source.
- Grafana provisioning is already baked into the published Grafana image.
