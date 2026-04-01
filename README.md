# Deploy API Client Automation Logs

[English version](README.en.md)

Este repositório é o pacote de deployment orientado ao cliente do stack **AXIANS Automation Logs**.

O objetivo dele é permitir que cada cliente:

- faça o deploy do `api-client-automation-logs` via Docker Compose
- configure a ligação com a plataforma central da Axians
- registe localmente as automações já aprovadas pela Axians
- envie tempos e estados de execução das suas automações para a API local

As ferramentas do cliente devem chamar **apenas a API local** exposta por este stack. Elas não devem enviar logs diretamente para a API central da Axians.

Este repositório não faz `build` de imagens localmente. Ele consome imagens já publicadas pela Axians no registry privado.

## Propósito do produto

O propósito deste produto é **registar execuções e tempos de execução de automações**.

A API local existe para:

- receber registos de execução enviados pelas ferramentas de automação do cliente
- persistir o histórico localmente
- disponibilizar histórico e observabilidade local para troubleshooting
- reenviar esses dados para a plataforma central da Axians

O passo de registo da automação existe apenas para persistir localmente a automação aprovada, para que cada execução possa referenciar o `automation_id` correto.

## Porque é que o cliente precisa de registar uma automação localmente?

Esta é a parte que mais costuma gerar confusão, por isso a regra fica explícita:

- a Axians cria e aprova a automação centralmente
- o cliente **não** cria uma nova automação na plataforma central da Axians
- o cliente faz um **registo local único** na API local
- esse registo local usa o **mesmo `automation_id` emitido pela Axians**

Na prática, existem duas APIs com responsabilidades diferentes:

| API | Função |
| --- | --- |
| API central da Axians (`api-axians`) | Guarda a automação aprovada centralmente, emite o token e recebe logs de execução de todos os clientes |
| API local do cliente (`api-client`) | Guarda uma cópia local da automação aprovada e recebe logs de execução das ferramentas locais |

O passo de registo local existe porque a API do lado do cliente mantém metadados da automação localmente e associa cada execução a um registo de automação existente.

Isto significa que:

- o cliente regista a automação aprovada localmente uma vez
- depois disso, o cliente só envia logs de execução
- o mesmo `automation_id` é reutilizado ponta a ponta

Este passo local **não**:

- cria uma nova automação na plataforma central da Axians
- substitui o fluxo de aprovação gerido pela Axians
- obriga o cliente a inventar um novo identificador

Ele apenas informa a API local de que:

> "Esta automação aprovada pela Axians existe neste ambiente de cliente e os próximos logs usando este `automation_id` pertencem a ela."

## O que este stack entrega

- uma API local que recebe logs de execução via HTTP
- uma base de dados PostgreSQL local para persistência
- uma instância Redis local para fila e retentativas
- uma instância Grafana pré-configurada para visibilidade local
- reencaminhamento automático de logs de execução para o gateway corporativo da Axians

O endpoint central de forwarding é:

- `https://api-corp.axiansms.pt/v1/automation-logs`

## Stack

- API: `registry.agc.local/automation-logs/api-client-automation-logs:latest`
- Grafana: `registry.agc.local/automation-logs/api-client-grafana:latest`
- PostgreSQL: `postgres:16-alpine`
- Redis: `redis:7-alpine`

## Pré-requisitos do cliente

- host Linux com Docker Engine e plugin Docker Compose
- acesso a `registry.agc.local`
- saída HTTPS para `https://api-corp.axiansms.pt`
- `CLIENT_ID` emitido pela Axians
- `AUTOMATION_TOKEN` emitido pela Axians
- `automation_id` emitido pela Axians para cada automação aprovada

## Ficheiros neste repositório

- [docker-compose.yml](docker-compose.yml): stack de runtime para o ambiente do cliente
- [.env.example](.env.example): template com secrets e configuração específica do cliente
- [examples/README.md](examples/README.md): índice de exemplos e notas de utilização
- [examples/curl/create-automation.sh](examples/curl/create-automation.sh): registo local de automação com `curl`
- [examples/curl/send-execution.sh](examples/curl/send-execution.sh): envio de execução com `curl`
- [examples/bash/automation-logs.sh](examples/bash/automation-logs.sh): wrapper reutilizável em Bash
- [examples/python/automation_logs_client.py](examples/python/automation_logs_client.py): wrapper em Python
- [examples/javascript/automation-logs-client.mjs](examples/javascript/automation-logs-client.mjs): wrapper em JavaScript
- [examples/ansible/playbook.yml](examples/ansible/playbook.yml): exemplo em Ansible
- [examples/powershell/send-execution.ps1](examples/powershell/send-execution.ps1): exemplo em PowerShell
- [examples/n8n/http-request-create-automation.json](examples/n8n/http-request-create-automation.json): workflow n8n importável para registo local da automação
- [examples/n8n/http-request-create-execution.json](examples/n8n/http-request-create-execution.json): workflow n8n importável para envio de execução

