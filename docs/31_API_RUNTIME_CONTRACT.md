# Contrato Técnico de Runtime das APIs - Brechó Express

## 1. Objetivo

Este documento define o contrato técnico oficial e reutilizável da fronteira entre ORDS, packages `*_API_PKG`, packages `*_SERVICE_PKG` e o Core Framework do Brechó Express.

Seu propósito é encerrar as pendências de runtime registradas em `28_CORE_FRAMEWORK.md` quanto a assinatura PL/SQL, status HTTP, corpo, contexto, ator técnico, transação, parsing JSON e tratamento de erros. Ele complementa `26_PHYSICAL_ARCHITECTURE.md`, `27_API_STANDARDS.md`, `28_CORE_FRAMEWORK.md` e `30_DEVELOPMENT_STANDARD.md`, sem redefinir contratos de domínio ou endpoints específicos.

Este contrato deve ser aplicado antes da implementação de qualquer novo `*_API_PKG` destinado ao ORDS.

---

## 2. Escopo

Este documento disciplina:

- chamadas síncronas do ORDS para `*_API_PKG`;
- entrada por body JSON, parâmetros de rota e query parameters;
- retorno separado de status HTTP e body JSON;
- lifecycle do Trace, Execution Context e Security Context;
- entrega de ator técnico confiável;
- fronteira transacional de operações externas;
- parsing e validação estrutural;
- tradução de exceções e códigos públicos;
- responsabilidades mínimas de segurança e observabilidade.

Não define:

- endpoints ou payloads de módulos específicos;
- autenticação, autorização ou resolução física de identidade;
- scripts ou sintaxe de configuração do ORDS;
- persistência de logs;
- alterações nos packages atuais do Core;
- catálogo completo de erros de negócio.

---

## 3. Arquitetura

O fluxo externo oficial permanece:

```text
Consumidor externo
        ↓
ORDS handler
        ↓
*_API_PKG
        ↓
*_SERVICE_PKG
        ↓
*_RULE_PKG / *_REPOSITORY_PKG
        ↓
Oracle Database
```

A direção é unidirecional. O ORDS não executa SQL de domínio e não chama Service, Rule, Repository ou tabela diretamente. O `*_API_PKG` não acessa Repository ou tabela e não implementa regra de negócio.

O `ACC_SESSION_API_PKG` é um precedente transacional anterior a este contrato, mas sua interface baseada em tipos internos e sem envelope Core não constitui o padrão para novos endpoints ORDS. Sua eventual adequação será tratada separadamente.

---

## 4. Responsabilidades por Camada

### 4.1 ORDS handler

O handler é o adapter técnico confiável. Ele:

- recebe body, parâmetros de rota, query parameters e metadados HTTP;
- autentica por meio da infraestrutura aprovada ou recebe identidade já autenticada;
- resolve, quando necessário, o ator técnico numérico;
- inicializa e limpa o Core Context;
- chama exclusivamente o `*_API_PKG` correspondente;
- aplica status HTTP, MIME type e body devolvidos pela API;
- garante limpeza do contexto em sucesso, erro e inicialização parcial.

### 4.2 `*_API_PKG`

A API:

- valida o contrato técnico de entrada;
- faz parsing do JSON e conversões técnicas explícitas;
- chama exclusivamente a Service ou outra fronteira de caso de uso aprovada;
- traduz exceções nominais para erros públicos;
- constrói payload e envelope com o Core;
- decide `COMMIT` ou `ROLLBACK` nas escritas externas;
- devolve status e body ao handler.

A API não executa SQL de domínio, não chama Repository diretamente, não implementa regras funcionais e não confia em ator vindo do body.

### 4.3 `*_SERVICE_PKG`

A Service executa o caso de uso, coordena Rule e Repository conforme a arquitetura aprovada e não conhece JSON, HTTP ou ORDS. Ela não executa `COMMIT` ou `ROLLBACK`.

### 4.4 Core Framework

