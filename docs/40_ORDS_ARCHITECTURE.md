# 40 — Arquitetura ORDS e Catálogo de Endpoints

## 1. Status

Contrato aceito e materializado de forma incremental em módulos, templates,
handlers e adapter ORDS versionados no repositório.

Em 2026-07-26, o runtime PL/SQL anterior ao ORDS foi compilado e testado no
Oracle AI Database 26ai Free, sem objetos inválidos. Na mesma data, a fundação
pública `brecho-express-v1`, o adapter de runtime e os handlers de criação de
conta e login foram instalados com sucesso.

Em 2026-07-26, os testes HTTP externos confirmaram criação de conta com `201`,
bloqueio seguro do login de conta pendente com `401 BEX-AUTH-001` e login de
conta ativa com `200`, `accessToken`, `sessionPublicId`, expiração e correlação
entre `X-Trace-Id` e o envelope JSON.

Na mesma data, a fundação autenticada com validação Bearer e logout foi
compilada e instalada. O teste SQL confirmou o contexto seguro para token
válido e a resposta uniforme `401 BEX-AUTH-002` para credencial malformada. O
teste HTTP externo confirmou logout com `204` e rejeição da reutilização do
mesmo token com `401 BEX-AUTH-002`, incluindo correlação entre `X-Trace-Id` e
o `traceId` do envelope.

## 2. Objetivo

Definir a borda HTTP oficial entre consumidores externos e os API packages
Oracle existentes, incluindo:

- base path e versionamento;
- roteamento por recurso;
- autenticação e resolução do ator;
- lifecycle do contexto;
- transação e respostas;
- idempotência;
- mapeamento entre endpoint e operação PL/SQL;
- estado de implementação.

## 3. Autoridades

Este documento aplica:

- `ADR-002_ORACLE_ORDS_BACKEND.md`;
- `ADR-007_EXTERNAL_PUBLIC_IDENTIFIERS.md`;
- `ADR-008_ORDS_PACKAGE_BOUNDARY.md`;
- `ADR-009_ORACLE_PACKAGE_LAYERS.md`;
- `27_API_STANDARDS.md`;
- `29_EXECUTION_CONTEXT.md`;
- `31_API_RUNTIME_CONTRACT.md`.

Em caso de conflito, prevalece a autoridade superior. Este catálogo não altera
payloads de domínio definidos por ADR ou arquitetura modular.

## 4. Base path

```text
/api/v1
```

Regras:

- recursos em inglês técnico e no plural;
- segmentos em `kebab-case`;
- identificadores de rota são Public IDs ou slugs aprovados;
- nenhum prefixo de tabela, sigla de package ou ID numérico aparece na URL;
- uma versão major incompatível usa novo prefixo;
- query parameters não fazem parte da identidade do recurso.

## 5. Módulo ORDS

O módulo oficial candidato é:

```text
brecho-express-v1
```

Seu base path é `/api/v1/`. Um único módulo pode agrupar templates por domínio
enquanto autorização, rate limit e observabilidade permanecerem explícitos por
handler.

Módulos separados para webhook são permitidos quando necessários para
segurança, rede ou política de gateway, mas preservam o contrato público
versionado deste documento.

## 6. Lifecycle de uma requisição autenticada

```text
HTTP request
  ↓
ORDS valida estrutura e extrai credencial
  ↓
Sessão é validada por contrato interno de ACCOUNT
  ↓
ACCOUNT técnica do ator é resolvida
  ↓
CORE_TRACE_PKG.initialize
  ↓
CORE_CONTEXT_PKG.initialize
  ↓
CORE_SECURITY_CONTEXT_PKG.initialize
  ↓
*_API_PKG
  ↓
status + envelope JSON
  ↓
limpeza garantida dos contextos
  ↓
HTTP response
```

O handler é proprietário da inicialização e limpeza. API package pressupõe
contexto ativo e não recebe identidade livremente do body.

## 7. Autenticação e ator

### 7.1 Rotas públicas

Rotas públicas não exigem bearer token, mas ainda recebem trace e contexto
anônimo. Exemplos:

