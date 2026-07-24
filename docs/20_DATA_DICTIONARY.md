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
- PRODUCT_QUESTION
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
- PAYMENT_PROVIDER
- PAYMENT
- PAYMENT_EVENT
- STORE_BALANCE_TRANSACTION
- STORE_BALANCE
- COMMISSION
- PAYOUT

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
| Soft Delete | Não se aplica nesta etapa |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo
Representar os dados pessoais e de apresentação associados a uma Account.

O Profile representa exclusivamente a identidade da pessoa dentro do domínio do Brechó Express. A Account permanece responsável pela identidade técnica e pelas credenciais da plataforma.

Não representa um Brechó.

Não representa autenticação.

Não representa permissões.

## Classificação
MASTER

## Responsabilidades
- Representar os dados pessoais e de apresentação de uma pessoa cadastrada.
- Manter nome de exibição, nome completo, data de nascimento e biografia.
- Manter referências de apresentação, localidade e fuso horário.
- Associar no máximo um Profile a cada Account.

## Não é responsabilidade
- Login.
- Senha.
- Sessão.
- Permissões.
- Informações de pagamento.
- Informações de catálogo.
- Informações logísticas.
- E-mail, telefone ou credenciais.
- Documentos, endereços ou dados bancários.
- Preferências de notificação ou localização em tempo real.
- Dados de loja ou reputação.

## Dono da Informação
Usuário

## Regras de Negócio
- RN-001 — Todo Profile pertence exatamente a uma Account, e cada Account possui no máximo um Profile.
- RN-002 — Um Profile pode possuir vários Endereços.
- RN-003 — Um Profile pode possuir diferentes papéis através de Roles.
- RN-004 — A pessoa representada por um Profile pode administrar Brechós por meio da ACCOUNT correspondente, sem vínculo estrutural entre PROFILE e STORE_USER.
- RN-005 — Um Profile nunca armazena informações de autenticação.
- RN-006 — PFL_BIRTH_DATE, quando informada, não pode estar no futuro; a validação pertence às regras de domínio.

## Relacionamentos
- ACCOUNT (1:0..1 a partir de ACCOUNT; exatamente 1 a partir de PROFILE)
- ADDRESS (1:N)
- ORDER (1:N)
- STORE_REVIEW (1:N)
- ROLE (N:N através de PROFILE_ROLE)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PFL_ID | NUMBER Identity | Sim |
| ACC_ID | NUMBER | Sim |
| PFL_PUBLIC_ID | CHAR(32) | Sim |
| PFL_DISPLAY_NAME | VARCHAR2(100 CHAR) | Sim |
| PFL_FULL_NAME | VARCHAR2(200 CHAR) | Não |
| PFL_BIRTH_DATE | DATE | Não |
| PFL_BIO | VARCHAR2(500 CHAR) | Não |
| PFL_AVATAR_URL | VARCHAR2(1000 CHAR) | Não |
| PFL_LOCALE_CODE | VARCHAR2(10 CHAR) DEFAULT 'pt-BR' | Sim |
| PFL_TIMEZONE_NAME | VARCHAR2(64 CHAR) DEFAULT 'America/Sao_Paulo' | Sim |
| PFL_CREATED_AT | TIMESTAMP(6) DEFAULT SYSTIMESTAMP | Sim |
| PFL_UPDATED_AT | TIMESTAMP(6) DEFAULT SYSTIMESTAMP | Sim |
| PFL_CREATED_BY | NUMBER | Não |
| PFL_UPDATED_BY | NUMBER | Não |

PFL_CREATED_BY e PFL_UPDATED_BY armazenam opcionalmente o identificador técnico do ator. Nenhuma foreign key de auditoria está aprovada nesta etapa.

PFL_BIRTH_DATE permite NULL. A regra que rejeita datas futuras será implementada futuramente por PFL_RULE_PKG, sem trigger ou check constraint dependente da data corrente.

## Índices
- PK_PFL
- UK_PFL_PUBLIC_ID
- UK_PFL_ACCOUNT

As três constraints criam os índices necessários. Nenhum índice adicional está aprovado nesta etapa.

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

No contrato inicial, revogação utiliza PRL_STATUS `INACTIVE` e uma concessão
posterior reativa a mesma associação `(PFL_ID, ROL_ID)`. Uma associação expirada
não concede autorização, ainda que permaneça registrada para auditoria.

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
- RN-010 — Uma ACCOUNT pode existir antes da criação do PROFILE e possuir zero ou um PROFILE.

## Relacionamentos

- PROFILE (1:0..1) — uma ACCOUNT pode possuir zero ou um PROFILE; cada PROFILE pertence exatamente a uma ACCOUNT.
- STORE (1:0..N) — uma ACCOUNT pode possuir zero, uma ou várias STORE; cada STORE possui exatamente uma ACCOUNT proprietária, registrada estruturalmente por STORE.ACC_ID.

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| ACC_ID | NUMBER Identity | Sim |
| ACC_PUBLIC_ID | CHAR(32) | Sim |
| ACC_EMAIL | VARCHAR2(255) | Sim |
| ACC_EMAIL_VERIFIED_AT | TIMESTAMP | Não |
| ACC_PASSWORD_HASH | VARCHAR2(255) | Sim |
| ACC_PASSWORD_CHANGED_AT | TIMESTAMP | Não |
| ACC_STATUS | VARCHAR2(30) | Sim |
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
- ADR_SERVICE_PKG
- ADR_REPOSITORY_PKG
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
| Soft Delete | Não se aplica; encerramento funcional por status |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar uma loja ou operação comercial de venda dentro do domínio do Brechó Express.

## Classificação

MASTER

## Responsabilidades

- Representar qualquer Brechó, ONG, projeto social, loja de economia circular ou revendedor parceiro.
- Servir como entidade central do módulo Brechós.
- Organizar dados básicos de identificação e apresentação do Brechó.
- Preservar a propriedade estrutural da loja por uma ACCOUNT.
- Preservar a identidade pública e o ciclo de vida da loja.
- Servir como agregado externo de referência para catálogo e operação comercial.

## Não é responsabilidade

- Armazenar credenciais de autenticação.
- Representar diretamente produtos.
- Armazenar estoque, pedidos, reputação, endereços, pagamentos ou entregas.
- Armazenar equipe, papéis, convites, promoções ou cupons.
- Concentrar configurações comerciais extensas, assinaturas, planos, comissões ou repasses.
- Definir regras comerciais, fiscais, financeiras ou logísticas completas.
- Substituir o papel de PROFILE na identidade da pessoa.

## Dono da Informação

ACCOUNT proprietária / Operação do Brechó

## Regras de Negócio

- RN-001 — STORE representa qualquer Brechó, ONG, projeto social, loja de economia circular ou revendedor parceiro.
- RN-002 — STORE é o termo técnico; na interface o termo oficial é Brechó.
- RN-003 — Toda STORE deve possuir exatamente uma ACCOUNT proprietária.
- RN-004 — Uma ACCOUNT pode possuir zero, uma ou várias STORE.
- RN-005 — PROFILE não é pré-condição estrutural para criação ou existência de STORE.
- RN-006 — A ACCOUNT deve estar ativa na criação e na ativação da STORE.
- RN-007 — STR_ID é interno, imutável e nunca exposto externamente.
- RN-008 — STR_PUBLIC_ID é obrigatório, único, opaco, imutável e independente de nome, slug, conta ou data.
- RN-009 — APIs e integrações externas usam STR_PUBLIC_ID, nunca STR_ID.
- RN-010 — STR_SLUG deve ser único globalmente, canônico em minúsculas e distinto de STR_PUBLIC_ID.
- RN-011 — STR_PUBLIC_ID e STR_SLUG exigem garantia física de unicidade; consulta prévia não elimina conflitos concorrentes.
- RN-012 — ACC_ID é obrigatório, privado e imutável após a criação; externamente, a conta é resolvida por accountPublicId.
- RN-013 — Uma ACCOUNT não possui limite estrutural de quantidade de STORE.
- RN-014 — STR_STATUS aceita exclusivamente DRAFT, ACTIVE, SUSPENDED e CLOSED.
- RN-015 — STR_STATUS é alterado somente por casos de uso específicos de estado, nunca por PATCH genérico.
- RN-016 — CLOSED representa encerramento funcional sem reversão na primeira versão.
- RN-017 — STORE encerrada preserva histórico, não recebe atualização comum e não é excluída fisicamente como operação normal.
- RN-018 — A API pública não oferece DELETE na primeira versão.
- RN-019 — STR_DESCRIPTION, STR_LOGO_URL e STR_COVER_URL são anuláveis; os demais atributos funcionais obrigatórios não aceitam JSON null.
- RN-020 — STORE não armazena credenciais, produtos, estoque, pedidos, reputação, endereços ou configurações comerciais extensas.

## Relacionamentos

- ACCOUNT (N:1) — relacionamento estrutural obrigatório de propriedade.
- PRODUCT (1:N) — relacionamento externo futuro ou evolutivo.
- INVENTORY ou STOCK_ITEM (1:N) — relacionamento externo futuro.
- ORDER (1:N) — relacionamento externo futuro.
- STORE_REPUTATION (1:N conceitual) — relacionamento externo sujeito ao contrato específico do módulo.
- STORE_ADDRESS (1:N) — entidade futura para endereços com semânticas próprias.
- STORE_USER (1:N) — vínculo operacional de contas administradoras e colaboradoras, sem alterar a propriedade por ACCOUNT.
- STORE_EVENT (1:N) — relacionamento externo.
- STORE_FOLLOWER (1:N) — relacionamento externo.
- STORE_REVIEW (1:N) — relacionamento externo.
- PROMOTION (1:N) — relacionamento externo futuro.
- COUPON (1:N) — relacionamento externo futuro.

Cardinalidade estrutural aprovada:

```text
ACCOUNT 1 → 0..N STORE
STORE N → 1 ACCOUNT
```

A atuação operacional de administradores e colaboradores ocorre por ACCOUNT através de STORE_USER. PROFILE pode fornecer dados pessoais ou de apresentação por composição, mas não participa estruturalmente da propriedade nem do vínculo operacional.

## Atributos

| Campo | Tipo físico proposto | Obrigatório | Padrão | Mutabilidade | Validação e finalidade | Exposição externa |
|--------|----------------------|-------------|--------|-------------|-----------------------|------------------|
| STR_ID | NUMBER Identity | Sim | Gerado pelo Oracle | Imutável | Chave primária e identificador técnico interno | Nunca exposto |
| STR_PUBLIC_ID | CHAR(32 CHAR) | Sim | Gerado pelo Service conforme padrão geral de Public IDs | Imutável | Identificador público opaco, independente de dados de negócio e sujeito a unicidade física | storePublicId |
| ACC_ID | NUMBER | Sim | Sem default | Imutável após criação | FK para BEX_ACCOUNT; identifica a ACCOUNT proprietária | Nunca exposto; recebido como accountPublicId |
| STR_NAME | VARCHAR2(200 CHAR) | Sim | Sem default | Mutável enquanto não CLOSED | Nome público; normalizar extremidades e espaços internos; entre 2 e 200 caracteres | storeName |
| STR_SLUG | VARCHAR2(100 CHAR) | Sim | Sem default | Mutável somente em DRAFT | Único globalmente; minúsculo; somente a-z, 0-9 e hífen; sem hífen nas extremidades e com hífens repetidos consolidados | storeSlug |
| STR_DESCRIPTION | VARCHAR2(1000 CHAR) | Não | NULL | Mutável e anulável | Texto público de apresentação; normalização e limite validados pela Rule | description |
| STR_STATUS | VARCHAR2(20 CHAR) | Sim | DRAFT | Mutável somente por casos de uso de estado | DRAFT, ACTIVE, SUSPENDED ou CLOSED | status |
| STR_LOGO_URL | VARCHAR2(1000 CHAR) | Não | NULL | Mutável e anulável | Referência textual; não armazena BLOB; validação estrutural sem buscar o recurso | logoUrl |
| STR_COVER_URL | VARCHAR2(1000 CHAR) | Não | NULL | Mutável e anulável | Referência textual; não armazena BLOB; validação estrutural sem buscar o recurso | coverUrl |
| STR_LOCALE_CODE | VARCHAR2(10 CHAR) | Sim | pt-BR | Mutável enquanto não CLOSED | Código validado por lista ou contrato aprovado | localeCode |
| STR_TIMEZONE_NAME | VARCHAR2(64 CHAR) | Sim | America/Sao_Paulo | Mutável enquanto não CLOSED | Identificador de timezone IANA validado por contrato aprovado | timezoneName |
| STR_CREATED_AT | TIMESTAMP(6) | Sim | SYSTIMESTAMP | Imutável | Instante técnico de criação | createdAt |
| STR_CREATED_BY | NUMBER | Não | Sem default | Imutável | Ator técnico responsável pela criação; não representa ACC_ID, proprietário ou PROFILE | Nunca exposto |
| STR_UPDATED_AT | TIMESTAMP(6) | Sim | SYSTIMESTAMP | Atualizado em escrita | Instante técnico da última alteração | updatedAt |
| STR_UPDATED_BY | NUMBER | Não | Sem default | Atualizado em escrita | Ator técnico da última alteração; não representa ACC_ID, proprietário ou PROFILE | Nunca exposto |

STR_CREATED_BY e STR_UPDATED_BY registram o ator técnico de auditoria conforme o contexto de execução. Eles não são chaves de propriedade e não devem ser confundidos com ACC_ID ou com PROFILE.

## Identidade pública e slug

- STR_PUBLIC_ID segue o formato físico geral já aprovado para Public IDs no projeto e deve possuir constraint única.
- STR_PUBLIC_ID não pode ser derivado de nome, slug, conta ou data e não pode ser substituído pelo slug.
- Colisão de Public ID deve ser tratada pelo caso de uso sem enfraquecer a garantia física.
- STR_SLUG é obrigatório na primeira versão e deve possuir constraint única global.
- A forma canônica do slug utiliza apenas letras minúsculas de a a z, dígitos de 0 a 9 e hífen.
- Hífens repetidos são consolidados e hífen não é permitido no início ou no fim.
- Após ativação, o slug permanece imutável enquanto não existir política aprovada de histórico e redirecionamento.

## Ciclo de Vida

- DRAFT — loja ainda não publicada.
- ACTIVE — loja operacional.
- SUSPENDED — suspensão administrativa temporária e reversível.
- CLOSED — encerramento funcional sem reversão na primeira versão.

Transições permitidas:

```text
DRAFT → ACTIVE
DRAFT → CLOSED
ACTIVE → SUSPENDED
SUSPENDED → ACTIVE
ACTIVE → CLOSED
SUSPENDED → CLOSED
```

Demais transições são inválidas. INACTIVE, BLOCKED e PENDING_REVIEW não pertencem à primeira versão.

## Atualização Parcial

- Campo ausente preserva o valor atual.
- Campo presente com valor substitui o valor atual.
- Campo presente com JSON null limpa somente atributo anulável.
- STR_DESCRIPTION, STR_LOGO_URL e STR_COVER_URL podem ser limpos.
- STR_NAME, STR_SLUG, STR_LOCALE_CODE e STR_TIMEZONE_NAME não aceitam NULL.
- STR_ID, STR_PUBLIC_ID, ACC_ID, STR_STATUS e os campos de auditoria não pertencem ao PATCH comum.

## Exclusão e Preservação Histórica

