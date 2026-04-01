const BASE_URL = process.env.BASE_URL || 'http://localhost:3001';

async function request(method, path, payload) {
  const response = await fetch(`${BASE_URL}${path}`, {
    method,
    headers: payload ? { 'Content-Type': 'application/json' } : {},
    body: payload ? JSON.stringify(payload) : undefined,
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${await response.text()}`);
  }

  return response.json();
}

export async function getAutomation(automationId) {
  try {
    return await request('GET', `/automations/${automationId}`);
  } catch (error) {
    if (String(error.message).startsWith('HTTP 404:')) {
      return null;
    }
    throw error;
  }
}

export async function createAutomation({ id, name, type, version, manualExecutionEffortMinutes }) {
  return request('POST', '/automations', {
    id,
    name,
    type,
    version,
    manualExecutionEffortMinutes,
  });
}

export async function ensureAutomation({ id, name, type, version, manualExecutionEffortMinutes }) {
  const existing = await getAutomation(id);
  if (existing) {
    return existing;
  }

  return createAutomation({ id, name, type, version, manualExecutionEffortMinutes });
}

export async function sendExecution(automationId, execution) {
  return request('POST', '/executions', {
    automation_id: automationId,
    ...execution,
  });
}

const automation = await ensureAutomation({
  id: process.env.AUTOMATION_ID || 'replace-with-approved-automation-id',
  name: 'Backup Firewall',
  type: 'javascript',
  version: '1.0.0',
  manualExecutionEffortMinutes: 30,
});

console.log('Using automation:', automation.id);

const executionResult = await sendExecution(automation.id, {
  execution_uuid: process.env.EXECUTION_UUID || 'a7b1f570-85fb-4b4d-bb63-19ce0d75dfe4',
  trigger_type: 'schedule',
  status: 'success',
  started_at: '2026-03-31T19:00:00.000Z',
  finished_at: '2026-03-31T19:01:23.000Z',
  duration_ms: 83000,
  host: 'runner-01',
  runtime: 'node20',
  error_code: null,
  error_message: null,
});

console.log('Execution response:', executionResult);
