# 36 — Arquitetura de Pagamento Inicial

A remessa financeira inicial contém PAYMENT_PROVIDER (`PPR_*`) e o agregado
PAYMENT com PAYMENT_EVENT (`PAY_*` e `PEV_*`).

PAYMENT nasce para uma PURCHASE_REQUEST APPROVED ou PARTIALLY_APPROVED e usa o
valor confirmado. PAYMENT_EVENT preserva o payload bruto e possui identidade
externa única por pagamento. Eventos repetidos retornam o resultado já
processado.

Somente PAYMENT_EVENT altera PAY_STATUS. PAYMENT_APPROVED cria ORDER na mesma
transação e vincula ORD_ID ao pagamento. Falha em qualquer etapa desfaz evento,
mudança de estado e pedido. A API de webhook controla COMMIT ou ROLLBACK.

Credenciais e segredos de gateways não pertencem a PAYMENT_PROVIDER nem ao
banco funcional desta remessa.
