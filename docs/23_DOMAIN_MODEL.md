# Modelo de Domínio - Brechó Express

## 1. Objetivo

Este documento apresenta a visão arquitetural oficial do domínio modelado até a Sprint 5A do Brechó Express.

A proposta é consolidar, de forma objetiva, a estrutura conceitual dos módulos de Identidade, Brechós, Catálogo, Compra, Logística e Financeiro, sem detalhar implementação Oracle, SQL ou Flutter.

## 2. Módulos contemplados

- Identidade
- Brechós
- Catálogo
- Compra
- Logística
- Financeiro

## 3. Identidade

### Visão do Módulo

```text
ACCOUNT
     │
     │ 1:1
     ▼
PROFILE
     │
     ├───────────────┐
     │               │
     ▼               ▼
ADDRESS        PROFILE_ROLE
                    │
                    ▼
                   ROLE

ACCOUNT
     │
     ▼
SESSION
```

Resumo do módulo:

- ACCOUNT representa a camada de autenticação e acesso da plataforma.
- PROFILE representa a pessoa cadastrada no domínio.
- ADDRESS representa os endereços associados ao Profile.
- ROLE representa os papéis globais da plataforma.
- PROFILE_ROLE associa Profile a Role.
- SESSION representa as sessões autenticadas vinculadas a uma Account.

## 4. Brechós

### Visão do Módulo

```text
PROFILE
      │
      ▼
STORE
      │
      ├──────────────┐
      │              │
      ▼              ▼
STORE_USER     STORE_PLAN
      │
      ├──────────────┐
      ▼              ▼
STORE_EVENT   STORE_FOLLOWER
```

Resumo do módulo:

- STORE representa o Brechó como organização comercial na plataforma.
- ACCOUNT pode possuir um ou mais Brechós.
- STORE_USER representa os papéis operacionais de uma ACCOUNT dentro de um Brechó.
- STORE_PLAN representa os planos comerciais disponíveis para um Brechó.
- STORE_EVENT representa eventos, campanhas e ações temporárias vinculadas ao Brechó.
- STORE_FOLLOWER representa os relacionamentos de acompanhamento de um Profile com um Brechó.

## 5. Catálogo

### Visão do Módulo

```text
STORE
      │
      ▼
PRODUCT
      │
 ┌────┼──────────────┬──────────────┬──────────────┐
 ▼    ▼              ▼              ▼              ▼
CATEGORY BRAND   PRODUCT_STATUS   PRODUCT_IMAGE   PRODUCT_QUESTION
```

Resumo do módulo:

- PRODUCT representa o Achado anunciado por um Brechó.
- STORE publica os Achados no catálogo.
- CATEGORY organiza os Achados por categoria.
- BRAND organiza os Achados por marca.
- PRODUCT_STATUS controla o ciclo de vida e a visibilidade do Achado.
- PRODUCT_IMAGE representa as imagens associadas ao Achado.
- PRODUCT_QUESTION representa o contexto de interação pública de pré-venda entre clientes e Brechós.
- PRODUCT_QUESTION não substitui STORE_REVIEW e não representa avaliação pós-venda; faz parte do processo de descoberta e decisão de compra.

## 6. Aggregate Roots do Domínio

Os Aggregate Roots atuais do domínio são:

- PROFILE
- STORE
- PRODUCT
- ORDER

Esses conceitos funcionam como raízes de agregação porque concentram a identidade e a consistência interna de seus respectivos contextos:

- PROFILE é a raiz de identidade da pessoa no domínio.
- STORE é a raiz organizacional do contexto de Brechós.
- PRODUCT é a raiz do catálogo e representa o principal objeto de negócio do módulo de Achados.
- ORDER é a raiz do contexto de Compra e concentra a consistência do ciclo de pedido, desde a confirmação da compra até a evolução do processamento comercial.

## 7. Classificação das Entidades

A classificação das entidades segue a função que cada uma exerce no domínio.

### MASTER

Entidades centrais da modelagem, com identidade própria e forte relevância para o negócio.

- ACCOUNT
- PROFILE
- STORE
- PRODUCT

### CONFIGURATION

Entidades de parametrização e referência que orientam o comportamento do domínio.

- ROLE
- STORE_PLAN
- CATEGORY
- BRAND
- PRODUCT_STATUS

### SUPPORT

Entidades auxiliares que sustentam relacionamentos, organização e apresentação.

- ADDRESS
- PROFILE_ROLE
- STORE_USER
- STORE_FOLLOWER
- PRODUCT_IMAGE

### TRANSACTION

Entidades associadas a ações, eventos ou estados transitórios do processo de negócio.

- SESSION
- STORE_EVENT

## 8. Dependência entre Módulos

A arquitetura do domínio é organizada por dependência progressiva entre módulos.

```text
IDENTIDADE
      ↓
BRECHÓS
      ↓
CATÁLOGO
      ↓
COMPRA
      ↓
LOGÍSTICA
      ↓
FINANCEIRO
      ↓
PÓS-VENDA
      ↓
ECONOMIA CIRCULAR
      ↓
SOCIAL
```

Essa estrutura reduz o acoplamento entre módulos e permite evoluir o domínio de forma incremental. Cada módulo depende, em maior ou menor grau, dos conceitos definidos nos módulos anteriores, preservando a coerência arquitetural do sistema.

## 9. Visão consolidada

Diagrama textual consolidado dos principais relacionamentos do domínio:

```text
ACCOUNT
  │
  │ 1:1
  ▼
PROFILE
  │
  ├───────────────┐
  │               │
  ▼               ▼
ADDRESS        PROFILE_ROLE
                  │
                  ▼
                 ROLE

PROFILE
  │
  ▼
STORE
  │
  ├──────────────┐
  │              │
  ▼              ▼
STORE_USER    STORE_PLAN
  │
  ├──────────────┐
  ▼              ▼
STORE_EVENT  STORE_FOLLOWER

STORE
  │
  ▼
PRODUCT
  │
  ├───────────────┬───────────────┬───────────────┐
  │               │               │               │
  ▼               ▼               ▼               ▼
CATEGORY        BRAND      PRODUCT_STATUS   PRODUCT_IMAGE
                                                    │
                                                    ▼
                                             PRODUCT_QUESTION

ACCOUNT
  │
  ▼
SESSION
```

## 10. Evolução do Domínio

A evolução arquitetural do Brechó Express pode ser acompanhada por sprints.

### Sprint 1

✔ Identidade

✔ Brechós

### Sprint 2

✔ Catálogo

### Sprint 3

✔ Compra

### Sprint 4

✔ Logística

### Sprint 5A

✔ Infraestrutura Financeira

### Sprint 5B

⬜ Wallet Financeira

### Sprint 6

⬜ Pós-venda

### Sprint 7

⬜ Economia Circular

### Sprint 8

⬜ Social

## 11. Observações arquiteturais

- PROFILE é a base da identidade da pessoa no domínio.
- ACCOUNT é separado de PROFILE para manter a distinção entre autenticação e identidade.
- STORE representa uma organização comercial, não uma pessoa.
- PRODUCT é apresentado na interface como Achado, embora o modelo técnico utilize o termo PRODUCT.
- CATEGORY, BRAND e PRODUCT_STATUS são configurações do catálogo.
- PRODUCT_IMAGE é o suporte visual do Achado.
- Compra já está modelada no domínio.
- Logística já está modelada no domínio.
- A Infraestrutura Financeira foi modelada na Sprint 5A.
- A Wallet Financeira, incluindo saldo, comissão e payout, será modelada na Sprint 5B.
