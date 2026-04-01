#!/usr/bin/env python3
import json
import os
import urllib.parse
import urllib.request
import urllib.error

BASE_URL = os.getenv("BASE_URL", "http://localhost:3001")


def _request(method: str, path: str, payload: dict | None = None) -> dict:
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(
        f"{BASE_URL}{path}",
        data=data,
        method=method,
        headers=headers,
    )
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8")
        raise RuntimeError(f"HTTP {error.code}: {body}") from error


def get_automation(automation_id: str) -> dict | None:
    try:
        return _request("GET", f"/automations/{automation_id}")
    except RuntimeError as error:
        if "HTTP 404:" in str(error):
            return None
        raise


def create_automation(
    automation_id: str,
    name: str,
    automation_type: str,
    version: str,
    manual_minutes: int | None = None,
) -> dict:
    payload = {
        "id": automation_id,
        "name": name,
        "type": automation_type,
        "version": version,
    }
    if manual_minutes is not None:
        payload["manualExecutionEffortMinutes"] = manual_minutes
    return _request("POST", "/automations", payload)


def ensure_automation(
    automation_id: str,
    name: str,
    automation_type: str,
    version: str,
    manual_minutes: int | None = None,
) -> dict:
    existing = get_automation(automation_id)
    if existing:
        return existing

    return create_automation(
        automation_id,
        name,
        automation_type,
        version,
        manual_minutes,
    )


def send_execution(automation_id: str, execution: dict) -> dict:
    return _request(
        "POST",
        "/executions",
        {
            "automation_id": automation_id,
            **execution,
        },
    )


if __name__ == "__main__":
    automation_id = os.getenv(
        "AUTOMATION_ID", "replace-with-approved-automation-id"
    )
    automation = ensure_automation(
        automation_id,
        "Backup Firewall",
        "python",
        "1.0.0",
        30,
    )
    print("Using automation:", automation["id"])

    result = send_execution(
        automation["id"],
        {
            "execution_uuid": os.getenv(
                "EXECUTION_UUID", "a7b1f570-85fb-4b4d-bb63-19ce0d75dfe4"
            ),
            "trigger_type": "schedule",
            "status": "success",
            "started_at": "2026-03-31T19:00:00.000Z",
            "finished_at": "2026-03-31T19:01:23.000Z",
            "duration_ms": 83000,
            "host": "runner-01",
            "runtime": "python3.11",
            "error_code": None,
            "error_message": None,
        },
    )
    print("Execution response:", json.dumps(result, indent=2))
