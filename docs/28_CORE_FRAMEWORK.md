# Core Framework Oracle - Brechó Express

## 1. Objetivo

Este documento define a arquitetura inicial do Core Framework Oracle reutilizável do Brechó Express para a Sprint 8.

O Core Framework fornece capacidades técnicas transversais para contexto de execução, rastreabilidade, tratamento de erros, JSON, respostas HTTP e contexto de segurança. Ele deve reduzir duplicação entre os packages de domínio sem concentrar regras de negócio ou se transformar em uma biblioteca genérica de utilidades.

Esta arquitetura complementa as decisões A-001 até A-007, as convenções de banco, a arquitetura física e os padrões de API já aprovados. Ela não redefine essas decisões.

O fluxo externo oficial permanece:

```text
Flutter
  ↓
ORDS
  ↓
*_API_PKG
  ↓
*_SERVICE_PKG
  ↓
*_RULE_PKG
  ↓
*_REPOSITORY_PKG
  ↓
Oracle Database 26ai
```

---

## 2. Escopo

Fazem parte do escopo desta arquitetura:

- definir as fronteiras do Core Framework;
- definir responsabilidades coesas para cada package do Core;
- definir dependências permitidas e proibidas;
- definir o lifecycle técnico de requisições e execuções internas;
- definir inicialização e limpeza do contexto;
- alinhar `traceId`, erros, JSON e respostas HTTP ao documento `27_API_STANDARDS.md`;
- definir o contrato técnico mínimo do contexto de segurança;
- definir integração conceitual com ORDS, APEX, Jobs e Scheduler;
- definir estratégia transacional, de testes e ordem futura de implementação;
- registrar decisões ainda pendentes sem antecipá-las.

Os componentes iniciais são:

- `CORE_CONTEXT_PKG`;
- `CORE_TRACE_PKG`;
- `CORE_ERROR_PKG`;
- `CORE_JSON_PKG`;
- `CORE_RESPONSE_PKG`;
- `CORE_SECURITY_CONTEXT_PKG`.

---

## 3. Fora de Escopo

Não fazem parte desta etapa:

- implementação SQL ou PL/SQL;
- criação de tabelas, views, types, sequences, triggers ou outros objetos físicos;
- implementação de módulos ou regras de negócio;
- definição de endpoints reais;
- autenticação, login ou validação de credenciais;
- geração, renovação, revogação ou validação de tokens;
- persistência ou expiração de sessões;
- regras de autorização, papéis ou permissões;
- definição de provedores de identidade;
- definição de paginação, filtros ou ordenação;
- implementação de auditoria de negócio;
- implementação de integrações externas;
- escolha definitiva do mecanismo de persistência de logs;
- definição física do catálogo de erros;
- definição definitiva de `correlationId`;
- criação de `CORE_UTIL_PKG` ou qualquer package utilitária genérica.

---

## 4. Princípios Arquiteturais

### 4.1 Responsabilidade única

Cada package do Core deve possuir uma capacidade técnica explícita e limitada. Funcionalidades sem dono claro não devem ser agrupadas em packages genéricos.

### 4.2 Core sem domínio

O Core não conhece entidades, estados, fluxos ou regras do negócio. Códigos e categorias de erro podem ser transportados pelo Core, mas a decisão funcional de quando um erro ocorre pertence às camadas de domínio e aplicação.

### 4.3 Dependência unidirecional

As dependências devem formar um grafo acíclico. Nenhum package do Core pode depender de `*_API_PKG`, `*_SERVICE_PKG`, `*_RULE_PKG` ou `*_REPOSITORY_PKG`.

### 4.4 Contrato antes da implementação

As interfaces e responsabilidades devem ser aprovadas antes da criação de PL/SQL ou objetos físicos.

### 4.5 Contexto explícito e limitado à execução

O contexto técnico deve existir apenas durante a execução correspondente. Inicialização e limpeza são obrigatórias para impedir vazamento de estado entre requisições, sessões reutilizadas ou jobs.

### 4.6 Segurança por minimização

O Core deve transportar apenas os identificadores e metadados técnicos necessários. Dados pessoais, credenciais, tokens e informações sensíveis não devem ser copiados indiscriminadamente para contexto, erros ou logs.

### 4.7 Erro também é contrato

Erros devem possuir código estável, categoria, mensagem externa segura, indicação de nova tentativa e `traceId`. Detalhes Oracle permanecem internos.

### 4.8 Transporte isolado do domínio

JSON, HTTP e ORDS pertencem à borda. `*_SERVICE_PKG`, `*_RULE_PKG` e `*_REPOSITORY_PKG` não devem conhecer envelopes JSON ou status HTTP.

### 4.9 Transação orientada ao caso de uso

O Core não redefine fronteiras transacionais. A camada externa continua responsável pela decisão de `COMMIT` ou `ROLLBACK`, conforme A-003.

### 4.10 Evolução incremental

O Core deve começar com o menor contrato reutilizável necessário. Capacidades futuras somente devem ser adicionadas quando houver necessidade concreta e responsabilidade bem definida.

---

## 5. Componentes do Core Framework

