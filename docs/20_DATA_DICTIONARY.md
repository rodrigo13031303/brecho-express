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
| PFL_PUBLIC_ID | CHAR(32) | Sim |
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

# ROLE

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | ROLE |
| Prefixo | ROL |
| Tipo | CONFIGURATION |
| Responsável | Identidade |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Não |
| Cache | Sim |

## Objetivo

Representar os papéis oficiais que um Profile pode assumir dentro da plataforma.

## Classificação

CONFIGURATION

## Responsabilidades

- Definir papéis de acesso.
- Apoiar autorização e controle de permissões.
- Permitir que um Profile atue como cliente, dono de brechó, atendente, administrador ou sistema.

## Não é responsabilidade

- Autenticação.
- Dados pessoais.
- Dados do Brechó.
- Regras comerciais.
- Sessão de usuário.

## Dono da Informação

Sistema

## Regras de Negócio

- RN-001 — Um Role representa um papel oficial da plataforma.
- RN-002 — Um Profile pode possuir vários Roles através de PROFILE_ROLE.
- RN-003 — Roles não devem ser excluídos fisicamente.
- RN-004 — Roles podem ser ativados ou inativados por status.
- RN-005 — O Role SYSTEM será utilizado para operações automáticas.

## Relacionamentos

- PROFILE (N:N através de PROFILE_ROLE)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| ROL_ID | NUMBER Identity | Sim |
| ROL_PUBLIC_ID | CHAR(32) | Sim |
| ROL_CODE | VARCHAR2(50) | Sim |
| ROL_NAME | VARCHAR2(100) | Sim |
| ROL_DESCRIPTION | VARCHAR2(500) | Não |
| ROL_STATUS | VARCHAR2(20) | Sim |
| ROL_CREATED_AT | TIMESTAMP | Sim |
| ROL_UPDATED_AT | TIMESTAMP | Sim |
| ROL_CREATED_BY | NUMBER | Não |
| ROL_UPDATED_BY | NUMBER | Não |

ROL_CREATED_BY e ROL_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_ROLE
- UK_ROLE_PUBLIC_ID
- UK_ROLE_CODE
- IDX_ROLE_STATUS

## Packages Oracle

- ROL_API_PKG
- ROL_RULE_PKG

## APIs

Nenhuma API pública prevista no MVP.

## Flutter

Uso interno para controle de acesso e permissões.

## Observações

Roles iniciais sugeridos:
- SYSTEM
- ADMIN
- CUSTOMER
- STORE_OWNER
- STORE_ATTENDANT

ROLE é uma entidade de configuração e deve ser cacheável.

# PROFILE_ROLE

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PROFILE_ROLE |
| Prefixo | PRL |
| Tipo | SUPPORT |
| Responsável | Identidade |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Não |
| Cache | Sim |

## Objetivo

Representar a associação entre um Profile e um Role dentro do domínio do Brechó Express.

## Classificação

SUPPORT

## Responsabilidades

- Registrar a associação entre um Profile e um Role.
- Suportar a composição de papéis de um Profile.
- Permitir futuros cenários de expiração, auditoria e histórico da associação.
- Servir como base para autorização e controle de atuação na plataforma.

## Não é responsabilidade

- Autenticação.
- Dados pessoais.
- Dados do Brechó.
- Regras comerciais.
- Sessão de usuário.

## Dono da Informação

Sistema

## Regras de Negócio

- RN-001 — Um Profile pode possuir vários Roles.
- RN-002 — Um Role pode pertencer a vários Profiles.
- RN-003 — A combinação (PFL_ID, ROL_ID) deve ser única.
- RN-004 — O relacionamento deve suportar futuras expansões como expiração, auditoria e histórico.
- RN-005 — A entidade não deve simplificar o relacionamento para uma associação apenas lógica sem rastreio.

## Relacionamentos

