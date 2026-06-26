# Modelo de Domínio Oficial - Brechó Express

## 1. Objetivo do documento
Este documento define o modelo de domínio oficial do Brechó Express, alinhando linguagem ubíqua, nomenclaturas Oracle, contratos de API e estrutura de features Flutter. Tem como meta garantir consistência entre negócio, banco de dados e camadas de aplicação.

## 2. Linguagem ubíqua oficial
- O banco utiliza nomes técnicos em inglês.
- A interface utiliza termos de negócio em português.
- O termo central de catálogo é "Achado" para `PRODUCT`.
- O termo central de operação comercial é "Brechó" para `STORE`.
- Todos os membros do time devem usar essa linguagem nas conversas, documentação e código de domínio.

## 3. Glossário de termos e mapeamento
| Termo na interface | Termo técnico | Tabela Oracle | Sigla | API | Feature Flutter |
|---|---|---|---|---|---|
| Conta | ACCOUNT | BEX_ACC | ACC | /api/account | account |
| Perfil | PROFILE | BEX_PFL | PFL | /api/profile | profile |
| Papel | ROLE | BEX_RLE | RLE | /api/account | account |
| PerfilPapel | PROFILE_ROLE | BEX_PRL | PRL | /api/account | account |
| Brechó | STORE | BEX_STR | STR | /api/store | store |
| Tipo de Brechó | STORE_TYPE | BEX_STY | STY | /api/store | store |
| Endereço | ADDRESS | BEX_ADD | ADD | /api/store | store |
| Categoria | CATEGORY | BEX_CAT | CAT | /api/product | product |
| Marca | BRAND | BEX_BRD | BRD | /api/product | product |
| Achado | PRODUCT | BEX_PRO | PRO | /api/product | product |
| Status do Achado | PRODUCT_STATUS | BEX_PRS | PRS | /api/product | product |
| Condição do Achado | PRODUCT_CONDITION | BEX_PRD | PRD | /api/product | product |
| Imagem do Achado | PRODUCT_IMAGE | BEX_PIM | PIM | /api/product | product |
| Carrinho | CART | BEX_CRT | CRT | /api/cart | cart |
| Item do Carrinho | CART_ITEM | BEX_CIT | CIT | /api/cart | cart |
| Solicitação de Compra | PURCHASE_REQUEST | BEX_PUR | PUR | /api/purchase-request | purchase_request |
| Status da Solicitação de Compra | PURCHASE_REQUEST_STATUS | BEX_PUS | PUS | /api/purchase-request | purchase_request |
| Pedido | ORDER | BEX_ODR | ODR | /api/order | order |
| Item do Pedido | ORDER_ITEM | BEX_OIT | OIT | /api/order | order |
| Remessa | SHIPMENT | BEX_SHP | SHP | /api/order | order |
| Entrega | DELIVERY | BEX_DLV | DLV | /api/order | order |
| Pagamento | PAYMENT | BEX_PMT | PMT | /api/payment | payment |
| Avaliação do Brechó | STORE_REVIEW | BEX_SRV | SRV | /api/store | store |
| Reputação do Brechó | STORE_REPUTATION | BEX_RPT | RPT | /api/store | store |

## 4. Entidades principais e responsabilidades

### ACCOUNT
Responsabilidade: gerenciar credenciais e credenciais de acesso do usuário.
- Armazena e-mail, senha, status e informações de autenticação.
- Relaciona-se com PROFILE para identificar perfil de cliente ou brechó.

### PROFILE
Responsabilidade: representar o usuário no domínio, seja cliente ou brechó.
- Contém dados de cadastro, nome, identificação e relacionamento com endereços.
- Define distinção entre perfil de cliente e perfil de brechó.

### ROLE
Responsabilidade: representar permissões ou funções no sistema.
- Define papéis como cliente, brechó, administrador ou suporte.
- Usada para controle de autorização.

### PROFILE_ROLE
Responsabilidade: vincular perfis a papéis.
- Implementa associação N:N entre PROFILE e ROLE.
- Permite aplicar múltiplas funções a um perfil.

### STORE
Responsabilidade: representar o brechó que oferece achados.
- Contém dados empresariais e links para endereço, reputação e avaliações.
- Relaciona-se com PRODUCT para catálogo e com ORDER para vendas.

### STORE_TYPE
Responsabilidade: classificar o tipo de brechó.
- Identifica categorias de loja, como loja física, pop-up, consignação ou curadoria.

### ADDRESS
Responsabilidade: armazenar localidades.
- Usada por perfil de brechó, cliente e logística de entrega.
- Normaliza rua, bairro, cidade, estado e CEP.

### CATEGORY
Responsabilidade: classificar achados.
- Agrupa produtos por categorias de moda e estilo.
- Permite filtragem e navegação no catálogo.

### BRAND
Responsabilidade: representar marcas de achados.
- Associa marca ao produto para apresentação e filtro.

### PRODUCT
Responsabilidade: representar o achado em si.
- Contém título, descrição, preço, categoria, marca, condição e brechó proprietário.
- Não é excluído fisicamente; seu ciclo de vida é controlado pelo status.

### PRODUCT_STATUS
Responsabilidade: representar o estado de visibilidade ou estoque do achado.
- Exemplos: ativo, reservado, vendido, inativo.
- Controla se o achado aparece no catálogo.

