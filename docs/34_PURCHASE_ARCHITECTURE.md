# 34 — Arquitetura do módulo PURCHASE

## 1. Objetivo

Definir o contrato do módulo de Compra, incluindo carrinho, solicitação,
confirmação comercial, aceite parcial, reserva temporária e preparação para
pagamento.

## 2. Status

Parcialmente implementado.

## 3. Escopo

O módulo compreende:

- CART e CART_ITEM, sob responsabilidade de `CRT_*`;
- PURCHASE_REQUEST e PURCHASE_REQUEST_ITEM, sob responsabilidade de `PUR_*`;
- aceite explícito de composição parcial;
- reserva temporária após confirmação positiva;
- expiração e liberação idempotente da reserva;
- fornecimento de snapshot elegível ao módulo PAYMENT.

Reserva, aceite parcial e integração do prazo parametrizado são contratos
aceitos ainda não implementados.

## 4. Fora de escopo

- captura ou aprovação financeira;
- criação direta de ORDER;
- logística;
- baixa financeira e ledger;
- reserva criada pelo carrinho;
- uso de `RESERVED` como status de PRODUCT.

## 5. Carrinho

Um PROFILE possui no máximo um CART ACTIVE. Estados:

- `ACTIVE`: aceita inclusão, alteração e remoção lógica de itens;
- `CHECKED_OUT`: convertido em PURCHASE_REQUEST e imutável;
- `EXPIRED`: expirado sem reserva;
- `ABANDONED`: encerrado pelo cliente.

CART_ITEM usa `ACTIVE` ou `REMOVED`. Um PRODUCT aparece no máximo uma vez como
item ACTIVE do mesmo carrinho. Quantidade é inteira e positiva.

A inclusão e a atualização validam PRODUCT ACTIVE e quantidade anunciada
suficiente naquele instante, mas não criam reserva nem garantia futura. O preço
é copiado ao item como snapshot e revalidado no checkout.

## 6. Solicitação de compra

Checkout bloqueia o CART, revalida seus itens e cria uma PURCHASE_REQUEST com
snapshot independente. A solicitação pode conter itens de várias STORE.

Estados comerciais atuais:

- `PENDING`;
- `PARTIALLY_APPROVED`;
- `APPROVED`;
- `REJECTED`;
- `EXPIRED`;
- `CANCELLED`.

Itens usam `PENDING`, `PARTIALLY_APPROVED`, `APPROVED` ou `REJECTED`.
Quantidade confirmada nunca excede a solicitada. Aprovação parcial confirma
valor positivo menor; rejeição exige motivo.

`PUR_RESPONSE_AT` registra conclusão das respostas comerciais.
`PUR_CONFIRMED_AT` registra aprovação integral. A evolução física necessária
deverá separar, quando aplicável, resposta comercial, aceite do cliente,
expiração de pagamento e encerramento.

Cada STORE responde somente seus próprios itens. O status agregado é
recalculado a partir dos itens.

## 7. Aceite parcial

Se qualquer item for parcialmente aprovado, o cliente deve aceitar
explicitamente a composição final antes da criação de PAYMENT.

O snapshot apresentado inclui:

- quantidades solicitadas e confirmadas;
- rejeições;
- preços;
- subtotal;
- descontos;
- frete;
- total;
- instante limite.

O aceite deve preservar ator, instante e snapshot ou versão aceita. Recusa ou
expiração libera as reservas e encerra a elegibilidade para pagamento.

## 8. Reserva temporária

CART e PURCHASE_REQUEST PENDING não reservam estoque.

A confirmação positiva do Brechó cria reserva apenas da quantidade confirmada.
A reserva pertence ao módulo PURCHASE e preserva histórico. Sua estrutura
física será detalhada antes da implementação.

A disponibilidade reservável corresponde à quantidade comercial do PRODUCT
menos reservas ativas. Confirmação e reserva participam da mesma transação e
devem usar locking para impedir excesso concorrente.

A reserva termina por:

- consumo em `PAYMENT_APPROVED`;
- expiração;
- cancelamento;
- recusa do cliente;
- rejeição financeira definitiva;
- liberação administrativa autorizada.

Toda finalização é idempotente.

## 9. Prazo

O prazo para pagamento é obtido de `PURCHASE_PAYMENT_TIMEOUT` em
BUSINESS_CONFIGURATION. O instante limite efetivamente aplicado deve ser
persistido para não mudar retroativamente quando a configuração for alterada.

Expiração deve possuir processamento idempotente e observável.

## 10. Integrações

- PROFILE resolve o comprador pela ACCOUNT autenticada;
- PRODUCT fornece identidade, STORE, status, preço e quantidade;
- STORE autoriza a resposta comercial;
- BUSINESS_CONFIGURATION fornece a política de prazo;
- PAYMENT recebe somente uma composição elegível, aceita quando necessário e
  coberta por reservas ativas;
- ORDER nasce exclusivamente após pagamento aprovado.

## 11. Camadas

```text
API
↓
SERVICE
├── RULE
└── REPOSITORY
    ↓
  TABLE
```

- Rule não executa SQL;
- Repository executa SQL e locking sem `COMMIT` ou `ROLLBACK`;
- Service coordena agregados e integrações;
- API controla JSON, envelope e transação.

## 12. Auditoria

O ator operacional é ACCOUNT conforme
`ADR-021_AUDIT_ACTOR_IDENTITY.md`. PROFILE continua sendo participante
funcional da compra, não identidade de auditoria.

## 13. Concorrência e transação

- checkout bloqueia o carrinho;
- resposta comercial bloqueia solicitação e item;
- confirmação e criação da reserva são atômicas;
- aceite valida a versão do snapshot;
- pagamento valida prazo e reservas;
- consumo ou liberação não pode ocorrer duas vezes;
- Repository não encerra transação.

## 14. Estado de implementação

Implementado:

- CART e CART_ITEM;
- PURCHASE_REQUEST e PURCHASE_REQUEST_ITEM;
- snapshots de preço;
- checkout com revalidação;
- resposta por STORE;
- aprovação parcial;
- locking de carrinho, solicitação e item;
- camadas API, Service, Rule e Repository.

Não implementado:

- reserva física;
- disponibilidade líquida de reservas;
- aceite explícito do cliente;
- snapshot versionado aceito;
- prazo integrado a Business Configuration;
- expiração/liberação automática;
- validações de reserva pelo PAYMENT.

## 15. Decisões relacionadas

- `ADR-019_PURCHASE_RESERVATION.md`;
- `ADR-020_PURCHASE_CONFIRMATION_AND_PAYMENT_TIMEOUT.md`;
- `ADR-021_AUDIT_ACTOR_IDENTITY.md`;
- `ADR-024_PAYMENT_PRECEDES_ORDER.md`.