O Core fornece contexto, trace, segurança técnica, construção de erros, primitivas JSON e envelopes. O Core não define payloads de domínio, não decide regras funcionais, não resolve o ator numérico e não controla transações.

---

## 5. Assinatura Padrão do API Package

### 5.1 Operação com body

O padrão para operação autenticada com body é:

```plsql
PROCEDURE operation_name(
    p_request_body   IN  CLOB,
    p_actor_id       IN  NUMBER,
    o_status_code    OUT PLS_INTEGER,
    o_response_body  OUT NOCOPY CLOB
);
```

Ordem obrigatória:

1. entradas de transporte;
2. ator técnico, quando exigido;
3. status de saída;
4. body de saída.

`p_request_body` representa exclusivamente o body recebido. `p_actor_id` é contexto técnico confiável e nunca uma propriedade JSON. `o_response_body` usa `NOCOPY` por ser LOB de saída.

### 5.2 Operação sem body

Uma operação com identificador de rota usa:

```plsql
PROCEDURE operation_name(
    p_public_id      IN  VARCHAR2,
    p_actor_id       IN  NUMBER,
    o_status_code    OUT PLS_INTEGER,
    o_response_body  OUT NOCOPY CLOB
);
```

O nome do identificador deve ser funcional, como `p_profile_public_id`, quando isso aumentar a clareza. APIs externas nunca recebem ID interno Oracle.

### 5.3 Leituras e ator

O ator somente integra a assinatura quando autenticação, autorização, visibilidade ou auditoria exigirem identidade técnica. Leitura pública anônima omite `p_actor_id`. Leitura autenticada o exige.

Não se usa `DEFAULT NULL` para tornar autenticação implicitamente opcional. O contrato do endpoint deve escolher uma das assinaturas. Operação de sistema não é exposta diretamente como endpoint público.

### 5.4 Parâmetros de rota e query

Parâmetros de rota são parâmetros `IN` separados do body e antecedem `p_request_body`. Query parameters também são parâmetros `IN` explícitos e tipados no contrato PL/SQL. A API valida formato, faixa e combinações. O body não duplica identificador definido na rota.

### 5.5 Headers

Headers não são representados por um record genérico nesta versão. Somente um header necessário ao contrato específico pode virar parâmetro explícito. Não será criada abstração genérica sem necessidade concreta.

---

## 6. Contrato de Entrada

- JSON externo usa propriedades em `camelCase`.
- Identificadores externos são exclusivamente `PUBLIC_ID`.
- IDs numéricos internos não aparecem em body, rota ou query.
- Body é `CLOB`; parâmetros simples permanecem escalares.
- Datas sem horário usam `YYYY-MM-DD`.
- Instantes usam ISO-8601 conforme `27_API_STANDARDS.md`.
- Booleanos são tipos JSON `true` e `false`.
- Enums são textos estáveis.
- Obrigatoriedade, nulabilidade e semântica de ausência pertencem ao contrato de cada operação.

O contrato externo não é derivado automaticamente de `%ROWTYPE`, nomes de coluna ou tipos de Repository.

---

## 7. Contrato de Saída

Toda operation retorna separadamente:

- `o_status_code OUT PLS_INTEGER`;
- `o_response_body OUT NOCOPY CLOB`.

O body com conteúdo é sempre construído por `CORE_RESPONSE_PKG`. O status não faz parte do CLOB e é aplicado pelo handler ORDS.

O MIME type padrão é:

```text
application/json; charset=UTF-8
```

O handler define o header `Content-Type`. Nenhum header customizado é obrigatório nesta versão. `traceId` é devolvido no envelope, não em header.

Respostas `204 No Content` usam `o_response_body := NULL`. Para qualquer outro status, a API deve tentar produzir o envelope oficial.

Na entrada da operação, a API deve inicializar defensivamente as saídas com status `500` e body `NULL`. Se ocorrer falha antes que o Core consiga construir um envelope, o handler devolve status 500 sem detalhe técnico e sem fabricar um envelope divergente. Esse é fallback de transporte, não resposta funcional normal.

---

