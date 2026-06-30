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

# ADDRESS

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | ADDRESS |
| Prefixo | ADR |
| Tipo | SUPPORT |
| Responsável | Identidade |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar endereços utilizados por Profiles, Brechós e futuramente operações logísticas.

## Classificação

SUPPORT

## Responsabilidades

- Representar localização física.
- Armazenar endereços associados a Profiles.
- Apoiar futuras integrações com brechós e logística.
- Servir como base para localização e entrega.

## Não é responsabilidade

- Armazenar dados de autenticação.
- Armazenar dados pessoais sensíveis.
- Representar diretamente um Brechó.
- Definir regras comerciais.
- Gerenciar logística completa.

## Dono da Informação

Usuário

## Regras de Negócio

- RN-001 — ADDRESS representa localização física.
- RN-002 — Um PROFILE pode possuir vários ADDRESS.
- RN-003 — Um ADDRESS pertence a exatamente um PROFILE.
- RN-004 — Um PROFILE pode possuir apenas um ADDRESS padrão ativo.
- RN-005 — ADR_PUBLIC_ID deve ser CHAR(32).
- RN-006 — APIs externas usam ADR_PUBLIC_ID, nunca ADR_ID.
- RN-007 — A exclusão deve ser lógica via ADR_STATUS.
- RN-008 — ADDRESS não representa STORE diretamente, mas pode ser utilizado futuramente por STORE e logística.
- RN-009 — Latitude e longitude são opcionais no MVP.
- RN-010 — Todo PROFILE deve possuir pelo menos um ADDRESS ativo para concluir o cadastro.

## Relacionamentos

