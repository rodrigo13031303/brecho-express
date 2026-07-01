# Configuração de Negócio - Brechó Express

## 1. Objetivo

Este documento oficializa as políticas operacionais do Brechó Express que, no futuro, poderão ser parametrizadas de forma independente da estrutura do domínio.

O objetivo é separar claramente:

- estrutura do domínio: conceitos e entidades permanentes do negócio;
- política operacional: regras configuráveis que determinam comportamento, limites e critérios de operação.

Este documento não representa implementação técnica, nem banco de dados, nem tabelas. Ele é uma referência de negócio para orientar futuras decisões de configuração.

---

## 2. Princípios

- Toda política operacional deverá ser configurável sempre que possível.
- Estruturas do domínio permanecem imutáveis em sua essência.
- Políticas podem mudar com o tempo sem exigir mudança estrutural do sistema.
- Políticas devem ser claras, documentadas e auditáveis.
- Alterações de políticas não devem exigir alterações de código sempre que possível.

---

## 3. Políticas por módulo

### 3.1 Compra

| Código | Nome | Descrição | Valor Inicial | Unidade | Observações |
|--------|------|-----------|---------------|---------|-------------|
| PURCHASE_STORE_CONFIRMATION_TIMEOUT | Tempo de confirmação do Brechó | Tempo máximo para o Brechó confirmar disponibilidade após uma solicitação de compra. | 24 | horas | Pode ser ajustado por tipo de produto ou campanha. |
| PURCHASE_PAYMENT_TIMEOUT | Tempo de pagamento | Tempo máximo para o cliente concluir o pagamento após a criação da compra. | 30 | minutos | Evita pendências de pagamento prolongadas. |

### 3.2 Financeiro

| Código | Nome | Descrição | Valor Inicial | Unidade | Observações |
|--------|------|-----------|---------------|---------|-------------|
| FUNDS_RETENTION_DAYS | Retenção de fundos | Prazo de retenção antes que o valor fique disponível para saque. | 7 | dias | Suporta devoluções e disputas. |
| PAYOUT_MINIMUM_AMOUNT | Valor mínimo para payout | Valor mínimo exigido para solicitar saque. | 50 | reais | Pode variar por canal ou tipo de conta. |
| PAYOUT_PROCESSING_TIME | Tempo de processamento do payout | Prazo estimado para processar um saque solicitado. | 3 | dias úteis | Inicialmente manual; futura automação. |

### 3.3 Logística

| Código | Nome | Descrição | Valor Inicial | Unidade | Observações |
|--------|------|-----------|---------------|---------|-------------|
| DELIVERY_OWN_RADIUS | Raio de entrega própria | Raio máximo de cobertura para entregas realizadas pelo próprio Brechó. | 10 | km | Pode ser configurado por região. |
| DELIVERY_AUTO_CARRIER | Uso automático de carrier | Define se a plataforma pode selecionar automaticamente um provedor logístico. | false | booleano | Pode evoluir para regras mais complexas. |

### 3.4 Catálogo

| Código | Nome | Descrição | Valor Inicial | Unidade | Observações |
|--------|------|-----------|---------------|---------|-------------|
| CATALOG_PUBLIC_QUESTIONS | Perguntas públicas | Determina se perguntas de pré-venda ficam públicas no achado. | true | booleano | Apoia transparência comercial. |
| CATALOG_MIN_IMAGES | Mínimo de imagens | Número mínimo de imagens exigido para publicação de um achado. | 1 | quantidade | Pode variar por categoria. |
| CATALOG_MAX_IMAGES | Máximo de imagens | Número máximo de imagens permitidas por achado. | 8 | quantidade | Evita excesso de conteúdo. |

### 3.5 Pós-venda

| Código | Nome | Descrição | Valor Inicial | Unidade | Observações |
|--------|------|-----------|---------------|---------|-------------|
| RETURN_FIRST_FREE | Primeira devolução gratuita | Define se a primeira devolução é gratuita para o cliente. | true | booleano | Pode depender do motivo da devolução. |
| RETURN_ALLOW_PARTIAL | Devolução parcial | Determina se devoluções parciais são permitidas. | true | booleano | Útil para pedidos com múltiplos itens. |
| RETURN_REQUIRE_PHOTO | Exigir foto | Determina se a devolução exige foto do item. | true | booleano | Ajuda na análise de pós-venda. |

### 3.6 Fidelização

| Código | Nome | Descrição | Valor Inicial | Unidade | Observações |
|--------|------|-----------|---------------|---------|-------------|
| LOYALTY_PURCHASE_ENABLED | Fidelidade por compra | Define se o programa de fidelidade é habilitado para compras. | false | booleano | Pode ser ativado em fases futuras. |
| LOYALTY_REVIEW_ENABLED | Fidelidade por avaliação | Define se avaliações geram pontos. | false | booleano | Requer governança de pós-venda. |
| LOYALTY_PHOTO_ENABLED | Fidelidade por foto | Define se fotos de produto ou postagem geram pontos. | false | booleano | Pode depender da estratégia comercial. |

### 3.7 Social

| Código | Nome | Descrição | Valor Inicial | Unidade | Observações |
|--------|------|-----------|---------------|---------|-------------|
| SOCIAL_PUBLIC_COMMENTS | Comentários públicos | Define se comentários públicos são permitidos em conteúdos sociais. | true | booleano | Pode ser limitado por tipo de conteúdo. |
| SOCIAL_MODERATION_REQUIRED | Moderação obrigatória | Define se conteúdo social precisa passar por moderação. | true | booleano | Apoia segurança e governança. |

---

## 4. Roadmap Evolutivo

A evolução desta documentação seguirá uma progressão natural.

### Versão atual

- Documentação de políticas operacionais.

### Próxima etapa

- Modelagem da entidade BUSINESS_CONFIGURATION como referência central para políticas configuráveis.

### Depois

- Implementação de uma tela administrativa para gestão dessas políticas.

### Depois

- Introdução de auditoria das alterações de política.

### Depois

- Versionamento das políticas para rastrear mudanças ao longo do tempo.

---

## 5. Observações

Esta lista deverá crescer ao longo da evolução da plataforma.

Novas políticas podem surgir à medida que o Brechó Express expande operações, integrações, programas de fidelidade, logística e gestão financeira.

A intenção é que alterações de políticas não exijam alterações de código sempre que possível, preservando flexibilidade operacional e redução de dependência técnica.