- criação de conta;
- login;
- catálogo público;
- consulta pública de Brechó, Categoria, Marca e Plano;
- webhook autenticado pelo provedor, que não é uma rota anônima comum.

### 7.2 Rotas autenticadas

Usam:

```http
Authorization: Bearer <session-token>
```

O token nunca é enviado ao API package de negócio. A infraestrutura valida a
sessão, revalida o status ativo da ACCOUNT e entrega `ACC_ID` e
`SESSION_PUBLIC_ID` por variáveis locais confiáveis. Token ausente, malformado,
desconhecido, expirado ou revogado produz a mesma resposta
`401 BEX-AUTH-002`, sem revelar a causa.

### 7.3 `ACC_SESSION_API_PKG`

Apesar do nome histórico, `ACC_SESSION_API_PKG` não é uma fronteira HTTP:

- recebe e devolve IDs internos;
- retorna `%ROWTYPE`;
- não utiliza envelope ou status HTTP;
- contém operações de infraestrutura e expiração.
- não executa `COMMIT` ou `ROLLBACK`; a fronteira externa ou o job chamador
  controla a unidade transacional.

Ele permanece contrato interno do módulo ACCOUNT. ORDS não o expõe
diretamente. Login e logout usam `ACC_AUTH_API_PKG`.

### 7.4 Webhooks

Webhook financeiro usa autenticação específica do provedor, allowlist, segredo
ou assinatura conforme contrato futuro. O payload nunca fornece livremente
`p_actor`. O handler resolve ACCOUNT técnica SYSTEM ou identidade técnica
aprovada e preserva o identificador externo do evento para idempotência.

## 8. Headers

### Entrada

- `Authorization`, quando autenticado;
- `Content-Type: application/json` para body JSON;
- `Accept: application/json`;
- `Idempotency-Key` quando o endpoint exigir;
- `X-Correlation-Id` opcional, validado e limitado;
- headers de assinatura do provedor em webhook.

### Saída

- `Content-Type: application/json`;
- `X-Trace-Id`;
- `X-Correlation-Id`, quando aplicável;
- headers de depreciação quando uma versão estiver em retirada;
- headers de rate limit quando a política for implementada.

Headers internos de ator, schema, package ou sessão Oracle nunca são expostos.

## 9. Transação

- handler ORDS não confirma transação de negócio;
- escrita é encerrada pelo `*_API_PKG`;
- leitura não encerra transação;
- falha conhecida ou inesperada produz rollback seguro na API;
- o adapter autenticado executa rollback ao rejeitar credencial para desfazer
  atualizações auxiliares da validação de sessão;
- webhook financeiro processa evento, pagamento, reserva e ORDER na mesma
  unidade transacional quando o contrato completo estiver implementado;
- contexto é limpo depois do término, inclusive em erro.

## 10. Contrato de resposta

Todo handler devolve exatamente:

- status retornado pelo API package;
- envelope JSON produzido por `CORE_RESPONSE_PKG`;
- `traceId` correspondente ao contexto.

Body nulo em erro não é contrato aceito. API packages que ainda retornam body
nulo precisam ser corrigidos antes de receber handler ORDS.

Exceção Oracle, stack, constraint, SQL, ID interno e nome físico nunca aparecem
na resposta.

## 11. Catálogo oficial de endpoints

Legenda:

- **Público:** não exige sessão de usuário;
- **Autenticado:** exige ACCOUNT válida;
- **Interno:** não recebe endpoint externo;
- **Webhook:** autenticação própria de integração.

### 11.1 Account e autenticação

| Método | Rota | Package e operação | Acesso |
|---|---|---|---|
| POST | `/accounts` | `ACC_API_PKG.create_account` | Público |
| POST | `/auth/login` | `ACC_AUTH_API_PKG.login` | Público |
| POST | `/auth/logout` | `ACC_AUTH_API_PKG.logout` | Autenticado |
| POST | `/auth/social/{provider}` | Verificador externo + autenticação ACCOUNT | Público |
| GET | `/account/identities` | Identidades externas da própria ACCOUNT | Autenticado |
| POST | `/account/identities/{provider}` | Vincular identidade validada | Autenticado |
| DELETE | `/account/identities/{identityPublicId}` | Desvincular sem remover o último método | Autenticado |

