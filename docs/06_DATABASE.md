# Banco de Dados - Brechó Express

## Visão Geral
O backend do Brechó Express utilizará Oracle como banco principal, com ORDS para expor APIs REST para o app Flutter.

## Modelo Inicial
### Entidades principais
- Usuário
- Perfil (Cliente / Brechó)
- Produto
- Pedido
- Brechó
- Categoria

## Considerações Técnicas
- Oracle para persistência transacional.
- ORDS para APIs REST padronizadas.
- Estrutura de dados preparada para catálogo, pedidos e histórico de entregas.

## Tabelas Sugeridas
- USERS
- PROFILES
- PRODUCTS
- ORDERS
- SHOPS
- CATEGORIES
- ORDER_ITEMS

## Requisitos de Dados
- Produtos devem armazenar título, preço, condição, descrição, categoria e brechó proprietário.
- Pedidos devem referenciar cliente, brechó, status e itens.
- Perfil deve diferenciar Cliente e Brechó no mesmo aplicativo.
