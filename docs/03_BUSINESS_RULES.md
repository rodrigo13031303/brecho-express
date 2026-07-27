# Regras de Negócio - Brechó Express

## Perfis
RN-001 O mesmo aplicativo atende Cliente e Brechó com perfis únicos e adaptados.
RN-002 O Brechó Express é um marketplace híbrido nacional de brechós, desapego, doação e logística inteligente.
RN-003 Brechós podem ser tradicionais, de igreja, ONGs, projetos sociais, lojas de economia circular ou revendedores parceiros.
RN-004 O termo oficial para o item listado é Achado, independente de o produto ser uma peça única ou possuir quantidade em estoque.

## Marketplace
RN-005 O Brechó Express conecta clientes a brechós e organizações que anunciam achados.
RN-006 O Brechó Gratuito vende pelo app com entrega.
RN-007 O Brechó Plus pode exibir endereço completo, rota, contato via WhatsApp e permitir reserva presencial.
RN-008 Eventos Temporários podem ser criados por brechós.

## Produtos
RN-009 Achados podem possuir quantidade em estoque.
RN-010 Achados podem ser peças únicas.
RN-011 Achados podem ser confirmados parcialmente pelo brechó.
RN-012 Avaliação pertence ao Brechó, nunca ao Achado.

## Carrinho
RN-013 O carrinho nunca reserva estoque.

## Checkout
RN-014 O checkout inicia a Purchase Request para verificar disponibilidade e quantidade.
RN-015 A Purchase Request pendente não reserva quantidade.
RN-016 A quantidade pode ser confirmada parcialmente pelo brechó.
RN-017 Pagamento ocorre somente após confirmação do brechó.
RN-018 Pedido nasce apenas após pagamento aprovado.

## Pedidos
RN-019 Um pedido pode gerar vários Shipments.
RN-020 Pedidos devem referenciar cliente, brechó, status, itens e entregas associadas.

## Logística
RN-021 A plataforma suporta Entrega Express e Entrega Nacional.
RN-022 A logística considera distância, peso, volume e modais disponíveis.
RN-023 Perfis de Entrega e custos são definidos conforme o tipo de entrega e a rota.

## Avaliações
RN-024 Avaliação do marketplace é do Brechó e alimenta a reputação do brechó.
RN-025 A reputação do Brechó é calculada a partir de avaliações, entregas, atendimento e conformidade.

## Doações
RN-026 A plataforma apoia doações e desapego como parte da economia circular.
RN-027 Itens podem ser oferecidos para doação ou colocados em campanhas de reaproveitamento.
RN-028 O fluxo de desapego deve ser transparente para cliente e brechó.

## Eventos
RN-029 Eventos Temporários podem ser criados por brechós para promover campanhas, bazares ou feiras.
RN-030 Eventos podem influenciar disponibilidade, promoções e logística.

## Confirmação, Reserva e Prazo

RN-031 A confirmação positiva do Brechó cria reserva temporária somente da quantidade confirmada.
RN-032 A reserva é consumida pelo pagamento aprovado ou liberada por expiração, cancelamento, recusa ou falha definitiva.
RN-033 Aprovação parcial exige aceite explícito do cliente antes da criação do pagamento.
RN-034 O prazo de pagamento é obtido de Business Configuration e nunca é constante oculta no código.
RN-035 O instante limite aplicado ao fluxo deve ser preservado mesmo que a configuração seja alterada posteriormente.
