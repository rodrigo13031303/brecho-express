# Arquitetura de Sistema - Brechó Express

## 1. Objetivo

Este documento define a arquitetura geral do Brechó Express como uma referência de alto nível para desenvolvedores, arquitetos e times de produto.

O objetivo é explicar:

- como os módulos do sistema se relacionam;
- quais são os principais fluxos de negócio;
- quais princípios de arquitetura orientam o projeto;
- como o domínio evolui de forma incremental por sprints.

Este documento não descreve implementação técnica detalhada, nem define modelos Oracle, Flutter, SQL ou ORDS.

---

## 2. Visão Geral da Arquitetura

O Brechó Express é um marketplace de economia circular que conecta:

- clientes;
- brechós;
- operadores de logística;
- provedores financeiros;
- a plataforma como intermediadora do processo comercial.

A arquitetura é organizada em módulos de negócio com dependência progressiva, preservando a coerência do domínio e permitindo evolução incremental.

### Visão conceitual

```text
CLIENTE
  │
  ▼
IDENTIDADE
  │
  ▼
BRECHÓS
  │
  ▼
CATÁLOGO
  │
  ▼
COMPRA
  │
  ▼
LOGÍSTICA
  │
  ▼
FINANCEIRO
  │
  ▼
PÓS-VENDA
  │
  ▼
ECONOMIA CIRCULAR
  │
  ▼
SOCIAL
```

A ideia central é que cada módulo amplia o contexto de negócio sem perder a consistência das camadas anteriores.

---

## 3. Fluxo Completo de Compra

O fluxo de compra representa o coração da plataforma e consolida diversos módulos em uma jornada integrada.

### Fluxo principal

```text
Cliente
  │
  ▼
Perfil / Conta
  │
  ▼
Catálogo de Achados
  │
  ▼
Visualiza Achado
  │
  ▼
Consulta Perguntas Públicas
  │
  ▼
Faz Pergunta (opcional)
  │
  ▼
Brechó Responde
  │
  ▼
Carrinho
  │
  ▼
Purchase Request
  │
  ▼
Confirmação do Brechó
  │
  ▼
Order
  │
  ▼
Pagamento
  │
  ▼
Webhook / Payment Event
  │
  ▼
Logística
  │
  ▼
Entrega
  │
  ▼
Confirmação de Recebimento
  │
  ▼
Encerramento do Pedido
```

### Papel de cada módulo no fluxo

- Identidade: identifica o cliente e o brechó no sistema.
- Brechós: representam as organizações comerciais que disponibilizam os produtos.
- Catálogo: organiza os produtos e suas características.
- Compra: coordena carrinho, pedido e confirmação comercial.
- Logística: transforma o pedido em uma entrega operacional.
- Financeiro: registra pagamentos e eventos de confirmação recebidos dos gateways.

---

## 4. Arquitetura por Módulos

### 4.1 Identidade

Responsável por representar a pessoa, sua conta e os papéis assumidos dentro da plataforma.

Principais conceitos:
- ACCOUNT
- PROFILE
- ROLE
- PROFILE_ROLE
- SESSION

Esse módulo fornece a base de identidade e autorização do sistema.

### 4.2 Brechós

Responsável por representar as organizações comerciais que publicam produtos na plataforma.

Principais conceitos:
- STORE
- STORE_USER
- STORE_PLAN
- STORE_EVENT
- STORE_FOLLOWER

Esse módulo organiza o relacionamento entre a plataforma e as operações do brechó.

### 4.3 Catálogo

Responsável por estruturar a oferta de produtos e suas referências de classificação.

O Catálogo não representa apenas produtos, mas também todo o contexto de descoberta do Achado, incluindo imagens, categorias, marcas, status e perguntas públicas de pré-venda.

Principais conceitos:
- CATEGORY
- BRAND
- PRODUCT
- PRODUCT_IMAGE
- PRODUCT_STATUS
- PRODUCT_QUESTION

Esse módulo concentra a representação dos achados disponibilizados para compra e a interação inicial que precede a decisão comercial.

### 4.4 Compra

Responsável por coordenar a intenção de compra, a confirmação comercial e a criação do pedido.

Principais conceitos:
- CART
- CART_ITEM
- PURCHASE_REQUEST
- PURCHASE_REQUEST_ITEM
- ORDER
- ORDER_ITEM

A compra é o contexto em que a plataforma transforma interesse em operação comercial formal.

### 4.5 Logística

Responsável pela execução operacional da entrega e pela representação da remessa.

Principais conceitos:
- SHIPMENT
- SHIPMENT_ITEM
- DELIVERY_PROFILE

Esse módulo transforma o pedido em uma entrega concreta, com separação operacional e rastreabilidade.

#### 4.6 Financeiro

Responsável por receber pagamentos, identificar o provedor responsável e registrar eventos de confirmação enviados pelos gateways.