- STORE não possui exclusão física como operação normal.
- CLOSED representa o encerramento funcional e preserva histórico e dependências.
- A API pública não oferece DELETE na primeira versão.
- Exclusão excepcional de DRAFT sem dependências permanece decisão futura.
- Não se utiliza coluna genérica de soft delete sem nova decisão arquitetural.

## Constraints Conceituais

- Primary Key obrigatória para STR_ID.
- Unique obrigatória para STR_PUBLIC_ID.
- Unique obrigatória para STR_SLUG.
- Foreign Key obrigatória de ACC_ID para BEX_ACCOUNT.
- Check obrigatória para os valores aprovados de STR_STATUS.
- Not Null para todos os atributos marcados como obrigatórios.
- ACC_ID não possui Unique, preservando várias STORE para a mesma ACCOUNT.
- Normalização e regras complementares de slug permanecem nas camadas apropriadas.

## Concorrência

- Public ID e slug devem ser protegidos por constraints físicas.
- Pré-validação de disponibilidade não elimina conflito concorrente.
- O Service traduz a violação física para sua exceção pública nominal.
- Mudanças de estado validam o estado corrente na mesma transação da atualização.
- Locking ou controle otimista será definido durante a modelagem física e a implementação.
- Criação não é idempotente sem uma futura chave explícita de idempotência.

## Erros Conceituais Candidatos

- STORE_NOT_FOUND
- ACCOUNT_NOT_FOUND_OR_INELIGIBLE
- INVALID_STORE_NAME
- INVALID_STORE_SLUG
- STORE_SLUG_ALREADY_EXISTS
- INVALID_STORE_STATUS
- INVALID_STATUS_TRANSITION
- STORE_ALREADY_CLOSED
- STORE_NOT_ACTIVE
- EMPTY_UPDATE

Os códigos não estão reservados por esta seção. A regra de loja equivalente não deve ser implementada enquanto sua definição permanecer pendente.

## Índices

- PK_STORE
- UK_STORE_PUBLIC_ID
- UK_STORE_SLUG
- IDX_STORE_ACCOUNT
- IDX_STORE_STATUS

UK_STORE_PUBLIC_ID e UK_STORE_SLUG já atendem às respectivas buscas de unicidade e não devem receber índices redundantes. IDX_STORE_ACCOUNT apoia a listagem 0..N por ACCOUNT, sem impor unicidade a ACC_ID.

## Packages Oracle

- STR_API_PKG
- STR_SERVICE_PKG
- STR_RULE_PKG
- STR_REPOSITORY_PKG

## APIs

- POST /accounts/{accountPublicId}/stores
- GET /stores/{storePublicId}
- GET /accounts/{accountPublicId}/stores
- PATCH /stores/{storePublicId}
- POST /stores/{storePublicId}/activation
- POST /stores/{storePublicId}/closure

As rotas são candidatas e não representam handlers implementados. A listagem por conta é autenticada na primeira versão. Suspensão permanece pendente de contrato administrativo.

## Flutter

- StoreModel
- StoreRepository
- StoreController
- StorePage

## Observações

STORE é a entidade central do módulo Brechós e representa o Brechó na plataforma.

Na interface, STORE deve ser apresentado como Brechó, conforme Linguagem Ubíqua oficial.

Produtos, estoque, pedidos, reputação, endereços, membros, papéis, convites, promoções, cupons, pagamentos, entregas, configurações extensas, assinaturas, planos, comissões, repasses, KYC e documentos fiscais permanecem fora do agregado STORE.

Permanecem pendentes a política administrativa de suspensão, a estratégia de locking ou controle otimista, a política de redirecionamento de slug, a eventual vitrine pública, a chave de idempotência e a exclusão excepcional de rascunhos sem dependências.

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

Representar o vínculo operacional entre uma ACCOUNT e uma STORE, permitindo que uma conta atue em um Brechó com uma função específica.

## Classificação

SUPPORT

## Responsabilidades

- Representar a participação operacional de uma ACCOUNT em uma STORE.
- Definir quem pode operar um Brechó e com qual função.
- Registrar a entrada e a saída de contas no contexto operacional do Brechó.
- Apoiar a gestão administrativa do Brechó.

## Não é responsabilidade

- Armazenar credenciais de autenticação.
- Armazenar dados pessoais de PROFILE.
- Substituir PROFILE_ROLE.
- Representar papéis globais da plataforma.
- Representar a propriedade estrutural da STORE, que permanece exclusivamente em BEX_STORE.ACC_ID.
- Definir regras comerciais.
- Armazenar dados pessoais sensíveis.

## Dono da Informação

Operação do Brechó

## Regras de Negócio

- RN-001 — STORE_USER representa a participação operacional de uma ACCOUNT em uma STORE.
- RN-002 — Um STORE pode possuir vários STORE_USER.
- RN-003 — Uma ACCOUNT pode participar operacionalmente de vários STORE.
- RN-004 — Uma ACCOUNT pode atuar como ADMIN, MANAGER, ATTENDANT ou COLLABORATOR em um STORE, sem que o vínculo substitua a propriedade estrutural registrada em BEX_STORE.ACC_ID.
- RN-005 — Pode existir no máximo um vínculo ACTIVE para a mesma combinação STR_ID + ACC_ID.
- RN-006 — STU_PUBLIC_ID deve ser CHAR(32).
- RN-007 — APIs externas usam STU_PUBLIC_ID, nunca STU_ID.
- RN-008 — A exclusão deve ser lógica via STU_STATUS.
- RN-009 — STORE_USER não armazena credenciais de autenticação.
- RN-010 — STORE_USER não substitui PROFILE_ROLE.
- RN-011 — PROFILE_ROLE representa papéis globais da plataforma.
- RN-012 — STORE_USER representa papéis operacionais dentro de um Brechó específico.
- RN-013 — STU_JOINED_AT deve ser obrigatório.
- RN-014 — STU_LEFT_AT deve ser opcional.
- RN-015 — STU_ROLE_CODE é obrigatório, não possui default e aceita exclusivamente ADMIN, MANAGER, ATTENDANT ou COLLABORATOR.
- RN-016 — STU_STATUS é obrigatório, possui default ACTIVE e aceita exclusivamente ACTIVE ou INACTIVE.
- RN-017 — Vínculos INACTIVE preservam o histórico e podem se repetir para a mesma combinação STR_ID + ACC_ID.
- RN-018 — Não deve existir UNIQUE convencional sobre STR_ID + ACC_ID; a unicidade condicional é garantida por índice único baseado em função somente para vínculos ACTIVE.
- RN-019 — PROFILE contém dados pessoais e não participa estruturalmente de BEX_STORE_USER.
- RN-020 — A propriedade da STORE não é representada por STORE_USER e não pode ser alterada por operações de membros.
- RN-021 — Apenas a ACCOUNT proprietária ou um STORE_USER ACTIVE com papel ADMIN pode administrar membros da STORE.
- RN-022 — MANAGER, ATTENDANT e COLLABORATOR não administram membros no MVP.
- RN-023 — Uma operação não pode remover ou rebaixar o último STORE_USER ACTIVE com papel ADMIN da STORE.
- RN-024 — O ator administrativo é recebido de contexto técnico confiável e nunca de propriedade controlada pelo cliente.
- RN-025 — Um STORE_USER só pode ser administrado dentro da STORE à qual pertence.

## Relacionamentos

- STORE (N:1)
- ACCOUNT (N:1)

Cardinalidades aprovadas:

```text
STORE 1 → 0..N STORE_USER
ACCOUNT 1 → 0..N STORE_USER
STORE_USER N → 1 STORE
STORE_USER N → 1 ACCOUNT
```

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| STU_ID | NUMBER Identity | Sim |
| STU_PUBLIC_ID | CHAR(32 CHAR) | Sim |
| STR_ID | NUMBER | Sim |
| ACC_ID | NUMBER | Sim |
| STU_ROLE_CODE | VARCHAR2(50 CHAR), sem default | Sim |
| STU_STATUS | VARCHAR2(20 CHAR) DEFAULT 'ACTIVE' | Sim |
| STU_JOINED_AT | TIMESTAMP | Sim |
| STU_LEFT_AT | TIMESTAMP | Não |
| STU_CREATED_AT | TIMESTAMP | Sim |
| STU_UPDATED_AT | TIMESTAMP | Sim |
| STU_CREATED_BY | NUMBER | Não |
| STU_UPDATED_BY | NUMBER | Não |

STU_CREATED_BY e STU_UPDATED_BY referenciam BEX_ACCOUNT.ACC_ID e identificam opcionalmente a ACCOUNT responsável pela operação de auditoria.

## Domínios

STU_ROLE_CODE é informado explicitamente na criação e aceita somente:

- ADMIN
- MANAGER
- ATTENDANT
- COLLABORATOR

STU_STATUS é obrigatório, possui default ACTIVE e aceita somente:

- ACTIVE
- INACTIVE

## Constraints Conceituais

- PK_STORE_USER para STU_ID.
- UK_STORE_USER_PUBLIC_ID para STU_PUBLIC_ID.
- FK_STU_STORE de STR_ID para BEX_STORE.STR_ID.
- FK_STU_ACCOUNT de ACC_ID para BEX_ACCOUNT.ACC_ID.
- FK_STU_CREATED_BY_ACCOUNT de STU_CREATED_BY para BEX_ACCOUNT.ACC_ID.
- FK_STU_UPDATED_BY_ACCOUNT de STU_UPDATED_BY para BEX_ACCOUNT.ACC_ID.
- CK_STU_ROLE_CODE para o domínio aprovado de STU_ROLE_CODE.
- CK_STU_STATUS para o domínio aprovado de STU_STATUS.
- NOT NULL nos atributos marcados como obrigatórios.

Não existe UNIQUE convencional sobre STR_ID + ACC_ID. A unicidade somente enquanto ACTIVE é garantida por índice único baseado em função, conceitualmente:

```sql
CREATE UNIQUE INDEX UK_STU_STORE_ACCOUNT_ACTIVE
    ON BEX_STORE_USER (
        CASE WHEN STU_STATUS = 'ACTIVE' THEN STR_ID END,
        CASE WHEN STU_STATUS = 'ACTIVE' THEN ACC_ID END
    );
```

Como as expressões retornam NULL para registros INACTIVE, o histórico de vínculos da mesma combinação STR_ID + ACC_ID permanece permitido.

## Índices

- PK_STORE_USER
- UK_STORE_USER_PUBLIC_ID
- UK_STU_STORE_ACCOUNT_ACTIVE
- IDX_STORE_USER_STORE
- IDX_STORE_USER_ACCOUNT
- IDX_STORE_USER_ROLE
- IDX_STORE_USER_STATUS

## Packages Oracle

- STU_RULE_PKG
- STU_REPOSITORY_PKG
- STU_SERVICE_PKG

## APIs

Nenhuma API pública prevista no MVP.
As operações serão realizadas pelas APIs administrativas de Store, que
orquestram os casos de uso internos de STU_SERVICE_PKG.
O contrato administrativo é definido por
`ADR-018_STORE_MEMBER_ADMINISTRATION.md`.

## Flutter

Uso interno pelos módulos administrativos de Brechó.

## Observações

STORE_USER é uma entidade de suporte do módulo Brechós.

Ela define quem pode operar um Brechó e com qual função.

ACCOUNT é a identidade estrutural e operacional do vínculo. PROFILE permanece responsável apenas por dados pessoais e não é dependência estrutural de STORE_USER.

A propriedade da STORE continua registrada exclusivamente por BEX_STORE.ACC_ID; STORE_USER não representa propriedade.

PROFILE_ROLE define papéis globais da plataforma, como CUSTOMER, STORE_OWNER, ADMIN e SYSTEM.

STORE_USER define papéis dentro de um Brechó específico, como ADMIN, MANAGER, ATTENDANT ou COLLABORATOR.

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

Nesta etapa, STORE_PLAN é somente o catálogo oficial de planos. A associação
contratual de uma STORE a um plano permanece adiada até existir um agregado de
assinatura com vigência, histórico e cobrança; não será criada uma foreign key
direta e sem temporalidade em BEX_STORE.

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

STE_CREATED_BY e STE_UPDATED_BY referenciam BEX_ACCOUNT.ACC_ID, pois eventos são
administrados por contas autorizadas a operar a STORE.

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

# CATEGORY

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | CATEGORY |
| Prefixo | CAT |
| Tipo | CONFIGURATION |
| Responsável | Catálogo |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar categorias de Achados para organização, navegação e filtragem do catálogo.

## Classificação

CONFIGURATION

## Responsabilidades

- Definir categorias oficiais de Achados.
- Apoiar filtros e navegação no catálogo.
- Organizar produtos por contexto comercial.
- Servir como referência para classificação do catálogo.

## Não é responsabilidade

- Representar produtos.
- Definir regras de estoque.
- Armazenar dados de clientes.
- Substituir a entidade PRODUCT.

## Dono da Informação

Catálogo

## Regras de Negócio

- RN-001 — CATEGORY representa categorias de Achados.
- RN-002 — CAT_SLUG deve ser único.
- RN-003 — CATEGORY é exibida na interface como Categoria.
- RN-004 — CATEGORY pode ser utilizada para filtros e navegação.
- RN-005 — CAT_PUBLIC_ID deve ser CHAR(32).
- RN-006 — APIs externas usam CAT_PUBLIC_ID, nunca CAT_ID.
- RN-007 — A inativação deve ocorrer via CAT_STATUS; não existe exclusão física como operação normal.
- RN-008 — CAT_STATUS aceita ACTIVE e INACTIVE.
- RN-009 — PRODUCT novo ou alterado só pode referenciar CATEGORY ACTIVE.

## Relacionamentos

- PRODUCT (1:N)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| CAT_ID | NUMBER(19) Identity | Sim |
| CAT_PUBLIC_ID | CHAR(32 CHAR) | Sim |
| CAT_NAME | VARCHAR2(200 CHAR) | Sim |
| CAT_SLUG | VARCHAR2(120 CHAR) | Sim |
| CAT_DESCRIPTION | VARCHAR2(1000 CHAR) | Não |
| CAT_STATUS | VARCHAR2(20 CHAR) | Sim |
| CAT_CREATED_AT | TIMESTAMP(6) | Sim |
| CAT_UPDATED_AT | TIMESTAMP(6) | Sim |
| CAT_CREATED_BY | NUMBER | Não |
| CAT_UPDATED_BY | NUMBER | Não |

CAT_CREATED_BY e CAT_UPDATED_BY armazenam o ator técnico confiável conforme o
Runtime Contract e não possuem foreign key para PROFILE.

## Índices

- PK_CATEGORY
- UK_CATEGORY_PUBLIC_ID
- UK_CATEGORY_SLUG
- IDX_CATEGORY_STATUS

## Packages Oracle

- CAT_RULE_PKG
- CAT_REPOSITORY_PKG
- CAT_SERVICE_PKG
- CAT_API_PKG

## APIs

- GET /categories
- GET /categories/{publicId}
Escritas administrativas não serão expostas antes de existir contrato de
autoridade global da plataforma.

## Flutter

- CategoryModel
- CategoryRepository
- CategoryController
- CategoryPage

## Observações

CATEGORY é uma entidade de configuração do módulo Catálogo.

Ela organiza os Achados por categorias oficiais, com foco em navegação e filtragem.

