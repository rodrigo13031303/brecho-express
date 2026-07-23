# 32 — Arquitetura do módulo STORE

## 1. Objetivo

Definir, antes da implementação, a arquitetura funcional e técnica do módulo STORE do Brechó Express. Este documento orienta a futura evolução do Data Dictionary, do modelo físico e das camadas Repository, Rule, Service e API, sem constituir DDL ou contrato executável.

## 2. Contexto

STORE representa uma loja ou operação comercial de venda dentro da plataforma. A arquitetura parte dos padrões já consolidados em ACCOUNT, PROFILE, Core Framework e API Runtime Contract.

O Data Dictionary e o modelo físico vigente registram a propriedade técnica de STORE em ACCOUNT por `ACC_ID`; PROFILE não é dependência estrutural. O vínculo operacional entre contas e lojas é representado pela entidade física `BEX_STORE_USER`.

## 3. Escopo

Pertencem ao escopo inicial:

- criação, consulta e listagem de lojas de uma conta;
- atualização dos dados básicos;
- alteração controlada de estado;
- identidade pública, propriedade estrutural e auditoria;
- normalização e validação dos atributos próprios de STORE.

## 4. Fora de Escopo

STORE não representa ACCOUNT, PROFILE, usuário autenticado, produto, estoque, pedido, endereço, pagamento, reputação, assinatura ou plano. Também ficam fora: logística, entrega, KYC, documentos fiscais, equipe completa, permissões, comissões, repasses, mensageria e autenticação.

## 5. Definições

- **ACCOUNT:** identidade técnica principal e proprietária.
- **PROFILE:** identidade pessoal ou pública associada à conta.
- **STORE:** operação comercial administrada por uma conta.
- **Proprietário:** ACCOUNT à qual a STORE pertence estruturalmente.
- **Administrador/colaborador:** vínculo funcional futuro, distinto da propriedade.
- **Public ID:** identificador público opaco, estável e sem semântica de negócio.
- **Slug:** nome canônico legível para URL; não é identificador técnico nem substitui o Public ID.

## 6. Responsabilidade do módulo

O módulo administra a identidade básica, os dados de apresentação e o ciclo de vida de STORE. Não absorve regras ou dados dos módulos que apenas a referenciam.

## 7. Limites do agregado

STORE é a raiz do seu agregado mínimo. Pertencem a ele seus identificadores, proprietário, nome, slug, descrição, imagens de apresentação, locale, timezone, estado e auditoria.

PRODUCT, INVENTORY, ORDER, STORE_REPUTATION, STORE_ADDRESS, BEX_STORE_USER, PROMOTION e COUPON possuem ciclo de vida próprio ou complexidade suficiente para serem agregados externos. Suas referências a STORE não transferem suas regras para este módulo.

## 8. Relação com ACCOUNT e PROFILE

Decisão da versão inicial:

```text
1 ACCOUNT pode possuir 0..N STORE
1 STORE possui exatamente 1 ACCOUNT proprietária
```

Não haverá restrição física de uma única loja por conta. Limites comerciais futuros pertencem a políticas ou planos.

Uma ACCOUNT ativa pode criar STORE. A atuação operacional também se vincula a ACCOUNT por BEX_STORE_USER. PROFILE pode ser exigido futuramente pela experiência do produto ou fornecer dados pessoais de apresentação por composição, mas não é pré-condição, chave proprietária nem participante estrutural do vínculo operacional.

## 9. Identidade e identificadores

- `STR_ID`: identidade técnica Oracle, interna e nunca exposta.
- `STR_PUBLIC_ID`: identidade pública opaca, única, imutável e independente de nome, slug, conta ou data.

APIs, URLs, integrações e logs funcionais usam `STR_PUBLIC_ID`. Colisões devem ser impedidas por constraint única e tratadas pelo caso de uso, inclusive com nova tentativa segura quando aplicável. O formato físico definitivo seguirá a decisão geral de Public IDs vigente quando o Data Dictionary e o DDL forem aprovados; este documento não cria formato paralelo.

## 10. Atributos candidatos

