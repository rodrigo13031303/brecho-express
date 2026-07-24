# 36 — Arquitetura de Store Engagement

## Escopo inicial

O bloco reúne três capacidades independentes:

- `STORE_PLAN` mantém o catálogo interno `FREE`, `PLUS` e `PREMIUM`;
- `STORE_EVENT` administra campanhas temporárias de uma STORE;
- `STORE_FOLLOWER` registra o relacionamento social entre PROFILE e STORE.

## Decisões

`STORE_PLAN` não representa assinatura. A associação de uma STORE a plano exige
vigência, histórico e integração financeira e será modelada futuramente em
agregado próprio.

`STORE_EVENT` utiliza os estados `DRAFT`, `ACTIVE`, `CLOSED` e `CANCELLED`.
Somente a conta proprietária ou um membro autorizado da STORE pode criar e
alterar eventos.

`STORE_FOLLOWER` nunca apaga o histórico. A unicidade é aplicada somente ao
vínculo `ACTIVE`, e um vínculo inativo pode ser reativado.

Os três fluxos não criam notificações automaticamente. NOTIFICATION ainda não
possui contrato detalhado aprovado no Data Dictionary.
