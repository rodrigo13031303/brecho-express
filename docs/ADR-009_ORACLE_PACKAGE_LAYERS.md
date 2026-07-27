# ADR-009 — Camadas dos packages Oracle

## Status

Aceito

## Data

2026-06-30

## Contexto

A separação original entre API e Rule não cobria orquestração, persistência,
consultas, eventos e execução assíncrona. A arquitetura física evoluiu para
responsabilidades explícitas.

## Decisão

O fluxo externo padrão é:

```text
ORDS
  ↓
*_API_PKG
  ↓
*_SERVICE_PKG
  ├── *_RULE_PKG
  └── *_REPOSITORY_PKG
          ↓
        TABLE
```

- API: transporte, envelope, tradução pública e transação;
- Service: caso de uso, autorização e coordenação;
- Rule: regra pura, sem SQL, JSON ou Core;
- Repository: persistência e locking, sem regra ou término de transação.

QUERY, EVENT, JOB, IMPORT e EXPORT são criados somente quando houver
responsabilidade concreta conforme `30_DEVELOPMENT_STANDARD.md`.

## Consequências

- API e Rule não são mais as únicas camadas reconhecidas;
- dependências são unidirecionais e acíclicas;
- nenhuma entidade recebe automaticamente todos os tipos de package;
- documentos e prompts antigos com fluxo API → RULE estão substituídos.