| Atributo | Finalidade | Obrigatório / padrão | Mutabilidade e exposição | Normalização, limite conceitual e validação |
|---|---|---|---|---|
| `STR_ID` | Identificador interno | Sim; gerado pelo Oracle | Imutável; privado | Integridade física |
| `STR_PUBLIC_ID` | Identificador público | Sim; sem default de negócio | Imutável; público | Gerado pelo Service; único; formato conforme padrão geral |
| `ACC_ID` | Proprietário técnico | Sim | Imutável; privado | FK para ACCOUNT; Service resolve o Public ID recebido |
| `STR_NAME` | Nome de exibição da loja | Sim | Mutável; público | Trim e espaços internos normalizados; proposta: 2 a 200 caracteres; Rule |
| `STR_SLUG` | Segmento amigável de URL | Sim na v1 | Mutável somente em `DRAFT`; público | Minúsculas, `[a-z0-9-]`, hífens consolidados, sem hífen nas extremidades; proposta: até 100; único |
| `STR_DESCRIPTION` | Apresentação curta | Não | Mutável e anulável; público | Trim; proposta: até 1.000 caracteres; Rule |
| `STR_STATUS` | Ciclo de vida | Sim; `DRAFT` | Mutável somente pelos casos de estado; autenticado/público conforme consulta | Valores e transições definidos neste documento; Rule e constraint |
| `STR_LOGO_URL` | Referência da logomarca | Não | Mutável e anulável; público | Trim; proposta: até 1.000 caracteres; validação estrutural sem buscar o recurso |
| `STR_COVER_URL` | Referência da capa | Não | Mutável e anulável; público | Mesma política de `STR_LOGO_URL` |
| `STR_LOCALE_CODE` | Localidade da loja | Sim; `pt-BR` | Mutável; autenticado/público | Trim; proposta: até 10 caracteres; lista aceita pela Rule |
| `STR_TIMEZONE_NAME` | Fuso horário IANA | Sim; `America/Sao_Paulo` | Mutável; autenticado/público | Trim; proposta: até 64 caracteres; lista aceita pela Rule |
| `STR_CREATED_AT` | Criação técnica | Sim; instante da criação | Imutável; público como `createdAt` | Timestamp conforme padrão físico; persistência |
| `STR_CREATED_BY` | Ator técnico criador | Conforme contexto obrigatório | Imutável; privado | Identificador técnico do ator, não `ACC_ID`; Service/Repository |
| `STR_UPDATED_AT` | Última alteração | Sim | Atualizado em escrita; público como `updatedAt` | Timestamp conforme padrão físico; persistência |
| `STR_UPDATED_BY` | Último ator técnico | Conforme contexto obrigatório | Atualizado em escrita; privado | Identificador técnico do ator; Service/Repository |

Nome e nome de exibição são um único conceito em `STR_NAME`; não se cria coluna duplicada. Logo e capa são referências, não conteúdo binário.

Endereço completo não integra STORE. Localização pública, endereço operacional, retirada, fiscal e área de atendimento têm semânticas diferentes e deverão ser analisados em uma futura `STORE_ADDRESS`.

Locale e timezone pertencem ao núcleo mínimo. Moeda, políticas de venda, prazo de resposta, reserva, expiração de pagamento, retirada, entrega e notificações não serão colunas genéricas de STORE; configurações extensas ou versionadas exigem contrato próprio, em alinhamento futuro com `25_BUSINESS_CONFIGURATION.md`.

## 11. Ciclo de vida

Estados aprovados para a arquitetura inicial:

- `DRAFT`: cadastro incompleto ou ainda não publicado; sem catálogo ou vendas públicas.
- `ACTIVE`: loja operacional e visível, apta a participar de catálogo e vendas conforme os módulos responsáveis.
- `SUSPENDED`: indisponibilidade administrativa temporária; catálogo e novas vendas ficam bloqueados, preservando histórico; reversível por autoridade administrativa.
- `CLOSED`: encerramento funcional voluntário ou administrativo definitivo; sem novas operações comerciais e sem reversão na primeira versão.

`PENDING_REVIEW`, `BLOCKED` e `INACTIVE` não são adotados: revisão ainda não possui processo aprovado; bloqueio se sobrepõe a suspensão; inatividade é ambígua.

## 12. Máquina de estados