Criação, validação, revogação global e expiração de sessão permanecem internas
em `ACC_SESSION_API_PKG` ou jobs autorizados.

Login e vinculação social seguem
`ADR-025_SOCIAL_AUTHENTICATION.md`. O ORDS nunca aceita subject ou e-mail como
prova isolada: a credencial do provedor é validada no backend e somente claims
verificados alcançam o caso de uso. A sessão emitida continua sendo a sessão
própria do Brechó Express.

### 11.2 Profiles e endereços

| Método | Rota | Package e operação | Acesso |
|---|---|---|---|
| POST | `/accounts/{accountPublicId}/profiles` | `PFL_API_PKG.create_profile` | Autenticado |
| GET | `/profiles/{profilePublicId}` | `PFL_API_PKG.get_profile` | Autenticado |
| GET | `/accounts/{accountPublicId}/profile` | `PFL_API_PKG.get_profile_by_account` | Autenticado |
| PATCH | `/profiles/{profilePublicId}` | `PFL_API_PKG.update_profile` | Autenticado |
| POST | `/addresses` | `ADR_API_PKG.create_address` | Autenticado |
| GET | `/addresses` | `ADR_API_PKG.list_addresses` | Autenticado |
| POST | `/addresses/{addressPublicId}/actions/set-default` | `ADR_API_PKG.set_default` | Autenticado |
| POST | `/addresses/{addressPublicId}/actions/deactivate` | `ADR_API_PKG.deactivate` | Autenticado |

### 11.3 Stores, membros e engajamento

| Método | Rota | Package e operação | Acesso |
|---|---|---|---|
| POST | `/accounts/{accountPublicId}/stores` | `STR_API_PKG.create_store` | Autenticado |
| GET | `/stores/{storePublicId}` | `STR_API_PKG.get_store` | Público ou autenticado conforme projeção |
| GET | `/stores/by-slug/{slug}` | `STR_API_PKG.get_store_by_slug` | Público |
| GET | `/accounts/{accountPublicId}/stores` | `STR_API_PKG.list_stores_by_account` | Autenticado |
| PATCH | `/stores/{storePublicId}` | `STR_API_PKG.update_store` | Autenticado |
| POST | `/stores/{storePublicId}/actions/activate` | `STR_API_PKG.activate_store` | Autenticado |
| POST | `/stores/{storePublicId}/actions/close` | `STR_API_PKG.close_store` | Autenticado |
| GET | `/store-slugs/{slug}/availability` | `STR_API_PKG.check_slug_availability` | Público |
| POST | `/stores/{storePublicId}/members` | `STR_API_PKG.add_member` | Autenticado |
| GET | `/stores/{storePublicId}/members/{memberPublicId}` | `STR_API_PKG.get_member` | Autenticado |
| GET | `/stores/{storePublicId}/members` | `STR_API_PKG.list_members` | Autenticado |
| POST | `/stores/{storePublicId}/members/{memberPublicId}/actions/change-role` | `STR_API_PKG.change_member_role` | Autenticado |
| POST | `/stores/{storePublicId}/members/{memberPublicId}/actions/activate` | `STR_API_PKG.activate_member` | Autenticado |
| POST | `/stores/{storePublicId}/members/{memberPublicId}/actions/deactivate` | `STR_API_PKG.deactivate_member` | Autenticado |
| GET | `/store-plans` | `STP_API_PKG.list_plans` | Público |
| POST | `/stores/{storePublicId}/events` | `STE_API_PKG.create_event` | Autenticado |
| POST | `/stores/{storePublicId}/followers` | `STF_API_PKG.follow_store` | Autenticado |
| DELETE | `/stores/{storePublicId}/followers/me` | `STF_API_PKG.unfollow_store` | Autenticado |

O DELETE do vínculo social encerra logicamente o vínculo; não executa DELETE
físico.

### 11.4 Catálogo

