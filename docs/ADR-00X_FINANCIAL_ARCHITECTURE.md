# ADR-00X — Arquitetura Financeira do Marketplace

## Status

Accepted

## Contexto

O Brechó Express é um marketplace onde clientes compram produtos de diferentes Brechós.

O dinheiro não é recebido diretamente pelos Brechós.

Todo pagamento é processado por um Gateway de Pagamento e inicialmente pertence à plataforma.

O módulo financeiro deve suportar crescimento futuro, múltiplos gateways, auditoria completa e integração com provedores externos.

---

## Decisão

### 1. A Plataforma é a intermediadora financeira

Todo pagamento recebido pertence inicialmente ao Brechó Express.

O Brechó nunca recebe diretamente do Gateway de Pagamento.

---

### 2. O Brechó possui um saldo interno

Cada Brechó possui um saldo controlado pela plataforma.

Esse saldo representa créditos internos e não uma conta bancária.

---

### 3. O saldo possui estados

Fluxo:

Pagamento Recebido

↓

Saldo Bloqueado

↓

Cliente confirma recebimento

OU

Prazo de retenção expira

↓

Saldo Disponível

↓

Solicitação de Saque (PIX)

↓

Saldo Pago

Explicar que o saldo nunca muda diretamente.

Toda alteração ocorre através de movimentações financeiras.

---

### 4. Pagamentos são confirmados por Webhook

O Brechó Express nunca depende de consulta manual ao Gateway.

A confirmação ocorre através de eventos enviados pelo Gateway de Pagamento.

Exemplos de Gateways:

- PagSeguro
- Mercado Pago
- Asaas
- Stripe

O sistema deve ser independente do provedor utilizado.

---

### 5. Pagamento ocorre somente após confirmação do Brechó

Fluxo:

Carrinho

↓

Purchase Request

↓

Brechó confirma disponibilidade

↓

Cliente realiza pagamento

↓

Pedido é criado

---

### 6. O cliente pode confirmar o recebimento

Fluxo:

Entrega

↓

Cliente confirma

↓

Saldo do Brechó é liberado

Caso o cliente não confirme:

Após o período de retenção configurado

↓

Saldo é liberado automaticamente.

O período de retenção deverá ser configurável futuramente.

---

### 7. Comissão e taxas

O valor recebido do cliente sofre descontos antes da disponibilização do saldo.

Exemplos:

- Comissão da plataforma
- Taxas do Gateway de Pagamento

Todos os descontos devem ser transparentes ao Brechó.

---

### 8. O cliente realiza apenas um pagamento

Mesmo que um pedido contenha produtos de vários Brechós.

Internamente a plataforma distribui os valores para cada Brechó.

---

### 9. O repasse é realizado através de PIX

Inicialmente:

Solicitação manual de saque.

Fluxo:

Saldo Disponível

↓

Solicitação de PIX

↓

Análise

↓

Pagamento realizado

No futuro poderá existir processamento automático em ciclos configuráveis.

---

### 10. Livro Razão

O sistema financeiro utilizará movimentações financeiras.

Nenhum saldo poderá ser alterado manualmente.

Toda alteração gera um lançamento financeiro.

---

### 11. Programa de Fidelidade

O programa de pontos é totalmente independente do financeiro.

Pontos não representam dinheiro.

Pontos não podem ser tratados como saldo financeiro.

O módulo de fidelização será modelado futuramente.

---

## Consequências

### Benefícios

- Independência do Gateway
- Auditoria completa
- Suporte a múltiplos Gateways
- Suporte a PIX
- Suporte a Cartão
- Suporte a Boleto futuramente
- Suporte a retenção de saldo
- Suporte a devoluções
- Suporte a chargeback
- Suporte a split futuramente
- Suporte a repasses automáticos
- Facilidade de expansão

### Trade-offs

- Maior complexidade financeira
- Necessidade de Webhooks
- Necessidade de conciliação financeira
- Necessidade de processamento assíncrono

---

## Entidades impactadas

Esta ADR fundamenta as seguintes entidades:

- PAYMENT_PROVIDER
- PAYMENT
- PAYMENT_EVENT
- COMMISSION
- STORE_BALANCE
- STORE_BALANCE_TRANSACTION
- PAYOUT

---

## Observações

Esta ADR representa uma das principais decisões arquiteturais do Brechó Express.

Qualquer alteração futura no módulo Financeiro deve permanecer compatível com os princípios definidos neste documento.
