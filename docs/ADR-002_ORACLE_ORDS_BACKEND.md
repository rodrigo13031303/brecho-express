# ADR-002 — Oracle e ORDS como backend oficial

## Status

Aceito

## Data

2026-06-30

## Contexto

O projeto requer persistência transacional, regras centralizadas, integração
REST e forte consistência nos fluxos comerciais e financeiros.

## Decisão

Oracle é o banco e runtime transacional principal. ORDS é a porta HTTP oficial
para consumidores externos e chama packages Oracle conforme os contratos
aprovados.

## Consequências

- DDL, packages, constraints e testes seguem padrões Oracle;
- contratos REST permanecem independentes da estrutura física;
- ORDS não executa regra de negócio nem SQL ad hoc;
- adoção de outra tecnologia estrutural exige nova ADR.

## Estado de implementação

Oracle, tabelas, packages e testes estão amplamente implementados. Os módulos,
templates e handlers ORDS ainda não estão versionados no repositório.
