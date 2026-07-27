# ADR-024 — Pagamento precede a criação do Pedido

## Status

Aceito e implementado

## Data

2026-07-26

## Contexto

O domínio determina que ORDER representa compra confirmada, não intenção de
compra nem tentativa de pagamento. A criação antecipada do pedido produziria
pedidos sem pagamento e duas fontes de verdade para o estado financeiro.

## Decisão

- PAYMENT nasce para uma PURCHASE_REQUEST elegível sem ORD_ID.
- Nenhum ORDER existe antes da aprovação financeira.
- Somente evento idempotente `PAYMENT_APPROVED` autoriza a criação do ORDER.
- O fluxo financeiro chama `ORD_SERVICE_PKG.create_paid_order`.
- Criação do ORDER, vínculo em PAYMENT e processamento do evento participam da
  mesma transação.
- Falha em qualquer etapa desfaz toda a unidade de trabalho.
- Reprocessamento do mesmo evento retorna o resultado existente e não duplica
  PAYMENT_EVENT nem ORDER.
- ORDER nasce com estado financeiro coerente e instante de pagamento.

## Estado de implementação

Implementado em 2026-07-26:

- BEX_PAYMENT permite ORD_ID nulo enquanto PENDING;
- BEX_ORDER exige origem em PURCHASE_REQUEST e estado inicial PAID;
- PAY_SERVICE_PKG cria ORDER somente ao aplicar PAYMENT_APPROVED;
- a suíte do módulo valida ausência de ORDER antes da aprovação e idempotência
  do webhook.

Reserva, aceite parcial e prazo parametrizado complementam este fluxo pelas
ADRs 019 e 020 e ainda possuem partes não implementadas.

## Consequências

- ORDER permanece registro de compra paga;
- tentativas financeiras não poluem o agregado de Pedido;
- idempotência protege contra webhooks repetidos;
- PAYMENT é a fonte da transição financeira que origina ORDER;
- documentos que exibam ORDER antes de pagamento estão substituídos por esta
  decisão.
