# 37 — Arquitetura de autorização global

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
