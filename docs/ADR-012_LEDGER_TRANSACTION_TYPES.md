# ADR-012 — Tipos de movimentação financeira textuais no MVP

## Status

Aceito e implementado

## Data

2026-07-01

## Contexto

Um catálogo configurável de tipos adicionaria complexidade antes de existir
necessidade operacional comprovada.

## Decisão

`SBT_TYPE` permanece textual e validado pelo contrato financeiro. Uma entidade
como BALANCE_TRANSACTION_TYPE somente será criada por nova ADR e migração
quando houver necessidade real de parametrização.

## Consequências

- o MVP mantém estrutura simples;
- códigos continuam centralizados e testados;
- tipos não podem surgir livremente em código;
- evolução futura não pode criar segunda fonte de verdade.
