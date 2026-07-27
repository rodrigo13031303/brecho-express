# 38 — Arquitetura de autorização global

## Status

Implementado no escopo inicial de ROLE, PROFILE_ROLE e
IAM_AUTHORIZATION_PKG. A identidade operacional de auditoria é ACCOUNT,
conforme `ADR-021_AUDIT_ACTOR_IDENTITY.md`; papéis globais de PROFILE não
substituem autoria técnica.

## Escopo

`ROLE` define papéis globais da plataforma. `PROFILE_ROLE` registra a concessão
de um papel a um Profile. Esses conceitos não substituem `STORE_USER`, que
continua responsável pelas funções operacionais dentro de uma STORE específica.

## Papéis iniciais

- `SYSTEM`
- `ADMIN`
- `CUSTOMER`
- `STORE_OWNER`
- `STORE_ATTENDANT`

## Decisões

- A combinação `(PROFILE, ROLE)` possui uma única identidade persistente.
- Revogação altera o status para `INACTIVE`; uma nova concessão reativa a mesma associação.
- Uma concessão expirada não autoriza, mesmo que seu status ainda seja `ACTIVE`.
- `IAM_AUTHORIZATION_PKG` é a fronteira de consulta para `has_role` e `require_role`.
- Concessão e revogação são operações internas de provisionamento e não possuem API pública no MVP.
- Autenticação permanece responsabilidade de ACCOUNT e SESSION.
- Identidades Google, Apple e Facebook pertencem a `BEX_ACCOUNT_IDENTITY` e
  seguem `ADR-025_SOCIAL_AUTHENTICATION.md`; elas autenticam a ACCOUNT, não
  concedem ROLE diretamente.