| Package | Capacidade técnica | Consumidores principais |
|---|---|---|
| `CORE_CONTEXT_PKG` | Lifecycle e metadados gerais da execução | ORDS adapters, `*_API_PKG`, APEX, `*_JOB_PKG` |
| `CORE_TRACE_PKG` | Criação, validação e acesso ao `traceId` | `CORE_CONTEXT_PKG`, erros, respostas e logs |
| `CORE_ERROR_PKG` | Erros padronizados e tradução técnica segura | Todas as camadas Oracle, especialmente a borda |
| `CORE_JSON_PKG` | Construção técnica consistente de JSON | `CORE_RESPONSE_PKG` e `*_API_PKG` |
| `CORE_RESPONSE_PKG` | Envelope de sucesso/erro e resultado HTTP | `*_API_PKG` e integração ORDS |
| `CORE_SECURITY_CONTEXT_PKG` | Identidade autenticada e metadados mínimos de segurança | Camadas que necessitem conhecer o ator técnico |

O nome `CORE_ERROR_PKG` concretiza o package central de erros descrito conceitualmente como `ERR_PKG` na decisão A-004. Essa especialização de nome não altera a responsabilidade aprovada para o tratamento centralizado de erros.

Não será criado `CORE_UTIL_PKG`. Uma nova capacidade transversal deverá receber nome, contrato e responsabilidade específicos ou permanecer no package ao qual pertence.

---

## 6. Responsabilidades de Cada Package

### 6.1 CORE_CONTEXT_PKG

Responsável pelo lifecycle do contexto técnico geral da execução.

Deve:

- iniciar o contexto de uma requisição ou execução interna;
- associar origem, instante de início e nome técnico do caso de uso, quando informado;
- coordenar a associação do `traceId` e do contexto de segurança;
- permitir leitura controlada dos metadados correntes;
- informar se existe contexto inicializado;
- limpar todo o estado ao final da execução;
- impedir reutilização acidental de contexto anterior.

Não deve:

- autenticar consumidores;
- decidir autorização;
- gerar respostas JSON;
- registrar regras ou estado de negócio;
- executar `COMMIT` ou `ROLLBACK`;
- persistir sessões.

### 6.2 CORE_TRACE_PKG

Responsável exclusivamente pelo identificador técnico de rastreabilidade.

Deve:

- aceitar um `traceId` confiável fornecido pela borda, quando a política aprovada permitir;
- gerar um novo `traceId` quando não existir valor aceitável;
- validar o formato técnico aprovado;
- disponibilizar o valor corrente como identificador opaco;
- garantir um único `traceId` por execução;
- permitir sua propagação para respostas e logs.

Não deve:

- incluir dados pessoais ou de negócio no identificador;
- atribuir significado funcional à estrutura do identificador;
- implementar `correlationId` nesta etapa;
- persistir logs;
- gerar identificadores públicos de entidades.

### 6.3 CORE_ERROR_PKG

Responsável pelo contrato central de erros da plataforma.

Deve:

- representar código, categoria, mensagem externa, severidade, `retryable` e política de log;
- permitir lançamento padronizado de erros conhecidos;
- normalizar falhas técnicas inesperadas em erro externo seguro;
- preservar detalhes técnicos apenas para diagnóstico interno;
- associar o `traceId` corrente;
- oferecer informação suficiente para a borda mapear o erro ao status HTTP;
- impedir uso disperso de mensagens Oracle como contrato externo;
- materializar a responsabilidade central prevista pela A-004.

Não deve:

- conter regras de negócio;
- decidir se uma precondição funcional foi violada;
- expor `SQLERRM`, stack trace, backtrace, packages, procedures, tabelas ou colunas;
- executar resposta HTTP diretamente;
- depender de packages de domínio;
- realizar persistência funcional.

### 6.4 CORE_JSON_PKG

Responsável por primitivas técnicas coesas para construção de JSON conforme o contrato externo.

Deve:

- apoiar a construção segura de objetos e arrays;
- preservar tipos JSON nativos;
- apoiar nomes em `camelCase` definidos pelo contrato;
- distinguir campo ausente, `null` e valor;
- representar coleções vazias como `[]`;
- apoiar datas e horários em ISO-8601;
- escapar valores corretamente;
- impedir concatenação manual insegura de JSON na borda.

Não deve:

- definir payloads de domínio;
- refletir automaticamente tabelas ou records físicos;
- expor nomes de colunas, tipos internos ou IDs Oracle;
- decidir status HTTP;
- consultar dados;
- formatar mensagens de interface visual.

### 6.5 CORE_RESPONSE_PKG

Responsável por construir o resultado técnico retornável pela camada `*_API_PKG` ao ORDS.

Deve:

- produzir o envelope padronizado de sucesso com `success`, `data` e `meta.traceId`;
- produzir o envelope padronizado de erro com `success`, `error` e `meta.traceId`;
- associar o status HTTP semanticamente correto;
- garantir ausência de corpo em respostas 204;
- usar `CORE_JSON_PKG` para serialização;
- usar a representação normalizada de `CORE_ERROR_PKG` para falhas;
- manter HTTP e JSON fora das camadas internas.

