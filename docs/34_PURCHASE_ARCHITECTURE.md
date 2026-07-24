# 34 — Arquitetura de Compra Inicial

## Escopo

A primeira remessa de Compra implementa dois agregados:

- CART, com CART_ITEM sob responsabilidade de `CRT_*`;
- PURCHASE_REQUEST, com PURCHASE_REQUEST_ITEM sob responsabilidade de `PUR_*`.

O carrinho e a solicitação podem conter Achados de várias STORE. Nenhuma das
duas etapas reserva estoque. O preço é copiado do PRODUCT quando o item entra
no carrinho e novamente quando o checkout cria a solicitação.

## Carrinho

Um PROFILE possui no máximo um CART ACTIVE. Estados:

- ACTIVE: aceita inclusão, alteração e remoção lógica de itens;
- CHECKED_OUT: convertido em PURCHASE_REQUEST e imutável;
- EXPIRED: expirado sem reserva;
- ABANDONED: encerrado pelo cliente.

CART_ITEM usa ACTIVE ou REMOVED. Um PRODUCT aparece no máximo uma vez como item
ACTIVE do mesmo carrinho. Quantidade é inteira e positiva. A inclusão exige
PRODUCT ACTIVE e quantidade anunciada suficiente naquele instante, sem criar
reserva ou garantia futura.

## Solicitação de compra

Checkout bloqueia o CART, revalida seus itens e cria uma PURCHASE_REQUEST com
snapshot independente. Estados:

- PENDING;
- PARTIALLY_APPROVED;
- APPROVED;
- REJECTED;
- EXPIRED;
- CANCELLED.

Itens usam PENDING, PARTIALLY_APPROVED, APPROVED ou REJECTED. Quantidade
confirmada nunca excede a solicitada. APPROVED confirma tudo;
PARTIALLY_APPROVED confirma valor positivo menor; REJECTED exige motivo.

PUR_RESPONSE_AT registra qualquer resposta comercial. PUR_CONFIRMED_AT existe
somente em APPROVED. Cada STORE responde apenas seus próprios itens. O status
agregado é recalculado a partir dos itens; pagamento e ORDER permanecem fora
desta remessa.

## Fronteiras e camadas

- PROFILE resolve o comprador pela ACCOUNT autenticada;
- PRODUCT fornece identidade, STORE, status, preço e quantidade;
- STORE autoriza a resposta comercial;
- Rule não executa SQL;
- Repository executa SQL e locking sem COMMIT ou ROLLBACK;
- Service coordena os agregados;
- API controla JSON, envelope e transação.

Auditoria usa ator técnico numérico sem foreign key. Participantes de domínio
mantêm foreign keys para PROFILE, PRODUCT e STORE.
