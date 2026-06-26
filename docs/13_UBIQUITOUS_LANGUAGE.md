# Linguagem Ubíqua Oficial - Brechó Express

## Objetivo
Este documento define a Linguagem Ubíqua oficial do Brechó Express. É a referência para desenvolvedores, analistas, IA (ChatGPT/Codex), documentação, APIs e interface de usuário. Toda nova funcionalidade deve utilizar obrigatoriamente esta nomenclatura para garantir consistência e evitar ambiguidades.

## Introdução
No Domain-Driven Design (DDD), a Linguagem Ubíqua é o vocabulário compartilhado entre o time de desenvolvimento e os especialistas do negócio. Ela é formada por termos comuns, claros e consistentes que descrevem o domínio da aplicação.

A Linguagem Ubíqua evita jargões isolados e garante que todas as áreas da empresa utilizem exatamente os mesmos termos. Isso reduz erros de entendimento, melhora a comunicação entre analistas, desenvolvedores e usuários, e garante que a API e a interface falem a mesma linguagem do negócio.

## Princípios
- A linguagem do negócio prevalece sobre a linguagem técnica.
- O cliente nunca verá nomes técnicos do banco.
- Oracle, Flutter, APIs e documentação devem utilizar o mesmo domínio.
- Sempre que houver conflito entre termo técnico e termo comercial, prevalece o termo comercial na interface.

## Tabela Oficial de Terminologia
| Termo Técnico | Nome apresentado ao Cliente | Descrição |
|---|---|---|
| Account | Conta | Entidade de autenticação e credenciais do usuário. |
| Profile | Perfil | Representa a pessoa cadastrada na plataforma. Um Perfil pode atuar como cliente, administrador, dono de brechó ou atendente de um brechó. |
| Store | Brechó | Representa qualquer organização que anuncia produtos na plataforma, incluindo brechó tradicional, brechó de igreja, ONG, projeto social, loja de economia circular ou revendedor parceiro. |
| Store Event | Evento do Brechó | Ação ou campanha especial realizada por um brechó. |
| Product | Achado | Representa qualquer item anunciado na plataforma, podendo ser uma peça única ou possuir quantidade em estoque. O nome comercial continua sendo "Achado". |
| Category | Categoria | Classificação do tipo de achado. |
| Brand | Marca | Identificação da marca do achado. |
| Cart | Carrinho | Área temporária onde o cliente reúne achados antes do checkout. |
| Purchase Request | Solicitação de Compra | Etapa de verificação de disponibilidade antes do pagamento. |
| Order | Pedido | Compra confirmada após pagamento aprovado. |
| Shipment | Entrega | Remessa ou despacho de itens de um pedido. |
| Payment | Pagamento | Transação financeira aprovada para finalizar o pedido. |
| Commission | Comissão | Percentual ou valor cobrado sobre a venda do achado. |
| Review | Avaliação | Feedback do cliente sobre o brechó. |
| Store Reputation | Reputação | Métrica consolidada do desempenho e confiança do brechó. |
| Return Request | Atendimento Pós-Venda | Solicitação de devolução ou suporte após a venda. |
| Address | Endereço | Localização física de clientes e brechós. |
| Delivery Profile | Perfil de Entrega | Configuração ou tipo de entrega disponível para um pedido. |

## Palavras proibidas na interface
Nunca utilizar:
- Produto
- Loja
- Seller
- Vendor
- User
- Delete Produto
- Cancelamento de Produto

Sempre utilizar:
- Achado
- Brechó
- Perfil
- Arquivar Achado
- Atendimento Pós-Venda

## Verbos Oficiais
- Cadastrar Brechó
- Publicar Achado
- Comprar
- Desapegar
- Doar
- Reservar
- Receber
- Entregar
- Avaliar
- Arquivar
- Favoritar
- Seguir Brechó
- Solicitar Coleta

## Termos do Negócio
### Achado
Achado é o nome comercial utilizado pelo Brechó Express para representar qualquer Product. O objetivo é transmitir ao cliente a sensação de descoberta típica dos brechós. No banco de dados, o conceito permanece como PRODUCT.

### Brechó
Organização que anuncia produtos na plataforma. Pode representar brechó tradicional, brechó de igreja, ONG, projeto social, loja de economia circular ou revendedor parceiro. O termo Brechó é utilizado para qualquer entidade que opera como ofertante de achados.

### Brechó Plus
Brechó com benefícios adicionais, como exibição de endereço completo, rota, contato via WhatsApp e opção de reserva presencial.