## 8. Status HTTP

O `*_API_PKG` escolhe o status conforme o contrato da operação e a categoria do erro. O ORDS apenas aplica o valor recebido.

Status gerais:

| Resultado | Status |
|---|---:|
| Consulta ou atualização com conteúdo | 200 |
| Recurso criado | 201 |
| Processamento assíncrono aceito | 202 |
| Sucesso sem body | 204 |
| Request estruturalmente inválido | 400 |
| Autenticação ausente ou inválida | 401 |
| Operação não autorizada | 403 |
| Recurso não encontrado | 404 |
| Conflito de estado ou unicidade funcional | 409 |
| Regra funcional rejeitada | 422 |
| Falha técnica inesperada | 500 |

O status HTTP expressa a categoria protocolar; o código público identifica a causa estável.

---

## 9. Envelope JSON

### 9.1 Contrato real vigente

O contrato instalado de `CORE_RESPONSE_PKG` usa `traceId` na raiz, e não dentro de `meta`. Esta forma prevalece sobre exemplos conceituais anteriores.

Sucesso com conteúdo:

```json
{
  "success": true,
  "traceId": "0123456789ABCDEF0123456789ABCDEF",
  "data": {}
}
```

Erro:

```json
{
  "success": false,
  "traceId": "0123456789ABCDEF0123456789ABCDEF",
  "error": {
    "code": "BEX-REQ-001",
    "category": "VALIDATION_ERROR",
    "message": "A requisicao e invalida.",
    "retryable": false
  }
}
```

### 9.2 Regras do envelope

- `build_success` exige `JSON_ELEMENT_T` não nulo em PL/SQL.
- Um JSON `null` explícito pode ser usado como `data` apenas quando o contrato da operação aprovar essa semântica.
- Sucesso sem propriedade `data` usa `empty_success`.
- Listas são `JSON_ARRAY_T`; lista vazia é `[]`.
- Paginação, quando aprovada, pertence ao objeto `data` até eventual evolução oficial do envelope.
- Não existem atualmente `meta`, `httpStatus`, `severity`, `technicalDetail`, `shouldLog` ou `suggestedHttpStatus` no envelope.
- A ordem física das propriedades não faz parte do contrato.

### 9.3 Datas e timestamps

Datas sem horário são strings `YYYY-MM-DD`, produzidas por conversão explícita e independente de NLS. Timestamps usam `CORE_JSON_PKG.format_timestamp` ou `format_timestamp_tz`, conforme o tipo. Valores de apresentação não são formatados localmente pelo Oracle.

Campos opcionais aplicáveis sem valor devem ser representados como JSON `null` quando o contrato os publicar. Campos que não pertencem ao contrato são omitidos.

---

## 10. Ator Técnico Confiável

O Core mantém o ator público como `CHAR(32)`. Algumas tabelas mantêm auditoria técnica como `NUMBER`. Não há conversão implícita entre esses identificadores.

Decisão provisória oficial:

- a infraestrutura confiável de autenticação associada ao ORDS resolve o ator técnico antes da chamada ao `*_API_PKG`;
- o handler entrega esse valor em `p_actor_id NUMBER`;
- `p_actor_id` não vem do body, query, rota ou header controlável diretamente pelo cliente;
- a API repassa o valor à Service sem consultar tabelas e sem convertê-lo a partir do public ID;
- o Core continua armazenando apenas a identidade pública;
- a resolução público → técnico permanece fora dos packages de negócio.

Operações autenticadas que exigem auditoria rejeitam ator técnico ausente. Operações públicas anônimas omitem o parâmetro e usam contexto anônimo. Processos de sistema utilizam contexto `SYSTEM`; o identificador numérico de auditoria somente será usado quando existir identidade técnica aprovada para o processo. `0`, valores negativos ou números fixos não representam automaticamente SYSTEM.

Um resolver transversal poderá substituir a resolução externa futuramente, mas não é criado nem presumido por este contrato.

---

## 11. Lifecycle do Contexto

