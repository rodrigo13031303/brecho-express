# Documentação Oficial — Brechó Express

## 1. Objetivo

Este arquivo é o ponto de entrada obrigatório da documentação do Brechó
Express. Ele define a ordem de autoridade, o significado dos estados
documentais, as fontes oficiais por assunto e a forma de tratar divergências
entre contrato, implementação e material histórico.

## 2. Regra fundamental

O projeto distingue três perspectivas:

- **contrato aprovado:** comportamento que deve orientar a evolução do sistema;
- **estado implementado:** comportamento comprovado por DDL, packages e testes;
- **material histórico:** documento preservado para contexto, mas que não
  autoriza nova implementação.

Código existente é evidência do estado implementado, não autoridade automática
para alterar o produto. Um contrato aprovado que ainda não foi implementado
deve declarar expressamente essa diferença.

## 3. Ordem de autoridade

Em caso de conflito, aplica-se a seguinte ordem:

1. `00_CONSTITUICAO.md`;
2. ADRs individuais aceitas em `docs/ADR-*.md`;
3. `13_UBIQUITOUS_LANGUAGE.md`;
4. `03_BUSINESS_RULES.md` e `14_BUSINESS_FLOW.md`;
5. `20_DATA_DICTIONARY.md`, `23_DOMAIN_MODEL.md` e
   `24_SYSTEM_ARCHITECTURE.md`;
6. arquiteturas especializadas `32` em diante;
7. padrões técnicos `21`, `22`, `26`, `27`, `28`, `29`, `30` e `31`;
8. guias de sprint, dentro do escopo autorizado;
9. banco, packages e testes, como evidência do estado implementado;
10. exemplos, prompts e documentos introdutórios.

Uma regra especializada prevalece sobre uma regra geral apenas quando não
contradiz autoridade superior. Conflitos materiais interrompem a implementação
até correção documental ou nova decisão.

## 4. Fontes oficiais por assunto

| Assunto | Fonte principal | Complementos |
|---|---|---|
| Identidade e propósito | `00_CONSTITUICAO.md`, `01_VISION.md` | `02_PRD.md` |
| Linguagem oficial | `13_UBIQUITOUS_LANGUAGE.md` | Data Dictionary |
| Regras e fluxos | `03_BUSINESS_RULES.md`, `14_BUSINESS_FLOW.md` | ADRs aplicáveis |
| Modelo de domínio | `23_DOMAIN_MODEL.md` | `20_DATA_DICTIONARY.md` |
| Dados | `20_DATA_DICTIONARY.md` | `21`, `22` e ADRs físicas |
| Arquitetura de sistema | `24_SYSTEM_ARCHITECTURE.md` | arquiteturas modulares |
| Oracle e PL/SQL | `26_PHYSICAL_ARCHITECTURE.md`, `30_DEVELOPMENT_STANDARD.md` | `28`, `29`, `31` |
| APIs | `27_API_STANDARDS.md`, `31_API_RUNTIME_CONTRACT.md` | `40_ORDS_ARCHITECTURE.md` e contrato do módulo |
| Configurações | `25_BUSINESS_CONFIGURATION.md` | `BEX_BUSINESS_CONFIGURATION` |
| Decisões | ADR individual aceita | `09_DECISIONS.md` como catálogo |
| Implementação atual | `database/` e seus testes | arquitetura do módulo |

## 5. Estados documentais

- **Rascunho:** ainda pode mudar e não autoriza implementação.
- **Proposto:** pronto para decisão, mas ainda não aprovado.
- **Aceito:** contrato oficial.
- **Implementado:** contrato aceito materializado e validado.
- **Parcialmente implementado:** apenas parte do contrato está executável.
- **Substituído:** preservado somente para histórico.
- **Arquivado:** não participa da documentação vigente.

Ausência de estado não significa que um documento seja aceito. Durante a
consolidação, documentos sem metadados devem ser interpretados segundo esta
hierarquia e revisados antes de orientar nova implementação.

## 6. Cabeçalho obrigatório

Todo novo documento normativo deve informar:

```yaml
document_id:
title:
status:
owner:
created_at:
last_reviewed_at:
authoritative_for:
supersedes:
related_documents:
implementation_status:
```