Não deve:

- implementar caso de uso;
- decidir regra funcional;
- consultar ou persistir dados;
- executar `COMMIT` ou `ROLLBACK`;
- retornar erro funcional com HTTP 200;
- expor detalhes internos Oracle.

### 6.6 CORE_SECURITY_CONTEXT_PKG

Responsável apenas pelo contrato técnico que disponibiliza a identidade já autenticada e o contexto mínimo de segurança ao restante da plataforma.

Deve:

- receber da borda uma identidade previamente autenticada e confiável;
- disponibilizar identificador público do ator quando aplicável;
- identificar o tipo de origem técnica, como ORDS, APEX, JOB ou SYSTEM;
- indicar se a execução é autenticada, anônima ou técnica, conforme contrato futuro aprovado;
- permitir inicialização, leitura e limpeza controladas;
- rejeitar estado parcial ou inconsistente do próprio contexto técnico.

Não deve:

- implementar login;
- validar senha ou credencial;
- gerar, validar, renovar ou revogar token;
- persistir, renovar ou encerrar sessão;
- consultar `PROFILE`, `ACCOUNT`, `ROLE` ou qualquer tabela;
- implementar regras de autorização;
- decidir permissões de recursos ou operações;
- armazenar o token bruto ou credenciais;
- expor identidade interna numérica ao consumidor externo.

---

## 7. Dependências Permitidas

As dependências permitidas representam contratos de uso, não implementação PL/SQL nesta etapa.

| Origem | Dependências permitidas | Finalidade |
|---|---|---|
| `CORE_TRACE_PKG` | nenhuma package do Core | Manter a rastreabilidade como raiz técnica |
| `CORE_SECURITY_CONTEXT_PKG` | `CORE_ERROR_PKG` | Sinalizar contexto técnico inválido de forma padronizada |
| `CORE_CONTEXT_PKG` | `CORE_TRACE_PKG`, `CORE_SECURITY_CONTEXT_PKG`, `CORE_ERROR_PKG` | Coordenar inicialização e limpeza |
| `CORE_JSON_PKG` | `CORE_ERROR_PKG` | Reportar falhas técnicas de serialização |
| `CORE_RESPONSE_PKG` | `CORE_TRACE_PKG`, `CORE_ERROR_PKG`, `CORE_JSON_PKG` | Construir resultado HTTP padronizado |
| `*_API_PKG` | packages do Core e `*_SERVICE_PKG` | Adaptar transporte e executar caso de uso |
| `*_SERVICE_PKG` | `CORE_CONTEXT_PKG`, `CORE_TRACE_PKG`, `CORE_ERROR_PKG`, `CORE_SECURITY_CONTEXT_PKG`, `*_RULE_PKG` | Consultar contexto técnico e orquestrar |
| `*_RULE_PKG` | `CORE_TRACE_PKG`, `CORE_ERROR_PKG`, `CORE_SECURITY_CONTEXT_PKG`, repository do próprio domínio | Aplicar regra com contexto mínimo |
| `*_REPOSITORY_PKG` | `CORE_TRACE_PKG`, `CORE_ERROR_PKG` | Rastrear e normalizar falhas técnicas de persistência |
| `*_JOB_PKG` | packages de contexto, trace, erro e `*_SERVICE_PKG` | Controlar execução interna |

O uso do `CORE_SECURITY_CONTEXT_PKG` pelas camadas internas deve ocorrer apenas quando o caso de uso realmente necessitar conhecer o ator. Ele não autoriza a operação por si só.

---

## 8. Dependências Proibidas

São proibidas:

- dependências circulares entre packages do Core;
- dependência do Core para qualquer package de negócio;
- dependência do Core para tabelas de domínio;
- acesso direto do Core a `PROFILE`, `ACCOUNT`, `SESSION`, `ROLE` ou `PROFILE_ROLE`;
- dependência de `CORE_TRACE_PKG` para qualquer outra package do Core;
- dependência de `CORE_ERROR_PKG` para `CORE_RESPONSE_PKG` ou `CORE_JSON_PKG`;
- dependência de `CORE_JSON_PKG` para `CORE_RESPONSE_PKG`;
- uso de `CORE_RESPONSE_PKG` por `*_SERVICE_PKG`, `*_RULE_PKG` ou `*_REPOSITORY_PKG`;
- uso de JSON ou status HTTP pelas camadas de regra e persistência;
- chamadas de ORDS diretamente para Core, `*_SERVICE_PKG`, `*_RULE_PKG` ou `*_REPOSITORY_PKG` como substituição de `*_API_PKG`;
- persistência de estado funcional por packages do Core;
- `COMMIT` ou `ROLLBACK` em packages do Core;
- criação ou uso de `CORE_UTIL_PKG`.

---

## 9. Grafo de Dependências

O grafo interno proposto é acíclico:

```text
CORE_TRACE_PKG
      ▲
      │
CORE_ERROR_PKG
      ▲
      ├────────────── CORE_SECURITY_CONTEXT_PKG
      │                         ▲
      ├────────────── CORE_CONTEXT_PKG
      │
      ├────────────── CORE_JSON_PKG
      │                         ▲
      └─────────────────────────┤
                         CORE_RESPONSE_PKG
```