O ORDS handler é o proprietário oficial do lifecycle para requisições externas. Essa decisão evita duplicação em cada endpoint e garante isolamento mesmo quando a sessão Oracle for reutilizada.

### 11.1 Inicialização

Antes de chamar a API, o handler deve:

1. limpar defensivamente Security Context, Execution Context e Trace, nessa ordem;
2. inicializar `CORE_TRACE_PKG` sem valor externo nesta versão;
3. inicializar `CORE_CONTEXT_PKG` com origem `EXTERNAL`, modo `SYNCHRONOUS`, ator público e estado de autenticação coerentes;
4. inicializar `CORE_SECURITY_CONTEXT_PKG` com tipo de ator e método de autenticação coerentes;
5. resolver e entregar separadamente `p_actor_id`, quando exigido.

Até existir política de confiança para trace recebido, o handler sempre gera o `traceId` no servidor. `correlationId` distinto ainda não integra o runtime.

### 11.2 Limpeza

Em bloco de finalização garantida, depois que status e body forem obtidos, o handler limpa:

```text
CORE_SECURITY_CONTEXT_PKG
  ↓
CORE_CONTEXT_PKG
  ↓
CORE_TRACE_PKG
```

A limpeza ocorre em sucesso, erro e inicialização parcial. Falha de limpeza não pode substituir silenciosamente a falha original. O `*_API_PKG` pressupõe contexto ativo e não o reinicializa nem o limpa.

---

## 12. Transações

### 12.1 Fronteira

Para uma chamada externa unitária via ORDS:

- `*_API_PKG` controla a transação das escritas;
- Service, Rule, Repository e Core não executam `COMMIT` ou `ROLLBACK`;
- leitura não executa `COMMIT` nem `ROLLBACK`;
- sucesso de escrita executa um único `COMMIT`;
- qualquer erro antes do commit executa `ROLLBACK`.

Esta é uma exceção explicitamente delimitada à proibição genérica de transação em API registrada em `30_DEVELOPMENT_STANDARD.md`. Um `*_API_PKG` chamado como parte de uma unidade interna maior não deve ser reutilizado para escrita; o consumidor interno deve chamar a Service e controlar sua própria transação.

### 12.2 Ordem oficial da escrita

```text
validacao estrutural
  ↓
Service
  ↓
construcao do payload
  ↓
construcao completa do envelope de sucesso
  ↓
COMMIT
  ↓
atribuicao final de status e body
```

O envelope é construído antes do commit. Assim, erro de payload, JSON ou serialização ainda permite rollback. Status e body de sucesso somente são publicados nas saídas depois do commit.

Se o `COMMIT` falhar, a API tenta `ROLLBACK`, descarta o sucesso preparado e segue o fluxo de erro técnico. Se uma falha ocorrer depois de commit bem-sucedido durante a simples atribuição das saídas, o rollback já não é possível; por isso toda operação falível de construção deve ocorrer antes do commit e a atribuição final deve permanecer trivial.

### 12.3 Fluxo de erro

Em erro conhecido ou inesperado de escrita:

1. executar `ROLLBACK`;
2. construir o erro público sanitizado;
3. construir o envelope de erro;
4. atribuir status e body.

Falha ao construir o envelope de erro mantém status 500 e body nulo para o fallback seguro do handler.

---

## 13. Parsing e Validação Estrutural

`CORE_JSON_PKG` é obrigatório para construção, tipagem, formatação temporal e serialização JSON. A versão atual não possui operação pública de parsing. Até sua evolução, a API usa diretamente os tipos JSON nativos do Oracle, especialmente `JSON_ELEMENT_T`, `JSON_OBJECT_T` e `JSON_ARRAY_T`, somente para parsing e inspeção estrutural.

Política oficial:

| Condição | Comportamento |
|---|---|
| Body PL/SQL `NULL` | 400, request ausente |
| Body vazio ou somente espaços | 400, request ausente |
| JSON malformado | 400, JSON inválido |
| Raiz diferente de objeto quando objeto é exigido | 400, tipo raiz inválido |
| Campo obrigatório ausente | 400, campo obrigatório |
| Campo obrigatório com JSON `null` | 400, salvo contrato explícito contrário |
| Tipo JSON incompatível | 400, tipo de campo inválido |
| Data fora de `YYYY-MM-DD` ou data inexistente | 400, formato inválido |
| Número fora da faixa aceita pelo tipo técnico | 400, valor inválido |
| Propriedade opcional ausente | usar semântica definida pelo contrato |
| Propriedade opcional com JSON `null` | limpar ou manter nulo somente quando permitido |
| Campo desconhecido em request | rejeitar com 400 |

Campos desconhecidos em requests são rejeitados para detectar erro de contrato e impedir aceitação silenciosa de intenção não suportada. Consumidores continuam obrigados a ignorar propriedades desconhecidas nas respostas, conforme `27_API_STANDARDS.md`.

Conversões de data usam validação exata e conversão explícita, sem depender de `NLS_DATE_FORMAT`. Parsing estrutural não executa regra de domínio: tamanhos funcionais, transições, datas futuras e invariantes continuam nas camadas internas.

---

## 14. Tradução de Exceções

Cada API mantém uma tabela explícita entre exceções nominais que podem alcançar sua fronteira e entradas aprovadas do catálogo público.

Regras:

- exceção de parsing ou contrato vira erro `REQUEST` com status 400;
- exceção nominal de validação funcional vira status 422;
- recurso não encontrado vira 404;
- conflito funcional vira 409;
- autenticação ou contexto inválido vira 401, 403 ou 500 conforme origem e exposição segura;
- exceção inesperada vira erro técnico 500;
- `DUP_VAL_ON_INDEX` não é traduzido por inspeção de `SQLERRM`; sem tradução nominal confiável, segue como erro técnico;
- `SQLERRM`, stack, backtrace e nomes internos nunca entram na resposta.

`CORE_ERROR_PKG.build_known_error` constrói erros conhecidos. `build_technical_error` constrói a representação externa segura de falhas inesperadas. `CORE_RESPONSE_PKG.build_error` produz o envelope. A política `should_log` é respeitada conceitualmente, mas não executa logging por si mesma.

---

## 15. Catálogo de Códigos

O formato obrigatório, imposto pelo Core real, é:

```text
BEX-{CONTEXTO}-{NNN}
```

`CONTEXTO` possui de 3 a 20 caracteres alfanuméricos maiúsculos. O sufixo possui exatamente três dígitos. Códigos são imutáveis depois de publicados e não podem ser reutilizados com outro significado.

Mensagens externas são inicialmente estáveis em português do Brasil. Consumidores devem tomar decisões pelo código, nunca pelo texto. Internacionalização futura não altera o significado do código.

### 15.1 Categorias mínimas

| Situação | Categoria Core | Status | Padrão de código | Mensagem externa |
|---|---|---:|---|---|
| Request inválido | `VALIDATION_ERROR` | 400 | `BEX-REQ-NNN` | específica, segura e sem detalhe Oracle |
| Autenticação ausente ou inválida | `AUTHENTICATION_ERROR` | 401 | `BEX-AUTH-NNN` | genérica quando necessário |
| Contexto autorizado insuficiente | `AUTHORIZATION_ERROR` ou `SECURITY_ERROR` | 403 | `BEX-AUTH-NNN` | não revela política interna |
| Recurso não encontrado | `NOT_FOUND` | 404 | `BEX-{MODULO}-NNN` | identifica o tipo público, não o ID interno |
| Conflito funcional | `CONFLICT_ERROR` | 409 | `BEX-{MODULO}-NNN` | descreve conflito seguro |
| Validação de negócio | `VALIDATION_ERROR` ou `BUSINESS_ERROR` | 422 | `BEX-{MODULO}-NNN` | explica condição corrigível |
| Erro interno | `TECHNICAL_ERROR` | 500 | `BEX-SYS-NNN` | genérica e não retryable por padrão |

