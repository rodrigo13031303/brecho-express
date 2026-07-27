# API do Brechó Express

> **Status:** visão conceitual histórica. Endpoints deste arquivo são exemplos
> não normativos. Novos contratos seguem `27_API_STANDARDS.md`,
> `31_API_RUNTIME_CONTRACT.md`, ADRs e a arquitetura do módulo. Recursos REST
> usam plural e versionamento aprovado.

## Visão Geral
A API é construída sobre Oracle + ORDS para expor recursos REST consumidos pelo app Flutter. As rotas seguem o domínio oficial e a Linguagem Ubíqua do projeto.

## Fluxo Oficial da API
Login
↓
Home
↓
Achados
↓
Carrinho
↓
Purchase Request
↓
Pagamento
↓
Pedido
↓
Shipment
↓
Avaliação

As APIs acompanham a jornada de negócio, mas não existe correspondência
obrigatória de uma chamada pública para cada etapa interna. A sequência
normativa pertence aos contratos especializados.

## Endpoints Históricos
- `POST /auth/login`
- `GET /api/product`
- `GET /api/product/{id}`
- `GET /api/category`
- `GET /api/store/{id}`
- `GET /api/cart`
- `POST /api/purchase-request`
- criação direta de Order por endpoint externo não é permitida; ORDER nasce de
  `PAYMENT_APPROVED`, conforme ADR-024;
- `GET /api/order/{id}`
- `POST /api/payment`
- `GET /api/store/{id}/review`

## Contratos Principais
### Autenticação
- Login com e-mail e senha.
- Gestão de contas e perfis.

### Achados
- Listagem de achados.
- Detalhe de achado.
- Busca e filtros por categoria, marca e condição.

### Checkout
- Criação de Purchase Request para confirmar disponibilidade.
- POST `/api/purchase-request` para verificar quantidade e disponibilidade.
- Criação de Order após pagamento aprovado.

### Entregas
- Suporte a Entrega Express e Entrega Nacional.
- Shipments vinculados a Order e Brechó.

### Brechó
- Detalhe do Brechó, endereço e reputação.
- Eventos temporários e promoção.

## Consumo no Flutter
- Dio para chamadas HTTP.
- Repositórios e providers para abstração da API.
- Mapeamento de JSON para entidades de domínio conforme Linguagem Ubíqua.