- PROFILE (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| ADR_ID | NUMBER Identity | Sim |
| ADR_PUBLIC_ID | CHAR(32) | Sim |
| PFL_ID | NUMBER | Sim |
| ADR_LABEL | VARCHAR2(100) | Não |
| ADR_ZIP_CODE | VARCHAR2(10) | Não |
| ADR_STREET | VARCHAR2(200) | Não |
| ADR_NUMBER | VARCHAR2(50) | Não |
| ADR_COMPLEMENT | VARCHAR2(200) | Não |
| ADR_DISTRICT | VARCHAR2(100) | Não |
| ADR_CITY | VARCHAR2(100) | Não |
| ADR_STATE | VARCHAR2(2) | Não |
| ADR_COUNTRY | CHAR(2) | Não |
| ADR_LATITUDE | NUMBER(10,7) | Não |
| ADR_LONGITUDE | NUMBER(10,7) | Não |
| ADR_IS_DEFAULT | CHAR(1) | Não |
| ADR_STATUS | VARCHAR2(20) | Sim |
| ADR_CREATED_AT | TIMESTAMP | Sim |
| ADR_UPDATED_AT | TIMESTAMP | Sim |
| ADR_CREATED_BY | NUMBER | Não |
| ADR_UPDATED_BY | NUMBER | Não |

ADR_CREATED_BY e ADR_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_ADDRESS
- UK_ADDRESS_PUBLIC_ID
- IDX_ADDRESS_PROFILE
- IDX_ADDRESS_STATUS
- IDX_ADDRESS_ZIP_CODE

## Packages Oracle

- ADR_API_PKG
- ADR_RULE_PKG

## APIs

- GET /addresses
- GET /addresses/{publicId}
- POST /addresses
- PUT /addresses/{publicId}

## Flutter

- AddressModel
- AddressRepository
- AddressController
- AddressPage

## Observações

ADDRESS é uma entidade compartilhada do domínio.

Inicialmente pertence ao módulo Identidade através de PROFILE, mas poderá ser reutilizada futuramente por STORE, ORDER, DELIVERY e outros módulos, mantendo um único modelo de endereço em toda a plataforma.

ADR_LABEL pode ser utilizado para identificar o endereço de forma amigável, como Casa, Trabalho, Loja, Entrega ou Retirada.

# STORE

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | STORE |
| Prefixo | STR |
| Tipo | MASTER |
| Responsável | Brechós |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar o Brechó dentro do domínio do Brechó Express.

## Classificação

MASTER

## Responsabilidades

- Representar qualquer Brechó, ONG, projeto social, loja de economia circular ou revendedor parceiro.
- Servir como entidade central do módulo Brechós.
- Organizar dados básicos de identificação e apresentação do Brechó.
- Apoiar a publicação de achados e a operação comercial da plataforma.

## Não é responsabilidade

- Armazenar credenciais de autenticação.
- Representar diretamente produtos.
- Definir regras comerciais completas.
- Gerenciar logística integral.
- Substituir o papel de PROFILE na identidade da pessoa.

## Dono da Informação

Usuário / Operação do Brechó

## Regras de Negócio

- RN-001 — STORE representa qualquer Brechó, ONG, projeto social, loja de economia circular ou revendedor parceiro.
- RN-002 — STORE é o termo técnico; na interface o termo oficial é Brechó.
- RN-003 — Um STORE deve possuir um PROFILE responsável.
- RN-004 — Um PROFILE pode administrar um ou mais STORE.
- RN-005 — Um STORE pode possuir um ADDRESS principal.
- RN-006 — STR_PUBLIC_ID deve ser CHAR(32).
- RN-007 — APIs externas usam STR_PUBLIC_ID, nunca STR_ID.
- RN-008 — STR_SLUG deve ser único.
- RN-009 — A exclusão deve ser lógica via STR_STATUS.
- RN-010 — STORE não armazena credenciais de autenticação.
- RN-011 — STORE não representa diretamente produtos; produtos serão representados por PRODUCT.
- RN-012 — STORE pode ser Gratuito ou Plus através de STR_IS_PLUS.

## Relacionamentos

- PROFILE (N:1)
- ADDRESS (N:1)
- PRODUCT (1:N)
- STORE_USER (1:N)
- STORE_EVENT (1:N)
- STORE_FOLLOWER (1:N)
- STORE_REVIEW (1:N)
- STORE_REPUTATION (1:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| STR_ID | NUMBER Identity | Sim |
| STR_PUBLIC_ID | CHAR(32) | Sim |
| PFL_ID | NUMBER | Sim |
| ADR_ID | NUMBER | Não |
| STR_NAME | VARCHAR2(200) | Sim |
| STR_SLUG | VARCHAR2(100) | Sim |
| STR_DESCRIPTION | VARCHAR2(1000) | Não |
| STR_PHONE | VARCHAR2(20) | Não |
| STR_WHATSAPP | VARCHAR2(20) | Não |
| STR_EMAIL | VARCHAR2(255) | Não |
| STR_LOGO_URL | VARCHAR2(500) | Não |
| STR_COVER_URL | VARCHAR2(500) | Não |
| STR_TYPE | VARCHAR2(50) | Não |
| STR_IS_PLUS | CHAR(1) | Não |
| STR_STATUS | VARCHAR2(20) | Sim |
| STR_CREATED_AT | TIMESTAMP | Sim |
| STR_UPDATED_AT | TIMESTAMP | Sim |
| STR_CREATED_BY | NUMBER | Não |
| STR_UPDATED_BY | NUMBER | Não |

STR_CREATED_BY e STR_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_STORE
- UK_STORE_PUBLIC_ID
- UK_STORE_SLUG
- IDX_STORE_PROFILE
- IDX_STORE_ADDRESS
- IDX_STORE_STATUS
- IDX_STORE_TYPE
- IDX_STORE_IS_PLUS

## Packages Oracle

- STR_API_PKG
- STR_RULE_PKG

## APIs

- GET /stores
- GET /stores/{publicId}
- GET /stores/slug/{slug}
- POST /stores
- PUT /stores/{publicId}

## Flutter

- StoreModel
- StoreRepository
- StoreController
- StorePage

## Observações

STORE é a entidade central do módulo Brechós e representa o Brechó na plataforma.

Na interface, STORE deve ser apresentado como Brechó, conforme Linguagem Ubíqua oficial.

# STORE_USER

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | STORE_USER |
| Prefixo | STU |
| Tipo | SUPPORT |
| Responsável | Brechós |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Não |
| Cache | Sim |

## Objetivo

Representar o vínculo operacional entre um Profile e um Store, permitindo que uma pessoa atue em um Brechó com uma função específica.

## Classificação

SUPPORT

## Responsabilidades

- Representar a participação de um Profile em um Store.
- Definir quem pode operar um Brechó e com qual função.
- Registrar a entrada e a saída de pessoas no contexto operacional do Brechó.
- Apoiar a gestão administrativa do Brechó.

## Não é responsabilidade

- Armazenar credenciais de autenticação.
- Substituir PROFILE_ROLE.
- Representar papéis globais da plataforma.
- Definir regras comerciais.
- Armazenar dados pessoais sensíveis.

## Dono da Informação

Operação do Brechó

## Regras de Negócio

- RN-001 — STORE_USER representa a participação de um PROFILE em um STORE.
- RN-002 — Um STORE pode possuir vários STORE_USER.
- RN-003 — Um PROFILE pode participar de vários STORE.
- RN-004 — Um PROFILE pode atuar como proprietário, atendente, gerente ou colaborador de um STORE.
- RN-005 — A combinação STR_ID + PFL_ID deve ser única enquanto ativa.
- RN-006 — STU_PUBLIC_ID deve ser CHAR(32).
- RN-007 — APIs externas usam STU_PUBLIC_ID, nunca STU_ID.
- RN-008 — A exclusão deve ser lógica via STU_STATUS.
- RN-009 — STORE_USER não armazena credenciais de autenticação.
- RN-010 — STORE_USER não substitui PROFILE_ROLE.
- RN-011 — PROFILE_ROLE representa papéis globais da plataforma.
- RN-012 — STORE_USER representa papéis operacionais dentro de um Brechó específico.
- RN-013 — STU_JOINED_AT deve ser obrigatório.
- RN-014 — STU_LEFT_AT deve ser opcional.

## Relacionamentos

- STORE (N:1)
- PROFILE (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| STU_ID | NUMBER Identity | Sim |
| STU_PUBLIC_ID | CHAR(32) | Sim |
| STR_ID | NUMBER | Sim |
| PFL_ID | NUMBER | Sim |
| STU_ROLE_CODE | VARCHAR2(50) | Sim |
| STU_STATUS | VARCHAR2(20) | Sim |
| STU_JOINED_AT | TIMESTAMP | Sim |
| STU_LEFT_AT | TIMESTAMP | Não |
| STU_CREATED_AT | TIMESTAMP | Sim |
| STU_UPDATED_AT | TIMESTAMP | Sim |
| STU_CREATED_BY | NUMBER | Não |
| STU_UPDATED_BY | NUMBER | Não |

STU_CREATED_BY e STU_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_STORE_USER
- UK_STORE_USER_PUBLIC_ID
- UK_STORE_USER_STORE_PROFILE
- IDX_STORE_USER_STORE
- IDX_STORE_USER_PROFILE
- IDX_STORE_USER_ROLE
- IDX_STORE_USER_STATUS

## Packages Oracle

- STU_API_PKG
- STU_RULE_PKG

## APIs

Nenhuma API pública prevista no MVP.
As operações serão realizadas indiretamente pelas APIs administrativas de Store.

## Flutter

Uso interno pelos módulos administrativos de Brechó.

## Observações

STORE_USER é uma entidade de suporte do módulo Brechós.

Ela define quem pode operar um Brechó e com qual função.

PROFILE_ROLE define papéis globais da plataforma, como CUSTOMER, STORE_OWNER, ADMIN e SYSTEM.

STORE_USER define papéis dentro de um Brechó específico, como OWNER, MANAGER, ATTENDANT ou COLLABORATOR.

# STORE_PLAN

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | STORE_PLAN |
| Prefixo | STP |
| Tipo | CONFIGURATION |
| Responsável | Brechós |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Não |
| Cache | Sim |

## Objetivo

Representar os planos comerciais disponíveis para um Brechó, permitindo diferenciar níveis de uso da plataforma.

## Classificação

CONFIGURATION

## Responsabilidades

- Definir os planos comerciais disponíveis para os Brechós.
- Servir como referência para associação de um Brechó a um plano.
- Apoiar a parametrização de produtos e limites comerciais.
- Manter uma lista estável de planos como FREE, PLUS e PREMIUM.

## Não é responsabilidade

- Gerenciar cobranças diretamente.
- Armazenar dados de pagamento.
- Definir regras operacionais de um Brechó.
- Substituir a entidade STORE.

## Dono da Informação

Brechós

## Regras de Negócio

- RN-001 — STORE_PLAN define planos comerciais para Brechós.
- RN-002 — Os planos oficiais são FREE, PLUS e PREMIUM.
- RN-003 — O código do plano deve ser único.
- RN-004 — Um Brechó pode estar associado a um único plano ativo.
- RN-005 — Planos não devem ser excluídos fisicamente.
- RN-006 — STP_PUBLIC_ID deve ser CHAR(32).
- RN-007 — APIs externas usam STP_PUBLIC_ID, nunca STP_ID.
- RN-008 — A exclusão deve ser lógica via STP_STATUS.

## Relacionamentos

- STORE (1:N)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| STP_ID | NUMBER Identity | Sim |
| STP_PUBLIC_ID | CHAR(32) | Sim |
| STP_CODE | VARCHAR2(50) | Sim |
| STP_NAME | VARCHAR2(100) | Sim |
| STP_DESCRIPTION | VARCHAR2(500) | Não |
| STP_PRICE | NUMBER(12,2) | Não |
| STP_STATUS | VARCHAR2(20) | Sim |
| STP_CREATED_AT | TIMESTAMP | Sim |
| STP_UPDATED_AT | TIMESTAMP | Sim |
| STP_CREATED_BY | NUMBER | Não |
| STP_UPDATED_BY | NUMBER | Não |

STP_CREATED_BY e STP_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_STORE_PLAN
- UK_STORE_PLAN_PUBLIC_ID
- UK_STORE_PLAN_CODE
- IDX_STORE_PLAN_STATUS

## Packages Oracle

- STP_API_PKG
- STP_RULE_PKG

## APIs

Nenhuma API pública prevista no MVP.
As operações de configuração serão acessadas indiretamente por módulos administrativos.

## Flutter

Uso interno para configuração e exibição de planos disponíveis.

## Observações

STORE_PLAN é uma entidade de configuração do módulo Brechós.

Ela descreve os planos comerciais disponíveis, sem armazenar dados financeiros completos.

# STORE_EVENT

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | STORE_EVENT |
| Prefixo | STE |
| Tipo | TRANSACTION |
| Responsável | Brechós |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar eventos, campanhas, bazares ou ações temporárias vinculadas a um Brechó.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar campanhas e ações temporárias de um Brechó.
- Definir período de vigência de um evento.
- Apoiar promoções, catálogo e logística.
- Levantar contextos temporários de venda ou engajamento.

## Não é responsabilidade

- Gerenciar pagamentos.
- Representar pedidos ou vendas.
- Armazenar dados de clientes.
- Substituir o catálogo de produtos.

## Dono da Informação

Brechós

## Regras de Negócio

- RN-001 — STORE_EVENT representa uma ação temporária vinculada a um STORE.
- RN-002 — Um STORE pode possuir vários STORE_EVENT.
- RN-003 — O evento deve possuir data de início e fim.
- RN-004 — STE_END_AT não pode ser menor que STE_START_AT.
- RN-005 — Eventos podem influenciar catálogo, promoções e logística.
- RN-006 — STE_PUBLIC_ID deve ser CHAR(32).
- RN-007 — APIs externas usam STE_PUBLIC_ID, nunca STE_ID.
- RN-008 — A exclusão deve ser lógica via STE_STATUS.

## Relacionamentos

- STORE (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| STE_ID | NUMBER Identity | Sim |
| STE_PUBLIC_ID | CHAR(32) | Sim |
| STR_ID | NUMBER | Sim |
| STE_NAME | VARCHAR2(200) | Sim |
| STE_DESCRIPTION | VARCHAR2(1000) | Não |
| STE_START_AT | TIMESTAMP | Sim |
| STE_END_AT | TIMESTAMP | Sim |
| STE_STATUS | VARCHAR2(20) | Sim |
| STE_CREATED_AT | TIMESTAMP | Sim |
| STE_UPDATED_AT | TIMESTAMP | Sim |
| STE_CREATED_BY | NUMBER | Não |
| STE_UPDATED_BY | NUMBER | Não |

STE_CREATED_BY e STE_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_STORE_EVENT
- UK_STORE_EVENT_PUBLIC_ID
- IDX_STORE_EVENT_STORE
- IDX_STORE_EVENT_STATUS
- IDX_STORE_EVENT_PERIOD

## Packages Oracle

- STE_API_PKG
- STE_RULE_PKG

## APIs

- GET /store-events
- GET /store-events/{publicId}
- POST /store-events
- PUT /store-events/{publicId}

## Flutter

- StoreEventModel
- StoreEventRepository
- StoreEventController
- StoreEventPage

## Observações

STORE_EVENT é uma entidade transacional do módulo Brechós.

Ela permite representar campanhas e ações temporárias que impactam a operação do Brechó.

# STORE_FOLLOWER

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | STORE_FOLLOWER |
| Prefixo | STF |
| Tipo | SUPPORT |
| Responsável | Social |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar o relacionamento de seguir um Brechó por um Profile, permitindo engajamento social e acompanhamento.

## Classificação

SUPPORT

## Responsabilidades

- Registrar que um Profile segue um Brechó.
- Apoiar o engajamento social da plataforma.
- Permitir rastrear seguidores ativos e históricos de relacionamento.
- Dar suporte a listagens e notificações.

## Não é responsabilidade

- Armazenar dados pessoais.
- Substituir a entidade STORE.
- Definir papéis operacionais.
- Armazenar credenciais de autenticação.

## Dono da Informação

Social

## Regras de Negócio

- RN-001 — STORE_FOLLOWER representa o relacionamento de seguir um STORE por um PROFILE.
- RN-002 — Um PROFILE pode seguir vários STORE.
- RN-003 — Um STORE pode possuir vários seguidores.
- RN-004 — A combinação STR_ID + PFL_ID deve ser única enquanto ativa.
- RN-005 — STF_FOLLOWED_AT deve ser obrigatório.
- RN-006 — STF_UNFOLLOWED_AT deve ser opcional.
- RN-007 — STF_PUBLIC_ID deve ser CHAR(32).
- RN-008 — APIs externas usam STF_PUBLIC_ID, nunca STF_ID.
- RN-009 — A exclusão deve ser lógica via STF_STATUS.

## Relacionamentos

- STORE (N:1)
- PROFILE (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| STF_ID | NUMBER Identity | Sim |
| STF_PUBLIC_ID | CHAR(32) | Sim |
| STR_ID | NUMBER | Sim |
| PFL_ID | NUMBER | Sim |
| STF_STATUS | VARCHAR2(20) | Sim |
| STF_FOLLOWED_AT | TIMESTAMP | Sim |
| STF_UNFOLLOWED_AT | TIMESTAMP | Não |
| STF_CREATED_AT | TIMESTAMP | Sim |
| STF_UPDATED_AT | TIMESTAMP | Sim |
| STF_CREATED_BY | NUMBER | Não |
| STF_UPDATED_BY | NUMBER | Não |

STF_CREATED_BY e STF_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_STORE_FOLLOWER
- UK_STORE_FOLLOWER_PUBLIC_ID
- UK_STORE_FOLLOWER_STORE_PROFILE
- IDX_STORE_FOLLOWER_STORE
- IDX_STORE_FOLLOWER_PROFILE
- IDX_STORE_FOLLOWER_STATUS

## Packages Oracle

- STF_API_PKG
- STF_RULE_PKG

## APIs

- GET /store-followers
- GET /store-followers/{publicId}
- POST /store-followers
- PUT /store-followers/{publicId}

## Flutter

- StoreFollowerModel
- StoreFollowerRepository
- StoreFollowerController
- StoreFollowerPage

## Observações

STORE_FOLLOWER é uma entidade de suporte do módulo Social.

Ela registra o relacionamento de acompanhamento entre Profiles e Brechós.

# SESSION

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | SESSION |
| Prefixo | SES |
| Tipo | TRANSACTION |
| Responsável | Identidade |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Não |
| Cache | Não |

## Objetivo

Representar uma sessão autenticada de uma Account, registrando o estado de login e os dados de segurança associados.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar uma sessão autenticada vinculada a uma Account.
- Manter informações de segurança da sessão.
- Apoiar a revogação e a expiração de sessões.
- Dar suporte à rastreabilidade de autenticação.

## Não é responsabilidade

- Armazenar dados pessoais.
- Substituir ACCOUNT.
- Substituir PROFILE.
- Manter credenciais em texto puro.

## Dono da Informação

Identidade

## Regras de Negócio

- RN-001 — SESSION representa uma sessão autenticada.
- RN-002 — SESSION pertence a uma ACCOUNT.
- RN-003 — Tokens nunca devem ser armazenados em texto puro.
- RN-004 — SES_TOKEN_HASH deve armazenar apenas hash do token.
- RN-005 — SES_REFRESH_TOKEN_HASH deve armazenar apenas hash do refresh token.
- RN-006 — Sessões podem expirar ou ser revogadas.
- RN-007 — SESSION não armazena dados pessoais.
- RN-008 — SESSION não substitui ACCOUNT.
- RN-009 — SESSION não substitui PROFILE.
- RN-010 — SES_PUBLIC_ID deve ser CHAR(32).
- RN-011 — APIs externas usam SES_PUBLIC_ID, nunca SES_ID.
- RN-012 — A exclusão deve ser lógica via SES_STATUS.

## Relacionamentos

- ACCOUNT (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| SES_ID | NUMBER Identity | Sim |
| SES_PUBLIC_ID | CHAR(32) | Sim |
| ACC_ID | NUMBER | Sim |
| SES_TOKEN_HASH | VARCHAR2(512) | Sim |
| SES_REFRESH_TOKEN_HASH | VARCHAR2(512) | Sim |
| SES_IP_ADDRESS | VARCHAR2(45) | Não |
| SES_USER_AGENT | VARCHAR2(1000) | Não |
| SES_EXPIRES_AT | TIMESTAMP | Sim |
| SES_REVOKED_AT | TIMESTAMP | Não |
| SES_STATUS | VARCHAR2(20) | Sim |
| SES_CREATED_AT | TIMESTAMP | Sim |
| SES_UPDATED_AT | TIMESTAMP | Sim |
| SES_CREATED_BY | NUMBER | Não |
| SES_UPDATED_BY | NUMBER | Não |

SES_CREATED_BY e SES_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_SESSION
- UK_SESSION_PUBLIC_ID
- IDX_SESSION_ACCOUNT
- IDX_SESSION_STATUS
- IDX_SESSION_EXPIRES_AT

## Packages Oracle

- SES_API_PKG
- SES_RULE_PKG

## APIs

Nenhuma API pública prevista no MVP.
As operações de sessão serão tratadas internamente pela camada de identidade.

## Flutter

Uso interno para gestão de sessão e autenticação.

## Observações

SESSION é uma entidade transacional do módulo Identidade.

Ela representa o estado autenticado de uma Account sem substituir os conceitos de Account e Profile.