A escolha entre `VALIDATION_ERROR` e `BUSINESS_ERROR` em 422 pertence ao catálogo do módulo. Retry, severidade e `shouldLog` também são definidos por entrada catalogada, não inferidos apenas do status.

O catálogo completo, sua reserva numérica e sua materialização central permanecem evolução futura. Antes de implementar um endpoint, os códigos concretos usados por ele devem ser aprovados e documentados.

---

## 16. Logging e Observabilidade

### 16.1 Limitação atual

`CORE_TRACE_PKG` mantém apenas o `traceId`; ele não persiste nem emite logs. `CORE_ERROR_PKG` produz `t_error_policy.should_log`, mas também não registra diagnóstico. Portanto, o Core atual não oferece logging técnico persistente.

### 16.2 Decisão provisória

- a API constrói a resposta segura e preserva o `traceId`;
- `should_log` sinaliza intenção, não execução;
- o handler ORDS ou a infraestrutura operacional pode registrar metadados de transporte e o `traceId`, sem body sensível e sem depender de detalhes retornados ao cliente;
- packages de negócio não simulam logging com `DBMS_OUTPUT`, tabelas ou transação autônoma;
- ausência do logger não autoriza exposição de `SQLERRM`.

### 16.3 Evolução necessária

Será necessário aprovar um componente transversal específico para logging técnico persistente, incluindo sanitização, retenção, acesso, atomicidade e comportamento quando o próprio log falhar. `CORE_TRACE_PKG` não deve absorver essa responsabilidade.

---

## 17. Responsabilidade do ORDS

O contrato conceitual do handler é:

1. receber método, rota, body, query e headers aprovados;
2. autenticar ou receber identidade autenticada;
3. resolver o ator técnico quando exigido;
4. limpar estado residual e inicializar Trace, Execution Context e Security Context;
5. chamar uma única operação pública de `*_API_PKG`;
6. aplicar `o_status_code` ao response HTTP;
7. aplicar `application/json; charset=UTF-8` quando houver body;
8. escrever `o_response_body` sem reconstruí-lo;
9. liberar LOBs temporários que pertençam ao adapter;
10. limpar todo contexto em finalização garantida.

O handler não interpreta regras, não remapeia códigos funcionais, não monta envelope alternativo e não controla a transação de domínio executada pela API.

---

## 18. Segurança

- Nunca aceitar ator técnico ou público livremente do body.
- Nunca expor ID interno Oracle em entrada ou saída externa.
- Nunca registrar senha, token, credencial, hash ou body sensível.
- Nunca retornar SQL, `SQLERRM`, stack, backtrace, schema, package, tabela ou coluna.
- Validar positivamente propriedades, tipos, formatos e faixas.
- Rejeitar campos desconhecidos em requests.
- Não usar concatenação manual para JSON.
- Não usar SQL dinâmico na API.
- Não considerar contexto autenticado como autorização automática.
- Liberar CLOBs temporários sob responsabilidade de quem os criou ou recebeu para descarte.
- Não reutilizar estado de contexto entre requisições.

---

## 19. Exemplos de Fluxo

### 19.1 Escrita com sucesso

```text
ORDS recebe a requisicao
→ autentica e resolve o ator
→ inicializa o contexto
→ API valida e faz parse
→ API chama Service
→ API constroi payload e envelope
→ API executa COMMIT
→ API devolve status + body
→ ORDS aplica HTTP
→ ORDS limpa o contexto
```

### 19.2 Regra de negócio inválida

```text
ORDS inicializa o contexto
→ API chama Service/Rule
→ excecao nominal
→ API executa ROLLBACK
→ API constroi erro funcional
→ ORDS devolve status + body
→ ORDS limpa o contexto
```

### 19.3 Erro técnico inesperado

```text
ORDS inicializa o contexto
→ API encontra excecao tecnica
→ API executa ROLLBACK
→ API constroi erro interno sanitizado
→ infraestrutura registra o trace quando disponivel
→ ORDS devolve resposta segura
→ ORDS limpa o contexto
```