| Origem | Destino | Ator | Condições | Reversível |
|---|---|---|---|---|
| `DRAFT` | `ACTIVE` | Proprietário autenticado | ACCOUNT ativa e dados mínimos válidos | Sim, apenas por suspensão administrativa |
| `DRAFT` | `CLOSED` | Proprietário autenticado | Encerramento explícito | Não |
| `ACTIVE` | `SUSPENDED` | Autoridade administrativa futura | Motivo e autorização definidos em contrato futuro | Sim |
| `SUSPENDED` | `ACTIVE` | Autoridade administrativa futura | Causa removida | Sim |
| `ACTIVE` | `CLOSED` | Proprietário ou autoridade administrativa | Encerramento explícito | Não |
| `SUSPENDED` | `CLOSED` | Proprietário ou autoridade administrativa | Encerramento explícito | Não |

Demais transições são inválidas. `SUSPENDED` é uma intervenção administrativa temporária; `CLOSED` é encerramento funcional. Desativação não é estado separado. Exclusão física não é transição de domínio.

## 13. Regras e invariantes

- toda STORE possui exatamente uma ACCOUNT proprietária ativa na criação;
- uma ACCOUNT pode possuir várias lojas;
- Public ID e proprietário são imutáveis;
- nome, slug, status, locale e timezone são obrigatórios;
- Public ID e slug são únicos, com garantias físicas e tratamento de concorrência;
- slug é canônico em minúsculas e distinto do Public ID;
- campos anuláveis são descrição, logo e capa;
- alteração de estado respeita exclusivamente a matriz aprovada;
- STORE fechada preserva dados e histórico e não recebe atualização comum;
- não há exclusão física pela API pública.

## 14. Propriedade e administração

O proprietário é a ACCOUNT informada na criação e registrada por `ACC_ID`. Administrador e colaborador são papéis de atuação, não colunas repetidas em STORE. O vínculo de membros e operadores é modelado pela entidade física aprovada `BEX_STORE_USER`, sem renomeá-la para STORE_MEMBER.

`BEX_STORE_USER` relaciona `STR_ID` a `BEX_STORE.STR_ID` e `ACC_ID` a `BEX_ACCOUNT.ACC_ID`. ACCOUNT é a identidade estrutural e operacional; PROFILE contém dados pessoais e não participa estruturalmente do vínculo. Os papéis operacionais são ADMIN, MANAGER, ATTENDANT e COLLABORATOR. O status aceita ACTIVE e INACTIVE, com no máximo um vínculo ACTIVE por combinação STR_ID + ACC_ID e preservação do histórico INACTIVE por índice único baseado em função. Essa entidade mantém ciclo de vida próprio e não altera a responsabilidade do agregado STORE.

## 15. Casos de uso

| Caso | Objetivo / ator | Pré-condições e resultado | Erros funcionais | Transação | Dependências | Primeira implementação |
|---|---|---|---|---|---|---|
| `create_by_account_public_id` | Criar STORE em `DRAFT`; conta autenticada | ACCOUNT ativa, dados válidos e slug livre; retorna loja | conta inexistente, dados/slug inválidos, slug ocupado | Escrita | `ACC_SERVICE_PKG`, Rule, Repository | Sim |
| `get_by_public_id` | Consultar loja; ator autenticado inicialmente | Public ID válido; retorna projeção pública | loja inexistente | Consulta | Repository | Sim |
| `list_by_account_public_id` | Listar lojas da conta; ator autenticado | ACCOUNT existente e acesso autorizado; lista possivelmente vazia | conta inexistente/não autorizada | Consulta | `ACC_SERVICE_PKG`, Repository | Sim |
| `update_by_public_id` | Atualizar dados básicos; proprietário autenticado | loja editável, PATCH válido; retorna estado atualizado | inexistente, atualização vazia, campo inválido/imutável | Escrita | Rule, Repository | Sim |
| `activate_by_public_id` | Publicar loja; proprietário autenticado | estado e dados mínimos válidos, ACCOUNT ativa | transição inválida, conta inativa | Escrita | `ACC_SERVICE_PKG`, Rule, Repository | Sim |
| `close_by_public_id` | Encerrar loja; proprietário autenticado | loja não fechada; preserva histórico | inexistente, já fechada, transição inválida | Escrita | Rule, Repository | Sim |
| `suspend_by_public_id` | Suspender administrativamente | ator administrativo e motivo ainda não definidos | não autorizado, transição inválida | Escrita | autorização futura, Rule, Repository | Não; pendente |

