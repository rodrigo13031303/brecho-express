# Fluxos de Negócio - Brechó Express

## 1. Objetivo
Documentar os principais fluxos de negócio do Brechó Express, definindo como clientes, brechós e operações comerciais interagem na plataforma. Este documento serve como referência alinhada ao modelo de domínio e às regras de operação do marketplace.

## 2. Contexto
O Brechó Express é uma plataforma nacional de economia circular com foco em brechós, achados, entrega rápida, venda online, reserva presencial para plano Plus e logística inteligente. O objetivo é conectar clientes a brechós de forma eficiente, flexível e confiável.

## 3. Regras gerais de negócio
- Carrinho não reserva produto.
- Reserva só acontece ao iniciar checkout.
- Brechó confirma disponibilidade e quantidade.
- Pagamento só ocorre após confirmação.
- Pedido nasce somente após pagamento aprovado.
- Um checkout pode gerar um `ORDER` com vários `SHIPMENT`s.
- Avaliação é do Brechó/STORE, nunca do Achado/PRODUCT.
- Brechó gratuito vende pelo app com entrega.
- Brechó Plus pode exibir endereço completo, rota, WhatsApp e reserva presencial.
- Produtos podem ter quantidade maior que 1.
- A logística deve considerar distância, peso, volume e modais disponíveis.

## 4. Fluxos de negócio

### 4.1 Cadastro de Cliente
1. Cliente acessa o app e escolhe criar conta.
2. O sistema solicita dados básicos: nome, e-mail, senha, telefone e endereço.
3. O cliente confirma os dados e envia o cadastro.
4. O sistema cria `ACCOUNT` e `PROFILE` do tipo cliente.
5. Cliente recebe confirmação e passa a poder navegar, favoritar e iniciar compra.

### 4.2 Cadastro de Brechó
1. Usuário cadastra-se com e-mail, senha e dados de contato.
2. Inicia-se registro do brechó: nome, descrição, tipo de brechó, endereço e informações de contato.
3. Brechó gratuito define catálogo, políticas de entrega e dados básicos.
4. Para Brechó Plus, adiciona endereço completo, rota e contato via WhatsApp.
5. O sistema cria `ACCOUNT`, `PROFILE` e `STORE` com vínculo à `PROFILE`.
6. Brechó passa a poder publicar achados e receber pedidos.

### 4.3 Publicação de Achado
1. Brechó acessa o painel e escolhe publicar novo achado.
2. Informa título, descrição, preço, quantidade, categoria, marca e condição.
3. Anexa imagens do produto e define status inicial (ex: ativo).
4. O sistema grava `PRODUCT`, `PRODUCT_IMAGE`, `PRODUCT_STATUS`, `PRODUCT_CONDITION`, `CATEGORY` e `BRAND`.
5. Achado entra em catálogo e fica disponível para clientes visualizarem.

### 4.4 Compra Online
1. Cliente adiciona itens ao `CART`.
2. Cliente inicia checkout, gerando um `PURCHASE_REQUEST`.
3. O sistema envia solicitação aos brechós envolvidos para confirmar disponibilidade e quantidade.
4. Cada brechó confirma ou ajusta a quantidade disponível.
5. Após todas confirmações, o sistema autoriza pagamento.
6. Cliente realiza pagamento.
7. Com pagamento aprovado, o sistema cria `ORDER` e `ORDER_ITEM`s.
8. Caso haja mais de um brechó, o `ORDER` pode gerar vários `SHIPMENT`s.
9. O cliente recebe confirmação de compra e previsão de entrega.

### 4.5 Compra com quantidade parcial confirmada
1. Cliente adiciona quantidade de um produto ao carrinho.
2. No checkout, o `PURCHASE_REQUEST` é enviado ao brechó.
3. O brechó confirma parte da quantidade solicitada ou propõe ajuste.
4. O cliente recebe a atualização de quantidade disponível.
5. Cliente decide aceitar quantidade parcial.
6. O sistema continua o fluxo de pagamento com a quantidade ajustada.
7. Pedido é gerado apenas após pagamento aprovado para a quantidade confirmada.