Leitura complementar por fluxo:

```text
ORDS
  ↓
*_API_PKG
  ├── CORE_CONTEXT_PKG
  │     ├── CORE_TRACE_PKG
  │     ├── CORE_SECURITY_CONTEXT_PKG
  │     └── CORE_ERROR_PKG
  ├── *_SERVICE_PKG → *_RULE_PKG → *_REPOSITORY_PKG → Oracle Database 26ai
  └── CORE_RESPONSE_PKG
        ├── CORE_TRACE_PKG
        ├── CORE_ERROR_PKG
        └── CORE_JSON_PKG
```

Uma futura implementação deve possuir validação automatizada para impedir ciclos e chamadas proibidas.

---

## 10. Lifecycle de uma Requisição

O lifecycle técnico conceitual de uma requisição externa é:

1. ORDS recebe a requisição HTTP.
2. ORDS extrai somente metadados de transporte aprovados.
3. ORDS chama o `*_API_PKG` correspondente, sem SQL solto e sem regra de negócio.
4. `*_API_PKG` solicita inicialização limpa ao `CORE_CONTEXT_PKG`.
5. `CORE_TRACE_PKG` adota um valor confiável ou gera um novo `traceId`.
6. `CORE_SECURITY_CONTEXT_PKG` recebe a identidade já autenticada, quando existir.
7. `*_API_PKG` valida o contrato técnico de entrada.
8. `*_API_PKG` chama `*_SERVICE_PKG`.
9. O caso de uso percorre `*_SERVICE_PKG` → `*_RULE_PKG` → `*_REPOSITORY_PKG` → Oracle Database 26ai.
10. O resultado retorna pelas camadas sem carregar conceitos HTTP para o domínio.
11. `*_API_PKG` decide `COMMIT` em sucesso ou `ROLLBACK` em falha, conforme A-003.
12. `CORE_RESPONSE_PKG` constrói a resposta HTTP e o envelope aplicável.
13. Em erro, `CORE_ERROR_PKG` normaliza a falha e o mecanismo técnico de log registra diagnóstico quando exigido.
14. A resposta contém o mesmo `traceId`, salvo respostas 204, que não possuem corpo.
15. Em bloco de finalização obrigatório, `CORE_CONTEXT_PKG` limpa contexto geral, trace e segurança.
16. ORDS devolve a resposta ao Flutter ou a outro consumidor externo.

A limpeza deve ocorrer tanto em sucesso quanto em erro, inclusive quando a falha acontecer durante inicialização ou serialização.

---

## 11. Inicialização e Limpeza do Contexto

### 11.1 Inicialização

Toda execução deve começar em estado conhecido. A inicialização deve:

- limpar defensivamente qualquer estado residual;
- registrar a origem técnica da execução;
- estabelecer o instante inicial;
- estabelecer um único `traceId`;
- inicializar o contexto de segurança como vazio, anônimo ou autenticado conforme dados confiáveis recebidos;
- recusar valores incompletos ou incompatíveis;
- concluir antes da chamada ao caso de uso.

Inicializações repetidas na mesma execução não devem sobrescrever silenciosamente contexto válido. O comportamento definitivo deve ser explícito e testável.

### 11.2 Limpeza

A limpeza deve:

- remover identidade e metadados de segurança;
- remover `traceId` e metadados gerais;
- ser segura mesmo após inicialização parcial;
- ser idempotente do ponto de vista técnico;
- ocorrer em um bloco de finalização garantida;
- não executar `COMMIT` ou `ROLLBACK`;
- não ocultar a falha original se também falhar.

### 11.3 Reutilização de sessão Oracle

Nenhuma implementação pode presumir que uma sessão Oracle é exclusiva de uma requisição. Estado de package pode sobreviver quando conexões forem reutilizadas; por isso, inicialização defensiva e limpeza garantida são requisitos arquiteturais.

**Decisão pendente:** mecanismo Oracle definitivo para armazenamento do contexto por execução, incluindo avaliação de estado de package, application context e recursos equivalentes do Oracle Database 26ai.

---

## 12. Estratégia de traceId

O `traceId` é um identificador técnico opaco de uma execução.

Regras:

- toda requisição e execução interna deve possuir `traceId`;
- o mesmo valor deve acompanhar as camadas da execução;
- respostas de sucesso com corpo incluem `meta.traceId`;
- respostas de erro incluem `meta.traceId`;
- logs técnicos devem registrar o mesmo valor;
- o valor não deve conter informação de negócio, dado pessoal ou informação sensível;
- o consumidor não deve interpretar sua estrutura;
- o `traceId` não substitui `PUBLIC_ID`, idempotency key, session id ou `correlationId`;
- valores recebidos externamente somente podem ser adotados após política de confiança e validação;
- ausência ou rejeição do valor recebido deve resultar na geração de novo identificador, sem impedir a execução apenas por esse motivo.

**Decisões pendentes:**

