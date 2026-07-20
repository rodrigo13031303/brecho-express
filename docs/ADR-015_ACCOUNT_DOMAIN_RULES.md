# ADR-015 — Regras de Domínio e Tratamento de Erros de ACCOUNT

## Status

Aceito

## Contexto

A implementação do body de `ACC_RULE_PKG` foi interrompida porque a política de senha, a semântica de transições idempotentes, o tratamento de parâmetros `BOOLEAN NULL`, o catálogo inicial de erros e a fronteira entre exceções de domínio e erros públicos ainda não estavam definidos.

Também foi identificado que `PENDING_EMAIL_VERIFICATION`, com 26 caracteres, não cabe no tamanho anteriormente documentado para `ACC_STATUS`.

---

## Decisão

### 1. Fronteira entre domínio e erro público

`ACC_RULE_PKG` preserva as invariantes do Aggregate ACCOUNT e lança exceções nominais para condições conhecidas do domínio. Ela não constrói `CORE_ERROR_PKG.t_public_error` e não depende diretamente do Core Framework apenas para sinalizar essas condições.

`ACC_API_PKG` será responsável por capturar as exceções conhecidas, associá-las ao catálogo `BEX-ACC-*`, construir o erro público com `CORE_ERROR_PKG` e produzir a resposta externa segura.

As exceções públicas de domínio são:

- `e_account_not_found`;
- `e_email_already_used`;
- `e_invalid_email`;
- `e_invalid_password`;
- `e_invalid_public_id`;
- `e_invalid_status`;
- `e_invalid_status_transition`.

Essas exceções não utilizam `PRAGMA EXCEPTION_INIT`, códigos Oracle ou `RAISE_APPLICATION_ERROR` como contrato de domínio.

### 2. Política inicial de senha

A senha de ACCOUNT:

- é obrigatória;
- deve possuir entre 8 e 128 caracteres;
- não exige inicialmente maiúsculas, minúsculas, números ou símbolos;
- aceita espaços como caracteres significativos;
- não deve sofrer `TRIM`;
- nunca deve ser incluída em trace, log, contexto ou mensagem de erro.

Geração, comparação e armazenamento de hash não pertencem a `ACC_RULE_PKG`.

### 3. Estados oficiais

Os estados oficiais de ACCOUNT são exclusivamente:

- `PENDING_EMAIL_VERIFICATION`;
- `ACTIVE`;
- `BLOCKED`;
- `DISABLED`.

`ACC_STATUS` deve ser documentado como `VARCHAR2(30)`.

### 4. Transições oficiais

São permitidas as transições:

```text
PENDING_EMAIL_VERIFICATION → ACTIVE
ACTIVE                     → BLOCKED
BLOCKED                    → ACTIVE
ACTIVE                     → DISABLED
BLOCKED                    → DISABLED
DISABLED                   → ACTIVE
```

Uma transição de qualquer status válido para ele mesmo também é válida e representa uma operação idempotente. O caso de uso pode evitar DML quando não houver mudança efetiva.

### 5. Parâmetros BOOLEAN NULL nas asserções

`NULL` em `assert_email_available` ou `assert_account_exists` representa violação técnica do contrato interno. O valor não deve ser interpretado como `TRUE` nem como `FALSE`.

Essa condição não recebe código público `BEX-ACC-*` nem nova exceção pública de negócio. A falha técnica deve propagar para tratamento seguro posterior pela borda.

### 6. Catálogo inicial ACCOUNT

| Código | Mensagem externa | Categoria | Severidade | Retentável |
|---|---|---|---|---|
| `BEX-ACC-001` | Conta não encontrada | `NOT_FOUND` | `WARN` | Não |
| `BEX-ACC-002` | E-mail já utilizado | `CONFLICT_ERROR` | `WARN` | Não |
| `BEX-ACC-003` | E-mail inválido | `VALIDATION_ERROR` | `WARN` | Não |
| `BEX-ACC-004` | Senha inválida | `VALIDATION_ERROR` | `WARN` | Não |
| `BEX-ACC-005` | Public ID inválido | `VALIDATION_ERROR` | `WARN` | Não |
| `BEX-ACC-006` | Status inválido | `VALIDATION_ERROR` | `WARN` | Não |
| `BEX-ACC-007` | Transição de status inválida | `BUSINESS_ERROR` | `WARN` | Não |

As categorias e a severidade utilizam somente valores suportados por `CORE_ERROR_PKG`. O mapeamento executável pertence futuramente a `ACC_API_PKG`, não a `ACC_RULE_PKG`.

---

## Consequências

- `ACC_RULE_PKG` permanece uma package de domínio pura, sem persistência e sem dependência de apresentação.
- `ACC_API_PKG` passa a ser a fronteira responsável pela tradução de erros conhecidos.
- o body de `ACC_RULE_PKG` pode implementar validações sem inventar códigos Oracle;
- a política de senha e a matriz de status tornam-se determinísticas e testáveis;
- chamadas internas com `BOOLEAN NULL` falham tecnicamente em vez de assumir semântica funcional;
- o tamanho documentado de `ACC_STATUS` passa a comportar todos os estados oficiais.
