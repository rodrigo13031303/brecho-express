# ADR-007 — APIs externas não expõem IDs internos

## Status

Aceito

## Data

2026-06-30

## Contexto

Expor chaves Oracle acopla consumidores ao modelo físico, facilita enumeração e
reduz a liberdade de evolução.

## Decisão

URLs, requests, responses, headers e erros externos usam apenas identificadores
públicos ou chaves funcionais aprovadas. IDs numéricos internos não atravessam
a fronteira pública.

## Consequências

- Services resolvem Public ID para identidade interna;
- Flutter e integrações não conhecem PKs Oracle;
- logs públicos não vazam IDs internos;
- contratos e testes devem verificar ausência de campos internos.