### 19.4 Consulta

```text
ORDS inicializa o contexto
→ API valida identificador
→ API chama Service
→ API constroi status + body
→ ORDS devolve a resposta
→ ORDS limpa o contexto
```

Consulta não executa `COMMIT` nem `ROLLBACK`.

---

## 20. Decisões Adiadas

Permanecem explicitamente adiados:

- implementação do resolver entre identificador público e técnico;
- logging técnico persistente e eventual transação autônoma;
- extensão de `CORE_RESPONSE_PKG` para metadados ou resultado HTTP composto;
- headers customizados, incluindo eventual exposição do `traceId`;
- política para aceitar trace ou correlation ID externo;
- `correlationId` distinto do `traceId`;
- catálogo central materializado em package ou tabela;
- reserva e governança das faixas numéricas do catálogo;
- detalhes estruturados de validação por campo;
- internacionalização de mensagens;
- geração automática de handlers ORDS;
- limite, streaming e política para payloads grandes;
- paginação oficial;
- política de idempotency key.

Essas pendências não impedem APIs síncronas simples, desde que seus contratos específicos não dependam delas.

---

## 21. Critérios de Conformidade

Um `*_API_PKG` destinado ao ORDS somente está conforme quando:

- usa a assinatura padrão ou possui exceção documentada;
- expõe apenas `PUBLIC_ID` nas fronteiras externas;
- recebe ator técnico somente por canal confiável separado;
- pressupõe contexto inicializado pelo handler;
- chama Service e não acessa Repository ou tabela;
- faz somente validação estrutural e conversão técnica;
- usa tipos JSON nativos para parsing e Core para construção e envelope;
- retorna status e body separadamente;
- constrói completamente o sucesso antes do commit;
- executa transação apenas em escrita externa unitária;
- traduz apenas exceções conhecidas catalogadas;
- sanitiza falhas inesperadas;
- não depende de `SQLERRM` para contrato externo;
- não afirma que logging ocorreu sem mecanismo real;
- possui testes de lifecycle, parsing, resposta, atomicidade e segurança.

---

## 22. Checklist para Novos `*_API_PKG`

- [ ] Endpoint e payload aprovados antes do package.
- [ ] Método, rota, autenticação e autorização definidos.
- [ ] Assinatura segue entrada, ator, status e body.
- [ ] Nenhum ID interno aparece no contrato externo.
- [ ] Ator técnico é resolvido fora do body.
- [ ] Contexto é inicializado e limpo pelo handler.
- [ ] Body nulo, vazio, inválido e de raiz incorreta são testados.
- [ ] Campos obrigatórios, tipos, datas e faixas são testados.
- [ ] Campos desconhecidos são rejeitados.
- [ ] API chama exclusivamente a Service aplicável.
- [ ] Payload usa `camelCase` e tipos JSON nativos.
- [ ] Datas e timestamps são independentes de NLS.
- [ ] Envelope usa o contrato real de `CORE_RESPONSE_PKG`.
- [ ] Status HTTP é devolvido separadamente.
- [ ] Sucesso é serializado antes do commit.
- [ ] Escrita executa um único commit ou rollback integral.
- [ ] Leitura não executa commit ou rollback.
- [ ] Exceções nominais possuem código aprovado.
- [ ] Erro inesperado retorna mensagem sanitizada.
- [ ] Nenhum detalhe Oracle é exposto.
- [ ] Política de logging não presume componente inexistente.
- [ ] CLOBs temporários são liberados pelo proprietário correto.
- [ ] Testes validam status, envelope, persistência e atomicidade.

---

## 23. Consequência Arquitetural

Este documento passa a ser a referência técnica especializada para o runtime de APIs chamadas pelo ORDS. Onde exemplos conceituais anteriores divergirem do Core efetivamente instalado, prevalece o contrato real registrado aqui. Mudanças futuras no envelope, lifecycle, transação, ator ou assinatura exigem revisão arquitetural e atualização coordenada deste documento antes da implementação.
