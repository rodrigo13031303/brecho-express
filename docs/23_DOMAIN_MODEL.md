# Modelo de Domínio - Brechó Express

## 1. Objetivo

Este documento apresenta a visão arquitetural do domínio modelado até a Sprint 2 do Brechó Express.

A proposta é consolidar, de forma objetiva, a estrutura conceitual dos módulos de Identidade, Brechós e Catálogo, sem detalhar implementação Oracle, SQL ou Flutter.

## 2. Módulos contemplados

- Identidade
- Brechós
- Catálogo

## 3. Identidade

Representação conceitual:

ACCOUNT
  -> PROFILE
  -> ADDRESS
  -> PROFILE_ROLE
  -> ROLE
  -> SESSION

Resumo do módulo:

- ACCOUNT representa a camada de autenticação e acesso da plataforma.
- PROFILE representa a pessoa cadastrada no domínio.
- ADDRESS representa os endereços associados ao Profile.
- ROLE representa os papéis globais da plataforma.
- PROFILE_ROLE associa Profile a Role.
- SESSION representa as sessões autenticadas vinculadas a uma Account.

## 4. Brechós

Representação conceitual:

PROFILE
  -> STORE
  -> STORE_USER
  -> STORE_PLAN
  -> STORE_EVENT
  -> STORE_FOLLOWER

Resumo do módulo:

- STORE representa o Brechó como organização comercial na plataforma.
- PROFILE pode administrar um ou mais Brechós.
- STORE_USER representa os papéis operacionais de um Profile dentro de um Brechó.
- STORE_PLAN representa os planos comerciais disponíveis para um Brechó.
- STORE_EVENT representa eventos, campanhas e ações temporárias vinculadas ao Brechó.
- STORE_FOLLOWER representa os relacionamentos de acompanhamento de um Profile com um Brechó.

## 5. Catálogo

Representação conceitual:

STORE
  -> PRODUCT
  -> CATEGORY
  -> BRAND
  -> PRODUCT_STATUS
  -> PRODUCT_IMAGE

Resumo do módulo:

- PRODUCT representa o Achado anunciado por um Brechó.
- STORE publica os Achados no catálogo.
- CATEGORY organiza os Achados por categoria.
- BRAND organiza os Achados por marca.
- PRODUCT_STATUS controla o ciclo de vida e a visibilidade do Achado.
- PRODUCT_IMAGE representa as imagens associadas ao Achado.

## 6. Visão consolidada

Diagrama textual consolidado dos principais relacionamentos:

ACCOUNT
  └─ PROFILE
       ├─ ADDRESS
       ├─ PROFILE_ROLE
       │    └─ ROLE
       └─ SESSION

PROFILE
  └─ STORE
       ├─ STORE_USER
       ├─ STORE_PLAN
       ├─ STORE_EVENT
       └─ STORE_FOLLOWER

STORE
  └─ PRODUCT
       ├─ CATEGORY
       ├─ BRAND
       ├─ PRODUCT_STATUS
       └─ PRODUCT_IMAGE

## 7. Observações arquiteturais

- PROFILE é a base da identidade da pessoa no domínio.
- ACCOUNT é separado de PROFILE para manter a distinção entre autenticação e identidade.
- STORE representa uma organização comercial, não uma pessoa.
- PRODUCT é apresentado na interface como Achado, embora o modelo técnico utilize o termo PRODUCT.
- CATEGORY, BRAND e PRODUCT_STATUS são configurações do catálogo.
- PRODUCT_IMAGE é o suporte visual do Achado.
- O domínio modelado até a Sprint 2 ainda não contempla Compra, Logística, Financeiro ou Pós-venda.
- Esses módulos serão modelados em sprints futuras.
