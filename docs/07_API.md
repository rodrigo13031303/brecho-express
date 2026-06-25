# API do Brechó Express

## Visão Geral
A API será construída sobre Oracle + ORDS para expor recursos REST consumidos pelo app Flutter.

## Principais Endpoints
- `POST /auth/login`
- `GET /products`
- `GET /products/{id}`
- `GET /categories`
- `POST /orders`
- `GET /orders/{id}`
- `GET /shops/{id}`

## Contratos Iniciais
### Autenticação
- Login com e-mail e senha.

### Produtos
- Listagem de achados.
- Detalhe do produto.
- Busca e filtros por categoria.

### Pedidos
- Criação de pedido.
- Status do pedido.

## Consumo no Flutter
- Dio para chamadas HTTP.
- Repositórios para abstração da API.
- Mapeamento de JSON para entidades de domínio.