Documentos existentes receberão esse cabeçalho progressivamente. A falta
temporária do cabeçalho não altera decisões já aceitas.

## 7. ADRs

Cada número identifica uma única decisão. Números não podem ser reutilizados.
ADRs provisórias usam estado `Proposto`, nunca identificador `00X`.

ADRs individuais são a forma vigente. `09_DECISIONS.md` é apenas o catálogo
de navegação e não possui autoridade normativa própria.

Decisões novas:

- `ADR-019_PURCHASE_RESERVATION.md`;
- `ADR-020_PURCHASE_CONFIRMATION_AND_PAYMENT_TIMEOUT.md`;
- `ADR-021_AUDIT_ACTOR_IDENTITY.md`;
- `ADR-022_FINANCIAL_ARCHITECTURE.md`;
- `ADR-023_POST_SALES_POLICY.md`;
- `ADR-024_PAYMENT_PRECEDES_ORDER.md`.

## 8. Estado conhecido da implementação

Em 2026-07-26:

- CART e PURCHASE_REQUEST estão implementados sem reserva de estoque;
- PAYMENT nasce antes de ORDER;
- `PAYMENT_APPROVED` cria e vincula ORDER de forma idempotente;
- as camadas predominantes são API, Service, Rule e Repository;
- auditoria física ainda usa modelos diferentes entre módulos;
- as 39 tabelas, incluindo identidades sociais e notificações, possuem ficha
  no Data Dictionary;
- `BEX_ACCOUNT_IDENTITY` foi instalada e aprovada por cinco testes físicos no
  Oracle AI Database 26ai Free; o domínio Google e seu plugin ORDS 25.4 estão
  instalados, enquanto Apple e Facebook ainda aguardam implementação;
- o runtime PL/SQL das APIs possui envelope, erro sanitizado, transação,
  parsing tipado, rejeição de campos desconhecidos e conversão temporal
  padronizados no Core;
- em 2026-07-26, os objetos atualizados foram compilados com sucesso no Oracle
  AI Database 26ai Free, sem objetos inválidos;
- a validação executável anterior ao ORDS aprovou 73 testes de `CORE_JSON_PKG`,
  57 de `CORE_RESPONSE_PKG`, 8 de sessão, 35 de `ACC_API_PKG` e 3 fluxos de
  autenticação;
- a fundação pública ORDS está instalada e foi validada externamente para
  criação de conta, rejeição segura de login e login de conta ativa;
- a fundação autenticada ORDS com Bearer Token e logout está instalada; seus
  testes SQL foram aprovados e o teste HTTP confirmou logout com `204` e
  rejeição da reutilização do token revogado com `401 BEX-AUTH-002`;
- o plugin Google está ativo no ORDS 25.4: health check aprovado e token
  inválido rejeitado com `401 BEX-AUTH-003`; falta validar um ID token real;
- o DBML cobre estruturalmente as 39 tabelas implementadas e declara o DDL como
  autoridade para detalhes físicos.

As ADRs 019 a 021 definem o contrato-alvo para corrigir parte dessas diferenças.

## 9. Regra de atualização

Uma mudança funcional deve atualizar, conforme aplicável:

1. ADR;
2. regras e fluxo de negócio;
3. Data Dictionary;
4. arquitetura do módulo;
5. contrato de API;
6. banco e packages;
7. testes;
8. estado de implementação no documento especializado.

Nenhuma dessas etapas deve declarar uma capacidade como implementada antes da
validação executável correspondente.

## 10. Catálogo documental

