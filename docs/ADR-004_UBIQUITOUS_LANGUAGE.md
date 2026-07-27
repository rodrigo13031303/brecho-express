# ADR-004 — Linguagem Ubíqua como fonte de nomenclatura

## Status

Aceito

## Data

2026-06-30

## Contexto

Negócio, documentação, banco, APIs e interface necessitam de vocabulário comum
sem expor termos físicos ao cliente.

## Decisão

`13_UBIQUITOUS_LANGUAGE.md` é a fonte oficial de terminologia. Oracle e
contratos internos usam termos técnicos aprovados; a interface usa termos
comerciais. A tradução pertence à apresentação.

## Consequências

- Achado representa PRODUCT e Brechó representa STORE;
- novos conceitos são registrados antes da implementação;
- nomes físicos ou estrangeiros não aparecem na interface sem decisão;
- conflitos terminológicos interrompem a implementação.