## 16. Arquitetura em camadas

```text
STR_API_PKG
    ↓
STR_SERVICE_PKG
    ↓
STR_RULE_PKG
    ↓
STR_REPOSITORY_PKG
```

- **API:** JSON, validação estrutural, envelope, status HTTP, identidade técnica recebida da borda, transação e tradução para o Service.
- **Service:** casos de uso, orquestração e fronteira pública; sem JSON, HTTP, COMMIT ou ROLLBACK.
- **Rule:** normalização, validações, invariantes e transições; sem SQL ou transação.
- **Repository:** SQL, persistência, consultas e locking necessário; sem regra de negócio ou transação final.

O prefixo `STR` está alinhado à nomenclatura física já documentada.

## 17. Dependências permitidas

- `STR_API_PKG` → `STR_SERVICE_PKG` e Core necessário ao Runtime Contract;
- `STR_SERVICE_PKG` → `STR_RULE_PKG`, `STR_REPOSITORY_PKG` e contratos públicos de outros Services, especialmente `ACC_SERVICE_PKG`;
- `STR_RULE_PKG` → tipos escalares e contratos estritamente necessários, sem persistência;
- `STR_REPOSITORY_PKG` → objetos físicos de STORE.

Cada dependência do Core existe apenas quando requerida pela responsabilidade da camada.

## 18. Dependências proibidas

- API → Rule, Repository, tabelas ou Services internos de outros módulos;
- Service → Repository/Rule de ACCOUNT ou de qualquer módulo externo;
- Rule → Service, Repository, SQL, JSON, HTTP ou ORDS;
- Repository → API, Service, Rule, JSON, HTTP, autenticação ou regras de domínio;
- SQL fora do Repository;
- COMMIT ou ROLLBACK fora da API de escrita;
- exposição de `STR_ID`, `ACC_ID`, `createdBy` ou `updatedBy`.

## 19. Fronteira de exceções

A API conhece apenas exceções públicas de `STR_SERVICE_PKG`. O Service traduz exceções de Rule, Repository e `ACC_SERVICE_PKG` para seu próprio contrato nominal. Não há `WHEN OTHERS`, `SQLERRM` como contrato, nem dependência direta da API em camadas internas.

## 20. Catálogo de erros candidato

Os códigos abaixo são candidatos no namespace `BEX-STR`, pesquisado para não reutilizar os namespaces atuais. A reserva definitiva ocorrerá junto ao contrato público.

| Código candidato | Condição | HTTP candidato |
|---|---|---|
| `BEX-STR-001` | STORE não encontrada | 404 |
| `BEX-STR-002` | ACCOUNT proprietária não encontrada ou inelegível | 404/422 conforme contrato final |
| `BEX-STR-003` | Nome inválido | 422 |
| `BEX-STR-004` | Slug inválido | 422 |
| `BEX-STR-005` | Slug já utilizado | 409 |
| `BEX-STR-006` | Loja equivalente já existente, se a regra vier a ser aprovada | 409 |
| `BEX-STR-007` | Status inválido | 422 |
| `BEX-STR-008` | Transição de status inválida | 409 |
| `BEX-STR-009` | Loja já encerrada | 409 |
| `BEX-STR-010` | Loja não está ativa | 409 |
| `BEX-STR-011` | Atualização vazia | 422 |

Erros estruturais reutilizam o catálogo transversal previsto no Runtime Contract. A equivalência entre lojas ainda não tem regra aprovada; portanto `BEX-STR-006` não deve ser implementado antes dessa decisão.

## 21. Segurança

Escritas exigem ator técnico autenticado. Receber `accountPublicId` não prova propriedade; o caso de uso deve resolver a conta e aplicar a autorização disponível. `p_actor_id` identifica o ator de auditoria e não se confunde com `ACC_ID`.

A listagem por conta será autenticada na primeira versão para não revelar a estrutura comercial de uma conta sem política pública aprovada. Uma vitrine pública e sua projeção reduzida podem surgir em contrato futuro. Erros evitam revelar existência ou dados além do necessário.