Principais conceitos:
- PAYMENT_PROVIDER
- PAYMENT
- PAYMENT_EVENT
- STORE_BALANCE_TRANSACTION
- STORE_BALANCE
- COMMISSION
- PAYOUT

A arquitetura financeira é orientada pela auditoria, pela independência de provedores e pela confirmação baseada em eventos.

## Arquitetura da Wallet Financeira

O Brechó Express adota uma arquitetura baseada em Livro Razão para o controle financeiro do Brechó.

### Fluxo conceitual

```text
Cliente paga
  │
  ▼
Gateway
  │
  ▼
PAYMENT
  │
  ▼
PAYMENT_EVENT
  │
  ▼
STORE_BALANCE_TRANSACTION
  │
  ▼
STORE_BALANCE
  │
  ▼
PAYOUT
  │
  ▼
PIX para o Brechó
```

Os pontos centrais dessa arquitetura são:

- STORE_BALANCE_TRANSACTION é a origem da verdade financeira.
- STORE_BALANCE é apenas um resumo otimizado para consultas.
- Nenhum saldo pode ser alterado diretamente.
- Toda alteração financeira gera obrigatoriamente uma movimentação no Ledger.

---

## 5. Integrações Externas

O projeto depende de integrações externas principalmente no contexto de pagamentos e logística.

### Integrações previstas

```text
BRECHÓ EXPRESS
  │
  ├── Gateway de Pagamento
  │      └── Webhook / Eventos
  │
  ├── Provedor Logístico
  │      └── Rastreamento / Entrega
  │
  └── Serviços de Identidade e Comunicação
```

### Características das integrações

- As integrações devem ser tratadas como componentes externos ao núcleo do domínio.
- O sistema deve preservar a auditoria dos eventos recebidos.
- O domínio deve permanecer independente da implementação específica do provedor.
- O fluxo financeiro não depende de validação manual do gateway; ele é confirmado por eventos.

---

## 6. Princípios Arquiteturais

Os princípios abaixo refletem as decisões já consolidadas nos documentos de domínio, convenções, padrões de modelagem e ADR financeira.

### 6.1 Domínio primeiro

O modelo de negócio orienta a estrutura do sistema.
A linguagem oficial do domínio deve ser preservada em toda a arquitetura.

### 6.2 Consistência entre modelos e documentação

Toda entidade deve ser formalizada antes de ser implementada.
As decisões de modelagem devem ser coerentes entre dicionário, convenções, padrões e arquitetura.

### 6.3 Identidade e rastreabilidade

Toda entidade de negócio deve possuir identidade, status e auditoria.
A rastreabilidade é essencial para operações comerciais e financeiras.

### 6.4 APIs e interfaces públicas baseadas em identificadores públicos

As interfaces externas devem utilizar identificadores públicos, não IDs internos.
Essa regra preserva isolação entre o domínio e a infraestrutura.

### 6.5 Soft delete e estado explícito

A exclusão física não deve ser usada para entidades de negócio.
O estado explícito é o mecanismo preferido para controlar ciclo de vida.

### 6.6 Separação entre contexto operacional e contexto de configuração

### 6.7 Transparência Comercial

As informações públicas que auxiliam a decisão de compra, como perguntas e respostas dos clientes, fazem parte do domínio do Catálogo e devem permanecer disponíveis para todos os usuários, preservando transparência e reduzindo dúvidas recorrentes.

Entidades como configuração e parametrização devem ser mantidas separadas das entidades transacionais.
Isso reduz acoplamento e facilita evolução.

### 6.7 Independência de provedores

O domínio deve ser capaz de evoluir sem depender de um único gateway, provedor logístico ou canal de pagamento.
A arquitetura deve favorecer abstração e extensão.

### 6.8 Auditoria como requisito estrutural

Eventos, pagamentos, entregas e operações relevantes devem ser rastreáveis.
A auditoria é parte da arquitetura, não apenas de implementação.

---

## 7. Roadmap Arquitetural

A evolução arquitetural do projeto segue uma progressão por sprints.

```text
Sprint 1  -> Identidade e Brechós
Sprint 2  -> Catálogo
Sprint 3  -> Compra
Sprint 4  -> Logística
Sprint 5A -> Infraestrutura Financeira
Sprint 5B -> Wallet Financeira
Sprint 6  -> Pós-venda
Sprint 7  -> Economia Circular
Sprint 8  -> Social
```

Essa evolução mantém o sistema alinhado ao domínio e permite que cada novo módulo seja incorporado de forma orgânica.

---

## Conclusão

A arquitetura do Brechó Express é organizada como um marketplace modular, orientado por domínio, com forte ênfase em consistência, rastreabilidade e evolução incremental.

Esse documento serve como ponto de entrada para compreender a visão geral do sistema e a lógica de evolução do projeto.