| Método | Rota | Package e operação | Acesso |
|---|---|---|---|
| GET | `/categories` | `CAT_API_PKG.list_categories` | Público |
| GET | `/categories/{categoryPublicId}` | `CAT_API_PKG.get_category` | Público |
| GET | `/categories/by-slug/{slug}` | `CAT_API_PKG.get_category_by_slug` | Público |
| GET | `/brands` | `BRD_API_PKG.list_brands` | Público |
| GET | `/brands/{brandPublicId}` | `BRD_API_PKG.get_brand` | Público |
| GET | `/brands/by-slug/{slug}` | `BRD_API_PKG.get_brand_by_slug` | Público |
| POST | `/stores/{storePublicId}/products` | `PRD_API_PKG.create_product` | Autenticado |
| GET | `/products/{productPublicId}` | `PRD_API_PKG.get_product` | Público |
| GET | `/stores/{storePublicId}/products/by-slug/{slug}` | `PRD_API_PKG.get_product_by_slug` | Público |
| GET | `/stores/{storePublicId}/products` | `PRD_API_PKG.list_store_products` | Autenticado para visão administrativa |
| GET | `/products` | `PRD_API_PKG.list_public_products` | Público |
| PATCH | `/stores/{storePublicId}/products/{productPublicId}` | `PRD_API_PKG.patch_product` | Autenticado |
| POST | `/stores/{storePublicId}/products/{productPublicId}/actions/change-status` | `PRD_API_PKG.change_status` | Autenticado |
| POST | `/stores/{storePublicId}/products/{productPublicId}/images` | `PIM_API_PKG.add_image` | Autenticado |
| GET | `/product-images/{imagePublicId}` | `PIM_API_PKG.get_image` | Público |
| GET | `/products/{productPublicId}/images` | `PIM_API_PKG.list_images` | Público |
| PATCH | `/stores/{storePublicId}/product-images/{imagePublicId}` | `PIM_API_PKG.update_image` | Autenticado |
| POST | `/stores/{storePublicId}/product-images/{imagePublicId}/actions/deactivate` | `PIM_API_PKG.deactivate_image` | Autenticado |
| POST | `/products/{productPublicId}/questions` | `PQA_API_PKG.ask_question` | Autenticado |
| GET | `/product-questions/{questionPublicId}` | `PQA_API_PKG.get_question` | Público |
| GET | `/products/{productPublicId}/questions` | `PQA_API_PKG.list_questions` | Público |
| POST | `/stores/{storePublicId}/product-questions/{questionPublicId}/actions/answer` | `PQA_API_PKG.answer_question` | Autenticado |
| POST | `/stores/{storePublicId}/product-questions/{questionPublicId}/actions/moderate` | `PQA_API_PKG.moderate_question` | Autenticado |

Filtros de `GET /products` usam query parameters `categoryPublicId`,
`brandPublicId` e `condition`.

### 11.5 Carrinho, solicitação e pedido

| Método | Rota | Package e operação | Acesso |
|---|---|---|---|
| POST | `/carts` | `CRT_API_PKG.get_or_create_cart` | Autenticado e idempotente por carrinho ativo |
| GET | `/carts/{cartPublicId}` | `CRT_API_PKG.get_cart` | Autenticado |
| POST | `/carts/{cartPublicId}/items` | `CRT_API_PKG.add_item` | Autenticado |
| PATCH | `/carts/{cartPublicId}/items/{itemPublicId}` | `CRT_API_PKG.update_item` | Autenticado |
| DELETE | `/carts/{cartPublicId}/items/{itemPublicId}` | `CRT_API_PKG.remove_item` | Autenticado |
| POST | `/carts/{cartPublicId}/actions/checkout` | `PUR_API_PKG.checkout` | Autenticado |
| GET | `/purchase-requests/{requestPublicId}` | `PUR_API_PKG.get_request` | Autenticado |
| POST | `/stores/{storePublicId}/purchase-requests/{requestPublicId}/items/{itemPublicId}/actions/respond` | `PUR_API_PKG.respond_item` | Autenticado |
| GET | `/orders/{orderPublicId}` | `ORD_API_PKG.get_order` | Autenticado |

Endpoints futuros, sem package implementado:

- `POST /purchase-requests/{requestPublicId}/actions/accept-partial`;
- `POST /purchase-requests/{requestPublicId}/actions/reject-partial`;
- consulta da reserva como projeção da solicitação.

