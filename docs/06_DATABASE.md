# Banco de Dados - Brechó Express

## Visão Geral
O backend do Brechó Express utiliza Oracle como banco principal, com ORDS para expor APIs REST alinhadas ao domínio. O modelo de dados segue a linguagem ubíqua oficial e a arquitetura nacional de economia circular.

## Entidades principais
- ACCOUNT
- PROFILE
- STORE
- PRODUCT
- CATEGORY
- BRAND
- CART
- PURCHASE_REQUEST
- ORDER
- SHIPMENT
- PAYMENT
- STORE_REVIEW
- STORE_REPUTATION
- ADDRESS

## Considerações Técnicas
- Oracle para persistência transacional.
- ORDS para APIs REST padronizadas e integradas.
- Tabelas usam prefixo `BEX_` e nomes completos de entidade.
- Siglas de três letras são utilizadas apenas para chaves primárias, chaves estrangeiras, prefixos de packages e nomes de colunas próprias.
- Chaves primárias usam identity/autoincrement.
- FKs seguem siglas de tabelas referenciadas.
- Dados modelados para suporte a estoque, quantidade parcial, múltiplos shipments e reserva presencial.

## Convenção de Nomes
- Tabelas: `BEX_ACCOUNT`, `BEX_PROFILE`, `BEX_STORE`, `BEX_PRODUCT`, `BEX_PURCHASE_REQUEST`, etc.
- PKs/FKs/colunas: `ACC_ID`, `PFL_ID`, `STR_ID`, `PRD_ID`, `PUR_ID`, `ODR_ID`, `SHP_ID`, `PMT_ID`, `SRV_ID`, `RPT_ID`, `ADD_ID`.
- Nunca utilizar tabelas abreviadas como `BEX_PRO`, `BEX_STR` ou `BEX_PUR`.

## Tabelas Principais
- BEX_ACCOUNT
- BEX_PROFILE
- BEX_STORE
- BEX_PRODUCT
- BEX_CATEGORY
- BEX_BRAND
- BEX_CART
- BEX_PURCHASE_REQUEST
- BEX_ORDER
- BEX_SHIPMENT
- BEX_PAYMENT
- BEX_STORE_REVIEW
- BEX_STORE_REPUTATION
- BEX_ADDRESS

## Requisitos de Dados
- Achados devem armazenar título, preço, condição, descrição, quantidade em estoque, categoria, marca e brechó proprietário.
- Purchase Request deve registrar disponibilidade, itens solicitados e quantidade confirmada.
- Pedidos devem referenciar cliente, brechó, status, itens e possíveis shipments.
- Perfis devem diferenciar Cliente e Brechó, preservando o mesmo app para ambos.
- Avaliação e reputação são vinculadas ao Brechó, não ao Achado.
