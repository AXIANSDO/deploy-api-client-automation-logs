# Exemplos

[English version](README.en.md)

Esta diretoria contém exemplos prontos para adaptação nas ferramentas de automação mais comuns do lado do cliente.

Todos os exemplos chamam a API local de Automation Logs exposta por este stack:

- base URL: `http://localhost:3001`
- não é necessário header de autenticação local
- `CLIENT_ID` e `AUTOMATION_TOKEN` ficam no `.env` do Docker Compose

Este produto é focado em registo de execuções e tempos de execução. O passo de registo da automação existe apenas para persistir localmente a automação aprovada antes do primeiro envio de execução.

## Porque existem exemplos que criam ou registam automações?

Porque a API local precisa de um passo único de registo local antes de conseguir aceitar logs de execução.

Isto **não** significa que o cliente esteja a criar uma nova automação na Axians.

O que realmente acontece é:

1. a Axians aprova a automação centralmente e fornece o `automation_id` oficial
2. o cliente regista essa automação aprovada uma vez na API local
3. o cliente continua a enviar logs de execução usando o mesmo `automation_id`

Por isso, os exemplos que chamam `POST /automations` mostram o passo de **registo local**, e não uma criação central ou uma nova aprovação.

## Sequência recomendada de utilização

1. Registar a automação aprovada uma vez na API local.
2. Guardar o `automation_id` devolvido na configuração da ferramenta.
3. Enviar um evento de execução após cada run.
4. Reutilizar o mesmo `execution_uuid` apenas quando estiver a repetir a mesma execução.

Use o `automation_id` emitido pela Axians ao registar a automação localmente.

O pedido de execução usa:

- rota: `POST /executions`
- body: campos da execução mais `automation_id`

Não envie `CLIENT_ID` nem `AUTOMATION_TOKEN` dentro do corpo JSON da execução local.

## Exemplos incluídos

- [curl/create-automation.sh](curl/create-automation.sh): script pontual para registo local de uma automação aprovada
- [curl/send-execution.sh](curl/send-execution.sh): script pontual para envio de execução
- [bash/automation-logs.sh](bash/automation-logs.sh): wrapper Bash reutilizável com subcomandos de registo local e envio
- [python/automation_logs_client.py](python/automation_logs_client.py): wrapper Python usando a standard library
- [javascript/automation-logs-client.mjs](javascript/automation-logs-client.mjs): wrapper Node.js com `fetch` nativo
- [ansible/playbook.yml](ansible/playbook.yml): exemplo idempotente em Ansible
- [n8n/http-request-create-automation.json](n8n/http-request-create-automation.json): workflow n8n importável para registo local de automação
- [n8n/http-request-create-execution.json](n8n/http-request-create-execution.json): workflow n8n importável para envio local de execuções
- [powershell/send-execution.ps1](powershell/send-execution.ps1): envio de execução para Windows/PowerShell

## Comportamento HTTP esperado

- `POST /automations` devolve `201` quando a automação é criada
- `POST /automations` devolve `409` se a mesma automação já existir
- `POST /executions` devolve `201` quando o log é guardado e reenviado de imediato
- `POST /executions` devolve `202` quando o log é aceite localmente e colocado em fila para retry

Considere `201` e `202` como submissões bem-sucedidas de execução.

O passo `POST /automations` é um passo de registo local. Ele existe porque a API do lado do cliente guarda automações localmente e espera `automation_id` no payload da execução.
