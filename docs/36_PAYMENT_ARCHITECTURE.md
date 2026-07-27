# 36 — Arquitetura de Pagamento Inicial

A remessa financeira inicial contém PAYMENT_PROVIDER (`PPR_*`) e o agregado
PAYMENT com PAYMENT_EVENT (`PAY_*` e `PEV_*`).

PAYMENT nasce para uma PURCHASE_REQUEST APPROVED ou para uma
PARTIALLY_APPROVED explicitamente aceita pelo cliente, usa o snapshot aceito e
exige reservas ativas correspondentes. O prazo é derivado de
`PURCHASE_PAYMENT_TIMEOUT`, nunca de constante oculta no código.

PAYMENT_EVENT preserva o payload bruto e possui identidade externa única por
pagamento. Eventos repetidos retornam o resultado já processado.

Somente PAYMENT_EVENT altera PAY_STATUS. PAYMENT_APPROVED cria ORDER na mesma
transação e vincula ORD_ID ao pagamento. Falha em qualquer etapa desfaz evento,
mudança de estado e pedido. A API de webhook controla COMMIT ou ROLLBACK.

Ao aprovar, o mesmo fluxo consome idempotentemente as reservas. Ao expirar,
cancelar ou rejeitar definitivamente, libera as reservas aplicáveis.

Credenciais e segredos de gateways não pertencem a PAYMENT_PROVIDER nem ao
banco funcional desta remessa.

## Estado de implementação

PAYMENT PENDING, evento idempotente e criação de ORDER após aprovação estão
implementados. Aceite parcial explícito, reserva e integração com prazo
parametrizado ainda não estão implementados.
