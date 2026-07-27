# ADR-005 — Identificador público em CHAR(32)

## Status

Aceito

## Data

2026-06-30

## Contexto

Fronteiras externas precisam de identidade estável sem expor chaves numéricas
internas e enumeráveis.

## Decisão

Entidades que necessitem de identidade pública aprovada usam
`<SIGLA>_PUBLIC_ID CHAR(32)` com unicidade física. O valor representa 16 bytes
em hexadecimal, é opaco e não possui significado de negócio.

Nem toda tabela é obrigada a possuir Public ID: a necessidade depende da
fronteira funcional. IDs internos continuam numéricos e exclusivos das camadas
Oracle autorizadas.

## Consequências

- APIs nunca expõem PK interna;
- Public ID e ID técnico não são intercambiáveis;
- geração, normalização e tentativa segura em colisão pertencem ao contrato do
  módulo;
- slug, código funcional e chave de integração não substituem Public ID.