# BRAND

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | BRAND |
| Prefixo | BRD |
| Tipo | CONFIGURATION |
| Responsável | Catálogo |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar marcas de Achados para organização, navegação e filtragem do catálogo.

## Classificação

CONFIGURATION

## Responsabilidades

- Definir marcas oficiais de Achados.
- Apoiar filtros e navegação no catálogo.
- Organizar produtos por marca.
- Servir como referência para classificação do catálogo.

## Não é responsabilidade

- Representar produtos.
- Definir regras de estoque.
- Armazenar dados de clientes.
- Substituir a entidade PRODUCT.

## Dono da Informação

Catálogo

## Regras de Negócio

- RN-001 — BRAND representa marcas de Achados.
- RN-002 — BRD_SLUG deve ser único.
- RN-003 — BRAND é exibida na interface como Marca.
- RN-004 — BRAND pode ser utilizada para filtros e navegação.
- RN-005 — BRD_PUBLIC_ID deve ser CHAR(32).
- RN-006 — APIs externas usam BRD_PUBLIC_ID, nunca BRD_ID.
- RN-007 — A inativação deve ocorrer via BRD_STATUS; não existe exclusão física como operação normal.
- RN-008 — BRD_STATUS aceita ACTIVE e INACTIVE.
- RN-009 — PRODUCT novo ou alterado só pode referenciar BRAND ACTIVE.

## Relacionamentos

- PRODUCT (1:N)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| BRD_ID | NUMBER(19) Identity | Sim |
| BRD_PUBLIC_ID | CHAR(32 CHAR) | Sim |
| BRD_NAME | VARCHAR2(200 CHAR) | Sim |
| BRD_SLUG | VARCHAR2(120 CHAR) | Sim |
| BRD_DESCRIPTION | VARCHAR2(1000 CHAR) | Não |
| BRD_STATUS | VARCHAR2(20 CHAR) | Sim |
| BRD_CREATED_AT | TIMESTAMP(6) | Sim |
| BRD_UPDATED_AT | TIMESTAMP(6) | Sim |
| BRD_CREATED_BY | NUMBER | Não |
| BRD_UPDATED_BY | NUMBER | Não |

BRD_CREATED_BY e BRD_UPDATED_BY armazenam o ator técnico confiável conforme o
Runtime Contract e não possuem foreign key para PROFILE.

## Índices

- PK_BRAND
- UK_BRAND_PUBLIC_ID
- UK_BRAND_SLUG
- IDX_BRAND_STATUS

## Packages Oracle

- BRD_RULE_PKG
- BRD_REPOSITORY_PKG
- BRD_SERVICE_PKG
- BRD_API_PKG

## APIs

- GET /brands
- GET /brands/{publicId}
Escritas administrativas não serão expostas antes de existir contrato de
autoridade global da plataforma.

## Flutter

- BrandModel
- BrandRepository
- BrandController
- BrandPage

## Observações

BRAND é uma entidade de configuração do módulo Catálogo.

Ela organiza os Achados por marcas oficiais, com foco em navegação e filtragem.

# PRODUCT_STATUS

PRODUCT_STATUS permanece como conceito evolutivo e não será materializado no
MVP. O ciclo de vida inicial possui fonte única em `BEX_PRODUCT.PRD_STATUS`,
validada por constraint física e por `PRD_RULE_PKG`.

Os estados aprovados são DRAFT, ACTIVE, INACTIVE, SOLD e ARCHIVED. RESERVED não
é estado de PRODUCT: carrinho não reserva, e qualquer reserva futura pertence
ao fluxo transacional de Purchase Request.

Uma futura entidade configurável de status exigirá ADR e migração próprios,
substituindo `PRD_STATUS`; nunca coexistirá com ele como segunda fonte de
verdade. Não existem DDL, packages ou API de PRODUCT_STATUS previstos no MVP.

# PRODUCT

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PRODUCT |
| Prefixo | PRD |
| Tipo | MASTER |
| Responsável | Catálogo |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar o Achado anunciado por um Brechó, incluindo dados de identificação, classificação, preço, quantidade e estado físico.

## Classificação

MASTER

## Responsabilidades

- Representar os Achados anunciados no catálogo.
- Organizar os dados comerciais e descritivos de um Achado.
- Apoiar a navegação, filtros, carrinho e pedidos.
- Vincular um Achado a um Brechó, categoria e marca.

## Não é responsabilidade

- Gerenciar autenticação.
- Armazenar dados de pagamento.
- Reservar itens no carrinho.
- Substituir a entidade STORE.

## Dono da Informação

Catálogo

## Regras de Negócio

- RN-001 — PRODUCT é o termo técnico; na interface o termo oficial é Achado.
- RN-002 — Um PRODUCT pertence a um STORE.
- RN-003 — Um PRODUCT deve possuir CATEGORY.
- RN-004 — BRAND pode ser opcional caso a marca seja desconhecida.
- RN-005 — PRD_STATUS controla ciclo de vida e visibilidade.
- RN-006 — Carrinho não reserva PRODUCT.
- RN-007 — PRODUCT pode ser peça única ou possuir quantidade em estoque.
- RN-008 — PRODUCT nunca deve ser excluído fisicamente.
- RN-009 — PRD_PUBLIC_ID deve ser CHAR(32).
- RN-010 — APIs externas usam PRD_PUBLIC_ID, nunca PRD_ID.
- RN-011 — PRD_SLUG deve ser único por STORE.
- RN-012 — Preço deve ser maior ou igual a zero.
- RN-013 — Quantidade deve ser maior ou igual a zero.
- RN-014 — PRD_STATUS aceita DRAFT, ACTIVE, INACTIVE, SOLD e ARCHIVED.
- RN-015 — PRODUCT só pode ser ativado com quantidade maior que zero.
- RN-016 — RESERVED não é estado de PRODUCT.
- RN-017 — Podem administrar catálogo o proprietário da STORE e membros ACTIVE com papel ADMIN, MANAGER ou COLLABORATOR.
- RN-018 — ATTENDANT não administra catálogo no MVP.

## Relacionamentos

- STORE (N:1)
- CATEGORY (N:1)
- BRAND (N:1)
- PRODUCT_IMAGE (1:N)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PRD_ID | NUMBER(19) Identity | Sim |
| PRD_PUBLIC_ID | CHAR(32 CHAR) | Sim |
| STR_ID | NUMBER(19) | Sim |
| CAT_ID | NUMBER(19) | Sim |
| BRD_ID | NUMBER(19) | Não |
| PRD_TITLE | VARCHAR2(200 CHAR) | Sim |
| PRD_SLUG | VARCHAR2(200 CHAR) | Sim |
| PRD_DESCRIPTION | VARCHAR2(4000 CHAR) | Não |
| PRD_PRICE | NUMBER(12,2) | Sim |
| PRD_QUANTITY | NUMBER(12) | Sim |
| PRD_CONDITION | VARCHAR2(20 CHAR) | Sim |
| PRD_WEIGHT | NUMBER(10,3) | Não |
| PRD_WIDTH | NUMBER(10,3) | Não |
| PRD_HEIGHT | NUMBER(10,3) | Não |
| PRD_LENGTH | NUMBER(10,3) | Não |
| PRD_STATUS | VARCHAR2(20 CHAR) | Sim |
| PRD_CREATED_AT | TIMESTAMP(6) | Sim |
| PRD_UPDATED_AT | TIMESTAMP(6) | Sim |
| PRD_CREATED_BY | NUMBER | Não |
| PRD_UPDATED_BY | NUMBER | Não |

PRD_CREATED_BY e PRD_UPDATED_BY armazenam o ator técnico confiável conforme o
Runtime Contract e não possuem foreign key para PROFILE.

## Índices

- PK_PRODUCT
- UK_PRODUCT_PUBLIC_ID
- UK_PRODUCT_STORE_SLUG
- UK_PRODUCT_ID_STORE
- IDX_PRODUCT_CATEGORY
- IDX_PRODUCT_BRAND
- IDX_PRODUCT_STATUS
- IDX_PRODUCT_PRICE

UK_PRODUCT_STORE_SLUG inicia por STR_ID e também atende às consultas por STORE;
por isso não existe IDX_PRODUCT_STORE redundante.

## Packages Oracle

- PRD_RULE_PKG
- PRD_REPOSITORY_PKG
- PRD_SERVICE_PKG
- PRD_API_PKG

## APIs

- GET /products
- GET /products/{publicId}
- POST /stores/{storePublicId}/products
- PATCH /stores/{storePublicId}/products/{productPublicId}
- POST /stores/{storePublicId}/products/{productPublicId}/activation
- POST /stores/{storePublicId}/products/{productPublicId}/inactivation
- POST /stores/{storePublicId}/products/{productPublicId}/sold
- POST /stores/{storePublicId}/products/{productPublicId}/archival

## Flutter

- ProductModel
- ProductRepository
- ProductController
- ProductPage

## Observações

PRODUCT é a entidade principal do módulo Catálogo.

Na interface, o termo oficial é Achado, mesmo sendo modelado tecnicamente como PRODUCT.

O contrato detalhado, o ciclo de vida e a ordem de implementação seguem
`33_CATALOG_ARCHITECTURE.md`.

# PRODUCT_IMAGE

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PRODUCT_IMAGE |
| Prefixo | PIM |
| Tipo | SUPPORT |
| Responsável | Catálogo |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar imagens de um Achado, incluindo a imagem principal e as demais imagens de apoio.

## Classificação

SUPPORT

## Responsabilidades

- Armazenar links ou referências de imagens de um Achado.
- Definir a ordem de exibição das imagens.
- Marcar uma imagem como principal.
- Apoiar a apresentação visual do catálogo.

## Não é responsabilidade

- Armazenar dados pessoais.
- Definir regras comerciais.
- Substituir a entidade PRODUCT.
- Armazenar conteúdo binário diretamente.

## Dono da Informação

Catálogo

## Regras de Negócio

- RN-001 — Um PRODUCT pode possuir várias imagens.
- RN-002 — Uma imagem pertence a exatamente um PRODUCT.
- RN-003 — Um PRODUCT pode possuir apenas uma imagem principal ativa.
- RN-004 — PIM_SORT_ORDER define ordem de exibição.
- RN-005 — PIM_PUBLIC_ID deve ser CHAR(32).
- RN-006 — APIs externas usam PIM_PUBLIC_ID, nunca PIM_ID.
- RN-007 — A exclusão deve ser lógica via PIM_STATUS.

## Relacionamentos

