# Product Requirements Document (PRD)

## Nome do Produto
Brechó Express

## Contexto
Plataforma nacional de marketplace voltada para brechós, desapego, doações e economia circular. O mesmo aplicativo atende perfis de Cliente e Brechó, garantindo experiências alinhadas ao modelo de negócio e à linguagem ubíqua oficial.

## Problema
- Brechós atualmente dependem de redes sociais e marketplaces genéricos, fragmentados e pouco especializados.
- Achados com peças únicas ou estoque limitado são difíceis de vender em plataformas que não conhecem os requisitos de brechó.
- Há falta de integração entre venda online, retirada presencial e entrega rápida.
- Não existe uma plataforma especializada em economia circular que una vendas, desapego e doações com logística inteligente.

## Solução
O Brechó Express resolve esses problemas oferecendo:
- um marketplace especializado em brechós e economia circular;
- logística inteligente para entregas expressas e nacionais;
- Purchase Request para confirmar disponibilidade antes do pagamento;
- entrega expressa para clientes que buscam rapidez;
- reserva presencial para Brechó Plus;
- suporte a economia circular, desapego e doações.

## Objetivos do Produto
- Permitir que clientes descubram e comprem achados de brechós e organizações de economia circular.
- Permitir que brechós publiquem e gerenciem achados, estoque e eventos.
- Controlar disponibilidade por meio de Purchase Request e pagamento somente após confirmação.
- Oferecer entregas expressas e nacionais, bem como reserva presencial para Brechó Plus.
- Suportar avaliação do brechó, reputação e fluxo de desapego/doação.

## Perfil de Usuário
- Cliente: busca achados, desapega ou doa, utilizando busca, carrinho e checkout.
- Brechó: registra achados, gerencia catálogo, responde a solicitações de compra, define logística e acompanha pedidos.
- Brechó Plus: oferece reserva presencial, endereço completo, rota e contato via WhatsApp.
- Brechó Gratuito: vende pelo app com entrega e presença no marketplace.

## Funcionalidades Principais
- Autenticação e cadastro de Conta e Perfil.
- Feed de achados com filtros por categoria, marca e condição.
- Página de detalhe do achado e imagens.
- Carrinho que não reserva produtos.
- Purchase Request para confirmar disponibilidade e quantidade.
- Checkout e pagamento após confirmação.
- Pedido que pode gerar múltiplos Shipments.
- Entrega Express, Entrega Nacional e Perfil de Entrega.
- Eventos temporários e promoções.
- Avaliação e reputação do brechó.
- Doação e desapego.

## Métricas de Sucesso
- Usuários ativos mensalmente.
- Itens publicados e vendidos.
- Taxa de conversão de Purchase Request para Pedido.
- Tempo médio de confirmação de disponibilidade.
- Índice de avaliação e reputação do brechó.
- Volume de doações e desapegos realizados.

## Restrições
- Plataforma nacional, não limitada a uma cidade ou região.
- Base de dados Oracle com ORDS para APIs REST.
- Front-end em Flutter com Riverpod, GoRouter e arquitetura feature-first.
- Uso de Linguagem Ubíqua e domínio oficial segundo os documentos 12-14.
- Design System preservado e aplicado de forma consistente.