- PROFILE (N:1)
- ROLE (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PRL_ID | NUMBER Identity | Sim |
| PRL_PUBLIC_ID | CHAR(32) | Sim |
| PFL_ID | NUMBER | Sim |
| ROL_ID | NUMBER | Sim |
| PRL_STATUS | VARCHAR2(20) | Sim |
| PRL_GRANTED_AT | TIMESTAMP | Sim |
| PRL_EXPIRES_AT | TIMESTAMP | Não |
| PRL_CREATED_AT | TIMESTAMP | Sim |
| PRL_UPDATED_AT | TIMESTAMP | Sim |
| PRL_CREATED_BY | NUMBER | Não |
| PRL_UPDATED_BY | NUMBER | Não |

PRL_CREATED_BY e PRL_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_PROFILE_ROLE
- UK_PROFILE_ROLE_PUBLIC_ID
- UK_PROFILE_ROLE_PROFILE_ROLE
- IDX_PROFILE_ROLE_STATUS

## Packages Oracle

- PRL_API_PKG
- PRL_RULE_PKG

## APIs

Nenhuma API pública prevista no MVP.

## Flutter

Uso interno para controle de associação de papéis e permissões.

## Observações

PROFILE_ROLE é uma entidade de suporte, com papel estrutural no relacionamento entre Profile e Role, e deve ser tratada como uma associação com rastreio e potencial evolução.

# ACCOUNT

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | ACCOUNT |
| Prefixo | ACC |
| Tipo | MASTER |
| Responsável | Identidade |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar autenticação e credenciais de acesso do usuário no domínio do Brechó Express.

## Classificação

MASTER

## Responsabilidades

- Armazenar credenciais e autenticação.
- Gerenciar identificação de acesso da conta.
- Gerenciar o ciclo de vida das credenciais.
- Suportar login e controle de acesso.
- Servir como base para o relacionamento com PROFILE.

## Não é responsabilidade

- Armazenar dados pessoais de perfil.
- Armazenar dados do Brechó.
- Armazenar dados de catálogo.
- Armazenar dados de pagamento.
- Armazenar dados logísticos.

## Dono da Informação

Sistema

## Regras de Negócio

- RN-001 — ACCOUNT armazena credenciais e autenticação.
- RN-002 — PROFILE representa a pessoa no domínio.
- RN-003 — ACCOUNT não deve armazenar dados pessoais de perfil.
- RN-004 — Todo PROFILE pertence exatamente a uma ACCOUNT.
- RN-005 — Uma ACCOUNT deve possuir e-mail único.
- RN-006 — A senha nunca deve ser armazenada em texto puro.
- RN-007 — APIs externas usam ACC_PUBLIC_ID, nunca ACC_ID.
- RN-008 — ACC_PUBLIC_ID deve ser CHAR(32).
- RN-009 — A exclusão deve ser lógica via ACC_STATUS.
- RN-010 — Toda ACCOUNT possui exatamente um PROFILE.

## Relacionamentos

- PROFILE (1:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| ACC_ID | NUMBER Identity | Sim |
| ACC_PUBLIC_ID | CHAR(32) | Sim |
| ACC_EMAIL | VARCHAR2(255) | Sim |
| ACC_EMAIL_VERIFIED_AT | TIMESTAMP | Não |
| ACC_PASSWORD_HASH | VARCHAR2(255) | Sim |
| ACC_PASSWORD_CHANGED_AT | TIMESTAMP | Não |
| ACC_STATUS | VARCHAR2(20) | Sim |
| ACC_LAST_LOGIN_AT | TIMESTAMP | Não |
| ACC_CREATED_AT | TIMESTAMP | Sim |
| ACC_UPDATED_AT | TIMESTAMP | Sim |
| ACC_CREATED_BY | NUMBER | Não |
| ACC_UPDATED_BY | NUMBER | Não |

ACC_CREATED_BY e ACC_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_ACCOUNT
- UK_ACCOUNT_PUBLIC_ID
- UK_ACCOUNT_EMAIL
- IDX_ACCOUNT_STATUS

## Packages Oracle

- ACC_API_PKG
- ACC_RULE_PKG

## APIs

- GET /accounts
- GET /accounts/{publicId}
- POST /accounts
- PUT /accounts/{publicId}

## Flutter

- AccountModel
- AccountRepository
- AccountController
- AccountPage

## Observações

ACCOUNT representa exclusivamente credenciais de autenticação.

PROFILE representa exclusivamente a identidade da pessoa.

A separação entre ACCOUNT e PROFILE é obrigatória em todo o domínio.

ACCOUNT é uma entidade de identidade dedicada à autenticação e credenciais de acesso, e deve ser tratada como uma entidade mestre com controle de auditoria e status.