Não existe `POST /orders`: ORDER nasce de `PAYMENT_APPROVED`.

### 11.6 Pagamento e webhooks

| Método | Rota | Package e operação | Acesso |
|---|---|---|---|
| POST | `/payments` | `PAY_API_PKG.create_payment` | Autenticado |
| GET | `/payments/{paymentPublicId}` | `PAY_API_PKG.get_payment` | Autenticado |
| POST | `/webhooks/payment-providers/{providerCode}/payments/{paymentPublicId}/events` | `PEV_API_PKG.receive_event` | Webhook |
| GET | `/payment-providers` | `PPR_API_PKG.list_providers` | Público somente se projeção segura for aprovada |
| GET | `/payment-providers/{providerPublicId}` | `PPR_API_PKG.get_provider` | Público somente se projeção segura for aprovada |

`paymentPublicId` na URL do webhook não substitui o identificador externo
idempotente do evento.

### 11.7 Logística

| Método | Rota | Package e operação | Acesso |
|---|---|---|---|
| GET | `/delivery-profiles` | `DLP_API_PKG.list_profiles` | Público |
| GET | `/delivery-profiles/{deliveryProfilePublicId}` | `DLP_API_PKG.get_profile` | Público |
| POST | `/shipments` | `SHP_API_PKG.create_shipment` | Autenticado e autorizado |
| GET | `/shipments/{shipmentPublicId}` | `SHP_API_PKG.get_shipment` | Autenticado |
| POST | `/shipments/{shipmentPublicId}/actions/change-status` | `SHP_API_PKG.change_status` | Autenticado e autorizado |

Criação de SHIPMENT pode evoluir para operação exclusivamente interna quando a
orquestração logística estiver completa.

### 11.8 Financeiro

| Método | Rota | Package e operação | Acesso |
|---|---|---|---|
| GET | `/stores/{storePublicId}/balance` | `SBL_API_PKG.get_balance` | Autenticado |
| POST | `/stores/{storePublicId}/payouts` | `POT_API_PKG.request_payout` | Autenticado |
| GET | `/payouts/{payoutPublicId}` | `POT_API_PKG.get_payout` | Autenticado |

Comissão, ledger e transições administrativas de payout permanecem internas.

### 11.9 Pós-venda

| Método | Rota | Package e operação | Acesso |
|---|---|---|---|
| POST | `/orders/{orderPublicId}/stores/{storePublicId}/return-requests` | `RRQ_API_PKG.create_request` | Autenticado |
| GET | `/return-requests/{requestPublicId}` | `RRQ_API_PKG.get_request` | Autenticado |
| POST | `/return-requests/{requestPublicId}/attachments` | `RAT_API_PKG.add_attachment` | Autenticado |
| POST | `/orders/{orderPublicId}/stores/{storePublicId}/reviews` | `SRV_API_PKG.create_review` | Autenticado |
| GET | `/store-reviews/{reviewPublicId}` | `SRV_API_PKG.get_review` | Público conforme moderação |
| GET | `/stores/{storePublicId}/reputation` | `SRP_API_PKG.get_store` | Público |

### 11.10 Notificações

Não existe API package compatível com a borda. `NTF_SERVICE_PKG` é interno.
Rotas candidatas somente poderão ser aprovadas depois de autorização, paginação
e contrato de erro:

- `GET /notifications`;
- `GET /notifications/{notificationPublicId}`;
- `POST /notifications/{notificationPublicId}/actions/read`;
- `POST /notifications/{notificationPublicId}/actions/archive`.

## 12. Paginação e filtros

Listagens públicas ou potencialmente extensas não serão expostas sem paginação
aprovada. Enquanto o API package não receber os parâmetros e metadados
necessários, o handler correspondente permanece bloqueado para produção.

Filtros:

- usam query parameters em `camelCase`;
- possuem allowlist;
- não aceitam nome de coluna ou expressão SQL;
- valores inválidos produzem erro público de validação;
- ordenação possui campos públicos explicitamente autorizados.

## 13. Idempotência

Exigem idempotência:

- criação de pagamento;
- processamento de webhook;
- aceite ou recusa de composição parcial;
- consumo e liberação de reserva;
- solicitação de payout;
- ações que possam ser repetidas por retry de rede.