| Documento ou conjunto | Estado | Uso |
|---|---|---|
| `00_CONSTITUICAO.md` | Aceito | identidade e limites fundamentais |
| `01_VISION.md` | Aceito | direção estratégica |
| `02_PRD.md` | Em revisão | requisitos de produto em alto nível |
| `03_BUSINESS_RULES.md` | Aceito | regras transversais de negócio |
| `04_ARCHITECTURE.md` | Introdutório | resumo, sem autoridade especializada |
| `05_DESIGN_SYSTEM.md` | Inicial | diretriz ainda não implementável por completo |
| `06_DATABASE.md` | Introdutório | resumo, sem autoridade física |
| `07_API.md` | Histórico | exemplos antigos, não normativos |
| `08_ROADMAP.md` | Histórico | não representa estado atual |
| `09_DECISIONS.md` | Catálogo | navegação para ADRs individuais |
| `10_PROMPTS.md` | Auxiliar | prompts subordinados à governança |
| `11_AI_CONTEXT.md` | Introdutório | contexto subordinado à governança |
| `12_DOMAIN_MODEL.md` | Substituído | preservar somente como histórico |
| `13_UBIQUITOUS_LANGUAGE.md` | Aceito | terminologia oficial |
| `14_BUSINESS_FLOW.md` | Aceito | fluxos funcionais oficiais |
| `20_DATA_DICTIONARY.md` | Aceito | entidades implementadas e contratos-alvo declarados |
| `21_DATABASE_CONVENTIONS.md` | Aceito | convenções de dados |
| `22_ENTITY_MODELING_STANDARD.md` | Aceito | template de entidades |
| `23_DOMAIN_MODEL.md` | Snapshot histórico parcial | visão até Sprint 5A |
| `24_SYSTEM_ARCHITECTURE.md` | Aceito | arquitetura funcional de alto nível |
| `25_BUSINESS_CONFIGURATION.md` | Aceito | políticas parametrizáveis |
| `26_PHYSICAL_ARCHITECTURE.md` | Aceito | arquitetura Oracle e camadas |
| `27_API_STANDARDS.md` | Aceito | padrão REST |
| `28_CORE_FRAMEWORK.md` | Aceito e implementado parcialmente | capacidades transversais |
| `29_EXECUTION_CONTEXT.md` | Aceito e implementado | contexto de execução |
| `30_DEVELOPMENT_STANDARD.md` | Aceito | padrão permanente PL/SQL |
| `31_API_RUNTIME_CONTRACT.md` | Aceito | contrato técnico da borda |
| `32_STORE_ARCHITECTURE.md` | Implementado | módulo STORE |
| `33_CATALOG_ARCHITECTURE.md` | Implementado | módulo CATALOG |
| `34_PURCHASE_ARCHITECTURE.md` | Parcialmente implementado | compra, aceite e reserva |
| `35_ORDER_LOGISTICS_ARCHITECTURE.md` | Implementado no escopo inicial | pedido e logística |
| `36_PAYMENT_ARCHITECTURE.md` | Parcialmente implementado | pagamento e integração futura com reserva |
| `37_STORE_ENGAGEMENT_ARCHITECTURE.md` | Implementado no escopo inicial | planos, eventos e seguidores |
| `38_IDENTITY_AUTHORIZATION_ARCHITECTURE.md` | Implementado no escopo inicial | papéis globais |
| `39_LEDGER_PAYOUT_ARCHITECTURE.md` | Implementado no escopo inicial | ledger, saldo e repasse |
| `40_ORDS_ARCHITECTURE.md` | Parcialmente implementado | borda HTTP e catálogo de endpoints |
| `41_FLUTTER_OAUTH_CONFIGURATION.md` | Parcialmente implementado | IDs móveis e configuração OAuth |
| `ADR-015` a `ADR-025` | Conforme cada arquivo | decisões individuais vigentes |
| `sprints/` | Operacional e histórico | execução limitada à sprint |

## 11. Pendências documentais controladas

As pendências abaixo são explícitas e não podem ser resolvidas por improvisação:

- definir contrato físico e API da reserva aprovada na ADR-019;
- definir estados e persistência do aceite aprovado na ADR-020;
- planejar migração de auditoria conforme ADR-021;
- ampliar módulos, templates e handlers ORDS após validar a fundação
  autenticada descrita em `40_ORDS_ARCHITECTURE.md`;
- concluir o contrato implementável do Design System e a arquitetura Flutter;
- definir fichas antes de implementar Donation, Donation Item, Collection
  Request, Favorite e Activity Log;
- evoluir notificações antes de exposição externa;
- criar instalador e suíte globais do banco.

Uma pendência listada não reduz a autoridade das decisões já aceitas e não
autoriza implementação sem o contrato necessário.
