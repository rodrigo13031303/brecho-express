# ADR-019 — Reserva de disponibilidade após confirmação comercial

## Status

Aceito

## Data

2026-07-26

## Contexto

O carrinho não reserva estoque. A implementação atual também cria e responde a
PURCHASE_REQUEST sem reduzir, bloquear ou reservar `PRD_QUANTITY`. Essa
estratégia permite que uma quantidade confirmada pelo Brechó seja consumida por
outro fluxo antes do pagamento, risco especialmente relevante para Achados de
peça única.

Documentos antigos divergiam entre “reservar no checkout”, “reservar durante a
análise” e “não reservar”. Era necessário definir um único instante e um único
proprietário para a reserva.

## Decisão

### 1. Instante da reserva

- CART nunca reserva quantidade.
- PURCHASE_REQUEST em análise não reserva quantidade.
- A confirmação comercial positiva de um item cria uma reserva temporária da
  quantidade confirmada.
- Aprovação parcial reserva somente a quantidade confirmada.
- Rejeição não cria reserva.

### 2. Propriedade

A reserva pertence ao módulo de Compra, não ao estado de PRODUCT. `RESERVED`
não será status de PRODUCT.

O contrato físico da reserva será definido antes da implementação. Ele deverá
preservar, no mínimo:

- item da solicitação;
- PRODUCT;
- quantidade reservada;
- início;
- expiração;
- status;
- motivo de liberação ou consumo;
- auditoria.

### 3. Concorrência

Confirmação, criação da reserva e verificação de disponibilidade efetiva
participam da mesma transação. O fluxo deve usar locking e proteção física
adequados para impedir que reservas ativas excedam a quantidade disponível.

`PRD_QUANTITY` representa a quantidade comercial total do Achado. A quantidade
disponível para nova confirmação é derivada descontando reservas ativas.

### 4. Término

A reserva termina por:

- consumo após pagamento aprovado;
- expiração do prazo de pagamento;
- cancelamento da solicitação ou do pagamento;
- rejeição técnica definitiva do pagamento;
- liberação administrativa expressamente autorizada.

O encerramento deve ser idempotente e preservar histórico.

### 5. Relação com pagamento e pedido

PAYMENT utiliza somente itens confirmados, aceitos pelo cliente quando houver
aprovação parcial, e cobertos por reserva ativa. `PAYMENT_APPROVED` consome a
reserva e cria ORDER na mesma unidade transacional do fluxo financeiro
aprovado.

## Estado de implementação

Não implementado em 2026-07-26. CART e PURCHASE_REQUEST atuais apenas validam e
confirmam quantidades. Nenhuma redução ou reserva física existe no banco.

Até a implementação desta ADR, o sistema não deve ser considerado protegido
contra venda concorrente entre confirmação e pagamento.

## Consequências

- elimina ambiguidade sobre o momento da reserva;
- protege peças únicas depois da confirmação do Brechó;
- exige evolução do Data Dictionary, arquitetura de Compra, packages e testes;
- exige job ou operação idempotente de expiração;
- exige que disponibilidade pública e disponibilidade reservável sejam
  conceitos distintos;
- impede o uso de `PRD_STATUS = 'RESERVED'` como atalho.
