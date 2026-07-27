# ADR-001 — Flutter como frontend oficial

## Status

Aceito

## Data

2026-06-30

## Contexto

O produto necessita de uma experiência consistente para clientes e Brechós em
múltiplas plataformas, com uma única base principal de interface.

## Decisão

Flutter é o frontend oficial do aplicativo Brechó Express. O código segue
organização feature-first, consome exclusivamente contratos públicos e traduz a
linguagem técnica para a Linguagem Ubíqua da interface.

## Consequências

- uma base tecnológica concentra a experiência principal;
- Design System, navegação, estado e acessibilidade precisam de contratos
  compartilhados;
- Flutter não recebe responsabilidade de domínio ou persistência Oracle;
- integrações externas permanecem atrás de repositories e serviços de dados.

## Referências

- `04_ARCHITECTURE.md`;
- `05_DESIGN_SYSTEM.md`;
- `13_UBIQUITOUS_LANGUAGE.md`;
- `ADR-010_FLUTTER_DATABASE_ISOLATION.md`.
