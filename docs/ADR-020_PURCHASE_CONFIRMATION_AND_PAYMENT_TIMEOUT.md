# ADR-020 — Aceite parcial e prazo parametrizado de pagamento

## Status

Aceito

## Data

2026-07-26

## Contexto

PURCHASE_REQUEST permite confirmação parcial, mas a implementação atual aceita
uma solicitação `PARTIALLY_APPROVED` como origem direta de PAYMENT. Isso pode
submeter o cliente a quantidade e total diferentes dos inicialmente
solicitados sem consentimento explícito.

O prazo de pagamento já era uma política prevista para configuração de
negócio, mas precisava ser relacionado formalmente à reserva e aos estados da
compra.

## Decisão

### 1. Aceite explícito

Quando qualquer item for parcialmente aprovado, o cliente deve visualizar:

- quantidade solicitada;
- quantidade confirmada;
- itens rejeitados;
- preços aplicáveis;
- subtotal, frete, descontos e total recalculado;
- prazo disponível para aceitar e pagar.

PAYMENT não pode ser criado até o cliente aceitar explicitamente a composição
atualizada. O aceite registra instante, versão ou snapshot aceito e ator.

Solicitação integralmente aprovada pode seguir ao pagamento sem um aceite de
ajuste, preservadas as confirmações normais do checkout.

### 2. Recusa ou ausência de aceite

O cliente pode recusar a composição parcial. A ausência de aceite até o prazo
aplicável expira o fluxo. Em ambos os casos, reservas ativas são liberadas de
forma idempotente.

### 3. Prazo parametrizado

O prazo para pagamento não será constante em código. A política oficial é
`PURCHASE_PAYMENT_TIMEOUT`, resolvida por
`BUSINESS_CONFIGURATION`.

A configuração deve possuir valor, unidade, vigência e fallback aprovado. Uma
evolução poderá especializar o prazo por método de pagamento ou contexto sem
alterar o domínio central.

O instante limite efetivo deve ser persistido no fluxo de compra ou pagamento
para preservar o prazo aplicado mesmo que a configuração mude posteriormente.

### 4. Validação no pagamento

A criação e a aprovação de PAYMENT devem validar:

- solicitação em estado elegível;
- aceite parcial, quando exigido;
- prazo não expirado;
- reservas correspondentes ainda ativas;
- total igual ao snapshot aceito.

## Estado de implementação

Parcialmente implementado em 2026-07-26:

- `PURCHASE_PAYMENT_TIMEOUT` está documentado como política;
- PURCHASE_REQUEST suporta aprovação parcial;
- PAYMENT calcula o valor confirmado;
- ainda não existe aceite explícito do cliente;
- ainda não existe integração completa do prazo com reserva e pagamento.

## Consequências

- impede cobrança silenciosa de composição diferente da intenção original;
- mantém prazo operacional fora do código;
- exige evolução dos estados e atributos de PURCHASE_REQUEST;
- exige contrato de API para aceitar ou recusar a composição parcial;
- exige testes de expiração, mudança de configuração e concorrência.
