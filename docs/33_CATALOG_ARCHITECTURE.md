# 33 — Arquitetura do módulo CATALOG

## 1. Objetivo

Definir a arquitetura inicial do módulo CATALOG antes de qualquer DDL ou package,
preservando a linguagem oficial em que PRODUCT é o termo técnico e Achado é o
termo apresentado ao usuário.

## 2. Escopo inicial

O primeiro ciclo do Catálogo compreende:

- CATEGORY como classificação obrigatória;
- BRAND como classificação opcional;
- PRODUCT como raiz do agregado Achado;
- criação, consulta, listagem, atualização e ciclo de publicação do Achado;
- quantidade disponível mantida pelo próprio PRODUCT até existir um contrato
  independente de estoque;
- autorização de escrita por meio da fronteira pública do módulo STORE.

PRODUCT_IMAGE, PRODUCT_QUESTION, reserva, carrinho, Purchase Request, estoque
independente, busca avançada, eventos e promoções permanecem fora deste ciclo.

## 3. Decisões estruturais

### 3.1 Ordem de implementação

```text
contrato de autorização de catálogo em STORE
↓
CATEGORY
↓
BRAND
↓
PRODUCT
↓
suíte consolidada de CATALOG
```

PRODUCT não será implementado antes de suas referências obrigatórias.

### 3.2 Status de PRODUCT

Na primeira versão, o ciclo de vida pertence diretamente a
`BEX_PRODUCT.PRD_STATUS`. A entidade configurável PRODUCT_STATUS e a coluna
`PST_ID` não serão materializadas no MVP.

Manter simultaneamente `PST_ID` e `PRD_STATUS` criaria duas fontes de verdade.
Uma futura migração para status configurável exigirá contrato e ADR próprios.

Estados iniciais:

- `DRAFT`: editável e não visível no catálogo público;
- `ACTIVE`: publicado e elegível para descoberta e compra;
- `INACTIVE`: retirado temporariamente pelo Brechó;
- `SOLD`: sem disponibilidade comercial;
- `ARCHIVED`: encerrado e preservado apenas para histórico.

`RESERVED` não é estado de PRODUCT. Carrinho não reserva, e a reserva comercial
pertence ao futuro fluxo de Purchase Request.

### 3.3 Quantidade

`PRD_QUANTITY` representa a disponibilidade anunciada nesta primeira versão:

- aceita inteiro maior ou igual a zero;
- quantidade `1` representa naturalmente peça única;
- quantidade maior que `1` representa itens equivalentes em estoque;
- carrinho não altera nem reserva quantidade;
- confirmação e reserva concorrente pertencem ao futuro módulo de compra;
- PRODUCT com quantidade zero não pode ser ativado;
- redução a zero por fluxo comercial futuro deverá levar o PRODUCT a `SOLD`.

Não será criada tabela de estoque antes de existir contrato próprio.

### 3.4 Classificação

CATEGORY é obrigatória e BRAND é opcional.

Referências recebidas pela API usam `categoryPublicId` e `brandPublicId`.
O Service resolve esses identificadores; IDs técnicos não atravessam a API.

CATEGORY e BRAND usam estado `ACTIVE` ou `INACTIVE`. Um Achado novo ou alterado
só pode referenciar uma classificação ACTIVE. A inativação de uma referência
não apaga nem invalida historicamente os Achados existentes.

### 3.5 Auditoria

Auditoria segue o padrão físico vigente:

- timestamps `TIMESTAMP(6)`;
- `createdBy` e `updatedBy` são atores técnicos numéricos;
- não existe foreign key de auditoria para PROFILE;
- ACCOUNT é a identidade técnica usada na autorização;
- PROFILE não participa estruturalmente de PRODUCT.

## 4. Propriedade e autorização

Toda escrita de PRODUCT exige uma STORE existente e um ator autorizado.

Podem administrar o catálogo da STORE:

- a ACCOUNT proprietária;
- STORE_USER `ACTIVE` com papel `ADMIN`;
- STORE_USER `ACTIVE` com papel `MANAGER`;
- STORE_USER `ACTIVE` com papel `COLLABORATOR`.

`ATTENDANT` não altera catálogo no MVP.

O módulo CATALOG não consulta `BEX_STORE` nem `BEX_STORE_USER` diretamente.
`STR_SERVICE_PKG` deverá expor um contrato público específico para validar a
permissão de catálogo e retornar a identidade interna da STORE somente ao
Service consumidor. Essa evolução será implementada e testada antes de PRODUCT.

## 5. Modelo físico candidato

### 5.1 BEX_CATEGORY

- `CAT_ID NUMBER(19)` identity;
- `CAT_PUBLIC_ID CHAR(32 CHAR)`;
- `CAT_NAME VARCHAR2(200 CHAR)`;
- `CAT_SLUG VARCHAR2(120 CHAR)`;
- `CAT_DESCRIPTION VARCHAR2(1000 CHAR)` anulável;
- `CAT_STATUS VARCHAR2(20 CHAR)`;
- auditoria temporal e de ator conforme padrão vigente.

Unicidade: Public ID e slug global.

### 5.2 BEX_BRAND

- `BRD_ID NUMBER(19)` identity;
- `BRD_PUBLIC_ID CHAR(32 CHAR)`;
- `BRD_NAME VARCHAR2(200 CHAR)`;
- `BRD_SLUG VARCHAR2(120 CHAR)`;
- `BRD_DESCRIPTION VARCHAR2(1000 CHAR)` anulável;
- `BRD_STATUS VARCHAR2(20 CHAR)`;
- auditoria temporal e de ator conforme padrão vigente.