## Configuração sensível

Copie `.env.example` para `.env` e substitua os placeholders antes do primeiro deploy.

Os seguintes valores são sensíveis ou específicos do cliente:

- `POSTGRES_PASSWORD`
- `GF_SECURITY_ADMIN_PASSWORD`
- `CLIENT_ID`
- `AUTOMATION_TOKEN`

Não faça commit do ficheiro `.env`.

## Como funciona a autenticação das ferramentas locais

As ferramentas de automação do cliente **não precisam** de enviar `CLIENT_ID` nem `AUTOMATION_TOKEN` quando chamam a API local.

Esses valores são configurados uma vez em `.env` e injetados pela API local quando ela reencaminha os logs de execução para a plataforma central da Axians.

## Primeiro deploy

1. Autentique-se no registry privado:

```bash
docker login registry.agc.local
```

2. Crie o ficheiro de ambiente:

```bash
cp .env.example .env
```

3. Edite `.env` com os valores finais.

4. Faça pull das imagens:

```bash
docker compose pull
```

5. Inicie o stack:

```bash
docker compose up -d
```

6. Valide a API:

```bash
curl http://localhost:3001/healthz
curl http://localhost:3001/readyz
```

## Serviços e portas

- API: `http://<host>:3001`
- Grafana: `http://<host>:3000`
- PostgreSQL: `tcp/<host>:5432`
- Redis: `tcp/<host>:6379`

Se PostgreSQL e Redis não precisarem de estar acessíveis externamente, remova ou restrinja as portas publicadas de acordo com a política de rede do cliente.

## Dados persistentes

O stack guarda dados persistentes em volumes Docker:

- `postgres_data`
- `grafana_data`
- `redis_data`

Estes volumes devem ser preservados entre upgrades e reinícios do host.

## Fluxo operacional

O fluxo esperado do lado do cliente é:

1. registar localmente a automação aprovada na API do cliente, usando o `automation_id` emitido pela Axians
2. guardar o `automation_id` devolvido
3. enviar logs de execução para `POST /executions`
4. deixar que a API persista localmente e reencaminhe centralmente

Se o endpoint central ficar indisponível temporariamente, a API local guarda o registo localmente e reprocessa-o automaticamente através de Redis/BullMQ.

## Diferença entre configuração inicial e uso recorrente

Existem duas ações separadas:

1. Configuração local única
   Registar a automação aprovada em `POST /automations`.

2. Utilização recorrente
   Enviar um registo de execução após cada corrida da automação para `POST /executions`.

Na maior parte dos casos, as ferramentas do cliente só precisam de executar o passo 1 uma vez e depois usar sempre o passo 2.

## Detalhe importante do contrato

Quando a ferramenta do cliente envia uma execução para a API local, o `automation_id` vai **dentro do corpo JSON**.

A rota é:

- `POST /executions`

O corpo JSON enviado pela ferramenta contém dados como:

- `execution_uuid`
- `automation_id`
- `trigger_type`
- `status`
- `started_at`
- `finished_at`
- `duration_ms`
- `host`
- `runtime`
- `error_code`
- `error_message`

A API local injeta depois o `CLIENT_ID` configurado e reencaminha a execução para a Axians usando o `automation_id` já presente no payload.

## Referência rápida da API

Base URL:

- `http://localhost:3001`

Principais endpoints:

- `GET /healthz`
- `GET /readyz`
- `POST /automations`
- `GET /automations`
- `GET /automations/{automationId}`
- `POST /executions`
- `GET /executions`

### Registar localmente uma automação aprovada

Use este endpoint uma vez por cada automação aprovada pela Axians.

Isto não cria uma nova automação no catálogo central da Axians.
Isto cria o registo local necessário para que a API do lado do cliente consiga guardar e enviar logs de execução usando o `automation_id` devolvido.

Use nesta chamada o `automation_id` emitido pela Axians, para que o identificador local e o identificador central se mantenham iguais.

Pense nisto desta forma:

- aprovação central na Axians: já concluída
- registo local no ambiente do cliente: obrigatório uma vez antes do primeiro log de execução

Pedido:

```json
{
  "id": "8c81036f-7db4-4c53-992f-5670fa76f7aa",
  "name": "Backup Firewall",
  "type": "ansible",
  "version": "1.0.0",
  "manualExecutionEffortMinutes": 30
}
```

### Enviar uma execução

A integração do cliente deve chamar:

- `POST /executions`

Não inclua `CLIENT_ID` nem `AUTOMATION_TOKEN` no corpo JSON enviado pela ferramenta de automação.

Pedido:

