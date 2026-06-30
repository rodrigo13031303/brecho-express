# Dicionário de Dados - Brechó Express

## Visão geral do domínio

O Brechó Express é um marketplace de economia circular voltado para conexão entre clientes, brechós, organizações e operações logísticas. O domínio central envolve a representação de perfis, brechós, catálogo de achados, carrinho, checkout, pedidos, logística, pagamentos, pós-venda, doações e engajamento social.

O documento abaixo organiza as entidades por módulos de negócio, preservando a linguagem oficial do domínio e servindo como base para a modelagem futura.

## Mapa do domínio por módulos

### IDENTIDADE
- ACCOUNT
- PROFILE
- ROLE
- PROFILE_ROLE
- SESSION

### BRECHÓS
- STORE
- STORE_USER
- STORE_PLAN
- STORE_EVENT
- STORE_FOLLOWER

### CATÁLOGO
- CATEGORY
- BRAND
- PRODUCT
- PRODUCT_IMAGE
- PRODUCT_STATUS

### COMPRA
- CART
- CART_ITEM
- PURCHASE_REQUEST
- PURCHASE_REQUEST_ITEM
- ORDER
- ORDER_ITEM

### LOGÍSTICA
- SHIPMENT
- SHIPMENT_ITEM
- DELIVERY_PROFILE

### FINANCEIRO
- PAYMENT
- COMMISSION

### PÓS-VENDA
- STORE_REVIEW
- STORE_REPUTATION
- RETURN_REQUEST
- RETURN_ATTACHMENT

### ECONOMIA CIRCULAR
- DONATION
- DONATION_ITEM
- COLLECTION_REQUEST

### SOCIAL
- FAVORITE
- NOTIFICATION
- ACTIVITY_LOG

# PROFILE

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PROFILE |
| Prefixo | PFL |
| Tipo | MASTER |
| Responsável | Identidade |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo
Representar uma pessoa cadastrada na plataforma.

O Profile representa exclusivamente a identidade da pessoa dentro do domínio do Brechó Express.

Não representa um Brechó.

Não representa autenticação.

Não representa permissões.

## Classificação
MASTER

## Responsabilidades
- Representar uma pessoa cadastrada.
- Armazenar seus dados básicos.
- Ser utilizado por Clientes.
- Ser utilizado por Proprietários de Brechós.
- Ser utilizado por Administradores.
- Servir como base para os relacionamentos do domínio.

## Não é responsabilidade
- Login.
- Senha.
- Sessão.
- Permissões.
- Informações de pagamento.
- Informações de catálogo.
- Informações logísticas.

## Dono da Informação
Usuário

## Regras de Negócio
- RN-001 — Todo Profile pertence exatamente a uma Account.
- RN-002 — Um Profile pode possuir vários Endereços.
- RN-003 — Um Profile pode possuir diferentes papéis através de Roles.
- RN-004 — Um Profile pode administrar um ou mais Brechós.
- RN-005 — Um Profile nunca armazena informações de autenticação.

## Relacionamentos
- ACCOUNT (1:1)
- ADDRESS (1:N)
- STORE_USER (1:N)
- ORDER (1:N)
- STORE_REVIEW (1:N)
- ROLE (N:N através de PROFILE_ROLE)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PFL_ID | NUMBER Identity | Sim |
| PFL_PUBLIC_ID | VARCHAR2(32) | Sim |
| PFL_NAME | VARCHAR2(200) | Sim |
| PFL_DISPLAY_NAME | VARCHAR2(120) | Não |
| PFL_PHONE | VARCHAR2(20) | Não |
| PFL_PHOTO_URL | VARCHAR2(500) | Não |
| PFL_STATUS | VARCHAR2(20) | Sim |
| PFL_CREATED_AT | TIMESTAMP | Sim |
| PFL_UPDATED_AT | TIMESTAMP | Sim |
| PFL_CREATED_BY | NUMBER | Não |
| PFL_UPDATED_BY | NUMBER | Não |

PFL_CREATED_BY e PFL_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices
- PK_PROFILE
- UK_PROFILE_PUBLIC_ID
- IDX_PROFILE_PHONE

## Packages Oracle
- PFL_API_PKG
- PFL_RULE_PKG

## APIs
- GET /profiles
- GET /profiles/{publicId}
- POST /profiles
- PUT /profiles/{publicId}

## Flutter
- ProfileModel
- ProfileRepository
- ProfileController
- ProfilePage

## Observações
PROFILE será a entidade modelo utilizada para padronizar todas as demais entidades do Data Dictionary.