- algoritmo de geração;
- tamanho e formato definitivos;
- nome do header de entrada e resposta;
- regras de confiança para valores fornecidos externamente;
- relação entre `traceId` e `correlationId`;
- política de propagação para integrações externas.

---

## 13. Estratégia de Tratamento de Erros

O tratamento é centralizado por `CORE_ERROR_PKG`, preservando a decisão A-004.

Fluxo conceitual:

1. A camada responsável identifica a condição de erro.
2. Para erros conhecidos, informa um código oficial e contexto técnico mínimo permitido.
3. `CORE_ERROR_PKG` associa categoria, mensagem externa segura, severidade, `retryable`, política de log e `traceId`.
4. A falha sobe até a borda sem ser convertida em sucesso.
5. A camada externa executa `ROLLBACK` quando aplicável.
6. Erros técnicos que exigem diagnóstico são enviados ao mecanismo específico de log.
7. `CORE_RESPONSE_PKG` mapeia a categoria para o status HTTP e produz o envelope padronizado.

Regras:

- `RAISE_APPLICATION_ERROR` não deve ser utilizado de forma dispersa;
- mensagens funcionais e técnicas devem permanecer separadas;
- falhas inesperadas devem resultar em mensagem externa genérica e segura;
- o erro original deve ser preservado apenas no diagnóstico interno autorizado;
- um erro durante logging não deve substituir a falha original;
- HTTP 200 nunca representa erro funcional;
- o status HTTP representa a categoria protocolar, enquanto o código representa a causa específica;
- 400 representa contrato tecnicamente inválido;
- 409 representa conflito de estado, concorrência ou duplicidade funcional;
- 422 representa request tecnicamente válido rejeitado por regra funcional;
- a política 404 em lugar de 403, quando necessária para não revelar existência, pertence ao contrato da API.

---

## 14. Catálogo de Erros

Cada entrada do catálogo deve possuir, no mínimo:

- código único e estável;
- categoria;
- mensagem externa segura;
- mensagem técnica ou orientação diagnóstica interna, quando aplicável;
- severidade;
- indicador `retryable`;
- indicador de geração de log técnico;
- status HTTP esperado na borda, quando aplicável;
- contexto ou módulo proprietário do código;
- estado de vigência e documentação.

Categorias iniciais já previstas pela arquitetura física:

- `BUSINESS_ERROR`;
- `VALIDATION_ERROR`;
- `NOT_FOUND`;
- `SECURITY_ERROR`;
- `AUTHENTICATION_ERROR`;
- `AUTHORIZATION_ERROR`;
- `CONFLICT_ERROR`;
- `TECHNICAL_ERROR`;
- `INTEGRATION_ERROR`.

O padrão conceitual de códigos permanece `BEX-{CONTEXTO}-{NNN}`, como `BEX-ORD-007`. Códigos publicados não devem ser reutilizados com outro significado.

O Core interpreta e transporta entradas catalogadas, mas não se torna proprietário de erros funcionais dos módulos.

**Decisões pendentes:**

- repositório oficial do catálogo;
- processo de reserva e aprovação de códigos;
- faixas de códigos por módulo;
- versionamento e depreciação de códigos;
- estrutura definitiva para detalhes de validação por campo;
- matriz definitiva entre categorias e status HTTP.

---

## 15. Estratégia de Logs Técnicos

Logs técnicos apoiam diagnóstico e observabilidade; não substituem auditoria de negócio.

Todo registro técnico deve considerar:

- `traceId`;
- instante do evento;
- origem técnica;
- severidade;
- código do erro, quando aplicável;
- componente ou etapa técnica em formato interno controlado;
- mensagem técnica sanitizada;
- duração ou resultado, quando aplicável;
- ausência de credenciais, tokens e dados sensíveis desnecessários.

Regras:

- logs técnicos não alteram estado funcional;
- logging deve ser acionado conforme política do catálogo, evitando duplicação por camada;
- a mesma falha não deve gerar registros redundantes em todas as camadas;
- falha de logging não deve mascarar o erro principal;
- detalhes técnicos nunca devem ser copiados para a resposta externa;
- retenção, acesso e sanitização devem respeitar segurança e governança futuras.

A arquitetura física admite `AUTONOMOUS_TRANSACTION` apenas para finalidades técnicas que precisem sobreviver ao rollback, mediante justificativa e aprovação arquitetural. Este documento não aprova nem implementa seu uso.

**Decisões pendentes:**

- packages específicos de log e suas fronteiras;
- criação e modelagem futura de `ERROR_LOG`, `JOB_LOG` e `INTEGRATION_LOG`;
- uso ou não de `AUTONOMOUS_TRANSACTION` por mecanismo;
- níveis de severidade definitivos;
- retenção, mascaramento, volume e observabilidade externa.

---

## 16. Estratégia de JSON

`CORE_JSON_PKG` deve apoiar os contratos definidos em `27_API_STANDARDS.md` sem conhecer payloads de negócio.

Regras:

- atributos externos usam `camelCase`;
- tipos JSON nativos devem ser preservados;
- booleanos são `true` ou `false`;
- datas e horários seguem ISO-8601;
- coleções vazias são `[]`, nunca `null`;
- campo ausente, campo `null` e campo com valor possuem semânticas distintas;
- enums externos são textos estáveis;
- IDs internos, nomes de colunas e tipos Oracle não podem aparecer;
- números não devem ser convertidos em texto sem decisão contratual;
- a ordem dos atributos não faz parte do contrato;
- consumidores devem poder ignorar propriedades desconhecidas;
- contratos não devem ser gerados automaticamente a partir de tabelas.

O `*_API_PKG` continua responsável por definir quais propriedades pertencem ao payload. `CORE_JSON_PKG` fornece apenas mecanismos seguros e consistentes de serialização.

**Decisões pendentes:**

- APIs Oracle 26ai que serão adotadas para construção e parsing;
- limites e estratégia para payloads grandes;
- padrão definitivo para valores monetários;
- estratégia de streaming, quando necessária;
- contrato técnico interno para objetos e arrays.

---

## 17. Estratégia de Respostas HTTP

`CORE_RESPONSE_PKG` deve preservar os contratos oficiais.

Sucesso com conteúdo:

```json
{
  "success": true,
  "data": {},
  "meta": {
    "traceId": "..."
  }
}
```

Erro:

```json
{
  "success": false,
  "error": {
    "code": "BEX-ORD-001",
    "category": "BUSINESS_ERROR",
    "message": "Não foi possível concluir o pedido.",
    "retryable": false
  },
  "meta": {
    "traceId": "..."
  }
}
```

Regras:

- 200 para consulta, atualização ou ação concluída com resposta;
- 201 quando um novo recurso identificável for criado;
- 202 quando a execução for apenas aceita para processamento assíncrono;
- 204 para operação concluída sem corpo e sem envelope JSON;
- erros usam o status HTTP correspondente, nunca 200;
- respostas externas não expõem SQL, stack, packages, tabelas, colunas ou IDs internos;
- `traceId` deve estar presente em todo envelope com corpo;
- `data` é definido pelo contrato do endpoint, não pelo Core;
- a borda deve definir status e headers antes de entregar o corpo ao ORDS.

**Decisões pendentes:** contrato técnico entre `CORE_RESPONSE_PKG`, `*_API_PKG` e ORDS para status, headers, MIME type e corpo.

---

## 18. Contexto de Segurança

`CORE_SECURITY_CONTEXT_PKG` é um portador técnico de identidade autenticada, não um serviço de autenticação ou autorização.

O contrato conceitual deve permitir representar:

- se existe identidade autenticada;
- `publicId` do ator autenticado, quando aplicável;
- tipo de ator ou origem técnica em vocabulário aprovado;
- canal de origem, como ORDS, APEX, JOB ou SYSTEM;
- identificador técnico da execução já fornecido pelo contexto geral;
- metadados mínimos de autenticação necessários às camadas internas, sem copiar credenciais.

Regras:

- somente uma borda confiável pode inicializar o contexto;
- camadas internas podem consultá-lo, mas não alterar a identidade;
- `publicId` externo nunca é substituído pelo ID numérico Oracle;
- ausência de identidade deve ser representada explicitamente;
- tokens e credenciais não devem ser armazenados;
- o contexto deve ser limpo ao final de toda execução;
- autorização continua pertencendo a contratos e regras específicas futuras;
- a existência do contexto não prova permissão para uma ação.

**Decisões pendentes:**

- atributos definitivos do contexto;
- vocabulário de tipos de ator e origem;
- mecanismo de confiança entre ORDS e Oracle;
- representação de chamadas anônimas e técnicas;
- relação futura com sessões, papéis e autorização.

---

## 19. Integração com ORDS

ORDS permanece a única porta oficial para consumidores externos.

ORDS deve:

- receber HTTP;
- extrair parâmetros e metadados aprovados;
- encaminhar identidade já autenticada e informações técnicas confiáveis;
- chamar exclusivamente `*_API_PKG`;
- devolver status, headers e corpo produzidos pela borda da aplicação.

ORDS não deve:

- executar SQL solto;
- implementar regra de negócio;
- chamar Core como endpoint de negócio;
- chamar `*_SERVICE_PKG`, `*_RULE_PKG` ou `*_REPOSITORY_PKG` diretamente;
- montar envelopes divergentes dos padrões oficiais;
- expor detalhes internos Oracle.

O `*_API_PKG` é responsável por coordenar contexto, validação técnica, caso de uso, transação e resposta. O Core oferece capacidades reutilizáveis, mas não substitui a fronteira `*_API_PKG`.

**Decisões pendentes:** configuração definitiva dos handlers ORDS, propagação de headers e mecanismo de entrega da identidade autenticada.

---

## 20. Integração com APEX, Jobs e Scheduler

### 20.1 APEX

APEX é consumidor interno e pode chamar `*_API_PKG` ou `*_SERVICE_PKG` conforme o contexto aprovado pela arquitetura física.

Quando chamar `*_SERVICE_PKG` diretamente, APEX deve:

- inicializar e limpar o contexto técnico;
- fornecer identidade confiável ao contexto de segurança;
- controlar sua transação;
- não exigir envelopes HTTP das camadas internas.

