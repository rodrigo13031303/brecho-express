# ADR-003 — DDD e organização feature-first

## Status

Aceito

## Data

2026-06-30

## Contexto

O Brechó Express possui múltiplos contextos de negócio e precisa evoluir sem
organização centrada apenas em tecnologia.

## Decisão

A solução aplica Domain-Driven Design e organiza aplicação e documentação por
features e módulos de negócio. Linguagem, limites, invariantes e dependências
do domínio precedem detalhes de framework.

## Consequências

- módulos refletem capacidades do negócio;
- dependências entre contextos precisam de fronteiras públicas;
- documentação, Oracle, API e Flutter devem representar os mesmos conceitos;
- compartilhamento técnico não pode criar domínio genérico sem proprietário.