### 4.6 Compra com vários brechós no mesmo checkout
1. Cliente adiciona itens de diferentes brechós ao carrinho.
2. No checkout, o `PURCHASE_REQUEST` engloba todos os itens de todos os brechós.
3. Cada brechó confirma disponibilidade de seus itens.
4. O pagamento é realizado em uma única transação para todos os itens.
5. Um único `ORDER` é criado após aprovação do pagamento.
6. O `ORDER` pode gerar múltiplos `SHIPMENT`s, um por brechó ou rota logística.

### 4.7 Reserva presencial para Brechó Plus
1. Cliente visualiza achado de um Brechó Plus.
2. Escolhe opção de reserva presencial no app.
3. Cliente seleciona data e horário disponíveis no brechó.
4. O sistema registra a intenção de reserva e notifica o brechó.
5. Brechó confirma a reserva e bloqueia o item para coleta presencial.
6. Cliente recebe confirmação com endereço completo, rota e contato via WhatsApp.
7. A reserva não utiliza o fluxo de `CART` padrão até o cliente confirmar o checkout presencial.

### 4.8 Entrega Express
1. Cliente finaliza pedido de achados com entrega rápida local.
2. O sistema avalia distância, peso, volume e modais disponíveis.
3. O pedido é atribuído a um `SHIPMENT` expresso.
4. O brechó prepara o item para coleta imediata.
5. A transportadora ou parceiro logístico executa a entrega direta.
6. O cliente recebe status de envio e previsão de chegada.

### 4.9 Entrega Nacional
1. Cliente realiza compra para entrega em outra região do país.
2. O sistema calcula logística nacional com base em distância, peso, volume e modais.
3. O pedido é separado em `SHIPMENT` adequado para transporte interestadual.
4. O brechó expede o item para o parceiro logístico nacional.
5. O cliente acompanha o rastreamento até a entrega final.

### 4.10 Evento Temporário de Brechó
1. Brechó cria evento temporário ou promoção especial no app.
2. Publica catálogo de achados selecionados para o evento.
3. Clientes visualizam evento e compram produtos com condições específicas.
4. O sistema pode flexibilizar opções de entrega, retirada ou reserva.
5. O evento gera métricas de engajamento e desempenho para o brechó.

### 4.11 Devolução / Atendimento Pós-Venda
1. Cliente solicita devolução ou suporte após a entrega.
2. Cliente abre atendimento no app, descrevendo motivo.
3. O sistema registra caso e avisa o brechó responsável.
4. Brechó e operação definem procedimento de retorno ou compensação.
5. Se aplicável, o pedido é atualizado com status de devolução e a reputação do brechó é afetada.
6. O fluxo suporta reembolso, troca ou autorização de devolução.

### 4.12 Doação / Desapego
1. Brechó ou cliente cadastra intenção de doação ou desapego.
2. O sistema publica ou encaminha itens para canais de doação.
3. Itens doados podem ser exibidos em seções especiais ou repassados a parceiros.
4. O fluxo reforça a economia circular e reduz descarte.

### 4.13 Economia Circular
1. Plataforma valoriza brechós e achados reutilizáveis.
2. Produtos ganham destaque por categoria, condição e impacto sustentável.
3. Clientes são incentivados a comprar, trocar ou doar itens.
4. Brechós recebem métricas de reciclagem, reaproveitamento e redução de resíduos.
5. A operação protege o ciclo de vida do produto, evitando exclusão física e valorizando renovação.

## 5. Observações finais
- O modelo de negócio prioriza transparência e agilidade.
- Os fluxos devem ser implementados respeitando o domínio do Brechó Express e as regras do marketplace.
- A documentação deve ser atualizada sempre que regras de checkout, logística ou atendimento evoluírem.