## 22. Contrato público candidato

Payload autenticado inicial:

```json
{
  "storePublicId": "...",
  "storeName": "...",
  "storeSlug": "...",
  "description": null,
  "status": "DRAFT",
  "logoUrl": null,
  "coverUrl": null,
  "localeCode": "pt-BR",
  "timezoneName": "America/Sao_Paulo",
  "createdAt": "...",
  "updatedAt": "..."
}
```

`accountPublicId` permanece na rota ou no contexto do caso de uso e não integra o payload padrão, evitando duplicação e resolução adicional apenas para apresentação. Poderá ser incluído numa projeção administrativa futura se houver necessidade aprovada.

Públicos/autenticados: Public ID, nome, slug, descrição, status, imagens, locale, timezone e timestamps. Privados: IDs técnicos e auditoria numérica. Futuras projeções públicas poderão omitir estado não publicável e dados de administração.

## 23. PATCH e mutabilidade

Semântica idêntica à consolidada em PROFILE:

- campo ausente preserva o valor;
- campo presente com valor substitui o atual;
- campo presente com JSON `null` limpa somente campo anulável.

Descrição, logo e capa podem ser limpos. Nome, slug, locale e timezone não aceitam `null`. Public IDs, proprietário, status e auditoria não pertencem ao corpo de atualização. O slug pode mudar somente em `DRAFT`; após ativação permanece imutável até existir política de histórico e redirecionamento.

## 24. Transações

- API: `COMMIT` após escrita bem-sucedida e `ROLLBACK` antes de propagar falha de escrita;
- consultas da API: sem `COMMIT` ou `ROLLBACK`;
- Service, Rule e Repository: sem `COMMIT` ou `ROLLBACK`.

O comportamento segue `31_API_RUNTIME_CONTRACT.md`.

## 25. Concorrência

Public ID e slug exigem constraints únicas; consulta prévia não garante unicidade. O Service pode antecipar conflitos para melhorar a mensagem, mas deve traduzir também a violação física concorrente.

Ativação, encerramento e atualizações simultâneas exigem leitura bloqueante ou controle otimista a ser definido no contrato físico. A transição deve validar o estado dentro da mesma transação da atualização. Criações repetidas não são consideradas idempotentes sem chave explícita futura; duplicidade por repetição deverá ser tratada sem relaxar unicidade.

## 26. Auditoria

`STR_CREATED_AT`, `STR_CREATED_BY`, `STR_UPDATED_AT` e `STR_UPDATED_BY` seguem o padrão físico do projeto. A API recebe o ator técnico do contexto e não o confunde com a conta proprietária.

`createdAt` e `updatedAt` podem ser públicos; `createdBy`, `updatedBy`, `ACC_ID` e `STR_ID` nunca são expostos. Auditoria técnica não substitui histórico funcional. Se o histórico de estados for necessário, deverá existir entidade/evento próprio.

## 27. Relacionamentos futuros

Relações conceituais esperadas:

```text
STORE 1 → N PRODUCT
STORE 1 → N INVENTORY ou STOCK_ITEM
STORE 1 → N ORDER
STORE 1 → N STORE_REPUTATION
STORE 1 → N STORE_ADDRESS
STORE 1 → N BEX_STORE_USER
STORE 1 → N PROMOTION
STORE 1 → N COUPON
```

STORE é referenciada como agregado externo por esses módulos. Nenhum deles integra automaticamente sua transação ou tabela principal. `BEX_STORE_USER` é a entidade física aprovada para membros e operadores da STORE e permanece um agregado externo ao núcleo de STORE; `STORE_ADDRESS` continua candidato futuro.

## 28. Rotas candidatas

```text
POST   /accounts/{accountPublicId}/stores
GET    /stores/{storePublicId}
GET    /accounts/{accountPublicId}/stores
PATCH  /stores/{storePublicId}
POST   /stores/{storePublicId}/activation
POST   /stores/{storePublicId}/closure
```

Criação e listagem são sub-recursos da conta. Consulta e atualização usam o Public ID da loja. Ativação e encerramento são comandos de domínio modelados como sub-recursos, pois não equivalem a alteração irrestrita do campo `status`. Suspensão não terá rota enquanto ator, autorização e contrato administrativo estiverem pendentes.