Unicidade: Public ID e slug global.

### 5.3 BEX_PRODUCT

- `PRD_ID NUMBER(19)` identity;
- `PRD_PUBLIC_ID CHAR(32 CHAR)`;
- `STR_ID NUMBER(19)`;
- `CAT_ID NUMBER(19)`;
- `BRD_ID NUMBER(19)` anulável;
- `PRD_TITLE VARCHAR2(200 CHAR)`;
- `PRD_SLUG VARCHAR2(200 CHAR)`;
- `PRD_DESCRIPTION VARCHAR2(4000 CHAR)` anulável;
- `PRD_PRICE NUMBER(12,2)`;
- `PRD_QUANTITY NUMBER(12)`;
- `PRD_CONDITION VARCHAR2(20 CHAR)`;
- peso e dimensões positivas, anuláveis e coerentes como conjunto;
- `PRD_STATUS VARCHAR2(20 CHAR)`;
- auditoria temporal e de ator conforme padrão vigente.

Unicidade: Public ID global e slug por STORE.

## 6. Condição física

Valores iniciais:

- `NEW`;
- `LIKE_NEW`;
- `GOOD`;
- `FAIR`.

A API recebe e devolve os códigos técnicos. A tradução para a linguagem da
interface pertence ao cliente. Condição não é uma entidade configurável no MVP.

## 7. Ciclo de vida

| Origem | Destino | Condição |
|---|---|---|
| `DRAFT` | `ACTIVE` | STORE ativa, classificação ativa, preço válido e quantidade positiva |
| `DRAFT` | `ARCHIVED` | encerramento do rascunho |
| `ACTIVE` | `INACTIVE` | retirada temporária pelo Brechó |
| `ACTIVE` | `SOLD` | indisponibilidade comercial confirmada |
| `ACTIVE` | `ARCHIVED` | encerramento definitivo |
| `INACTIVE` | `ACTIVE` | invariantes de publicação novamente satisfeitas |
| `INACTIVE` | `ARCHIVED` | encerramento definitivo |
| `SOLD` | `ACTIVE` | reposição explícita com quantidade positiva |
| `SOLD` | `ARCHIVED` | encerramento definitivo |

`ARCHIVED` é terminal. Alteração comum de conteúdo em `ARCHIVED` é proibida.

## 8. Camadas

Para cada prefixo implementado:

```text
API
↓
SERVICE
├── RULE
└── REPOSITORY
    ↓
  TABLE
```

- API: JSON, envelope, status HTTP e transação;
- Service: casos de uso, autorização e tradução entre módulos;
- Rule: validações, normalizações e transições puras;
- Repository: SQL e locking, sem transação final.

Packages previstas:

- `CAT_RULE_PKG`, `CAT_REPOSITORY_PKG`, `CAT_SERVICE_PKG`, `CAT_API_PKG`;
- `BRD_RULE_PKG`, `BRD_REPOSITORY_PKG`, `BRD_SERVICE_PKG`, `BRD_API_PKG`;
- `PRD_RULE_PKG`, `PRD_REPOSITORY_PKG`, `PRD_SERVICE_PKG`, `PRD_API_PKG`.

## 9. Contrato público inicial de PRODUCT

```json
{
  "productPublicId": "...",
  "storePublicId": "...",
  "categoryPublicId": "...",
  "brandPublicId": null,
  "title": "...",
  "slug": "...",
  "description": null,
  "price": 0,
  "quantity": 1,
  "condition": "GOOD",
  "status": "DRAFT",
  "weight": null,
  "width": null,
  "height": null,
  "length": null,
  "createdAt": "...",
  "updatedAt": "..."
}
```

IDs técnicos e atores de auditoria nunca são expostos.

## 10. Casos de uso iniciais

- criar Achado em DRAFT;
- consultar por Public ID;
- consultar por STORE e slug;
- listar Achados de uma STORE;
- listar catálogo público ACTIVE com filtros aprovados;
- atualizar campos editáveis com semântica PATCH;
- publicar;
- retirar temporariamente;
- marcar como vendido;
- arquivar;
- verificar disponibilidade de slug dentro da STORE.

Busca textual, paginação definitiva e ordenação pública serão contratadas antes
da API pública de feed; não serão improvisadas no Repository.

## 11. Concorrência

- constraints garantem Public ID e slug por STORE;
- conflitos físicos são traduzidos pelo Service;
- atualização e transição usam locking da linha de PRODUCT;
- quantidade não será reservada por este módulo;
- operações futuras de compra deverão tratar concorrência de disponibilidade em
  contrato transacional próprio.

## 12. Próxima entrega executável

Antes do DDL de CATEGORY, a documentação permanente deverá ser alinhada para:

1. remover `PST_ID` de PRODUCT no MVP;
2. registrar `PRD_STATUS` como fonte única do ciclo de vida;
3. corrigir auditoria baseada em PROFILE;
4. completar as camadas Oracle previstas;
5. registrar o contrato público de autorização de catálogo em STORE.

Somente após esse alinhamento iniciaremos CATEGORY, seguindo:

```text
arquitetura
↓
DDL
↓
RULE
↓
REPOSITORY
↓
SERVICE
↓
API
↓
Oracle
↓
Git
```