### 20.2 Jobs

O fluxo interno permanece:

```text
DBMS_SCHEDULER
  ↓
*_JOB_PKG
  ↓
*_SERVICE_PKG
  ↓
*_RULE_PKG
  ↓
*_REPOSITORY_PKG
  ↓
Oracle Database 26ai
```

`*_JOB_PKG` deve:

- inicializar contexto com origem JOB ou SYSTEM;
- estabelecer `traceId` por execução;
- controlar a fronteira transacional definida para o job;
- registrar resultado técnico conforme estratégia aprovada;
- limpar o contexto em sucesso ou falha.

### 20.3 Scheduler

`DBMS_SCHEDULER` apenas agenda e dispara. Ele não inicializa Core diretamente, não executa SQL de domínio e não contém regra de negócio.

**Decisões pendentes:** granularidade de `traceId` para job, lote e item; identidade técnica SYSTEM; e integração definitiva com logs de job.

---

## 21. Estratégia Transacional

O Core Framework não controla transações de negócio.

Regras:

- `*_API_PKG` controla `COMMIT` ou `ROLLBACK` nas chamadas externas via ORDS;
- APEX, `*_JOB_PKG` e outros consumidores internos controlam as próprias transações;
- `*_SERVICE_PKG`, `*_RULE_PKG` e `*_REPOSITORY_PKG` não executam `COMMIT` ou `ROLLBACK`;
- packages do Core não executam `COMMIT` ou `ROLLBACK`;
- construção de contexto, trace, erro, JSON e resposta não confirma estado funcional;
- limpeza do contexto deve ocorrer depois da decisão transacional e também quando a decisão falhar;
- logs técnicos que precisem sobreviver ao rollback exigem mecanismo específico e aprovação arquitetural;
- nenhuma falha de serialização pode transformar uma transação ainda não decidida em confirmação implícita.

O caso de uso, e não o Core, a tabela ou a operação SQL, determina a fronteira transacional.

---

## 22. Estratégia de Testes

A futura implementação deve possuir testes por package e testes de integração do lifecycle.

### 22.1 Testes unitários conceituais

- `CORE_TRACE_PKG`: geração, adoção, rejeição e estabilidade do `traceId`;
- `CORE_ERROR_PKG`: categorias, mensagens seguras, `retryable`, severidade e falhas inesperadas;
- `CORE_JSON_PKG`: tipos, escaping, `null`, ausência, arrays vazios, booleanos e ISO-8601;
- `CORE_RESPONSE_PKG`: envelopes, status e ausência de corpo em 204;
- `CORE_SECURITY_CONTEXT_PKG`: inicialização confiável, imutabilidade, ausência e limpeza;
- `CORE_CONTEXT_PKG`: ordem de inicialização, estado parcial, reinicialização e limpeza idempotente.

### 22.2 Testes de integração

- lifecycle completo em sucesso;
- lifecycle completo em erro conhecido;
- falha técnica inesperada;
- rollback com preservação controlada de diagnóstico técnico, quando aprovado;
- propagação do mesmo `traceId` por todas as camadas;
- ausência de vazamento de contexto entre execuções na mesma sessão Oracle;
- integração ORDS → `*_API_PKG` sem acesso direto a camadas internas;
- execução por APEX e Job com contexto e transação próprios;
- garantia de que detalhes Oracle não aparecem na resposta.

### 22.3 Testes arquiteturais

- detecção de dependências circulares;
- detecção de chamadas proibidas entre camadas;
- proibição de `CORE_UTIL_PKG`;
- proibição de `COMMIT` e `ROLLBACK` no Core e camadas internas;
- proibição de SQL de domínio no Core;
- conformidade dos envelopes com `27_API_STANDARDS.md`.

**Decisão pendente:** framework, organização física, métricas de cobertura e automação dos testes Oracle.

---

## 23. Ordem de Implementação

A ordem recomendada para uma sprint futura de implementação é:

1. aprovar decisões pendentes que bloqueiam os contratos públicos dos packages;
2. definir contratos e tipos técnicos mínimos compartilhados, sem criar package genérica;
3. implementar `CORE_TRACE_PKG`;
4. implementar `CORE_ERROR_PKG` e a primeira versão governada do catálogo;
5. implementar `CORE_SECURITY_CONTEXT_PKG`;
6. implementar `CORE_CONTEXT_PKG`;
7. implementar `CORE_JSON_PKG`;
8. implementar `CORE_RESPONSE_PKG`;
9. integrar um fluxo técnico mínimo de `*_API_PKG` com ORDS, sem módulo de negócio;
10. validar APEX e um `*_JOB_PKG` técnico de teste, sem persistência funcional;
11. executar testes unitários, de integração, segurança e dependências;
12. revisar documentação e critérios de aceite antes de habilitar o Core para módulos.

Essa ordem reduz ciclos: trace e erro formam a base; segurança e contexto organizam o lifecycle; JSON e resposta ficam na borda.

---

## 24. Critérios de Aceite da Sprint 8

A Sprint 8 arquitetural será considerada aceita quando:

