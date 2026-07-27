# ADR-006 — Preservação histórica de entidades de negócio

## Status

Aceito

## Data

2026-06-30

## Contexto

Remoção física indiscriminada compromete histórico, auditoria, conciliação e
integridade referencial.

## Decisão

Entidades de negócio preservam histórico por estado ou evento terminal. DELETE
físico não faz parte de casos de uso normais.

Exceções somente são admitidas quando o contrato da entidade demonstrar que não
existe valor histórico ou dependência, ou em limpeza controlada de dados
criados por testes. Exceção material exige documentação.

## Consequências

- ciclo de vida precisa de estados e transições explícitos;
- arquivamento não é sinônimo de remoção;
- dados transacionais e financeiros permanecem rastreáveis;
- testes podem excluir seus próprios dados de forma controlada.
