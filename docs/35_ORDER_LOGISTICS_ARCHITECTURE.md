# 35 — Arquitetura de Pedido e Logística Inicial

## Escopo

A remessa implementa quatro agregados:

- ADDRESS, sob responsabilidade de `ADR_*`;
- DELIVERY_PROFILE, sob responsabilidade de `DLP_*`;
- ORDER com ORDER_ITEM, sob responsabilidade de `ORD_*`;
- SHIPMENT com SHIPMENT_ITEM, sob responsabilidade de `SHP_*`.

## Decisões

ADDRESS pertence a PROFILE. Há no máximo um endereço ACTIVE padrão por perfil.
Remoção é lógica. A troca de endereço padrão é atômica.

DELIVERY_PROFILE é configuração global. A API inicial é somente de consulta;
criação e manutenção são operações internas. Os códigos oficiais iniciais são
PICKUP, LOCAL, EXPRESS e NATIONAL.

ORDER nasce de PURCHASE_REQUEST finalizada e possui snapshot financeiro e de
itens. Sua criação não é exposta pela API: o contrato interno
`create_paid_order` será chamado pelo futuro módulo PAYMENT após aprovação.
Esta remessa não simula nem antecipa pagamento.

SHIPMENT agrupa itens de uma única STORE do ORDER, usa ADDRESS e
DELIVERY_PROFILE e controla o ciclo CREATED, READY, IN_TRANSIT, DELIVERED ou
CANCELLED. Um ORDER_ITEM pertence a no máximo uma remessa não cancelada.

Auditoria usa ator técnico numérico sem foreign key. Participantes estruturais
mantêm foreign keys. Rules não executam SQL; Repositories não controlam
transação; Services não conhecem JSON; APIs controlam envelope e transação.