### PRODUCT_CONDITION
Responsabilidade: classificar a condição do achado.
- Exemplos: novo, seminovo, usado, reformado.
- Ajuda na apresentação do produto ao cliente.

### PRODUCT_IMAGE
Responsabilidade: armazenar imagens do achado.
- Mantém galeria do produto com ordem e metadados.

### CART
Responsabilidade: representar o carrinho temporário do cliente.
- Contém itens selecionados para possível compra.
- Não reserva produto e não garante disponibilidade.

### CART_ITEM
Responsabilidade: representar cada item dentro do carrinho.
- Associa produto, quantidade e preço estimado ao carrinho.

### PURCHASE_REQUEST
Responsabilidade: representar a intenção de compra antes do pedido.
- Agrupa itens de um carrinho para checagem de disponibilidade.
- Serve como base para autorização de pagamento.

### PURCHASE_REQUEST_STATUS
Responsabilidade: controlar o fluxo da solicitação de compra.
- Exemplos: pendente, aprovado, recusado, expirado.

### ORDER
Responsabilidade: representar a compra confirmada.
- Nasce somente após pagamento aprovado.
- Contém dados de cliente, total, status e referências de pagamento.

### ORDER_ITEM
Responsabilidade: representar cada item dentro do pedido.
- Registra produto, quantidade, preço final e brechó fornecedor.

### SHIPMENT
Responsabilidade: coordenar a remessa de itens.
- Um pedido pode gerar vários shipments quando envolve múltiplos brechós ou roteiros.
- Agrupa itens e indica transportadora/serviço.

### DELIVERY
Responsabilidade: rastrear a entrega física.
- Representa o acompanhamento desde a expedição até a entrega ao cliente.
- Vinculada a shipment e ordem de entrega.

### PAYMENT
Responsabilidade: registrar o pagamento do cliente.
- Só ocorre após confirmação de disponibilidade dos itens.
- Pode cobrir itens de vários brechós em uma única transação.

### STORE_REVIEW
Responsabilidade: representar avaliação do brechó.
- Avaliação é do Brechó/STORE, nunca do Achado/PRODUCT.
- Relaciona cliente, brechó, nota e comentário.

### STORE_REPUTATION
Responsabilidade: consolidar indicadores do brechó.
- Agrega avaliações, taxa de cancelamento e métricas de serviço.
- Alimenta ranking e confiança do marketplace.

## 5. Regras fundamentais
- Carrinho não reserva produto. A inclusão de itens em `CART` é apenas uma intenção de compra.
- Pagamento só ocorre após confirmação de disponibilidade dos itens no `PURCHASE_REQUEST`.
- Pedido nasce somente após pagamento aprovado; `ORDER` é criação de compra finalizada.
- Cliente pode pagar uma única vez por itens de vários brechós em uma transação unificada.
- Um `ORDER` pode gerar vários `SHIPMENT`s para diferentes brechós ou rotas de entrega.
- Avaliação é do Brechó/STORE, nunca do Achado/PRODUCT.
- Produto nunca é excluído fisicamente; seu ciclo de vida é controlado por `PRODUCT_STATUS`.

## 6. Padrão de nomenclatura Oracle
- Tabelas começam com prefixo `BEX_`.
- Cada tabela tem sigla única de 3 letras.
- Colunas próprias usam a sigla da tabela como prefixo.
  - Exemplo: `PRO_ID`, `PRO_TITLE`, `PRO_PRICE`.
- FKs usam a sigla da tabela referenciada.
  - Exemplo: `PRO_STR_ID` referencia `BEX_STR(STR_ID)`.
- Chaves primárias usam `ID` com `identity` / `autoincrement` em Oracle.
  - Exemplo: `ACC_ID`, `PRO_ID`, `ODR_ID`.
- Nomes de índice e constraint seguem o domínio e siglas.

## 7. Padrão de packages Oracle
- Packages Oracle seguem o domínio de negócio.
- Nomes oficiais:
  - `PKG_ACCOUNT`
  - `PKG_PROFILE`
  - `PKG_STORE`
  - `PKG_PRODUCT`
  - `PKG_ORDER`
  - `PKG_PAYMENT`
- Cada package concentra regras e operações da respectiva área.
- Exemplo: `PKG_PRODUCT` para catálogo de achados, status e imagens.

## 8. Padrão de APIs
- APIs REST seguem o domínio principal.
- Endpoints oficiais:
  - `/api/account`
  - `/api/profile`
  - `/api/store`
  - `/api/product`
  - `/api/cart`
  - `/api/purchase-request`
  - `/api/order`
  - `/api/payment`
- Cada API expõe recursos alinhados à feature correspondente.
- As APIs devem utilizar linguagem de negócio voltada ao modelo do Brechó Express.

## 9. Padrão de features Flutter
- O app Flutter segue a divisão por domínio nas features.
- Features oficiais:
  - `account`
  - `profile`
  - `store`
  - `product`
  - `cart`
  - `purchase_request`
  - `order`
  - `payment`
- Cada feature deve consumir a API do mesmo domínio e mapear as entidades do modelo.
- A separação deve manter coesão de responsabilidade e facilitar testes.