- este documento estiver revisado e aprovado;
- os seis packages iniciais possuírem responsabilidades e limites inequívocos;
- `CORE_UTIL_PKG` estiver explicitamente proibido;
- o grafo de dependências estiver acíclico;
- dependências permitidas e proibidas estiverem documentadas;
- o lifecycle externo e interno estiver definido;
- inicialização e limpeza forem obrigatórias em todos os caminhos;
- a estratégia de `traceId` estiver alinhada ao padrão de API;
- o tratamento de erros preservar A-004 e não expuser detalhes Oracle;
- os envelopes de sucesso e erro coincidirem com `27_API_STANDARDS.md`;
- respostas 204 forem definidas sem corpo;
- o contexto de segurança estiver limitado a identidade já autenticada e metadados mínimos;
- login, tokens, sessões e autorização permanecerem fora do Core desta Sprint;
- a fronteira transacional permanecer conforme A-003;
- integrações com ORDS, APEX, Jobs e Scheduler estiverem documentadas;
- decisões não aprovadas estiverem marcadas explicitamente como pendentes;
- nenhuma tabela, SQL, PL/SQL, endpoint real ou regra de negócio tiver sido criada;
- nenhum outro documento tiver sido alterado nesta atividade.

---

## 25. Decisões Pendentes

As seguintes decisões permanecem deliberadamente abertas:

1. mecanismo Oracle 26ai para armazenamento isolado do contexto por execução;
2. formato, tamanho e algoritmo de geração do `traceId`;
3. headers de entrada e resposta para rastreabilidade;
4. política de confiança para `traceId` recebido;
5. definição e relação futura de `correlationId`;
6. atributos definitivos do contexto geral e do contexto de segurança;
7. integração confiável da identidade autenticada entre ORDS e Oracle;
8. tratamento de chamadas anônimas, APEX, JOB e SYSTEM;
9. repositório, governança e versionamento do catálogo de erros;
10. matriz definitiva entre categorias de erro e status HTTP;
11. estrutura de detalhes de validação por campo;
12. mecanismo e modelo físico de logs técnicos;
13. uso excepcional de `AUTONOMOUS_TRANSACTION` em cada tipo de log;
14. severidades, retenção, mascaramento e acesso aos logs;
15. APIs nativas do Oracle 26ai adotadas para JSON;
16. padrão definitivo para valores monetários em JSON;
17. limites, streaming e tratamento de payloads grandes;
18. contrato técnico entre `CORE_RESPONSE_PKG`, `*_API_PKG` e ORDS;
19. framework e organização dos testes Oracle;
20. mecanismo automatizado para validação de dependências arquiteturais.

Nenhum item desta lista deve ser considerado aprovado por aparecer neste documento. Cada decisão deverá ser avaliada, registrada e aprovada antes de orientar implementação definitiva.

---

## 26. Checklist Arquitetural

Antes de aprovar uma evolução do Core Framework, verificar:

- [ ] A mudança possui responsabilidade técnica específica e coesa.
- [ ] A mudança não redefine A-001 até A-007.
- [ ] Não existe regra de negócio no Core.
- [ ] Não existe SQL de domínio no Core.
- [ ] Não existe acesso do Core a tabelas ou packages de negócio.
- [ ] Não existe dependência circular.
- [ ] A direção das dependências permanece válida.
- [ ] `CORE_UTIL_PKG` não foi criado nem simulado por outro nome genérico.
- [ ] ORDS continua chamando exclusivamente `*_API_PKG`.
- [ ] HTTP e JSON permanecem fora de SERVICE, RULE e REPOSITORY.
- [ ] IDs internos Oracle não são expostos.
- [ ] O `traceId` é opaco, não sensível e propagado corretamente.
- [ ] O contexto é inicializado e limpo em sucesso e erro.
- [ ] O contexto de segurança não autentica nem autoriza.
- [ ] Tokens, credenciais e sessões não são persistidos pelo Core.
- [ ] Erros usam códigos estáveis e mensagens externas seguras.
- [ ] Detalhes Oracle permanecem apenas no diagnóstico interno autorizado.
- [ ] Envelopes de sucesso e erro seguem `27_API_STANDARDS.md`.
- [ ] HTTP 204 não possui corpo.
- [ ] HTTP 200 não representa erro funcional.
- [ ] Packages do Core não executam `COMMIT` ou `ROLLBACK`.
- [ ] Logs técnicos não alteram estado funcional.
- [ ] Decisões ainda abertas estão marcadas como pendentes.
- [ ] Testes cobrem lifecycle, isolamento de contexto, segurança e dependências.
- [ ] Nenhuma tabela, SQL ou PL/SQL foi antecipada.

---

## 27. Observações

O Core Framework é infraestrutura transversal e não um novo módulo de negócio. Seu valor depende de fronteiras pequenas, contratos estáveis e uso disciplinado pelas camadas existentes.

Esta versão inicia a arquitetura da Sprint 8 sem antecipar implementação. A evolução deverá continuar alinhada à Constituição do projeto, às ADRs, às convenções de banco e modelagem, à Arquitetura de Sistema, à Arquitetura Física e aos Padrões de API do Brechó Express.