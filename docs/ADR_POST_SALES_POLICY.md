# ADR-POST-SALES — Política de Pós-venda do Brechó Express

## 1. Objetivo

Este documento define a filosofia, os princípios e o fluxo de pós-venda do Brechó Express.

O objetivo é preservar confiança entre Cliente, Brechó e Plataforma em situações ocorridas após a conclusão de uma venda, sem transformar esse documento em uma especificação técnica ou em uma definição de banco de dados.

Este documento orienta decisões futuras de negócio e arquitetura, servindo de base para a modelagem de pós-venda.

---

## 2. Princípios

### Boa-fé

A plataforma deve tratar todas as partes com boa-fé, presumindo a honestidade das informações apresentadas, mas sem abrir mão da verificação quando houver inconsistências.

A análise de pós-venda deve priorizar a resolução justa e equilibrada, evitando decisões arbitrárias.

### Transparência

As regras de pós-venda devem ser compreensíveis para clientes e brechós.

Quando houver uma decisão, ela deve ser explicada de forma objetiva, com base em fatos, evidências e critérios previamente aplicáveis.

### Evidências

Toda análise deve priorizar evidências objetivas.

Exemplos de evidências incluem fotos, mensagens, registros de entrega, histórico de status, comunicação entre as partes e informações da compra.

### Proporcionalidade

A resposta a uma ocorrência deve ser proporcional ao impacto e à gravidade do problema.

Nem todo problema deve resultar em devolução, estorno ou penalidade. A plataforma deve adaptar a resposta ao contexto.

### Mediação

Quando o problema não for evidente ou houver conflito entre as partes, a plataforma deve atuar como mediadora.

A mediação pode incluir revisão, solicitação de evidências, negociação comercial e, quando necessário, intervenção da plataforma para restabelecer o equilíbrio do processo.

### Evolução por Business Configuration

As políticas operacionais de pós-venda devem evoluir por meio de configurações de negócio sempre que possível.

Isso permite ajustar prazos, limites, regras de gratuidades, critérios de análise e outras decisões sem exigir alterações estruturais do domínio.

---

## 3. Fluxo Geral do Pós-venda

```text
Pedido
  │
  ▼
Entrega
  │
  ▼
Cliente satisfeito OU Cliente identifica problema
  │
  ▼
Solicitação
  │
  ▼
Análise
  │
  ▼
Brechó
  │
  ▼
Plataforma (quando necessário)
  │
  ▼
Resolução
  │
  ▼
Encerramento
```

O fluxo acima representa o caminho padrão de uma ocorrência de pós-venda, desde a entrega até a resolução final.

---

## 4. Tipos de Ocorrência

As ocorrências de pós-venda podem ser classificadas em diferentes categorias.

### Divergência do anúncio

Problemas relacionados ao produto entregue em relação ao anunciado, como descrição incorreta, estado não conforme, ausência de característica esperada ou discrepância visual.

### Problemas logísticos

Problemas relacionados à entrega, como atraso, perda, extravio, dano no transporte ou entrega incompleta.

### Problemas operacionais

Problemas relacionados ao processo comercial, como falha de confirmação, erro de processamento, conflito de status ou inconsistência entre pedido e entrega.

### Fraudes

Situações que envolvem tentativa de fraude, uso indevido do sistema, apresentação de evidências falsas ou comportamento abusivo por parte de qualquer das partes.

---

## 5. Possíveis Resoluções

Uma ocorrência pode resultar em diferentes respostas, conforme o tipo de problema e a análise realizada.

As resoluções possíveis incluem:

- Encerramento
- Devolução
- Devolução parcial
- Estorno
- Crédito promocional
- Advertência
- Suspensão

A escolha da resolução deve considerar:

- prova disponível;
- impacto para o cliente;
- impacto para o brechó;
- histórico de ocorrências;
- regras configuráveis da plataforma.

---

## 6. Integração com outros módulos

O pós-venda interage com vários módulos já modelados no domínio.

### ORDER

O contexto de pós-venda nasce a partir de um pedido concluído ou em processamento.

### PAYMENT

Quando houver estorno, reembolso parcial ou crédito associado, o pós-venda impacta o módulo financeiro.

### STORE_BALANCE_TRANSACTION

Movimentações financeiras relacionadas a estornos, reembolsos ou compensações devem ser registradas no livro razão financeiro.

### STORE_REVIEW

A experiência pós-venda pode influenciar a percepção do brechó e a formação de avaliações públicas.

### STORE_REPUTATION

Problemas recorrentes podem impactar a reputação do brechó no longo prazo.

### BUSINESS_CONFIGURATION

Regras específicas de pós-venda, como prazos, limites, gratuidades e critérios de atendimento, devem ser controladas por políticas configuráveis.

---

## 7. Observações

- Nem toda ocorrência resulta em devolução.
- Toda análise deve priorizar evidências objetivas.
- Regras operacionais específicas, como dias, prazos, limites e gratuidades, pertencem ao documento de configuração de negócio.
- A política deverá evoluir sem necessidade de alterar a arquitetura do domínio.
- Este documento serve como base para a futura modelagem das entidades de pós-venda, incluindo RETURN_REQUEST, RETURN_ATTACHMENT, STORE_REVIEW e STORE_REPUTATION.
