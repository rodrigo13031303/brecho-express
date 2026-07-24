# Architecture Decision Records - Brechó Express

Este documento consolida as decisões arquiteturais e de apoio já adotadas pelo projeto, organizadas no formato ADR. As decisões de produto já consolidadas continuam válidas e foram refletidas nas decisões de arquitetura e domínio abaixo.

## ADR-001 — Flutter como frontend oficial

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | Flutter |

### Contexto
O projeto precisa de uma aplicação oficial para atender clientes e brechós com uma experiência consistente, em múltiplas telas e com foco em usabilidade.

### Decisão
O Flutter será o frontend oficial do Brechó Express para a experiência de app, utilizando o ecossistema já adotado no projeto.

### Consequências
- Centraliza o desenvolvimento da interface em uma única base tecnológica.
- Mantém consistência visual e de experiência entre as telas principais.
- Exige que a camada de interface siga os contratos definidos pela arquitetura e pela Linguagem Ubíqua.

## ADR-002 — Oracle + ORDS como backend oficial

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | Banco de Dados |

### Contexto
O projeto necessita de um backend robusto para persistência transacional, integrações REST e alinhamento com o modelo de domínio.

### Decisão
O backend oficial do Brechó Express será implementado com Oracle como banco de dados principal e ORDS para exposição de APIs REST.

### Consequências
- O banco e as APIs passam a seguir o modelo de domínio e as convenções estabelecidas.
- A camada de integração deve ser organizada por packages Oracle e contratos REST.
- O desenvolvimento precisa respeitar a separação entre persistência, regras de negócio e exposição de APIs.

## ADR-003 — Arquitetura DDD com Feature First

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | Arquitetura |

### Contexto
O projeto possui múltiplos domínios de negócio e precisa de uma organização que preserve coesão e evolução incremental.

### Decisão
A arquitetura do projeto seguirá Domain-Driven Design, com organização por features e domínio, mantendo o foco no negócio do Brechó Express.

### Consequências
- As features passam a refletir o modelo de negócio e não apenas a estrutura técnica.
- A evolução do sistema se torna mais previsível e alinhada ao domínio.
- O time deve manter a consistência entre documentação, APIs, banco e interface.

## ADR-004 — Linguagem Ubíqua como fonte oficial de nomenclatura

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | Domínio |

### Contexto
O projeto precisa de um vocabulário comum entre negócio, documentação, banco de dados, APIs e aplicação.

### Decisão
A Linguagem Ubíqua do Brechó Express é a fonte oficial de nomenclatura para todo o projeto.

### Consequências
- O termo comercial prevalece na interface, enquanto o banco usa nomenclatura técnica.
- A documentação, o modelo de dados e as APIs devem permanecer alinhados.
- Novos conceitos precisam ser registrados antes de serem implementados.

## ADR-005 — PUBLIC_ID como CHAR(32)

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | Banco de Dados |

### Contexto
É necessário padronizar identificadores públicos para comunicação externa, com tamanho fixo e previsível.

### Decisão
Todos os identificadores públicos das entidades serão representados como CHAR(32).

### Consequências
- As APIs e integrações passam a usar identificadores públicos estáveis e padronizados.
- O modelo de dados ganha consistência e previsibilidade.
- O ID interno permanece exclusivo do Oracle e não é exposto externamente.

## ADR-006 — Não utilizar DELETE físico em entidades de negócio

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | Banco de Dados |

### Contexto
Entidades de negócio precisam preservar histórico e integridade sem remoção física indiscriminada.

### Decisão
Entidades de negócio não devem ser removidas fisicamente; a exclusão lógica deve ser tratada por status.

### Consequências
- O histórico e a auditoria ficam mais preservados.
- O modelo de dados passa a priorizar rastreabilidade e controle de ciclo de vida.
- O status da entidade torna-se um ponto central de governança.

## ADR-007 — APIs externas nunca expõem ID interno

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | API |

### Contexto
A comunicação com sistemas externos deve ser baseada em identificadores públicos e não em chaves internas do banco.

### Decisão
As APIs externas utilizam exclusivamente PUBLIC_ID e nunca expõem o ID interno do Oracle.

### Consequências
- O contrato de API fica mais estável e menos acoplado ao banco.
- A camada de integração se torna mais segura e desacoplada.
- O Flutter e outros clientes passam a consumir identificadores públicos.

## ADR-008 — ORDS deve chamar packages Oracle, nunca SQL solto

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | API |

### Contexto
É preciso evitar que a camada de API execute lógica de banco de forma dispersa e pouco governável.

### Decisão
ORDS deve chamar packages Oracle, e não executar SQL solto diretamente.