### Brechó Gratuito
Brechó sem pacote Plus, que vende pelo app com entrega, mas não exibe rota completa ou reservas presenciais.

### Evento
Período programado de funcionamento ou campanha do brechó. Exemplos: Brechó de Páscoa, Brechó de Natal, Bazar Beneficente, Feira Temporária e Campanhas Promocionais.

### Entrega Express
Modalidade de entrega rápida, local e priorizada, otimizada por distância, peso e volume.

### Entrega Nacional
Modalidade de entrega interestadual ou de longa distância, com logística apropriada para peso, volume e modais disponíveis.

### Reserva Presencial
Ação de reservar um achado para retirada física no brechó, disponível para Brechó Plus.

### Economia Circular
Modelo que valoriza reutilização, desapego, doação e menor descarte de roupas e acessórios, fomentado pelo marketplace.

### Solicitação de Compra
Etapa em que a disponibilidade e quantidade do achado são verificadas antes do pagamento.

### Pedido
Registro de compra efetivado após pagamento aprovado.

### Checkout
Fluxo final de compra no app, que inicia com a solicitação de compra e termina com a criação do pedido.

### Comissão
Valor ou percentual aplicado sobre a venda do achado, repassado ao marketplace ou parceiros.

### Marketplace
O Brechó Express é um marketplace especializado em economia circular que conecta pessoas, brechós e organizações para compra, venda, doação e reutilização de produtos.

### Desapego
Ação de colocar itens à venda ou doação como parte da economia circular.

### Doação
Ação de transferir um item sem pagamento, dentro de um fluxo de sustentabilidade e reaproveitamento.

## Diretrizes para Desenvolvimento
- Oracle utilizará nomes técnicos (PRODUCT, STORE, PROFILE).
- Flutter exibirá nomes comerciais (Achado, Brechó, Perfil).
- APIs utilizarão nomes técnicos REST, mantendo consistência com o modelo de dados.
- A documentação utilizará ambos quando necessário, preferindo o termo comercial para interface e explicações ao usuário.

## Linguagem por Camada
| Camada | Nome |
|---|---|
| Oracle | PRODUCT |
| API REST | product |
| Flutter (interno) | Product |
| Interface | Achado |

| Camada | Nome |
|---|---|
| Oracle | STORE |
| API REST | store |
| Flutter | Store |
| Interface | Brechó |

| Camada | Nome |
|---|---|
| Oracle | PURCHASE_REQUEST |
| API REST | purchase-request |
| Flutter | PurchaseRequest |
| Interface | Solicitação de Compra |

A tradução entre linguagem técnica e comercial pertence exclusivamente à camada de apresentação.

## Regra de Ouro
Todo novo conceito criado durante o desenvolvimento deverá ser registrado neste documento antes da implementação técnica.

Nenhuma nova entidade, funcionalidade ou módulo poderá utilizar nomenclaturas não documentadas na Linguagem Ubíqua.

## Exemplos
- Banco:
  - `PRODUCT`
  - API: `/api/product`
  - Flutter: Achado

- Banco:
  - `STORE`
  - Flutter: Brechó

- Banco:
  - `PURCHASE_REQUEST`
  - Flutter: Solicitação de Compra

## Exemplos de Conversação
Cliente:
"Quero comprar um Achado."

Flutter:
ProductDetailPage

API:
GET /api/product/{id}

Oracle:
BEX_PRODUCT

Cliente:
"Quero reservar um Achado."

Flutter:
PurchaseRequest

API:
POST /api/purchase-request

Oracle:
BEX_PURCHASE_REQUEST

Objetivo: Demonstrar que todas as camadas representam o mesmo conceito utilizando nomenclaturas diferentes.

## Termos Reservados para Futuras Versões
- Wallet
- Programa de Fidelidade
- Badge
- Live Commerce
- Busca por Imagem
- IA para descrição automática
- IA para sugestão de preço
- Campanhas Patrocinadas
- Marketplace Ads
- Closet
- Brechó Certificado
- Reserva Presencial
- Eventos Temporários

Estes conceitos estão reservados para versões futuras e deverão ser documentados neste mesmo arquivo quando forem implementados.

## Conclusão
Este documento é a referência oficial da linguagem do Brechó Express. Todos os desenvolvedores, IA e documentação futura devem respeitar essa nomenclatura para manter coesão entre negócio, implementação e experiência do usuário.