- PRODUCT (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PIM_ID | NUMBER Identity | Sim |
| PIM_PUBLIC_ID | CHAR(32) | Sim |
| PRD_ID | NUMBER | Sim |
| PIM_URL | VARCHAR2(1000) | Sim |
| PIM_ALT_TEXT | VARCHAR2(200) | Não |
| PIM_SORT_ORDER | NUMBER | Sim |
| PIM_IS_PRIMARY | NUMBER(1) | Sim |
| PIM_STATUS | VARCHAR2(20) | Sim |
| PIM_CREATED_AT | TIMESTAMP | Sim |
| PIM_UPDATED_AT | TIMESTAMP | Sim |
| PIM_CREATED_BY | NUMBER | Não |
| PIM_UPDATED_BY | NUMBER | Não |

PIM_CREATED_BY e PIM_UPDATED_BY armazenam o ator técnico confiável e não
possuem foreign key para PROFILE.

## Índices

- PK_PRODUCT_IMAGE
- UK_PRODUCT_IMAGE_PUBLIC_ID
- IDX_PRODUCT_IMAGE_PRODUCT
- IDX_PRODUCT_IMAGE_PRIMARY
- IDX_PRODUCT_IMAGE_STATUS

## Packages Oracle

- PIM_RULE_PKG
- PIM_REPOSITORY_PKG
- PIM_SERVICE_PKG
- PIM_API_PKG

## APIs

- GET /product-images
- GET /product-images/{publicId}
- POST /product-images
- PATCH /product-images/{publicId}
- POST /product-images/{publicId}/deactivate

## Flutter

- ProductImageModel
- ProductImageRepository
- ProductImageController
- ProductImagePage

## Observações

PRODUCT_IMAGE é uma entidade de suporte do módulo Catálogo.

Ela representa as imagens associadas aos Achados, incluindo a imagem principal.

# PRODUCT_QUESTION

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PRODUCT_QUESTION |
| Prefixo | PQA |
| Tipo | SUPPORT |
| Responsável | Catálogo |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar perguntas públicas feitas por clientes em um Achado e as respectivas respostas fornecidas pelo Brechó.

## Classificação

SUPPORT

## Responsabilidades

- Registrar perguntas públicas feitas por clientes em um Achado.
- Registrar respostas fornecidas por um Profile autorizado a operar o STORE.
- Preservar o contexto de pré-venda associado ao Achado.
- Apoiar a transparência da comunicação entre cliente e Brechó.

## Não é responsabilidade

- Substituir STORE_REVIEW.
- Representar avaliação pós-venda.
- Armazenar dados pessoais sensíveis.
- Definir regras comerciais do pedido.

## Dono da Informação

Catálogo

## Regras de Negócio

- RN-001 — Toda PRODUCT_QUESTION pertence a um PRODUCT.
- RN-002 — Toda PRODUCT_QUESTION deve preservar o STORE responsável pelo PRODUCT.
- RN-003 — Um PROFILE pode fazer perguntas em vários PRODUCT.
- RN-004 — A resposta deve ser fornecida por um PROFILE autorizado a operar o STORE.
- RN-005 — A pergunta pode existir sem resposta.
- RN-006 — Perguntas e respostas ficam públicas para outros usuários quando ativas.
- RN-007 — Perguntas ofensivas, spam ou contendo dados pessoais podem ser moderadas.
- RN-008 — PRODUCT_QUESTION não substitui STORE_REVIEW.
- RN-009 — PRODUCT_QUESTION não representa avaliação pós-venda.
- RN-010 — PRODUCT_QUESTION faz parte do pré-venda.
- RN-011 — PQA_PUBLIC_ID deve ser CHAR(32).
- RN-012 — APIs externas usam PQA_PUBLIC_ID, nunca PQA_ID.
- RN-013 — A exclusão deve ser lógica via PQA_STATUS.

## Relacionamentos

- PRODUCT (N:1)
- STORE (N:1)
- PROFILE como autor da pergunta (N:1)
- PROFILE como autor da resposta (N:1 opcional)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PQA_ID | NUMBER Identity | Sim |
| PQA_PUBLIC_ID | CHAR(32) | Sim |
| PRD_ID | NUMBER | Sim |
| STR_ID | NUMBER | Sim |
| PFL_QUESTION_BY | NUMBER | Sim |
| PFL_ANSWERED_BY | NUMBER | Não |
| PQA_QUESTION_TEXT | VARCHAR2(4000) | Sim |
| PQA_ANSWER_TEXT | VARCHAR2(4000) | Não |
| PQA_ASKED_AT | TIMESTAMP | Sim |
| PQA_ANSWERED_AT | TIMESTAMP | Não |
| PQA_STATUS | VARCHAR2(20) | Sim |
| PQA_CREATED_AT | TIMESTAMP | Sim |
| PQA_UPDATED_AT | TIMESTAMP | Sim |
| PQA_CREATED_BY | NUMBER | Não |
| PQA_UPDATED_BY | NUMBER | Não |

PQA_CREATED_BY e PQA_UPDATED_BY armazenam o ator técnico confiável e não
possuem foreign key para PROFILE. PFL_QUESTION_BY e PFL_ANSWERED_BY são
participantes do domínio e, por isso, referenciam PROFILE.

PQA_STATUS aceita ACTIVE, HIDDEN e MODERATED. Resposta, autor e timestamp de
resposta são todos nulos ou todos preenchidos. A foreign key composta
(PRD_ID, STR_ID) garante que a STORE preservada seja a proprietária do PRODUCT.

## Índices

- PK_PRODUCT_QUESTION
- UK_PRODUCT_QUESTION_PUBLIC_ID
- IDX_PRODUCT_QUESTION_PRODUCT
- IDX_PRODUCT_QUESTION_STORE
- IDX_PRODUCT_QUESTION_QUESTION_BY
- IDX_PRODUCT_QUESTION_ANSWERED_BY
- IDX_PRODUCT_QUESTION_STATUS

## Packages Oracle

- PQA_RULE_PKG
- PQA_REPOSITORY_PKG
- PQA_SERVICE_PKG
- PQA_API_PKG

## APIs

- GET /product-questions
- GET /product-questions/{publicId}
- POST /product-questions
- POST /product-questions/{publicId}/answer
- POST /product-questions/{publicId}/moderate

## Flutter

- ProductQuestionModel
- ProductQuestionRepository
- ProductQuestionController
- ProductQuestionPage

## Observações

PRODUCT_QUESTION pertence ao módulo Catálogo e representa interação pública de pré-venda no Achado.

Ela complementa o contexto de descoberta e esclarecimento do produto, sem substituir avaliações ou feedback pós-venda.

# STORE_BALANCE_TRANSACTION

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | STORE_BALANCE_TRANSACTION |
| Prefixo | SBT |
| Tipo | TRANSACTION |
| Responsável | Financeiro |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Não |
| Cache | Não |

## Objetivo

Registrar cada movimentação financeira que afeta o saldo interno de um Brechó.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar créditos, débitos, bloqueios, liberações e payouts relacionados ao saldo do Brechó.
- Servir como livro razão financeiro do Brechó.
- Apoiar o cálculo do saldo disponível e do saldo bloqueado.

## Não é responsabilidade

- Alterar saldo manualmente.
- Substituir STORE_BALANCE.
- Representar uma solicitação de saque.
- Definir regras comerciais do pedido.

## Dono da Informação

Financeiro

## Regras de Negócio

- RN-001 — STORE_BALANCE_TRANSACTION é o livro razão financeiro do Brechó.
- RN-002 — Todo crédito, débito, comissão, taxa, bloqueio, liberação ou payout deve gerar uma movimentação.
- RN-003 — SBT_DIRECTION deve indicar CREDIT ou DEBIT.
- RN-004 — SBT_AMOUNT deve ser sempre positivo.
- RN-005 — O efeito no saldo é definido por SBT_DIRECTION.
- RN-006 — Movimentações não devem ser excluídas fisicamente.
- RN-007 — Movimentações não devem ser alteradas após consolidadas.
- RN-008 — SBT_AVAILABLE_AT indica quando o valor poderá compor saldo disponível.
- RN-009 — SBT_PUBLIC_ID deve ser CHAR(32).
- RN-010 — APIs externas usam SBT_PUBLIC_ID, nunca SBT_ID.

## Relacionamentos

- STORE (N:1)
- ORDER (N:1 opcional)
- PAYMENT (N:1 opcional)
- PAYOUT (N:1 opcional futuro)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| SBT_ID | NUMBER Identity | Sim |
| SBT_PUBLIC_ID | CHAR(32) | Sim |
| STR_ID | NUMBER | Sim |
| ORD_ID | NUMBER | Não |
| PAY_ID | NUMBER | Não |
| POT_ID | NUMBER | Não |
| SBT_TYPE | VARCHAR2(50) | Sim |
| SBT_AMOUNT | NUMBER(12,2) | Sim |
| SBT_DIRECTION | VARCHAR2(10) | Sim |
| SBT_AVAILABLE_AT | TIMESTAMP | Não |
| SBT_DESCRIPTION | VARCHAR2(1000) | Não |
| SBT_STATUS | VARCHAR2(20) | Sim |
| SBT_CREATED_AT | TIMESTAMP | Sim |
| SBT_UPDATED_AT | TIMESTAMP | Sim |
| SBT_CREATED_BY | NUMBER | Não |
| SBT_UPDATED_BY | NUMBER | Não |

SBT_CREATED_BY e SBT_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_STORE_BALANCE_TRANSACTION
- UK_STORE_BALANCE_TRANSACTION_PUBLIC_ID
- IDX_STORE_BALANCE_TRANSACTION_STORE
- IDX_STORE_BALANCE_TRANSACTION_ORDER
- IDX_STORE_BALANCE_TRANSACTION_PAYMENT
- IDX_STORE_BALANCE_TRANSACTION_STATUS

## Packages Oracle

- SBT_SERVICE_PKG
- SBT_REPOSITORY_PKG
- SBT_RULE_PKG

## APIs

Nenhuma API pública prevista no MVP.

## Flutter

Uso interno para o módulo financeiro.

## Observações

STORE_BALANCE_TRANSACTION representa o livro razão financeiro interno do Brechó Express.

Cada alteração de saldo deve ser registrada através desta entidade, preservando rastreabilidade e auditoria.

# STORE_BALANCE

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | STORE_BALANCE |
| Prefixo | SBL |
| Tipo | SUPPORT |
| Responsável | Financeiro |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar o resumo financeiro atual de um Brechó, derivado das movimentações do livro razão.

## Classificação

SUPPORT

## Responsabilidades

- Resumir os valores bloqueados, disponíveis, pendentes e pagos de um Brechó.
- Servir como visão consolidada do estado financeiro do Brechó.
- Apoiar consultas de saldo e repasses.

## Não é responsabilidade

- Substituir STORE_BALANCE_TRANSACTION.
- Ser alterado manualmente sem movimentação correspondente.
- Representar uma solicitação de saque.

## Dono da Informação

Financeiro

## Regras de Negócio

- RN-001 — STORE_BALANCE representa um resumo derivado de STORE_BALANCE_TRANSACTION.
- RN-002 — Um STORE deve possuir no máximo um STORE_BALANCE ativo.
- RN-003 — Saldos não devem ser alterados manualmente sem movimentação correspondente.
- RN-004 — SBL_BLOCKED_AMOUNT representa valores ainda em retenção.
- RN-005 — SBL_AVAILABLE_AMOUNT representa valores liberados para saque.
- RN-006 — SBL_PENDING_PAYOUT_AMOUNT representa valores em solicitação de saque.
- RN-007 — SBL_PAID_AMOUNT representa valores já repassados ao Brechó.
- RN-008 — STORE_BALANCE não substitui STORE_BALANCE_TRANSACTION.
- RN-009 — SBL_PUBLIC_ID deve ser CHAR(32).
- RN-010 — APIs externas usam SBL_PUBLIC_ID, nunca SBL_ID.

## Relacionamentos

- STORE (1:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| SBL_ID | NUMBER Identity | Sim |
| SBL_PUBLIC_ID | CHAR(32) | Sim |
| STR_ID | NUMBER | Sim |
| SBL_BLOCKED_AMOUNT | NUMBER(12,2) | Sim |
| SBL_AVAILABLE_AMOUNT | NUMBER(12,2) | Sim |
| SBL_PENDING_PAYOUT_AMOUNT | NUMBER(12,2) | Sim |
| SBL_PAID_AMOUNT | NUMBER(12,2) | Sim |
| SBL_STATUS | VARCHAR2(20) | Sim |
| SBL_CREATED_AT | TIMESTAMP | Sim |
| SBL_UPDATED_AT | TIMESTAMP | Sim |
| SBL_CREATED_BY | NUMBER | Não |
| SBL_UPDATED_BY | NUMBER | Não |

SBL_CREATED_BY e SBL_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_STORE_BALANCE
- UK_STORE_BALANCE_PUBLIC_ID
- UK_STORE_BALANCE_STORE
- IDX_STORE_BALANCE_STATUS

## Packages Oracle

- SBL_API_PKG
- SBL_QUERY_PKG

## APIs

- GET /store-balances
- GET /store-balances/{publicId}
- PUT /store-balances/{publicId}

## Flutter

- StoreBalanceModel
- StoreBalanceRepository
- StoreBalanceController
- StoreBalancePage

## Observações

STORE_BALANCE é o resumo financeiro consolidado de um Brechó.

Ele é derivado das movimentações registradas em STORE_BALANCE_TRANSACTION e não substitui o livro razão financeiro.

# COMMISSION

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | COMMISSION |
| Prefixo | COM |
| Tipo | TRANSACTION |
| Responsável | Financeiro |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Não |
| Cache | Não |

## Objetivo

Registrar a comissão da plataforma e taxas descontadas do saldo do Brechó.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar os descontos financeiros aplicados ao Brechó.
- Documentar a base de cálculo, a comissão e as taxas do gateway.
- Gerar a movimentação financeira correspondente no saldo interno.

## Não é responsabilidade

- Alterar saldo manualmente.
- Substituir STORE_BALANCE_TRANSACTION.
- Definir regras de negócio de pedido.

## Dono da Informação

Financeiro

## Regras de Negócio

- RN-001 — COMMISSION registra os descontos financeiros aplicados ao Brechó.
- RN-002 — A comissão da plataforma é descontada do valor do Brechó.
- RN-003 — A taxa do Gateway também é descontada do valor do Brechó.
- RN-004 — COM_BASE_AMOUNT representa a base de cálculo.
- RN-005 — COM_COMMISSION_AMOUNT representa o valor da comissão da plataforma.
- RN-006 — COM_GATEWAY_FEE_AMOUNT representa a taxa do gateway.
- RN-007 — COM_NET_AMOUNT representa o valor líquido destinado ao Brechó.
- RN-008 — COMMISSION deve gerar movimentações correspondentes em STORE_BALANCE_TRANSACTION.
- RN-009 — COM_PUBLIC_ID deve ser CHAR(32).
- RN-010 — APIs externas usam COM_PUBLIC_ID, nunca COM_ID.

## Relacionamentos

- STORE (N:1)
- ORDER (N:1)
- PAYMENT (N:1 opcional)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| COM_ID | NUMBER Identity | Sim |
| COM_PUBLIC_ID | CHAR(32) | Sim |
| STR_ID | NUMBER | Sim |
| ORD_ID | NUMBER | Sim |
| PAY_ID | NUMBER | Não |
| COM_BASE_AMOUNT | NUMBER(12,2) | Sim |
| COM_COMMISSION_RATE | NUMBER(5,2) | Não |
| COM_COMMISSION_AMOUNT | NUMBER(12,2) | Sim |
| COM_GATEWAY_FEE_AMOUNT | NUMBER(12,2) | Sim |
| COM_NET_AMOUNT | NUMBER(12,2) | Sim |
| COM_STATUS | VARCHAR2(20) | Sim |
| COM_CREATED_AT | TIMESTAMP | Sim |
| COM_UPDATED_AT | TIMESTAMP | Sim |
| COM_CREATED_BY | NUMBER | Não |
| COM_UPDATED_BY | NUMBER | Não |

COM_CREATED_BY e COM_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_COMMISSION
- UK_COMMISSION_PUBLIC_ID
- IDX_COMMISSION_STORE
- IDX_COMMISSION_ORDER
- IDX_COMMISSION_PAYMENT
- IDX_COMMISSION_STATUS

## Packages Oracle

- COM_SERVICE_PKG
- COM_REPOSITORY_PKG
- COM_RULE_PKG

## APIs

Nenhuma API pública prevista no MVP.

## Flutter

Uso interno para o módulo financeiro.

## Observações

COMMISSION registra os descontos financeiros aplicados ao Brechó e preserva rastreabilidade do cálculo de repasse.

# PAYOUT

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PAYOUT |
| Prefixo | POT |
| Tipo | TRANSACTION |
| Responsável | Financeiro |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar uma solicitação de saque/repasse PIX feita por um Brechó.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar solicitações de repasse ao Brechó.
- Controlar o estado da solicitação de saque.
- Apoiar o fluxo manual de pagamento ao Brechó.

## Não é responsabilidade

- Alterar saldo diretamente.
- Substituir STORE_BALANCE_TRANSACTION.
- Processar pagamentos bancários automaticamente.

## Dono da Informação

Financeiro

## Regras de Negócio

- RN-001 — PAYOUT representa uma solicitação de repasse ao Brechó.
- RN-002 — PAYOUT só pode ser solicitado se houver saldo disponível suficiente.
- RN-003 — Ao solicitar PAYOUT, o valor deve sair de saldo disponível e ir para saldo em payout pendente.
- RN-004 — Quando pago, o valor deve ser marcado como repassado.
- RN-005 — Quando rejeitado, o valor deve retornar ao saldo disponível.
- RN-006 — PAYOUT inicialmente será processado manualmente.
- RN-007 — Futuramente poderá ser processado automaticamente por API bancária ou gateway.
- RN-008 — POT_PUBLIC_ID deve ser CHAR(32).
- RN-009 — APIs externas usam POT_PUBLIC_ID, nunca POT_ID.
- RN-010 — Exclusão deve ser lógica via POT_STATUS.

## Relacionamentos

- STORE (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| POT_ID | NUMBER Identity | Sim |
| POT_PUBLIC_ID | CHAR(32) | Sim |
| STR_ID | NUMBER | Sim |
| POT_AMOUNT | NUMBER(12,2) | Sim |
| POT_PIX_KEY | VARCHAR2(200) | Sim |
| POT_PIX_KEY_TYPE | VARCHAR2(20) | Sim |
| POT_REQUESTED_AT | TIMESTAMP | Sim |
| POT_APPROVED_AT | TIMESTAMP | Não |
| POT_PAID_AT | TIMESTAMP | Não |
| POT_REJECTED_AT | TIMESTAMP | Não |
| POT_REJECT_REASON | VARCHAR2(1000) | Não |
| POT_STATUS | VARCHAR2(20) | Sim |
| POT_CREATED_AT | TIMESTAMP | Sim |
| POT_UPDATED_AT | TIMESTAMP | Sim |
| POT_CREATED_BY | NUMBER | Não |
| POT_UPDATED_BY | NUMBER | Não |

POT_CREATED_BY e POT_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_PAYOUT
- UK_PAYOUT_PUBLIC_ID
- IDX_PAYOUT_STORE
- IDX_PAYOUT_STATUS
- IDX_PAYOUT_REQUESTED_AT

## Packages Oracle

- POT_API_PKG
- POT_SERVICE_PKG
- POT_REPOSITORY_PKG
- POT_RULE_PKG

## APIs

- GET /payouts
- GET /payouts/{publicId}
- POST /payouts
- PUT /payouts/{publicId}

## Flutter

- PayoutModel
- PayoutRepository
- PayoutController
- PayoutPage

## Observações

PAYOUT representa a solicitação de repasse ao Brechó e é o ponto de entrada do fluxo de saque inicial do módulo financeiro.

Ele depende do saldo disponível consolidado e do livro razão financeiro para garantir consistência do fluxo.

# CART

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | CART |
| Prefixo | CRT |
| Tipo | TRANSACTION |
| Responsável | Compra |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar o carrinho temporário de um Profile, registrando a intenção de compra antes da confirmação comercial.

O carrinho pode expirar automaticamente, sem reservar produtos, e carrinhos expirados podem ser descartados por processo automático.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar a intenção de compra de um Profile.
- Agrupar os itens escolhidos para futura análise comercial.
- Apoiar a criação de uma Purchase Request.
- Representar o estado temporário do processo de compra.
- Suportar a expiração automática de carrinhos sem reservar produtos.

## Não é responsabilidade

- Reservar estoque.
- Confirmar pagamento.
- Substituir a entidade PURCHASE_REQUEST.
- Substituir a entidade ORDER.

## Dono da Informação

Compra

## Regras de Negócio

- RN-001 — CART representa intenção de compra.
- RN-002 — Um PROFILE pode possuir um CART ativo.
- RN-003 — CART nunca reserva PRODUCT.
- RN-004 — CART pode possuir vários CART_ITEM.
- RN-005 — O carrinho pode expirar automaticamente.
- RN-006 — A expiração não reserva produtos.
- RN-007 — Carrinhos expirados podem ser descartados por processo automático.
- RN-008 — CRT_PUBLIC_ID deve ser CHAR(32).
- RN-009 — APIs externas usam CRT_PUBLIC_ID, nunca CRT_ID.
- RN-010 — A exclusão deve ser lógica via CRT_STATUS.

## Relacionamentos

- PROFILE (N:1)
- CART_ITEM (1:N)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| CRT_ID | NUMBER Identity | Sim |
| CRT_PUBLIC_ID | CHAR(32) | Sim |
| PFL_ID | NUMBER | Sim |
| CRT_STATUS | VARCHAR2(20) | Sim |
| CRT_EXPIRES_AT | TIMESTAMP | Não |
| CRT_CREATED_AT | TIMESTAMP | Sim |
| CRT_UPDATED_AT | TIMESTAMP | Sim |
| CRT_CREATED_BY | NUMBER | Não |
| CRT_UPDATED_BY | NUMBER | Não |

CRT_CREATED_BY e CRT_UPDATED_BY são identificadores técnicos de auditoria e não
possuem foreign key. A participação de domínio é protegida por PFL_ID.

## Índices

- PK_CART
- UK_CART_PUBLIC_ID
- IDX_CART_PROFILE
- IDX_CART_STATUS
- UK_CART_ACTIVE_PROFILE

## Packages Oracle

- CRT_API_PKG
- CRT_SERVICE_PKG
- CRT_REPOSITORY_PKG
- CRT_RULE_PKG

## APIs

- GET /carts
- GET /carts/{publicId}
- POST /carts
- PUT /carts/{publicId}

## Flutter

- CartModel
- CartRepository
- CartController
- CartPage

## Observações

CART é uma entidade transacional do módulo Compra.

Ele representa intenção de compra, não confirmação comercial nem reserva de estoque.

# CART_ITEM

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | CART_ITEM |
| Prefixo | CTI |
| Tipo | TRANSACTION |
| Responsável | Compra |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar um Achado selecionado por um Profile dentro do carrinho.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar um PRODUCT incluído no carrinho.
- Manter a quantidade selecionada pelo cliente.
- Preservar o preço estimado no momento da inclusão.
- Apoiar a transformação do carrinho em Purchase Request.

## Não é responsabilidade

- Reservar estoque.
- Confirmar compra.
- Substituir a entidade PRODUCT.
- Substituir a entidade PURCHASE_REQUEST_ITEM.

## Dono da Informação

Compra

## Regras de Negócio

- RN-001 — CART_ITEM representa um PRODUCT selecionado pelo cliente.
- RN-002 — CART_ITEM não reserva estoque.
- RN-003 — A quantidade deve ser maior que zero.
- RN-004 — O preço registrado é uma estimativa no momento da inclusão.
- RN-005 — Um CART pode possuir vários CART_ITEM.
- RN-006 — CTI_PUBLIC_ID deve ser CHAR(32).
- RN-007 — APIs externas usam CTI_PUBLIC_ID, nunca CTI_ID.
- RN-008 — A exclusão deve ser lógica via CTI_STATUS.

## Relacionamentos

- CART (N:1)
- PRODUCT (N:1)
- STORE (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| CTI_ID | NUMBER Identity | Sim |
| CTI_PUBLIC_ID | CHAR(32) | Sim |
| CRT_ID | NUMBER | Sim |
| PRD_ID | NUMBER | Sim |
| STR_ID | NUMBER | Sim |
| CTI_QUANTITY | NUMBER | Sim |
| CTI_UNIT_PRICE | NUMBER(12,2) | Sim |
| CTI_STATUS | VARCHAR2(20) | Sim |
| CTI_CREATED_AT | TIMESTAMP | Sim |
| CTI_UPDATED_AT | TIMESTAMP | Sim |
| CTI_CREATED_BY | NUMBER | Não |
| CTI_UPDATED_BY | NUMBER | Não |

CTI_CREATED_BY e CTI_UPDATED_BY são identificadores técnicos de auditoria e não
possuem foreign key. O PRODUCT e sua STORE são protegidos por foreign key
composta.

## Índices

- PK_CART_ITEM
- UK_CART_ITEM_PUBLIC_ID
- IDX_CART_ITEM_CART
- IDX_CART_ITEM_PRODUCT
- IDX_CART_ITEM_STORE
- IDX_CART_ITEM_STATUS
- UK_CART_ITEM_ACTIVE_PRODUCT

## Packages Oracle

- CRT_API_PKG
- CRT_SERVICE_PKG
- CRT_REPOSITORY_PKG
- CRT_RULE_PKG

## APIs

- GET /cart-items
- GET /cart-items/{publicId}
- POST /cart-items
- PUT /cart-items/{publicId}

## Flutter

- CartItemModel
- CartItemRepository
- CartItemController
- CartItemPage

## Observações

CART_ITEM é uma entidade transacional do módulo Compra.

Ele representa a seleção de um Achado pelo cliente dentro de um carrinho temporário.

# PURCHASE_REQUEST

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PURCHASE_REQUEST |
| Prefixo | PUR |
| Tipo | TRANSACTION |
| Responsável | Compra |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar a solicitação de compra enviada ao Brechó para confirmação de disponibilidade antes do pagamento.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar uma solicitação de compra derivada do carrinho.
- Verificar disponibilidade com o Brechó antes do pagamento.
- Apoiar a confirmação parcial ou total dos itens.
- Servir de base para o nascimento de um Pedido.
- Registrar a resposta do Brechó, independentemente do resultado.

## Não é responsabilidade

- Confirmar pagamento.
- Reservar estoque de forma definitiva.
- Substituir a entidade ORDER.
- Substituir a entidade CART.

## Dono da Informação

Compra

## Regras de Negócio

- RN-001 — PURCHASE_REQUEST nasce a partir do checkout do CART.
- RN-002 — PURCHASE_REQUEST verifica disponibilidade antes do pagamento.
- RN-003 — PURCHASE_REQUEST pode envolver itens de vários STORE.
- RN-004 — PURCHASE_REQUEST pode ser confirmada total ou parcialmente.
- RN-005 — A resposta do Brechó pode ser aprovada, parcialmente aprovada ou recusada.
- RN-006 — PUR_CONFIRMED_AT representa apenas confirmação total.
- RN-007 — PUR_RESPONSE_AT representa o momento em que o Brechó respondeu à solicitação, independentemente do resultado.
- RN-008 — Pagamento só ocorre após confirmação.
- RN-009 — PUR_PUBLIC_ID deve ser CHAR(32).
- RN-010 — APIs externas usam PUR_PUBLIC_ID, nunca PUR_ID.
- RN-011 — A exclusão deve ser lógica via PUR_STATUS.

## Relacionamentos

- PROFILE (N:1)
- PURCHASE_REQUEST_ITEM (1:N)
- ORDER (1:1 futuro)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PUR_ID | NUMBER Identity | Sim |
| PUR_PUBLIC_ID | CHAR(32) | Sim |
| PFL_ID | NUMBER | Sim |
| PUR_STATUS | VARCHAR2(30) | Sim |
| PUR_REQUESTED_AT | TIMESTAMP | Sim |
| PUR_CONFIRMED_AT | TIMESTAMP | Não |
| PUR_RESPONSE_AT | TIMESTAMP | Não |
| PUR_EXPIRES_AT | TIMESTAMP | Não |
| PUR_CREATED_AT | TIMESTAMP | Sim |
| PUR_UPDATED_AT | TIMESTAMP | Sim |
| PUR_CREATED_BY | NUMBER | Não |
| PUR_UPDATED_BY | NUMBER | Não |

PUR_CREATED_BY e PUR_UPDATED_BY são identificadores técnicos de auditoria e não
possuem foreign key. A participação de domínio é protegida por PFL_ID.

## Índices

- PK_PURCHASE_REQUEST
- UK_PURCHASE_REQUEST_PUBLIC_ID
- IDX_PURCHASE_REQUEST_PROFILE
- IDX_PURCHASE_REQUEST_STATUS
- IDX_PURCHASE_REQUEST_REQUESTED_AT

## Packages Oracle

- PUR_API_PKG
- PUR_SERVICE_PKG
- PUR_REPOSITORY_PKG
- PUR_RULE_PKG

## APIs

- GET /purchase-requests
- GET /purchase-requests/{publicId}
- POST /purchase-requests
- PUT /purchase-requests/{publicId}

## Flutter

- PurchaseRequestModel
- PurchaseRequestRepository
- PurchaseRequestController
- PurchaseRequestPage

## Observações

PURCHASE_REQUEST é uma entidade transacional do módulo Compra.

Ela representa a etapa de confirmação comercial e disponibilidade antes da criação do pedido definitivo.

# PURCHASE_REQUEST_ITEM

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PURCHASE_REQUEST_ITEM |
| Prefixo | PRI |
| Tipo | TRANSACTION |
| Responsável | Compra |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar cada item solicitado dentro de uma Purchase Request, preservando o contexto da solicitação e da confirmação.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar um PRODUCT solicitado pelo cliente.
- Preservar a quantidade solicitada e a quantidade confirmada.
- Apoiar a confirmação parcial ou recusa de itens.
- Servir como base para a criação de ORDER_ITEM.
- Registrar recusas individuais de itens quando houver motivo específico.

## Não é responsabilidade

- Confirmar pagamento.
- Substituir a entidade PRODUCT.
- Substituir a entidade ORDER_ITEM.

## Dono da Informação

Compra

## Regras de Negócio

- RN-001 — PURCHASE_REQUEST_ITEM representa um PRODUCT solicitado.
- RN-002 — A quantidade confirmada pode ser menor que a solicitada.
- RN-003 — Um item pode ser recusado individualmente pelo Brechó.
- RN-004 — O preço deve ser registrado no momento da solicitação.
- RN-005 — PRI_REJECT_REASON pode registrar motivos como Produto indisponível, Produto vendido na loja física, Produto reservado ou Produto danificado.
- RN-006 — PRI_PUBLIC_ID deve ser CHAR(32).
- RN-007 — APIs externas usam PRI_PUBLIC_ID, nunca PRI_ID.
- RN-008 — A exclusão deve ser lógica via PRI_STATUS.

## Relacionamentos

- PURCHASE_REQUEST (N:1)
- PRODUCT (N:1)
- STORE (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PRI_ID | NUMBER Identity | Sim |
| PRI_PUBLIC_ID | CHAR(32) | Sim |
| PUR_ID | NUMBER | Sim |
| PRD_ID | NUMBER | Sim |
| STR_ID | NUMBER | Sim |
| PRI_REQUESTED_QUANTITY | NUMBER | Sim |
| PRI_CONFIRMED_QUANTITY | NUMBER | Não |
| PRI_UNIT_PRICE | NUMBER(12,2) | Sim |
| PRI_REJECT_REASON | VARCHAR2(500) | Não |
| PRI_STATUS | VARCHAR2(30) | Sim |
| PRI_CREATED_AT | TIMESTAMP | Sim |
| PRI_UPDATED_AT | TIMESTAMP | Sim |
| PRI_CREATED_BY | NUMBER | Não |
| PRI_UPDATED_BY | NUMBER | Não |

PRI_CREATED_BY e PRI_UPDATED_BY são identificadores técnicos de auditoria e não
possuem foreign key. O PRODUCT e sua STORE são protegidos por foreign key
composta.

## Índices

- PK_PURCHASE_REQUEST_ITEM
- UK_PURCHASE_REQUEST_ITEM_PUBLIC_ID
- IDX_PURCHASE_REQUEST_ITEM_REQUEST
- IDX_PURCHASE_REQUEST_ITEM_PRODUCT
- IDX_PURCHASE_REQUEST_ITEM_STORE
- IDX_PURCHASE_REQUEST_ITEM_STATUS

## Packages Oracle

- PUR_API_PKG
- PUR_SERVICE_PKG
- PUR_REPOSITORY_PKG
- PUR_RULE_PKG

## APIs

- GET /purchase-request-items
- GET /purchase-request-items/{publicId}
- POST /purchase-request-items
- PUT /purchase-request-items/{publicId}

## Flutter

- PurchaseRequestItemModel
- PurchaseRequestItemRepository
- PurchaseRequestItemController
- PurchaseRequestItemPage

## Observações

PURCHASE_REQUEST_ITEM é uma entidade transacional do módulo Compra.

Ela representa cada item solicitado dentro da confirmação comercial anterior ao pedido final.

# ORDER

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | ORDER |
| Prefixo | ORD |
| Tipo | TRANSACTION |
| Responsável | Compra |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar o pedido confirmado após pagamento aprovado, consolidando os itens efetivamente aceitos pelo processo comercial.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar um pedido confirmado após pagamento aprovado.
- Consolidar os itens aceitos comercialmente.
- Servir de base para logística e pós-venda.
- Relacionar um pedido a uma Purchase Request confirmada.
- Preservar a composição do valor final com subtotal, desconto e frete.

## Não é responsabilidade

- Confirmar disponibilidade de forma independente.
- Substituir a entidade PURCHASE_REQUEST.
- Substituir a entidade PAYMENT.

## Dono da Informação

Compra

## Regras de Negócio

- RN-001 — ORDER nasce somente após pagamento aprovado.
- RN-002 — ORDER deve estar associado a uma PURCHASE_REQUEST confirmada.
- RN-003 — ORDER pode conter itens de vários STORE.
- RN-004 — ORDER pode gerar vários SHIPMENT.
- RN-005 — ORD_NUMBER deve ser único.
- RN-006 — ORD_PUBLIC_ID deve ser CHAR(32).
- RN-007 — APIs externas usam ORD_PUBLIC_ID, nunca ORD_ID.
- RN-008 — A exclusão deve ser lógica via ORD_STATUS.

## Relacionamentos

- PROFILE (N:1)
- PURCHASE_REQUEST (1:1)
- ORDER_ITEM (1:N)
- PAYMENT (1:N futuro)
- SHIPMENT (1:N futuro)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| ORD_ID | NUMBER Identity | Sim |
| ORD_PUBLIC_ID | CHAR(32) | Sim |
| PUR_ID | NUMBER | Sim |
| PFL_ID | NUMBER | Sim |
| ORD_NUMBER | VARCHAR2(50) | Sim |
| ORD_SUBTOTAL_AMOUNT | NUMBER(12,2) | Sim |
| ORD_DISCOUNT_AMOUNT | NUMBER(12,2) | Sim |
| ORD_SHIPPING_AMOUNT | NUMBER(12,2) | Sim |
| ORD_TOTAL_AMOUNT | NUMBER(12,2) | Sim |
| ORD_STATUS | VARCHAR2(20) | Sim |
| ORD_PAID_AT | TIMESTAMP | Não |
| ORD_CREATED_AT | TIMESTAMP | Sim |
| ORD_UPDATED_AT | TIMESTAMP | Sim |
| ORD_CREATED_BY | NUMBER | Não |
| ORD_UPDATED_BY | NUMBER | Não |

ORD_CREATED_BY e ORD_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_ORDER
- UK_ORDER_PUBLIC_ID
- UK_ORDER_NUMBER
- IDX_ORDER_PROFILE
- IDX_ORDER_PURCHASE_REQUEST
- IDX_ORDER_STATUS

## Packages Oracle

- ORD_API_PKG
- ORD_SERVICE_PKG
- ORD_REPOSITORY_PKG
- ORD_RULE_PKG

## APIs

- GET /orders
- GET /orders/{publicId}
- POST /orders
- PUT /orders/{publicId}

## Flutter

- OrderModel
- OrderRepository
- OrderController
- OrderPage

## Observações

ORDER é uma entidade transacional do módulo Compra.

Ela representa o pedido final após confirmação comercial e aprovação de pagamento.

# ORDER_ITEM

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | ORDER_ITEM |
| Prefixo | ORI |
| Tipo | TRANSACTION |
| Responsável | Compra |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar cada item confirmado dentro de um pedido, preservando a quantidade, o preço e o fornecedor.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar um PRODUCT confirmado em um pedido.
- Preservar a quantidade, o preço e o valor total do item.
- Manter a referência ao STORE fornecedor.
- Servir como base para logística e pós-venda.
- Suportar desconto próprio por item quando houver regra comercial aplicável.

## Não é responsabilidade

- Confirmar pagamento.
- Substituir a entidade PRODUCT.
- Substituir a entidade SHIPMENT.

## Dono da Informação

Compra

## Regras de Negócio

- RN-001 — ORDER_ITEM representa um PRODUCT confirmado no pedido.
- RN-002 — ORDER_ITEM deve refletir a quantidade confirmada da Purchase Request.
- RN-003 — ORI_TOTAL_PRICE deve representar quantidade vezes preço unitário.
- RN-004 — ORDER_ITEM preserva o STORE fornecedor.
- RN-005 — ORI_PUBLIC_ID deve ser CHAR(32).
- RN-006 — APIs externas usam ORI_PUBLIC_ID, nunca ORI_ID.
- RN-007 — A exclusão deve ser lógica via ORI_STATUS.

## Relacionamentos

- ORDER (N:1)
- PRODUCT (N:1)
- STORE (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| ORI_ID | NUMBER Identity | Sim |
| ORI_PUBLIC_ID | CHAR(32) | Sim |
| ORD_ID | NUMBER | Sim |
| PRD_ID | NUMBER | Sim |
| STR_ID | NUMBER | Sim |
| ORI_QUANTITY | NUMBER | Sim |
| ORI_UNIT_PRICE | NUMBER(12,2) | Sim |
| ORI_DISCOUNT_AMOUNT | NUMBER(12,2) | Não |
| ORI_TOTAL_PRICE | NUMBER(12,2) | Sim |
| ORI_STATUS | VARCHAR2(20) | Sim |
| ORI_CREATED_AT | TIMESTAMP | Sim |
| ORI_UPDATED_AT | TIMESTAMP | Sim |
| ORI_CREATED_BY | NUMBER | Não |
| ORI_UPDATED_BY | NUMBER | Não |

ORI_CREATED_BY e ORI_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_ORDER_ITEM
- UK_ORDER_ITEM_PUBLIC_ID
- IDX_ORDER_ITEM_ORDER
- IDX_ORDER_ITEM_PRODUCT
- IDX_ORDER_ITEM_STORE
- IDX_ORDER_ITEM_STATUS

## Packages Oracle

- ORI_API_PKG
- ORI_RULE_PKG

## APIs

- GET /order-items
- GET /order-items/{publicId}
- POST /order-items
- PUT /order-items/{publicId}

## Flutter

- OrderItemModel
- OrderItemRepository
- OrderItemController
- OrderItemPage

## Observações

ORDER_ITEM é uma entidade transacional do módulo Compra.

Ela representa cada item confirmado dentro de um pedido final após a confirmação comercial.

# SHIPMENT

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | SHIPMENT |
| Prefixo | SHP |
| Tipo | TRANSACTION |
| Responsável | Logística |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar uma remessa gerada a partir de um Order, controlando o fluxo operacional da entrega.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar uma remessa operacional derivada de um pedido.
- Associar uma remessa a um Order, Store, endereço e perfil de entrega.
- Acompanhar o ciclo logístico da entrega.
- Servir de base para rastreio e execução operacional.

## Não é responsabilidade

- Representar um pedido completo.
- Substituir ORDER.
- Definir regras comerciais.
- Armazenar dados pessoais sensíveis.

## Dono da Informação

Logística

## Regras de Negócio

- RN-001 — Um ORDER pode gerar vários SHIPMENT.
- RN-002 — Um SHIPMENT pertence a um ORDER.
- RN-003 — Um SHIPMENT pode estar associado a um STORE fornecedor.
- RN-004 — Um SHIPMENT deve possuir endereço de destino.
- RN-005 — Um SHIPMENT deve possuir um DELIVERY_PROFILE.
- RN-006 — A modalidade de entrega é definida no SHIPMENT.
- RN-007 — A escolha da entrega pode ser automática ou manual.
- RN-008 — A escolha pode considerar distância, endereço, peso, volume, disponibilidade do provedor e regra operacional do Brechó.
- RN-009 — SHIPMENT representa a entrega concreta aplicada ao pedido.
- RN-010 — DELIVERY_PROFILE representa a modalidade/configuração de entrega.
- RN-011 — Futuramente, SHIPMENT poderá se relacionar com CARRIER para representar o provedor logístico executor.
- RN-012 — SHIPMENT controla o fluxo logístico da entrega.
- RN-013 — SHP_PUBLIC_ID deve ser CHAR(32).
- RN-014 — APIs externas usam SHP_PUBLIC_ID, nunca SHP_ID.
- RN-015 — A exclusão deve ser lógica via SHP_STATUS.

## Relacionamentos

- ORDER (N:1)
- STORE (N:1)
- ADDRESS (N:1)
- DELIVERY_PROFILE (N:1)
- SHIPMENT_ITEM (1:N)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| SHP_ID | NUMBER Identity | Sim |
| SHP_PUBLIC_ID | CHAR(32) | Sim |
| ORD_ID | NUMBER | Sim |
| STR_ID | NUMBER | Sim |
| ADR_ID | NUMBER | Sim |
| DLP_ID | NUMBER | Sim |
| SHP_TRACKING_CODE | VARCHAR2(100) | Não |
| SHP_ESTIMATED_DELIVERY_AT | TIMESTAMP | Não |
| SHP_DELIVERED_AT | TIMESTAMP | Não |
| SHP_STATUS | VARCHAR2(20) | Sim |
| SHP_CREATED_AT | TIMESTAMP | Sim |
| SHP_UPDATED_AT | TIMESTAMP | Sim |
| SHP_CREATED_BY | NUMBER | Não |
| SHP_UPDATED_BY | NUMBER | Não |

SHP_CREATED_BY e SHP_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_SHIPMENT
- UK_SHIPMENT_PUBLIC_ID
- IDX_SHIPMENT_ORDER
- IDX_SHIPMENT_STORE
- IDX_SHIPMENT_ADDRESS
- IDX_SHIPMENT_DELIVERY_PROFILE
- IDX_SHIPMENT_STATUS

## Packages Oracle

- SHP_API_PKG
- SHP_SERVICE_PKG
- SHP_REPOSITORY_PKG
- SHP_RULE_PKG

## APIs

- GET /shipments
- GET /shipments/{publicId}
- POST /shipments
- PUT /shipments/{publicId}

## Flutter

- ShipmentModel
- ShipmentRepository
- ShipmentController
- ShipmentPage

## Observações

SHIPMENT é uma entidade transacional do módulo Logística.

Ela representa a remessa operacional concreta gerada a partir de um pedido.

SHIPMENT é o ponto onde a decisão logística é aplicada ao pedido. Um mesmo pedido pode gerar diferentes remessas com perfis de entrega distintos.

Futuramente SHIPMENT poderá registrar eventos operacionais através da entidade SHIPMENT_EVENT, permitindo integração com provedores logísticos externos e histórico completo do ciclo de entrega.

A execução física da entrega poderá ser realizada por diferentes provedores logísticos, mantendo SHIPMENT desacoplado de integrações específicas.

# SHIPMENT_ITEM

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | SHIPMENT_ITEM |
| Prefixo | SHI |
| Tipo | TRANSACTION |
| Responsável | Logística |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar os itens de pedido incluídos em uma remessa, vinculando itens concretos a uma entrega operacional.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar quais ORDER_ITEM fazem parte de uma SHIPMENT.
- Acompanhar a quantidade enviada em cada remessa.
- Apoiar a execução operacional da logística.
- Manter a rastreabilidade da entrega.

## Não é responsabilidade

- Definir o pedido completo.
- Substituir ORDER_ITEM.
- Substituir PRODUCT.

## Dono da Informação

Logística

## Regras de Negócio

- RN-001 — SHIPMENT_ITEM representa um ORDER_ITEM dentro de um SHIPMENT.
- RN-002 — Um SHIPMENT pode possuir vários SHIPMENT_ITEM.
- RN-003 — Um ORDER_ITEM pode estar em apenas um SHIPMENT ativo.
- RN-004 — A quantidade enviada deve ser maior que zero.
- RN-005 — SHI_PUBLIC_ID deve ser CHAR(32).
- RN-006 — APIs externas usam SHI_PUBLIC_ID, nunca SHI_ID.
- RN-007 — A exclusão deve ser lógica via SHI_STATUS.

## Relacionamentos

- SHIPMENT (N:1)
- ORDER_ITEM (N:1)
- PRODUCT (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| SHI_ID | NUMBER Identity | Sim |
| SHI_PUBLIC_ID | CHAR(32) | Sim |
| SHP_ID | NUMBER | Sim |
| ORI_ID | NUMBER | Sim |
| PRD_ID | NUMBER | Sim |
| SHI_QUANTITY | NUMBER | Sim |
| SHI_STATUS | VARCHAR2(20) | Sim |
| SHI_CREATED_AT | TIMESTAMP | Sim |
| SHI_UPDATED_AT | TIMESTAMP | Sim |
| SHI_CREATED_BY | NUMBER | Não |
| SHI_UPDATED_BY | NUMBER | Não |

SHI_CREATED_BY e SHI_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_SHIPMENT_ITEM
- UK_SHIPMENT_ITEM_PUBLIC_ID
- IDX_SHIPMENT_ITEM_SHIPMENT
- IDX_SHIPMENT_ITEM_ORDER_ITEM
- IDX_SHIPMENT_ITEM_PRODUCT
- IDX_SHIPMENT_ITEM_STATUS

## Packages Oracle

- SHI_API_PKG
- SHI_RULE_PKG

## APIs

- GET /shipment-items
- GET /shipment-items/{publicId}
- POST /shipment-items
- PUT /shipment-items/{publicId}

## Flutter

- ShipmentItemModel
- ShipmentItemRepository
- ShipmentItemController
- ShipmentItemPage

## Observações

SHIPMENT_ITEM é uma entidade transacional do módulo Logística.

Ela representa os itens concretos que compõem uma remessa operacional.

# DELIVERY_PROFILE

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | DELIVERY_PROFILE |
| Prefixo | DLP |
| Tipo | CONFIGURATION |
| Responsável | Logística |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar modalidades e configurações de entrega disponíveis para as remessas da plataforma, sem representar uma entrega concreta e sem representar um provedor logístico.

## Classificação

CONFIGURATION

## Responsabilidades

- Definir modalidades de entrega disponíveis.
- Parametrizar regras de entrega, como preço base, distância máxima e peso máximo.
- Apoiar a escolha da modalidade de entrega em cada SHIPMENT.
- Servir como referência operacional para logística.

## Não é responsabilidade

- Representar uma entrega específica.
- Armazenar dados de pedido.
- Substituir SHIPMENT.
- Definir regras comerciais de produto.

## Dono da Informação

Logística

## Regras de Negócio

- RN-001 — DELIVERY_PROFILE define modalidades disponíveis.
- RN-002 — Exemplos oficiais: PICKUP, LOCAL, EXPRESS, NATIONAL.
- RN-003 — DLP_CODE deve ser único.
- RN-004 — DELIVERY_PROFILE pode definir preço base, distância máxima e peso máximo.
- RN-005 — DLP_IS_EXPRESS indica entrega rápida ou local.
- RN-006 — DELIVERY_PROFILE não executa a entrega.
- RN-007 — A execução concreta acontece em SHIPMENT.
- RN-008 — A escolha final do perfil ocorre no SHIPMENT.
- RN-009 — DELIVERY_PROFILE representa apenas a modalidade da entrega. O provedor responsável pela execução poderá ser definido futuramente através da entidade CARRIER.
- RN-010 — Futuramente, a execução poderá ser delegada a CARRIER.
- RN-011 — DLP_PUBLIC_ID deve ser CHAR(32).
- RN-012 — APIs externas usam DLP_PUBLIC_ID, nunca DLP_ID.
- RN-013 — A exclusão deve ser lógica via DLP_STATUS.

## Relacionamentos

- SHIPMENT (1:N)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| DLP_ID | NUMBER Identity | Sim |
| DLP_PUBLIC_ID | CHAR(32) | Sim |
| DLP_CODE | VARCHAR2(50) | Sim |
| DLP_NAME | VARCHAR2(100) | Sim |
| DLP_DESCRIPTION | VARCHAR2(500) | Não |
| DLP_BASE_PRICE | NUMBER(12,2) | Não |
| DLP_MAX_DISTANCE_KM | NUMBER(10,2) | Não |
| DLP_MAX_WEIGHT_KG | NUMBER(10,2) | Não |
| DLP_IS_EXPRESS | NUMBER(1) | Sim |
| DLP_STATUS | VARCHAR2(20) | Sim |
| DLP_CREATED_AT | TIMESTAMP | Sim |
| DLP_UPDATED_AT | TIMESTAMP | Sim |
| DLP_CREATED_BY | NUMBER | Não |
| DLP_UPDATED_BY | NUMBER | Não |

DLP_CREATED_BY e DLP_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_DELIVERY_PROFILE
- UK_DELIVERY_PROFILE_PUBLIC_ID
- UK_DELIVERY_PROFILE_CODE
- IDX_DELIVERY_PROFILE_STATUS

## Packages Oracle

- DLP_API_PKG
- DLP_SERVICE_PKG
- DLP_REPOSITORY_PKG
- DLP_RULE_PKG

## APIs

- GET /delivery-profiles
- GET /delivery-profiles/{publicId}
- POST /delivery-profiles
- PUT /delivery-profiles/{publicId}

## Flutter

- DeliveryProfileModel
- DeliveryProfileRepository
- DeliveryProfileController
- DeliveryProfilePage

## Observações

DELIVERY_PROFILE é uma entidade de configuração do módulo Logística.

Ela funciona como catálogo de modalidades logísticas. SHIPMENT registra qual modalidade foi aplicada ao pedido.

Exemplos de provedores logísticos como Correios, Lalamove, 99 Entrega, Uber Direct ou Motoboy Próprio não pertencem ao conceito de DELIVERY_PROFILE. Esses provedores poderão ser representados futuramente pela entidade CARRIER.

# PAYMENT_PROVIDER

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PAYMENT_PROVIDER |
| Prefixo | PPR |
| Tipo | CONFIGURATION |
| Responsável | Financeiro |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar provedores responsáveis pelo processamento financeiro da plataforma.

Exemplos oficiais:
- PagSeguro
- Mercado Pago
- Asaas
- Stripe

## Classificação

CONFIGURATION

## Responsabilidades

- Cadastrar os Gateways de Pagamento utilizados pela plataforma.
- Armazenar a configuração operacional associada a cada provedor.
- Identificar qual provedor foi utilizado em cada pagamento.

## Não é responsabilidade

- Receber pagamentos diretamente.
- Confirmar pagamentos.
- Definir regras comerciais de pedidos.
- Armazenar dados de clientes para fins de cobrança.

## Dono da Informação

Financeiro

## Regras de Negócio

- RN-001 — Um Gateway representa apenas um provedor.
- RN-002 — PAYMENT referencia exatamente um PAYMENT_PROVIDER.
- RN-003 — PPR_PUBLIC_ID deve ser CHAR(32).
- RN-004 — APIs utilizam apenas PUBLIC_ID.
- RN-005 — A exclusão deve ser lógica via PPR_STATUS.

## Relacionamentos

- PAYMENT (1:N)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PPR_ID | NUMBER Identity | Sim |
| PPR_PUBLIC_ID | CHAR(32) | Sim |
| PPR_CODE | VARCHAR2(50) | Sim |
| PPR_NAME | VARCHAR2(100) | Sim |
| PPR_STATUS | VARCHAR2(20) | Sim |
| PPR_CREATED_AT | TIMESTAMP | Sim |
| PPR_UPDATED_AT | TIMESTAMP | Sim |
| PPR_CREATED_BY | NUMBER | Não |
| PPR_UPDATED_BY | NUMBER | Não |

PPR_CREATED_BY e PPR_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_PAYMENT_PROVIDER
- UK_PAYMENT_PROVIDER_PUBLIC_ID
- UK_PAYMENT_PROVIDER_CODE
- IDX_PAYMENT_PROVIDER_STATUS

## Packages Oracle

- PPR_API_PKG
- PPR_SERVICE_PKG
- PPR_REPOSITORY_PKG
- PPR_RULE_PKG

## APIs

- GET /payment-providers
- GET /payment-providers/{publicId}
- POST /payment-providers
- PUT /payment-providers/{publicId}

## Flutter

- PaymentProviderModel
- PaymentProviderRepository
- PaymentProviderController
- PaymentProviderPage

## Observações

PAYMENT_PROVIDER é a entidade de configuração do módulo financeiro que representa os provedores externos utilizados para processar pagamentos.

Ela não representa o pagamento em si, mas a referência oficial do gateway utilizado por cada operação.

# PAYMENT

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PAYMENT |
| Prefixo | PAY |
| Tipo | TRANSACTION |
| Responsável | Financeiro |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar um pagamento realizado pelo cliente e registrado pela plataforma.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar uma tentativa de pagamento associada a uma Purchase Request finalizada.
- Vincular o pagamento ao provedor financeiro utilizado.
- Apoiar o acompanhamento do fluxo de cobrança.
- Permitir a integração com eventos de confirmação emitidos pelos Gateways.

## Não é responsabilidade

- Confirmar pagamentos sozinho.
- Executar integração com Gateways diretamente.
- Definir comissão ou repasse financeiro.
- Substituir ORDER.

## Dono da Informação

Financeiro

## Regras de Negócio

- RN-001 — Todo PAYMENT nasce vinculado a uma PURCHASE_REQUEST finalizada.
- RN-002 — Todo PAYMENT utiliza um PAYMENT_PROVIDER.
- RN-003 — PAYMENT nunca confirma pagamento sozinho.
- RN-004 — A confirmação ocorre exclusivamente através de PAYMENT_EVENT.
- RN-005 — APIs nunca utilizam PAY_ID.
- RN-006 — PAY_PUBLIC_ID deve ser CHAR(32).
- RN-007 — A exclusão deve ser lógica via PAY_STATUS.
- RN-008 — ORDER só é criado após PAYMENT_EVENT de aprovação.
- RN-009 — ORD_ID permanece nulo antes da aprovação e é preenchido atomicamente depois.

## Relacionamentos

- PURCHASE_REQUEST (1:1)
- ORDER (1:1 opcional antes da aprovação)
- PAYMENT_PROVIDER (N:1)
- PAYMENT_EVENT (1:N)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PAY_ID | NUMBER Identity | Sim |
| PAY_PUBLIC_ID | CHAR(32) | Sim |
| PUR_ID | NUMBER | Sim |
| ORD_ID | NUMBER | Não |
| PPR_ID | NUMBER | Sim |
| PAY_EXTERNAL_ID | VARCHAR2(100) | Não |
| PAY_AMOUNT | NUMBER(12,2) | Sim |
| PAY_METHOD | VARCHAR2(20) | Sim |
| PAY_STATUS | VARCHAR2(20) | Sim |
| PAY_CREATED_AT | TIMESTAMP | Sim |
| PAY_UPDATED_AT | TIMESTAMP | Sim |
| PAY_CREATED_BY | NUMBER | Não |
| PAY_UPDATED_BY | NUMBER | Não |

PAY_CREATED_BY e PAY_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_PAYMENT
- UK_PAYMENT_PUBLIC_ID
- UK_PAYMENT_REQUEST
- UK_PAYMENT_ORDER
- IDX_PAYMENT_PROVIDER
- IDX_PAYMENT_STATUS

## Packages Oracle

- PAY_API_PKG
- PAY_SERVICE_PKG
- PAY_REPOSITORY_PKG
- PAY_RULE_PKG

## APIs

- GET /payments
- GET /payments/{publicId}
- POST /payments
- PUT /payments/{publicId}

## Flutter

- PaymentModel
- PaymentRepository
- PaymentController
- PaymentPage

## Observações

PAYMENT é a entidade transacional central do módulo financeiro.

Ela representa a intenção e o registro do pagamento realizado pelo cliente, mas a confirmação do estado financeiro ocorre exclusivamente por meio de PAYMENT_EVENT.

Os meios aceitos inicialmente incluem PIX, Cartão, Débito, Crédito e outros meios futuros.

# PAYMENT_EVENT

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | PAYMENT_EVENT |
| Prefixo | PEV |
| Tipo | TRANSACTION |
| Responsável | Financeiro |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Registrar todos os eventos enviados pelos Gateways de Pagamento e recebidos por Webhook.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar cada evento recebido do provedor financeiro.
- Preservar o payload bruto para auditoria.
- Acompanhar a evolução do estado de um pagamento.
- Permitir múltiplos eventos para o mesmo pagamento.

## Não é responsabilidade

- Alterar o estado de um pagamento sem evento válido.
- Interpretar o pagamento sem contexto de auditoria.
- Substituir PAYMENT.
- Definir comissão ou saldo.

## Dono da Informação

Financeiro

## Regras de Negócio

- RN-001 — PAYMENT_EVENT representa um evento recebido por Webhook.
- RN-002 — Nenhum PAYMENT muda de estado sem um PAYMENT_EVENT correspondente.
- RN-003 — O payload recebido deve ser preservado para auditoria.
- RN-004 — O sistema deve aceitar múltiplos eventos para o mesmo PAYMENT.
- RN-005 — PEV_PUBLIC_ID deve ser CHAR(32).
- RN-006 — APIs utilizam apenas PUBLIC_ID.
- RN-007 — A exclusão deve ser lógica via PEV_STATUS.

## Relacionamentos

- PAYMENT (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| PEV_ID | NUMBER Identity | Sim |
| PEV_PUBLIC_ID | CHAR(32) | Sim |
| PAY_ID | NUMBER | Sim |
| PEV_EVENT_TYPE | VARCHAR2(50) | Sim |
| PEV_EXTERNAL_EVENT_ID | VARCHAR2(100) | Não |
| PEV_EVENT_AT | TIMESTAMP | Sim |
| PEV_RAW_PAYLOAD | CLOB | Sim |
| PEV_STATUS | VARCHAR2(20) | Sim |
| PEV_CREATED_AT | TIMESTAMP | Sim |
| PEV_UPDATED_AT | TIMESTAMP | Sim |
| PEV_CREATED_BY | NUMBER | Não |
| PEV_UPDATED_BY | NUMBER | Não |

PEV_CREATED_BY e PEV_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_PAYMENT_EVENT
- UK_PAYMENT_EVENT_PUBLIC_ID
- IDX_PAYMENT_EVENT_PAYMENT
- IDX_PAYMENT_EVENT_STATUS
- IDX_PAYMENT_EVENT_EVENT_AT

## Packages Oracle

- PEV_API_PKG
- PEV_SERVICE_PKG
- PEV_REPOSITORY_PKG
- PEV_RULE_PKG

## APIs

- GET /payment-events
- GET /payment-events/{publicId}
- POST /payment-events
- PUT /payment-events/{publicId}

## Flutter

- PaymentEventModel
- PaymentEventRepository
- PaymentEventController
- PaymentEventPage

## Observações

PAYMENT_EVENT é a entidade de auditoria e rastreabilidade do módulo financeiro.

Ela registra a origem dos estados de pagamento e garante que toda mudança significativa seja rastreada a partir de eventos recebidos dos Gateways de Pagamento.

# RETURN_REQUEST

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | RETURN_REQUEST |
| Prefixo | RRQ |
| Tipo | TRANSACTION |
| Responsável | Pós-venda |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar oficialmente um processo de pós-venda iniciado após um pedido, permitindo análise, mediação, resolução e encerramento de uma ocorrência.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar oficialmente uma ocorrência de pós-venda vinculada a um pedido.
- Acompanhar o ciclo de abertura, análise, decisão e encerramento de uma solicitação.
- Servir como aggregate root do módulo de Pós-venda.
- Dar suporte à mediação, evidência e resolução de problemas após a compra.
- Registrar a resposta do Brechó quando aplicável.
- Registrar a origem da ocorrência.
- Registrar a decisão separadamente do encerramento.
- Diferenciar prioridade operacional de severidade da ocorrência.

## Não é responsabilidade

- Garantir automaticamente a devolução ou estorno.
- Substituir a lógica financeira ou operacional do módulo de pagamento.
- Definir regras operacionais específicas sem apoio de BUSINESS_CONFIGURATION.
- Armazenar evidências diretamente sem o uso de uma entidade complementar.

## Dono da Informação

Pós-venda / Operação

## Regras de Negócio

- RN-001 — Todo RETURN_REQUEST pertence a um ORDER.
- RN-002 — Nem todo RETURN_REQUEST resulta em devolução.
- RN-003 — RETURN_REQUEST representa um processo de pós-venda e não apenas uma devolução técnica.
- RN-004 — Evidências deverão ser armazenadas em RETURN_ATTACHMENT.
- RN-005 — RRQ_REASON_CODE deverá permitir futura parametrização.
- RN-006 — RRQ_STATUS representa o estado do processo.
- RN-007 — RRQ_RESULT representa a decisão final.
- RN-008 — RRQ_DECIDED_AT registra quando a decisão foi tomada.
- RN-009 — RRQ_DECIDED_BY registra quem tomou a decisão.
- RN-010 — RRQ_CLOSED_AT registra quando o processo foi encerrado.
- RN-011 — Decisão e encerramento são momentos distintos.
- RN-012 — RRQ_STORE_RESPONSE registra a resposta formal do Brechó durante a análise.
- RN-013 — RRQ_SOURCE indica a origem da ocorrência, como CUSTOMER, STORE, SYSTEM ou ADMIN.
- RN-014 — RRQ_SEVERITY indica a gravidade da ocorrência.
- RN-015 — RRQ_PRIORITY indica prioridade operacional de atendimento.
- RN-016 — RRQ_RESULT só deve ser preenchido quando houver decisão ou estado final compatível.
- RN-017 — RRQ_CLOSED_AT só deve ser preenchido quando o processo estiver em estado final.
- RN-018 — Um ORDER pode possuir várias RETURN_REQUEST ao longo do tempo, desde que representem ocorrências distintas.
- RN-019 — RRQ_PUBLIC_ID deve ser CHAR(32).
- RN-020 — APIs utilizam RRQ_PUBLIC_ID.
- RN-021 — Toda ocorrência deve possuir histórico auditável.
- RN-022 — Toda resolução deverá respeitar a ADR_POST_SALES_POLICY.
- RN-023 — Regras operacionais específicas deverão ser controladas por BUSINESS_CONFIGURATION.

## Relacionamentos

- ORDER (N:1)
- STORE (N:1)
- PROFILE (Cliente) (N:1)
- PROFILE (Responsável pela análise) (N:1 opcional)
- PROFILE (Responsável pela decisão) (N:1 opcional)
- STORE_USER (Responsável operacional do Brechó) (N:1 opcional futuro)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| RRQ_ID | NUMBER Identity | Sim |
| RRQ_PUBLIC_ID | CHAR(32) | Sim |
| ORD_ID | NUMBER | Sim |
| STR_ID | NUMBER | Sim |
| PFL_ID | NUMBER | Sim |
| RRQ_REASON_CODE | VARCHAR2(50) | Sim |
| RRQ_DESCRIPTION | VARCHAR2(2000) | Não |
| RRQ_STATUS | VARCHAR2(20) | Sim |
| RRQ_RESULT | VARCHAR2(50) | Não |
| RRQ_PRIORITY | VARCHAR2(20) | Não |
| RRQ_SEVERITY | VARCHAR2(20) | Não |
| RRQ_SOURCE | VARCHAR2(50) | Sim |
| RRQ_REQUESTED_AT | TIMESTAMP | Sim |
| RRQ_DECIDED_AT | TIMESTAMP | Não |
| RRQ_DECIDED_BY | NUMBER | Não |
| RRQ_CLOSED_AT | TIMESTAMP | Não |
| RRQ_CLOSED_BY | NUMBER | Não |
| RRQ_STORE_RESPONSE | VARCHAR2(2000) | Não |
| RRQ_CREATED_AT | TIMESTAMP | Sim |
| RRQ_UPDATED_AT | TIMESTAMP | Sim |
| RRQ_CREATED_BY | NUMBER | Não |
| RRQ_UPDATED_BY | NUMBER | Não |

RRQ_CREATED_BY e RRQ_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_RETURN_REQUEST
- UK_RETURN_REQUEST_PUBLIC_ID
- IDX_RETURN_REQUEST_ORDER
- IDX_RETURN_REQUEST_STORE
- IDX_RETURN_REQUEST_STATUS
- IDX_RETURN_REQUEST_SOURCE
- IDX_RETURN_REQUEST_SEVERITY
- IDX_RETURN_REQUEST_PRIORITY

## Packages Oracle

- RRQ_API_PKG
- RRQ_RULE_PKG

## APIs

- GET /return-requests
- GET /return-requests/{publicId}
- POST /return-requests
- PUT /return-requests/{publicId}

## Flutter

- ReturnRequestModel
- ReturnRequestRepository
- ReturnRequestController
- ReturnRequestPage

## Observações

RETURN_REQUEST representa o Aggregate Root do módulo de Pós-venda.

Ele separa abertura, análise, decisão e encerramento, permitindo evolução futura para mediação, disputa, fraude e resolução financeira.

Nem toda ocorrência resultará em devolução, estorno ou compensação financeira.

# STORE_REVIEW

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | STORE_REVIEW |
| Prefixo | SRV |
| Tipo | TRANSACTION |
| Responsável | Experiência do Cliente |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar a avaliação realizada pelo cliente após a conclusão de um pedido, registrando sua experiência de compra e contribuindo para a reputação do Brechó.

## Classificação

TRANSACTION

## Responsabilidades

- Registrar a experiência do cliente.
- Avaliar a qualidade da compra.
- Permitir comentário público.
- Permitir resposta pública do Brechó.
- Alimentar STORE_REPUTATION.
- Alimentar indicadores de qualidade.
- Futuramente integrar com o programa de fidelidade.

## Não é responsabilidade

- Resolver disputas.
- Gerenciar devoluções.
- Movimentar financeiro.
- Armazenar reputação consolidada.

## Dono da Informação

Cliente / Experiência do Cliente

## Regras de Negócio

- RN-001 — Cada par ORDER e STORE pode possuir no máximo uma STORE_REVIEW, permitindo uma avaliação por loja em pedidos multiloja, conforme ADR_POST_SALES_POLICY.
- RN-002 — Apenas pedidos concluídos podem ser avaliados.
- RN-003 — O cliente pode editar sua avaliação dentro do período definido em BUSINESS_CONFIGURATION.
- RN-004 — O Brechó pode responder publicamente à avaliação.
- RN-005 — A resposta do Brechó não altera a avaliação do cliente.
- RN-006 — STORE_REVIEW alimenta STORE_REPUTATION.
- RN-007 — APIs utilizam SRV_PUBLIC_ID.
- RN-008 — SRV_PUBLIC_ID deve ser CHAR(32).
- RN-009 — Fotos da avaliação poderão ser adicionadas futuramente por entidade específica.
- RN-010 — Regras de prazo, edição e pontuação deverão ser controladas por BUSINESS_CONFIGURATION.

## Relacionamentos

- ORDER (N:1)
- STORE (N:1)
- PROFILE (Cliente) (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| SRV_ID | NUMBER Identity | Sim |
| SRV_PUBLIC_ID | CHAR(32) | Sim |
| ORD_ID | NUMBER | Sim |
| STR_ID | NUMBER | Sim |
| PFL_ID | NUMBER | Sim |
| SRV_OVERALL_RATE | NUMBER | Sim |
| SRV_PRODUCT_MATCH_RATE | NUMBER | Não |
| SRV_CONSERVATION_RATE | NUMBER | Não |
| SRV_SERVICE_RATE | NUMBER | Não |
| SRV_DELIVERY_RATE | NUMBER | Não |
| SRV_PACKAGING_RATE | NUMBER | Não |
| SRV_WOULD_BUY_AGAIN | CHAR(1) | Não |
| SRV_COMMENT | VARCHAR2(2000) | Não |
| SRV_STORE_REPLY | VARCHAR2(2000) | Não |
| SRV_STATUS | VARCHAR2(20) | Sim |
| SRV_REVIEWED_AT | TIMESTAMP | Sim |
| SRV_CREATED_AT | TIMESTAMP | Sim |
| SRV_UPDATED_AT | TIMESTAMP | Sim |
| SRV_CREATED_BY | NUMBER | Não |
| SRV_UPDATED_BY | NUMBER | Não |

SRV_CREATED_BY e SRV_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_STORE_REVIEW
- UK_STORE_REVIEW_PUBLIC_ID
- UK_STORE_REVIEW_ORDER_STORE
- IDX_STORE_REVIEW_STORE
- IDX_STORE_REVIEW_RATE

## Packages Oracle

- SRV_API_PKG
- SRV_RULE_PKG

## APIs

- GET /reviews
- GET /reviews/{publicId}
- POST /reviews
- PUT /reviews/{publicId}

## Flutter

- StoreReviewModel
- StoreReviewRepository
- StoreReviewController
- StoreReviewPage

## Observações

STORE_REVIEW representa a percepção pública do cliente sobre sua experiência de compra.

As avaliações são um dos principais mecanismos de confiança do Brechó Express e constituem a base para a reputação dos Brechós.

# RETURN_ATTACHMENT

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | RETURN_ATTACHMENT |
| Prefixo | RAT |
| Tipo | SUPPORT |
| Responsável | Pós-venda |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Não |

## Objetivo

Representar evidências anexadas a uma ocorrência de pós-venda, como fotos, vídeos, comprovantes, embalagens, etiquetas ou documentos.

## Classificação

SUPPORT

## Responsabilidades

- Registrar evidências associadas a uma ocorrência de pós-venda.
- Apoiar análise, mediação e resolução da ocorrência.
- Manter rastreio do autor do anexo.
- Permitir classificação e controle de status das evidências.

## Não é responsabilidade

- Decidir a ocorrência.
- Armazenar conteúdo binário diretamente.
- Substituir RETURN_REQUEST.
- Definir regras operacionais sem apoio de BUSINESS_CONFIGURATION.

## Dono da Informação

Pós-venda / Operação

## Regras de Negócio

- RN-001 — Todo RETURN_ATTACHMENT pertence a um RETURN_REQUEST.
- RN-002 — RETURN_ATTACHMENT representa evidência de uma ocorrência.
- RN-003 — Um RETURN_REQUEST pode possuir vários anexos.
- RN-004 — Um anexo pode ser enviado pelo cliente, Brechó, administrador ou sistema.
- RN-005 — RAT_TYPE deve permitir classificar o anexo, como PHOTO, VIDEO, RECEIPT, PACKAGE, LABEL, DOCUMENT ou OTHER.
- RN-006 — RAT_URL armazena a referência do arquivo, não o conteúdo binário.
- RN-007 — Evidências não devem ser excluídas fisicamente.
- RN-008 — Evidências podem ser moderadas ou ocultadas por status.
- RN-009 — RAT_PUBLIC_ID deve ser CHAR(32).
- RN-010 — APIs utilizam RAT_PUBLIC_ID, nunca RAT_ID.
- RN-011 — A validade e obrigatoriedade dos anexos devem respeitar BUSINESS_CONFIGURATION.
- RN-012 — RETURN_ATTACHMENT não decide a ocorrência; apenas registra evidências.

## Relacionamentos

- RETURN_REQUEST (N:1)
- PROFILE (autor do anexo) (N:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| RAT_ID | NUMBER Identity | Sim |
| RAT_PUBLIC_ID | CHAR(32) | Sim |
| RRQ_ID | NUMBER | Sim |
| PFL_ID | NUMBER | Sim |
| RAT_TYPE | VARCHAR2(50) | Sim |
| RAT_URL | VARCHAR2(1000) | Sim |
| RAT_FILENAME | VARCHAR2(255) | Não |
| RAT_MIME_TYPE | VARCHAR2(100) | Não |
| RAT_SIZE_BYTES | NUMBER | Não |
| RAT_DESCRIPTION | VARCHAR2(2000) | Não |
| RAT_UPLOADED_AT | TIMESTAMP | Sim |
| RAT_STATUS | VARCHAR2(20) | Sim |
| RAT_CREATED_AT | TIMESTAMP | Sim |
| RAT_UPDATED_AT | TIMESTAMP | Sim |
| RAT_CREATED_BY | NUMBER | Não |
| RAT_UPDATED_BY | NUMBER | Não |

RAT_CREATED_BY e RAT_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_RETURN_ATTACHMENT
- UK_RETURN_ATTACHMENT_PUBLIC_ID
- IDX_RETURN_ATTACHMENT_REQUEST
- IDX_RETURN_ATTACHMENT_PROFILE
- IDX_RETURN_ATTACHMENT_TYPE
- IDX_RETURN_ATTACHMENT_STATUS

## Packages Oracle

- RAT_API_PKG
- RAT_RULE_PKG

## APIs

- GET /return-attachments
- GET /return-attachments/{publicId}
- POST /return-attachments
- PUT /return-attachments/{publicId}

## Flutter

- ReturnAttachmentModel
- ReturnAttachmentRepository
- ReturnAttachmentController
- ReturnAttachmentPage

## Observações

RETURN_ATTACHMENT complementa RETURN_REQUEST armazenando evidências objetivas para análise, mediação e resolução de ocorrências.

Não armazenar arquivo binário diretamente nesta entidade.

# STORE_REPUTATION

## Ficha Técnica

| Campo | Valor |
|--------|--------|
| Entidade | STORE_REPUTATION |
| Prefixo | SRP |
| Tipo | SUPPORT |
| Responsável | Experiência do Cliente |
| Soft Delete | Sim |
| Auditoria | Sim |
| Exposto pela API | Sim |
| Cache | Sim |

## Objetivo

Representar os indicadores consolidados de reputação de um Brechó, derivados de avaliações, pedidos, ocorrências, entregas e comportamento operacional.

## Classificação

SUPPORT

## Responsabilidades

- Consolidar indicadores públicos de confiança do Brechó.
- Diferenciar reputação percebida pelo cliente de confiança operacional calculada pela plataforma.
- Apoiar níveis de reputação do Brechó.
- Apoiar selos especiais de qualidade e confiança.
- Apoiar ranking com base em relevância, confiança e histórico operacional.
- Ser alimentada por STORE_REVIEW, ORDER, RETURN_REQUEST, SHIPMENT e outros indicadores operacionais.
- Servir como visão otimizada para exibição da reputação.

## Não é responsabilidade

- Armazenar avaliações individuais.
- Substituir STORE_REVIEW.
- Resolver disputas.
- Movimentar financeiro.
- Definir regras de reputação diretamente sem apoio de BUSINESS_CONFIGURATION.

## Dono da Informação

Experiência do Cliente / Operação

## Regras de Negócio

- RN-001 — Cada STORE deve possuir no máximo uma STORE_REPUTATION ativa.
- RN-002 — STORE_REPUTATION é derivada de dados operacionais e avaliações.
- RN-003 — STORE_REPUTATION não substitui STORE_REVIEW.
- RN-004 — STORE_REPUTATION deve ser recalculada por processo controlado.
- RN-005 — Indicadores devem ser rastreáveis até suas origens.
- RN-006 — A reputação pode considerar avaliações, pedidos concluídos, ocorrências, cancelamentos, devoluções, tempo de resposta e tempo de confirmação.
- RN-007 — SRP_TRUST_SCORE representa a confiabilidade operacional calculada pela plataforma.
- RN-008 — SRP_REPUTATION_SCORE representa a pontuação consolidada de reputação.
- RN-009 — SRP_LEVEL_CODE representa o nível geral do Brechó, como BEGINNER, BRONZE, SILVER, GOLD ou PLATINUM.
- RN-010 — SRP_BADGE_CODE representa selos especiais, como FAST_SHIPPING, TOP_RATED, TRUSTED_STORE, EXCELLENT_SERVICE, MOST_RECOMMENDED ou SUSTAINABLE_STORE.
- RN-011 — SRP_FIRST_ORDER_AT registra a primeira venda concluída do Brechó.
- RN-012 — SRP_LAST_ORDER_AT registra a venda mais recente do Brechó.
- RN-013 — SRP_LAST_REVIEW_AT registra a avaliação mais recente recebida pelo Brechó.
- RN-014 — SRP_LAST_RECALCULATED_AT deve ser atualizado a cada processamento de reputação.
- RN-015 — STORE_REPUTATION representa dados derivados e não deve ser alterada manualmente.
- RN-016 — SRP_TRUST_SCORE e SRP_REPUTATION_SCORE devem ser calculados exclusivamente por processos internos.
- RN-017 — Regras de cálculo, pesos, níveis e selos deverão ser controladas futuramente por BUSINESS_CONFIGURATION.
- RN-018 — APIs utilizam SRP_PUBLIC_ID.
- RN-019 — SRP_PUBLIC_ID deve ser CHAR(32).

## Relacionamentos

- STORE (1:1)

## Atributos

| Campo | Tipo | Obrigatório |
|--------|------|-------------|
| SRP_ID | NUMBER Identity | Sim |
| SRP_PUBLIC_ID | CHAR(32) | Sim |
| STR_ID | NUMBER | Sim |
| SRP_OVERALL_RATE | NUMBER | Não |
| SRP_PRODUCT_MATCH_RATE | NUMBER | Não |
| SRP_CONSERVATION_RATE | NUMBER | Não |
| SRP_SERVICE_RATE | NUMBER | Não |
| SRP_DELIVERY_RATE | NUMBER | Não |
| SRP_PACKAGING_RATE | NUMBER | Não |
| SRP_REVIEW_COUNT | NUMBER | Não |
| SRP_ORDER_COUNT | NUMBER | Não |
| SRP_RETURN_REQUEST_COUNT | NUMBER | Não |
| SRP_RETURN_RATE | NUMBER | Não |
| SRP_WOULD_BUY_AGAIN_RATE | NUMBER | Não |
| SRP_RESPONSE_TIME_AVG_MIN | NUMBER | Não |
| SRP_CONFIRMATION_TIME_AVG_MIN | NUMBER | Não |
| SRP_CANCELLATION_RATE | NUMBER | Não |
| SRP_TRUST_SCORE | NUMBER | Não |
| SRP_REPUTATION_SCORE | NUMBER | Não |
| SRP_LEVEL_CODE | VARCHAR2(50) | Não |
| SRP_BADGE_CODE | VARCHAR2(50) | Não |
| SRP_FIRST_ORDER_AT | TIMESTAMP | Não |
| SRP_LAST_ORDER_AT | TIMESTAMP | Não |
| SRP_LAST_REVIEW_AT | TIMESTAMP | Não |
| SRP_LAST_RECALCULATED_AT | TIMESTAMP | Não |
| SRP_STATUS | VARCHAR2(20) | Sim |
| SRP_CREATED_AT | TIMESTAMP | Sim |
| SRP_UPDATED_AT | TIMESTAMP | Sim |
| SRP_CREATED_BY | NUMBER | Não |
| SRP_UPDATED_BY | NUMBER | Não |

SRP_CREATED_BY e SRP_UPDATED_BY referenciam BEX_PROFILE.PFL_ID. Para operações automáticas, será utilizado um Profile técnico do tipo SYSTEM.

## Índices

- PK_STORE_REPUTATION
- UK_STORE_REPUTATION_PUBLIC_ID
- UK_STORE_REPUTATION_STORE
- IDX_STORE_REPUTATION_SCORE
- IDX_STORE_REPUTATION_TRUST_SCORE
- IDX_STORE_REPUTATION_LEVEL
- IDX_STORE_REPUTATION_BADGE
- IDX_STORE_REPUTATION_STATUS
- IDX_STORE_REPUTATION_LAST_ORDER
- IDX_STORE_REPUTATION_LAST_REVIEW

## Packages Oracle

- SRP_API_PKG
- SRP_RULE_PKG

## APIs

- GET /store-reputations
- GET /store-reputations/{publicId}
- GET /stores/{publicId}/reputation

## Flutter

- StoreReputationModel
- StoreReputationRepository
- StoreReputationController
- StoreReputationWidget

## Observações

STORE_REPUTATION representa uma visão consolidada e otimizada da confiança do Brechó.

Ela separa percepção do cliente, confiança operacional, nível do Brechó e selos especiais.

Ela deve ser tratada como uma consequência dos eventos e experiências da plataforma, nunca como substituta das avaliações individuais.
