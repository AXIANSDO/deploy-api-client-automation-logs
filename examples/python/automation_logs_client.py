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


def list_automations(search: str | None = None, automation_type: str | None = None) -> list[dict]:
    query = {}
    if search:
      query["search"] = search
    if automation_type:
      query["type"] = automation_type

    path = "/automations"
    if query:
        path = f"/automations?{urllib.parse.urlencode(query)}"

    response = _request("GET", path)
    return response.get("data", [])


def create_automation(name: str, automation_type: str, version: str, manual_minutes: int | None = None) -> dict:
    payload = {
        "name": name,
        "type": automation_type,
        "version": version,
    }
    if manual_minutes is not None:
        payload["manualExecutionEffortMinutes"] = manual_minutes
    return _request("POST", "/automations", payload)


def ensure_automation(name: str, automation_type: str, version: str, manual_minutes: int | None = None) -> dict:
    for automation in list_automations(search=name, automation_type=automation_type):
        if (
            automation.get("name") == name
            and automation.get("type") == automation_type
            and automation.get("version") == version
        ):
            return automation

    return create_automation(name, automation_type, version, manual_minutes)


def send_execution(automation_id: str, execution: dict) -> dict:
    return _request("POST", f"/automations/{automation_id}/executions", execution)


if __name__ == "__main__":
    automation = ensure_automation("Backup Firewall", "python", "1.0.0", 30)
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
