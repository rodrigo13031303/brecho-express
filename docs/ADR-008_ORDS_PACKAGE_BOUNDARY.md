# ADR-008 — ORDS chama API packages, nunca SQL solto

## Status

Aceito

## Data

2026-06-30

## Contexto

SQL ou regra dispersa em handlers ORDS dificulta segurança, teste, transação e
governança.

## Decisão

Todo handler ORDS chama uma operação de `*_API_PKG`. Handler não executa SQL
funcional, não acessa tabela, não implementa regra e não chama diretamente
Service, Rule ou Repository.

## Consequências

- API package é a fronteira PL/SQL externa;
- ORDS controla somente aspectos de transporte e lifecycle atribuídos pelo
  Runtime Contract;
- regras e persistência permanecem testáveis fora do HTTP;
- exceções exigem ADR específica.