## 29. Estratégia de testes

- **Repository:** SQL, ausência, múltiplas lojas por conta, unicidade, locking e propagação técnica.
- **Rule:** normalização, limites, slug, nullable, estados e matriz de transições.
- **Service:** orquestração, resolução da conta, exceções públicas, concorrência e auditoria.
- **API:** parsing, PATCH/JSON null, envelopes, status HTTP, commit, rollback e não exposição de IDs.
- **Integração:** criação, consulta, listagem, atualização, ativação e encerramento completos.
- **Arquitetura:** ausência de SQL fora do Repository, dependências proibidas e transações fora da API.

A cobertura inclui conta inexistente, várias lojas por conta, Public ID e slug únicos, campos imutáveis, transições válidas/inválidas, concorrência, atualização vazia, encerramento e ausência de exclusão pública.

## 30. Ordem de implementação

```text
alinhamento documental e Data Dictionary
↓
DDL e teste estrutural
↓
STR_RULE_PKG
↓
STR_REPOSITORY_PKG
↓
STR_SERVICE_PKG
↓
STR_API_PKG
↓
instaladores e suítes consolidadas
↓
validação no Oracle
↓
Git
```

Cada etapa estabiliza seu contrato antes da seguinte.

## 31. Critérios de aceite

- Data Dictionary alinhado à propriedade por ACCOUNT antes do DDL;
- agregado mínimo sem atributos de módulos externos;
- relação ACCOUNT 1 para 0..N STORE garantida sem limite comercial físico;
- identificadores técnicos nunca expostos;
- Public ID e slug com unicidade concorrente;
- estados e transições implementados conforme matriz;
- dependências respeitando as camadas;
- exceções públicas pertencentes ao Service;
- PATCH aderente ao Runtime Contract;
- transação apenas na API;
- testes individuais, consolidados, estruturais e de integração aprovados;
- objetos compilados e `USER_ERRORS` vazio no Oracle suportado.

## 32. Decisões pendentes

- formato físico final e mecanismo comum de geração de `STR_PUBLIC_ID`;
- tamanho físico definitivo dos atributos candidatos;
- política de autorização detalhada e modelo de administradores;
- contrato administrativo para suspensão e reativação;
- necessidade e definição de loja “equivalente” por conta;
- estratégia de locking/controle otimista;
- política de histórico e redirecionamento de slug antes de permitir alteração após ativação;
- existência e projeção de vitrine pública;
- moeda e demais configurações em entidade futura;
- condições excepcionais para exclusão física de rascunhos sem dependências.

Nenhuma pendência autoriza improvisação durante a implementação.

## 33. Checklist arquitetural

- [x] STORE separada de ACCOUNT e PROFILE.
- [x] ACCOUNT proprietária e PROFILE não estrutural.
- [x] Cardinalidade 1 para 0..N sem limite artificial.
- [x] Agregado mínimo definido.
- [x] Public ID separado de slug e ID técnico.
- [x] Ciclo de vida e matriz definidos.
- [x] Encerramento distinto de suspensão e exclusão.
- [x] Camadas, dependências e exceções delimitadas.
- [x] PATCH e transações alinhados ao Runtime Contract.
- [x] Segurança, concorrência e auditoria consideradas.
- [x] Casos imediatos separados dos pendentes.
- [x] Data Dictionary alinhado à propriedade e à operação por ACCOUNT.
- [ ] Decisões pendentes aprovadas antes das funcionalidades correspondentes.

## 34. Observações

Este documento deve ser lido em conjunto com `20_DATA_DICTIONARY.md`, `21_DATABASE_CONVENTIONS.md`, `26_PHYSICAL_ARCHITECTURE.md`, `27_API_STANDARDS.md`, `28_CORE_FRAMEWORK.md` e `31_API_RUNTIME_CONTRACT.md`. Em caso de conflito com documento hierarquicamente superior, a implementação deve parar para revisão.

A arquitetura de STORE não define o DDL de BEX_STORE_USER nesta etapa. O Data Dictionary e o DBML registram ACCOUNT como identidade estrutural e operacional, preservando PROFILE exclusivamente como repositório de dados pessoais, sem participação estrutural em STORE ou STORE_USER.