### Consequências
- A regra de negócio fica concentrada em packages explícitos.
- A manutenção da camada de integração fica mais organizada.
- O acesso ao banco se torna mais controlado e padronizado.

## ADR-009 — Separação entre *_API_PKG e *_RULE_PKG

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | Banco de Dados |

### Contexto
É necessário separar operações de exposição de API de regras de negócio para preservar responsabilidade e manutenção.

### Decisão
Cada domínio terá packages específicos, com *_API_PKG para operações consumidas pela API e *_RULE_PKG para regras de negócio.

### Consequências
- A lógica fica mais modular e fácil de evoluir.
- Regras de negócio não ficam misturadas à camada de acesso.
- O código Oracle ganha maior coesão e rastreabilidade.

## ADR-010 — Flutter nunca acessa SQL nem conhece estrutura interna do banco

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-06-30 |
| Área | Flutter |

### Contexto
A camada de interface deve permanecer desacoplada da estrutura técnica do banco de dados.

### Decisão
O Flutter nunca acessa SQL, nunca conhece a estrutura interna do banco e deve consumir APIs por meio de repositories e providers.

### Consequências
- A aplicação fica mais segura e desacoplada.
- Mudanças internas no banco não impactam diretamente a interface.
- A responsabilidade de integração fica concentrada na camada de dados da aplicação.

## ADR-011 — Arquitetura Financeira baseada em Livro Razão

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-07-01 |
| Área | Financeiro |

### Contexto
O módulo financeiro precisa de rastreabilidade completa, auditoria e suporte a retenção, estornos e conciliação.

### Decisão
O Brechó Express utilizará STORE_BALANCE_TRANSACTION como Ledger Financeiro oficial.

STORE_BALANCE será apenas uma visão consolidada derivada das movimentações.

### Consequências
- Auditoria completa.
- Rastreabilidade.
- Facilidade para estornos.
- Facilidade para conciliação.
- Escalabilidade financeira.

## ADR-012 — Tipos de Movimentação Financeira serão Parametrizáveis

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-07-01 |
| Área | Financeiro |

### Contexto
O módulo financeiro pode evoluir com diferentes tipos de movimentação e é importante não sobrecarregar o MVP com complexidade prematura.

### Decisão
Neste momento SBT_TYPE permanece como VARCHAR2.

Futuramente poderá ser substituído por uma entidade de configuração, como BALANCE_TRANSACTION_TYPE, caso a quantidade de tipos de movimentação aumente.

### Motivação
Evitar complexidade desnecessária no MVP, mantendo possibilidade de evolução.

## ADR-013 — Conta Financeira do Brechó

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-07-01 |
| Área | Financeiro |

### Contexto
O fluxo inicial de repasse precisa ser simples, mas deve permitir evolução futura para múltiplos canais financeiros.

### Decisão
Inicialmente PAYOUT armazenará diretamente a chave PIX.

Futuramente poderá existir uma entidade STORE_PAYMENT_ACCOUNT para suportar:
- PIX
- Conta Bancária
- Mercado Pago
- PagBank
- Outros provedores financeiros.

### Motivação
Manter simplicidade no MVP e permitir expansão futura.

## ADR-014 — Estados Financeiros de Retenção

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-07-01 |
| Área | Financeiro |

### Contexto
Valores recebidos poderão permanecer temporariamente bloqueados antes de ficarem disponíveis ao Brechó.

### Decisão
A retenção será representada através de movimentações financeiras, como HOLD e RELEASE, no Ledger Financeiro.

Nenhuma entidade adicional será criada neste momento.

### Motivação
Permitir retenção de valores para devoluções e disputas utilizando a própria arquitetura do Ledger.

## ADR-015 — Pagamento precede a criação do Pedido

| Campo | Valor |
|------|-------|
| Status | Aceito |
| Data | 2026-07-24 |
| Área | Compra / Financeiro |

### Contexto

O domínio determina que ORDER nasce somente após pagamento aprovado. O contrato
anterior de PAYMENT exigia ORDER já existente, criando uma dependência circular.

### Decisão

PAYMENT nasce vinculado à PURCHASE_REQUEST finalizada. PAYMENT_EVENT é a única
fonte de mudança do estado financeiro. Ao processar idempotentemente um evento
de aprovação, PAY_SERVICE_PKG cria ORDER pelo contrato interno
ORD_SERVICE_PKG.create_paid_order e então vincula PAYMENT ao ORDER criado.

PAYMENT.ORD_ID é opcional antes da aprovação, obrigatório no estado APPROVED e
único quando preenchido.

### Consequências

- nenhum ORDER existe antes do pagamento aprovado;
- webhooks repetidos não criam pedidos duplicados;
- PAYMENT preserva rastreabilidade antes e depois da aprovação;
- a criação de ORDER permanece interna e transacional.
