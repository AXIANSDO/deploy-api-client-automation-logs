$BaseUrl = if ($env:BASE_URL) { $env:BASE_URL } else { "http://localhost:3001" }
$AutomationId = if ($env:AUTOMATION_ID) { $env:AUTOMATION_ID } else { "replace-with-local-automation-id" }
$ExecutionUuid = if ($env:EXECUTION_UUID) { $env:EXECUTION_UUID } else { "a7b1f570-85fb-4b4d-bb63-19ce0d75dfe4" }

$Body = @{
  execution_uuid = $ExecutionUuid
  trigger_type   = "schedule"
  status         = "success"
  started_at     = "2026-03-31T19:00:00.000Z"
  finished_at    = "2026-03-31T19:01:23.000Z"
  duration_ms    = 83000
  host           = "runner-01"
  runtime        = "powershell"
  error_code     = $null
  error_message  = $null
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "$BaseUrl/automations/$AutomationId/executions" `
  -ContentType "application/json" `
  -Body $Body