```json
{
  "automation_id": "8c81036f-7db4-4c53-992f-5670fa76f7aa",
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

Notas importantes:

- `execution_uuid` deve ser único por execução
- reutilize o mesmo `execution_uuid` apenas em retentativas da mesma execução
- `status` deve ser `success` ou `error`
- timestamps devem ser valores ISO-8601 válidos
- sucesso com persistência imediata devolve `201 Created`
- aceite para retentativa devolve `202 Accepted`

### Registo duplicado de automação

Criar a mesma automação duas vezes devolve `409 AUTOMATION_ALREADY_EXISTS`.

Para integrações repetíveis ou idempotentes, prefira wrappers que:

- registem a automação uma vez e guardem o `automation_id`
- ou pesquisem primeiro a automação e reutilizem o `automation_id` existente

## Exemplos de integração

Este repositório inclui exemplos funcionais na diretoria [examples](examples).

Comece por [examples/README.md](examples/README.md) se quiser uma orientação rápida por ferramenta.

### curl

Registar a automação aprovada localmente:

```bash
bash examples/curl/create-automation.sh
```

Enviar execução:

```bash
bash examples/curl/send-execution.sh
```

### Bash

O wrapper Bash é útil para `cron`, scripts shell e hosts Linux com automações leves.

Registar uma automação aprovada localmente:

```bash
bash examples/bash/automation-logs.sh register-automation "<approved-automation-id>" "Backup Firewall" "bash" "1.0.0" "30"
```

Enviar uma execução:

```bash
bash examples/bash/automation-logs.sh send-execution "<automation-id>" "success" "83000"
```

### Python

O wrapper Python expõe helpers para:

- `get_automation(...)`
- `ensure_automation(...)`
- `send_execution(...)`

Executar o exemplo:

```bash
python3 examples/python/automation_logs_client.py
```

### JavaScript

O wrapper JavaScript usa `fetch` nativo em Node.js 20+.

Inclui:

- `getAutomation(...)`
- `ensureAutomation(...)`
- `sendExecution(...)`

Executar o exemplo:

```bash
node examples/javascript/automation-logs-client.mjs
```

### Ansible

O exemplo de Ansible usa o módulo `uri` para:

- procurar uma automação já existente
- criá-la apenas se estiver em falta
- capturar o `automation_id`
- submeter um evento de execução

Executar:

```bash
ansible-playbook examples/ansible/playbook.yml
```

### n8n

Importe os workflows de exemplo em:

- [examples/n8n/http-request-create-automation.json](examples/n8n/http-request-create-automation.json)
- [examples/n8n/http-request-create-execution.json](examples/n8n/http-request-create-execution.json)

Eles criam fluxos importáveis do tipo `Manual Trigger -> Set -> HTTP Request` chamando a API local.

### PowerShell

O exemplo em PowerShell é útil para hosts Windows:

```powershell
./examples/powershell/send-execution.ps1
```

## Padrão recomendado de integração do lado do cliente

Para cada automação aprovada:

1. registar a automação uma vez na API local
2. guardar o `automation_id` devolvido na configuração da plataforma ou do script
3. enviar um registo de execução no final de cada corrida
4. em caso de falha, enviar `status=error` com `error_code` e `error_message`

Isto dá ao cliente:

- observabilidade local no Grafana
- persistência local durável
- forwarding automático para a Axians

## Sequência típica de implementação no cliente

1. a Axians fornece `CLIENT_ID`, `AUTOMATION_TOKEN` e um `automation_id` por automação aprovada
2. o cliente faz o deploy deste stack
3. o cliente regista a automação aprovada na API local usando o `automation_id` emitido pela Axians
4. o cliente guarda o `automation_id` resultante
5. o cliente actualiza scripts, playbooks, jobs ou workflows para publicar execuções na API local

## Procedimento de upgrade

Quando a Axians publicar uma nova release:

1. actualize as tags das imagens em [docker-compose.yml](docker-compose.yml)
2. faça pull das novas imagens:

```bash
docker compose pull
```

3. recrie os serviços:

```bash
docker compose up -d
```

## Notas operacionais

- `AUTOMATION_TOKEN` é enviado pela API para o gateway KrakenD da Axians como `Authorization: Bearer <token>`
- `CLIENT_ID` é injectado no payload reenviado para identificar o cliente
- o provisioning do Grafana já vem embutido na imagem publicada
- a API local é o único endpoint que as ferramentas do cliente devem chamar diretamente

## Troubleshooting

### A API responde, mas `/readyz` devolve `503`

A API ainda não conseguiu ligar-se ao PostgreSQL. Verifique:

- `docker compose ps`
- credenciais do PostgreSQL em `.env`
- logs dos contentores:

```bash
docker compose logs api
docker compose logs postgres
```

### As execuções são aceites localmente mas não aparecem centralmente

Verifique:

- `CLIENT_ID`
- `AUTOMATION_TOKEN`
- saída HTTPS para `api-corp.axiansms.pt`
- logs da API:

```bash
docker compose logs api
```

### A ferramenta do cliente precisa de um wrapper pronto a usar

Comece pelos exemplos na diretoria [examples](examples) e adapte apenas:

- base URL
- metadados da automação
- campos do payload de execução
- qualquer lógica específica de scheduling ou orquestração
