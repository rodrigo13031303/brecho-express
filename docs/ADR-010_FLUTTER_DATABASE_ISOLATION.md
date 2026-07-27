# ADR-010 — Flutter isolado da estrutura Oracle

## Status

Aceito

## Data

2026-06-30

## Contexto

A interface deve evoluir sem dependência direta de schema, SQL, packages ou
identificadores internos.

## Decisão

Flutter nunca acessa SQL, Oracle ou packages diretamente. Consome APIs
contratadas por repositories/providers e mantém regras de negócio no backend ou
domínio apropriado.

## Consequências

- mudanças físicas não quebram automaticamente a interface;
- models externos não reproduzem linhas de tabela;
- mensagens Oracle e IDs internos não chegam ao cliente;
- validação de experiência não substitui validação de domínio.