`Idempotency-Key` complementa, mas não substitui, unicidades funcionais e IDs
externos de evento. Política de persistência da chave deve ser aprovada antes
do endpoint correspondente.

## 14. Rate limit e segurança

Políticas mínimas distintas:

- login e criação de conta;
- catálogo público;
- escrita autenticada;
- perguntas e conteúdo público;
- webhook;
- operações financeiras;
- administração de STORE.

Rate limit não substitui autorização. Payload, path e query são validados antes
do caso de uso. CLOBs, URLs, texto e arquivos respeitam limites documentados.

## 15. Estado de implementação

### Implementado

- API packages listados neste documento;
- envelopes Core padronizados e validados nos módulos expostos;
- Public IDs nas fronteiras principais;
- contexto e segurança Core;
- status e bodies PL/SQL;
- idempotência de evento financeiro e criação de ORDER.
- fundação pública ORDS para criação de conta e login instalada e validada por
  HTTP externo;
- adapter autenticado, validação Bearer e handler de logout versionados;
- teste executável do adapter aprovado para token válido e credencial
  malformada;
- handler autenticado de logout instalado e validado por HTTP externo;
- revogação confirmada pela rejeição da reutilização do mesmo Bearer Token;
- framework oficial de plugins do ORDS 25.4 validado com conexão injetada no
  schema `BRECHOEXPRESS`;
- plugin Google instalado em `lib/ext`, com health check externo aprovado;
- endpoint `POST /auth/social/google` publicado pelo plugin e rejeição segura
  de token inválido confirmada com `401 BEX-AUTH-003`;
- domínio Oracle do login Google instalado e aprovado por cinco testes
  transacionais.

### Parcial ou divergente

- `ACC_SESSION_API_PKG` possui nome de API, mas contrato interno;
- paginação não está disponível em várias listagens;
- ator ainda é recebido como parâmetro PL/SQL e depende de binding ORDS
  confiável;
- autenticação de webhook ainda precisa de contrato do provedor;
- verificador Google está materializado, mas aguarda validação com um ID token
  real emitido para a audience aprovada;
- verificadores Apple e Facebook ainda não estão materializados;
- notificações não possuem API package;
- aceite parcial e reserva ainda não possuem operações executáveis.

### Não implementado

- templates e handlers além de conta, login, logout e login social Google;
- políticas de privilege/role ORDS;
- rate limit;
- CORS oficial;
- OpenAPI;
- suíte HTTP automatizada além da evidência manual inicial.

## 16. Critérios para materialização

Um endpoint somente pode ser criado quando:

- rota e método constarem neste catálogo ou em evolução aprovada;
- API package possuir envelope de sucesso e erro conforme runtime;
- autenticação e autorização estiverem definidas;
- ator vier de canal confiável;
- transação estiver correta;
- IDs internos não forem expostos;
- paginação existir quando necessária;
- idempotência estiver implementada quando exigida;
- handler garantir inicialização e limpeza do contexto;
- teste PL/SQL estiver aprovado;
- teste HTTP validar status, headers e body;
- OpenAPI estiver sincronizado.

## 17. Próxima etapa

Antes de gerar scripts ORDS:

1. instalar e testar por HTTP a fundação pública versionada;
2. materializar autenticação por sessão para rotas protegidas;
3. aprovar política de autenticação do webhook;
4. definir paginação comum;
5. definir CORS e rate limit por grupo;
6. produzir OpenAPI 3.1;
7. ampliar handlers por domínio e criar suíte HTTP automatizada.

## Conteúdo global da Home

| Método | Rota | Acesso |
|---|---|---|
| GET | `/platform-banners` | Público, somente ativos e vigentes |
| GET | `/platform-banners/{bannerPublicId}/image` | Público |
| GET | `/admin/platform-banners` | ROLE global ADMIN |
| POST | `/admin/platform-banners` | ROLE global ADMIN |
| PUT | `/admin/platform-banners/{bannerPublicId}` | ROLE global ADMIN |
| POST | `/admin/platform-banners/{bannerPublicId}/image` | ROLE global ADMIN |
| GET | `/me/roles` | Sessão autenticada |
