# Arquitetura Física - Brechó Express

## 1. Objetivo

Este documento tem por objetivo organizar a referência oficial da Arquitetura Física do Brechó Express.

Ele servirá como guia estrutural para o registro e a evolução das decisões de implementação da plataforma, sem substituir a documentação de domínio, arquitetura de sistema, convenções de banco ou decisões de negócio já consolidadas.

A proposta desta primeira versão é estabelecer a estrutura do documento, permitindo que a Sprint 7 o preencha de forma incremental, consistente e alinhada ao restante da documentação oficial do projeto.

---

## 2. Introdução

A Arquitetura Física do Brechó Express descreve a forma como a solução será implementada e operada em termos de componentes, responsabilidades, integração entre camadas, governança técnica e critérios de execução.

Este documento não pretende definir decisões arquiteturais novas de forma definitiva. Sua função é organizar o conhecimento técnico necessário para apoiar a implementação futura, preservando a coerência com os documentos já existentes do projeto.

A estrutura abaixo representa a base inicial para a evolução da Arquitetura Física ao longo da Sprint 7.

---

## 3. Índice Completo

### 3.1 Objetivos
- Definir o propósito da Arquitetura Física da plataforma.
- Organizar as decisões de implementação em uma referência única.
- Servir de guia para evolução técnica do Brechó Express.
- Preservar consistência com o domínio, a arquitetura de sistema e as convenções do banco.

### 3.2 Princípios Arquiteturais
- Alinhamento com a visão do domínio.
- Coerência entre banco de dados, APIs, aplicação Flutter e governança operacional.
- Evolução incremental e controlada.
- Preservação da arquitetura já documentada.

### 3.3 Organização Física da Solução
- Estruturação dos componentes da plataforma.
- Relação entre camadas de negócio, integração e interface.
- Organização das fronteiras técnicas da solução.

### 3.4 Arquitetura Oracle
- Papel do banco Oracle na solução.
- Organização dos componentes de persistência, regras transacionais e integração.
- Relação com a modelagem de domínio já documentada.

### 3.5 Objetos Oracle
- Organização futura para documentação de Tables, Views, Materialized Views, Packages, Types, Constraints, Indexes, Synonyms, Scheduler, Queues e demais objetos Oracle utilizados pelo projeto.
- Estrutura para registrar padrões de uso e evolução dos objetos físicos do banco.

### 3.6 Organização dos Schemas
- Modelo de organização lógica do banco.
- Possíveis separações de responsabilidade entre schemas e contextos.
- Alinhamento com as convenções de nomenclatura e organização do projeto.

### 3.7 Convenções de Implementação
- Padronização das implementações técnicas.
- Diretrizes de estrutura, governança e evolução da implementação física.
- Regras de alinhamento com os documentos oficiais do projeto.

### 3.8 Convenções de Desenvolvimento
- Estrutura futura para documentação de Trigger, Package, Procedure, Function, View, Materialized View, Job, Scheduler, JSON, CLOB e demais recursos Oracle utilizados pela implementação.
- Organização inicial para padronizar a construção e manutenção dos componentes físicos.

### 3.9 Naming Convention
- Estrutura futura para padronizar Packages, Procedures, Functions, Parameters, Variáveis, Cursores, Collections, Records, Tipos Oracle, Constantes, Objetos REST e Objetos APEX.
- Organização inicial para garantir consistência técnica e legibilidade da implementação.

### 3.10 Estratégia de Chaves e Identificadores
- Uso de identificadores internos e públicos.
- Estratégia de unicidade, rastreabilidade e uso de PUBLIC_ID.
- Conformidade com as convenções definidas no projeto.

### 3.11 Arquitetura dos Packages PL/SQL
- Organização dos packages de regras e APIs.
- Papel dos packages no acesso e processamento do banco.
- Alinhamento com a lógica de domínio previamente modelada.

### 3.12 Arquitetura REST (ORDS)
- Papel das APIs REST na integração entre camadas.
- Organização dos endpoints por contexto de negócio.
- Alinhamento com as convenções e padrões do projeto.

### 3.13 Oracle APEX
- Papel da camada de experiência APEX na solução.
- Organização futura da interface de administração, operação e processos de apoio.
- Relação com o domínio e com as demais camadas da plataforma.

### 3.14 Flutter
- Papel da aplicação Flutter na experiência do usuário.
- Organização futura da camada de interface e integração com os serviços da plataforma.
- Relação com os componentes de domínio, APIs e dados da solução.

### 3.15 Estratégia de Transações
- Tratamento de transações de negócio.
- Limites e escopo transacional das operações principais.
- Relação com consistência de domínio e integridade operacional.

### 3.16 Estratégia de Concorrência
- Controle de acesso simultâneo a dados e processos críticos.
- Estratégia para evitar inconsistências em operações concorrentes.
- Alinhamento com o modelo de negócio e o comportamento esperado da plataforma.

### 3.17 Tratamento de Erros
- Estratégia de captura, classificação e resposta a falhas.
- Padrões para erros de domínio, integração e infraestrutura.
- Relação com rastreabilidade e observabilidade.

### 3.18 Auditoria
- Estratégia de rastreio de alterações e eventos.
- Coerência com as convenções de auditoria do projeto.
- Papel da auditoria na governança e conformidade do sistema.

### 3.19 Logs
- Estratégia de registro de eventos operacionais e de negócio.
- Separação entre logs de aplicação, integração e execução de processos.
- Relacionamento com análise e suporte.

### 3.20 Jobs
- Estratégia para execução de processos assíncronos e recorrentes.
- Papel de jobs em integrações, recalculações e rotinas de apoio.
- Alinhamento com o modelo operacional da plataforma.

### 3.21 Scheduler
- Organização de execução de tarefas programadas.
- Relação com jobs, processamento de dados e rotina operacional.
- Governança de execução e monitoramento.

### 3.22 Versionamento do Banco
- Estratégia de versionamento de estruturas e dados.
- Organização das mudanças de schema ao longo do tempo.
- Alinhamento com a evolução controlada do domínio.

### 3.23 Migrations
- Estratégia de aplicação de mudanças no banco.
- Processo de evolução incremental da base de dados.
- Relação com ambientes, validação e release.

### 3.24 Estratégia de Índices
- Critérios para criação e manutenção de índices.
- Alinhamento com necessidades de consulta e performance.
- Coerência com as convenções do projeto.

### 3.25 Estratégia de Performance
- Mecanismos para monitoramento e otimização de execução.
- Critérios de escalabilidade e eficiência para os fluxos principais.
- Relação com o volume esperado da plataforma.

### 3.26 Estratégia de Cache
- Organização futura para documentação de entidades cacheáveis, critérios de cache, invalidação, tempo de vida e responsabilidades.
- Estrutura inicial para governar a reutilização de dados e o comportamento de leitura da plataforma.

### 3.27 Estratégia de Segurança
- Princípios de segurança da solução.
- Proteção de dados, integrações e operações sensíveis.
- Alinhamento com os requisitos de negócio e a camada de identidade.

### 3.28 Autenticação
- Estratégia de autenticação da plataforma.
- Integração com a camada de identidade e acesso.
- Coerência com os conceitos já definidos no domínio.

### 3.29 Autorização
- Estratégia de autorização por papéis, perfis e permissões.
- Relação com a modelagem de PROFILE, ROLE e PROFILE_ROLE.
- Uso de regras de domínio e controle de acesso.

### 3.30 Escalabilidade
- Estrutura futura para contemplar particionamento, arquivamento, compressão, grandes volumes, processamento assíncrono, filas e retenção de dados.
- Organização inicial para apoiar a evolução da solução em cenários de crescimento.

### 3.31 Modelo de Dependência entre Camadas
- A arquitetura física do Brechó Express será organizada com foco inicial no aplicativo Flutter, preservando a abertura para futuras interfaces web, painéis administrativos, integrações externas e outros consumidores.
- A única porta de entrada oficial para consumidores externos será o ORDS.
- Consumidores externos incluem Flutter Mobile, Flutter Web futuro, aplicações web futuras, parceiros e integrações externas.
- Esses consumidores nunca acessarão o banco diretamente.
- O fluxo oficial para consumidores externos será: Flutter / Web / Integrações → ORDS → *_API_PKG → *_SERVICE_PKG → *_RULE_PKG → *_REPOSITORY_PKG → Oracle Tables.
- Consumidores internos ao Oracle poderão chamar packages diretamente, sem passar pelo ORDS.
- Consumidores internos incluem Oracle APEX, DBMS_SCHEDULER, jobs e rotinas internas.
- O fluxo interno será: APEX / Jobs / Scheduler → *_SERVICE_PKG ou *_API_PKG → *_RULE_PKG → *_REPOSITORY_PKG → Oracle Tables.
- ORDS não implementará regra de negócio e não executará SQL solto.
- ORDS apenas receberá requisições externas, chamará packages e devolverá respostas.
- Flutter não conhecerá a estrutura interna do banco nem acessará SQL.
- APEX não será a camada principal da arquitetura, mas sim uma possível interface administrativa e interna.
- Toda regra de negócio deverá existir em um único lugar e ser reutilizável por qualquer interface.
- O aplicativo Flutter é a prioridade inicial do produto.
- As visões web serão tratadas futuramente sem alterar a arquitetura central.

### 3.32 Arquitetura Assíncrona
- Estrutura futura para documentar processamento assíncrono, eventos, webhooks, filas, retry, idempotência, dead letter, integrações externas e processamento em background.
- Organização inicial para apoiar a evolução de integrações e operações não bloqueantes.

### 3.33 Governança de Dados
- Estrutura futura para documentar ciclo de vida dos dados, retenção, arquivamento, anonimização, LGPD, responsabilidade sobre dados e políticas de atualização.
- Organização inicial para apoiar a gestão e a conformidade dos dados da plataforma.

### 3.34 Estratégia de Testes
- Estrutura futura para documentar testes unitários, testes de packages, testes REST, testes de integração, testes de performance, smoke tests e estratégia de homologação.
- Organização inicial para apoiar a validação contínua da implementação física.

### 3.35 Observabilidade
- Estratégia de monitoramento, diagnóstico e rastreabilidade operacional.
- Coleta de sinais de saúde, erros e execução de processos.
- Apoio a operações e suporte da plataforma.
- Evolução futura para contemplar métricas, tracing, logging e health checks operacionais.

### 3.36 Deploy
- Estratégia de implantação da solução.
- Organização de ambientes e ciclos de liberação.
- Coordenação entre banco, APIs, interfaces e integrações.

### 3.37 Decisões Arquiteturais Futuras
- Estrutura de backlog arquitetural para registrar tecnologias e assuntos ainda não decididos.
- Organização inicial para contemplar temas futuros como Redis, Oracle AQ, Kafka, Elastic, Object Storage, CDN, IA, Split Payment, Microservices e Event Bus.
- Espaço para evolução sem tomar decisões arquiteturais prematuras.

### 3.38 Checklist Arquitetural
- Lista de verificação para validar coerência arquitetural da implementação.
- Critérios de alinhamento com o domínio, convenções e decisões já aceitas.
- Guia para revisão e evolução da arquitetura física.

---

## 4. Descrição Breve de Cada Seção

Esta seção serve como introdução ao guia estrutural da Arquitetura Física e descreve, de forma resumida, o que cada bloco deve contemplar à medida que o documento for preenchido.

- Objetivos: consolidar o propósito da arquitetura física e o papel deste documento na evolução da plataforma.
- Princípios Arquiteturais: registrar os fundamentos que orientarão a implementação técnica futura.
- Organização Física da Solução: mapear a estrutura lógica e operacional dos componentes da solução.
- Arquitetura Oracle: detalhar o papel do banco Oracle e a forma como ele sustentará o domínio.
- Objetos Oracle: organizar a documentação futura de Tables, Views, Materialized Views, Packages, Types, Constraints, Indexes, Synonyms, Scheduler, Queues e demais objetos físicos utilizados pela solução.
- Organização dos Schemas: definir como os contextos do sistema serão organizados de forma lógica e governável.
- Convenções de Implementação: registrar padrões e regras para a execução técnica da plataforma.
- Convenções de Desenvolvimento: documentar a evolução futura de Trigger, Package, Procedure, Function, View, Materialized View, Job, Scheduler, JSON, CLOB e demais recursos Oracle.
- Naming Convention: padronizar a nomenclatura de Packages, Procedures, Functions, Parameters, Variáveis, Cursores, Collections, Records, Tipos Oracle, Constantes, Objetos REST e Objetos APEX.
- Estratégia de Chaves e Identificadores: preservar o uso de identificadores internos e públicos de forma consistente.
- Arquitetura dos Packages PL/SQL: estruturar a camada de regras e integração localizada no banco.
- Arquitetura REST (ORDS): organizar a exposição de serviços e integração entre camadas.
- Oracle APEX: registrar o papel da camada de experiência e administração da plataforma.
- Flutter: estruturar a camada de interface e integração com a solução.
- Estratégia de Transações: definir o escopo e o comportamento transacional das operações mais importantes.
- Estratégia de Concorrência: garantir consistência em cenários de uso simultâneo.
- Tratamento de Erros: padronizar o tratamento de falhas e exceções.
- Auditoria: documentar como o sistema manterá rastreabilidade dos eventos relevantes.
- Logs: organizar o registro de eventos e a observação operacional.
- Jobs: descrever a execução de processos recorrentes e assíncronos.
- Scheduler: registrar a coordenação e a programação dessas rotinas.
- Versionamento do Banco: preservar a evolução do schema e da estrutura da base.
- Migrations: detalhar a aplicação de mudanças incrementais no ambiente de dados.
- Estratégia de Índices: organizar a performance de leitura e consulta.
- Estratégia de Performance: garantir eficiência para os fluxos principais da plataforma.
- Estratégia de Cache: documentar o uso de cache, invalidação, TTL e responsabilidades futuras.
- Estratégia de Segurança: proteger os ativos, dados e integrações do sistema.
- Autenticação: documentar como o acesso será validado.
- Autorização: registrar como permissões e papéis serão aplicados.
- Escalabilidade: apoiar a evolução da solução em cenários de crescimento e processamento intensivo.
- Modelo de Dependência entre Camadas: registrar a direção oficial das dependências entre as camadas da plataforma.
- Arquitetura Assíncrona: organizar a documentação futura de eventos, filas, webhooks e processamento em background.
- Governança de Dados: estruturar a gestão do ciclo de vida, retenção, arquivamento e conformidade dos dados.
- Estratégia de Testes: organizar a validação futura por níveis e cenários de execução.
- Integração Oracle + ORDS + APEX + Flutter: explicar o fluxo entre as camadas da solução.
- Observabilidade: registrar como a plataforma será monitorada e diagnosticada, incluindo métricas, tracing, logging e health checks futuros.
- Deploy: organizar o ciclo de implantação da solução.
- Decisões Arquiteturais Futuras: manter um backlog estrutural para temas ainda não decididos.
- Checklist Arquitetural: consolidar os critérios de revisão da arquitetura física.

---

## 5. Observações

Este documento inicial tem caráter de estrutura-guia para a Sprint 7.

Ele deve ser preenchido progressivamente, sempre preservando a coerência com os documentos já existentes de domínio, arquitetura, banco de dados, decisões e políticas de negócio.

Não se trata de uma especificação final, nem de uma nova definição arquitetural desvinculada do projeto. Trata-se de um documento vivo, orientado à implementação e à evolução técnica da plataforma.

---

## 6. Arquitetura Oracle

O Oracle Database constitui o coração da persistência física e do processamento transacional do Brechó Express.

Esta seção descreve os princípios arquiteturais que orientarão a organização física do banco, a estrutura dos objetos e a estratégia de crescimento futuro.

### 6.1 Estratégia de Schemas

O Brechó Express utilizará inicialmente um único schema Oracle para toda a aplicação.

Este schema será responsável por armazenar todos os objetos físicos da plataforma, incluindo:

- Tables
- Views
- Materialized Views
- Packages
- Types
- Scheduler Jobs
- Constraints
- Indexes
- Sequences (quando necessárias)
- Objetos auxiliares

#### Racionalidade

A escolha por um único schema foi motivada pelos seguintes fatores:

- Simplicidade operacional.
- Menor custo de manutenção.
- Equipe de desenvolvimento reduzida.
- Facilidade de deploy e administração Oracle.
- Menor quantidade de grants e synonyms.
- Menor complexidade para ORDS e Oracle APEX.
- O domínio da aplicação já está organizado pela modelagem conceitual, pelos Packages PL/SQL e pela documentação oficial do projeto, não existindo necessidade técnica de separar módulos em schemas diferentes neste momento.

#### Preparação para Evolução Futura

A arquitetura será construída de forma que uma futura separação em múltiplos schemas seja possível, caso a evolução da plataforma justifique essa mudança.

Para isso:

- Não serão utilizadas referências explícitas ao nome do schema no código.
- Serão evitadas dependências desnecessárias entre objetos.
- Será mantido baixo acoplamento entre módulos.
- A aplicação será organizada por domínio e packages, e não por schemas.

### 6.2 Beneficios da Estratégia

- Arquitetura simples e direta.
- Menor complexidade operacional na fase inicial.
- Deploy simplificado e de rápida execução.
- Manutenção facilitada.
- Maior produtividade da equipe.
- Evolução incremental sem entraves técnicos.

### 6.3 Consideracões de Trade-off

- Isolamento físico entre módulos será menor.
- Caso a plataforma cresça significativamente, a separação em múltiplos schemas poderá ser reavaliada futuramente sem impacto na arquitetura de domínio.

### 6.4 Princípio Arquitetural

O Brechó Express não antecipa complexidades que ainda não existem.

Ao mesmo tempo, evita decisões que dificultem sua evolução futura.

A arquitetura deve ser simples para o cenário atual e preparada para crescer quando necessário.

### 6.5 Organização Lógica

Apesar de utilizar um único schema físico, a organização lógica seguirá a estrutura do domínio já definida na documentação do projeto.

Os objetos serão organizados por módulo e contexto de negócio, respeitando:

- A modelagem de domínio.
- As convenções de banco de dados do projeto.
- Os padrões de packages (API_PKG, RULE_PKG, REPOSITORY_PKG, SERVICE_PKG).
- A estrutura de identidade, auth, brechó, catálogo, compra, logística, financeiro e pós-venda.

---

## 7. Arquitetura dos Packages PL/SQL

Os Packages PL/SQL constituem a estrutura técnica responsável pela orquestração de regras de negócio, acesso a dados e exposição de operações do domínio do Brechó Express.

Esta seção descreve a arquitetura de camadas que define as responsabilidades, dependências e padrões de organização dos packages utilizados na plataforma.

### 7.1 Decisão Arquitetural A-002

O Brechó Express adota uma arquitetura de camadas para os Packages PL/SQL, organizada em quatro níveis distintos com responsabilidades bem definidas.

A estrutura de dependência é unidirecional e segue a seguinte hierarquia:

**API_PKG** ↓ **SERVICE_PKG** ↓ **RULE_PKG** ↓ **REPOSITORY_PKG** ↓ **Oracle Tables**

Esta decisão estabelece o contrato arquitetural que guiará toda a implementação de packages no projeto.

### 7.2 Camada API_PKG

A camada API_PKG é responsável pela exposição de operações aos consumidores externos da plataforma.

Ela atua como tradutor entre contratos externos (REST, HTTP, JSON, etc.) e a implementação interna (chamadas PL/SQL).

#### Responsabilidades

- Expor operações consumidas por ORDS (Oracle REST Data Services) e consumidores internos quando necessário.
- Receber parâmetros dos consumidores.
- Validar o contrato de entrada (tipos, obrigatoriedade, formatos).
- Traduzir parâmetros externos para chamadas internas compreensíveis por SERVICE_PKG.
- Orquestrar a chamada à camada SERVICE_PKG.
- Traduzir respostas internas para estruturas retornáveis ao consumidor externo.
- Retornar resposta estruturada ao consumidor.

#### Restrições

- Nunca implementa regra de negócio.
- Nunca acessa tabelas diretamente.
- Nunca chama REPOSITORY_PKG diretamente.
- Nunca implementa lógica de persistência.

#### Papel na Solução

A camada API_PKG atua como contrato técnico entre os consumidores (ORDS, APEX, Scripts internos) e o domínio de negócio implementado nas camadas inferiores.

Ela valida a corretude dos dados de entrada antes de qualquer processamento.

API_PKG protege as camadas inferiores de conhecer detalhes de protocolos externos, formatos de transporte e tipos de consumidores.

### 7.3 Camada SERVICE_PKG

A camada SERVICE_PKG representa os casos de uso da plataforma e é responsável pela orquestração de operações e coordenação entre diferentes contextos de negócio.

#### Natureza de SERVICE_PKG

SERVICE_PKG não é criado automaticamente para cada entidade ou módulo de dados. Ao contrário, SERVICE_PKG nasce quando existe um caso de uso ou um fluxo de negócio que necessita orquestração.

Casos de uso são operações de negócio que frequentemente envolvem múltiplos domínios e requerem coordenação entre diferentes RULE_PKG.

Exemplos conceituais de nomes de SERVICE que refletem casos de uso (não implementações):
- CHECKOUT_SERVICE_PKG: Orquestração do fluxo de finalização de compra
- PURCHASE_SERVICE_PKG: Orquestração da compra, integrando carrinho, pagamento e pedido
- LOGIN_SERVICE_PKG: Orquestração de autenticação e autorização
- STORE_APPROVAL_SERVICE_PKG: Orquestração de aprovação e ativação de lojas
- DELIVERY_SERVICE_PKG: Orquestração do fluxo de entrega, coordenando locais, rotas e rastreamento

Cada SERVICE_PKG representa um fluxo de negócio, não uma tabela ou entidade.

#### Responsabilidades

- Orquestrar casos de uso que frequentemente envolvem múltiplas operações.
- Coordenar operações que ultrapassam os limites de um único domínio.
- Chamar diferentes RULE_PKG quando necessário para implementação distribuída de regras.
- Garantir a sequência correta de operações conforme a lógica de domínio.
- Gerenciar o fluxo de controle entre as camadas.

#### Restrições

- Nunca implementa regra de negócio.
- Nunca acessa tabelas diretamente.
- Nunca chama REPOSITORY_PKG diretamente.
- Nunca chama API_PKG.

#### Papel na Solução

A camada SERVICE_PKG implementa a orquestração e a coordenação necessária para executar os casos de uso da plataforma, distribuindo as responsabilidades entre diferentes RULE_PKG conforme apropriado.

SERVICE_PKG é o local onde fluxos de negócio complexos ganham forma, sem descender a detalhes de implementação de regras ou acesso a dados.

SERVICE_PKG é opaca para a camada API_PKG: ela não conhece ou precisa se importar com protocolos externos, JSON, HTTP, ORDS ou Flutter. Esses detalhes permanecem na camada superior.

### 7.4 Camada RULE_PKG

A camada RULE_PKG é responsável pela implementação das regras de negócio específicas do seu domínio.

#### Responsabilidades

- Implementar as regras de negócio do próprio domínio.
- Conhecer e chamar o REPOSITORY_PKG do próprio domínio.
- Validar precondições e postcondições de operações.
- Calcular e derivar dados conforme as regras do domínio.
- Garantir a consistência interna do domínio.

#### Restrições

- Nunca chama API_PKG.
- Nunca chama SERVICE_PKG.
- Nunca chama RULE_PKG de outro domínio.
- Nunca implementa contrato REST.
- Nunca acessa tabelas de outro domínio diretamente.

#### Papel na Solução

A camada RULE_PKG encapsula e implementa toda a lógica de negócio específica de um contexto de domínio.

Ela é o local onde as regras, validações e cálculos determinam o comportamento correto do sistema conforme a modelagem de domínio.

RULE_PKG é agnóstica a tecnologia: não conhece ORDS, JSON, HTTP, Flutter, APEX, Oracle ou qualquer mecanismo específico de transporte ou interface.

RULE_PKG contém apenas conceitos e regras do domínio, permanecendo independente de como a plataforma expõe suas operações ou persiste dados.

### 7.5 Camada REPOSITORY_PKG

A camada REPOSITORY_PKG é responsável por todo acesso à infraestrutura de persistência e dados.

Repository abstrai o mecanismo específico de persistência, ocultando detalhes tecnológicos das camadas superiores.

#### Natureza de REPOSITORY_PKG

No MVP do Brechó Express, REPOSITORY_PKG acessa predominantemente Oracle Tables através de operações SQL diretas.

No futuro, o mesmo conceito de Repository poderá representar acesso a:
- Oracle Advanced Queuing (AQ)
- Object Storage
- Cache distribuído (Redis, Memcached)
- Search engines (Elastic, Solr)
- Data lakes ou data warehouses
- Outros mecanismos de persistência ou consulta

A decisão sobre essas tecnologias será tomada quando for necessário.

O importante agora é que REPOSITORY_PKG abstrai infraestrutura de persistência, não apenas SQL.

#### Responsabilidades

- Executar operações de leitura (SELECT).
- Executar operações de escrita (INSERT).
- Executar operações de atualização (UPDATE).
- Executar operações de merge de dados (MERGE).
- Executar exclusão lógica conforme as convenções do projeto.
- Retornar dados em estruturas de dados apropriadas.

#### Restrições

- Nunca implementa regra de negócio.
- Nunca chama API_PKG, SERVICE_PKG ou RULE_PKG.
- Nunca executa COMMIT ou ROLLBACK.
- Nunca implementa lógica condicional complexa (apenas lógica de mapeamento).

#### Papel na Solução

A camada REPOSITORY_PKG isola toda complexidade de acesso aos dados, permitindo que as camadas superiores se concentrem em lógica de negócio.

Ela não controla transações, delegando essa responsabilidade para a camada mais externa (API_PKG ou consumidor).

REPOSITORY_PKG é opaca para RULE_PKG: ela oculta como os dados são persistidos, se em Oracle Tables, Oracle AQ, Object Storage, Cache ou outras infraestruturas.

RULE_PKG nunca precisa conhecer esses detalhes.

### 7.6 Regras de Dependência Obrigatórias

As seguintes regras definem a validade arquitetural de qualquer implementação de packages no projeto:

1. **Hierarquia Unidirecional**: A dependência sempre desce. API → SERVICE → RULE → REPOSITORY → TABLE. Nunca sobe.

2. **Nenhuma Chamada Ascendente**: Nenhuma camada inferior pode chamar uma camada superior. RULE nunca chama SERVICE. REPOSITORY nunca chama RULE.

3. **API Sem Lógica de Negócio**: API_PKG valida contratos e coordena, mas nunca implementa regras. Toda lógica vai para SERVICE ou RULE.

4. **SERVICE Sem Lógica de Negócio**: SERVICE_PKG orquestra, mas nunca implementa regras. A lógica vai para RULE_PKG.

5. **RULE Não Cruza Domínios**: RULE_PKG não acessa outro domínio diretamente. Se precisa, passa pela SERVICE_PKG.

6. **REPOSITORY Sem Regras**: REPOSITORY_PKG executa SQL puro, sem lógica condicional de negócio.

7. **REPOSITORY Sem Transações**: REPOSITORY_PKG nunca executa COMMIT ou ROLLBACK. O controle transacional fica em camadas superiores.

8. **Transações Controladas Externamente**: Apenas a camada externa (API_PKG ou consumidor direto) controla o escopo transacional (COMMIT/ROLLBACK).

9. **ORDS Sempre via API**: Endpoints ORDS sempre chamam API_PKG, nunca SERVICE ou RULE diretamente.

10. **APEX e Jobs com Flexibilidade**: Oracle APEX, Jobs e Scheduler podem chamar SERVICE_PKG ou API_PKG conforme o contexto.

11. **Flutter Não Conhece o Banco**: Flutter nunca acessa SQL, procedures diretamente, nem conhece estruturas internas do banco. Sempre via ORDS.

12. **REPOSITORY Não Cruza Domínios via Outro REPOSITORY**: REPOSITORY_PKG nunca chama outro REPOSITORY_PKG. REPOSITORY_PKG conhece apenas as tabelas e estruturas de persistência do seu próprio domínio. Quando uma operação exige dados ou ações de múltiplos domínios, essa coordenação deve acontecer na camada SERVICE_PKG. Se um REPOSITORY precisa consultar ou alterar outro domínio, isso indica que a lógica está no lugar errado.

### 7.7 Benefícios da Arquitetura

- **Separação de Responsabilidades Clara**: Cada camada tem um propósito bem definido e inconfundível.
- **Reutilização de Código**: Regras de negócio em RULE_PKG podem ser chamadas por múltiplas SERVICE ou API.
- **Testabilidade**: Cada camada pode ser testada isoladamente.
- **Manutenibilidade**: Mudanças em regras de negócio ficam localizadas em RULE_PKG.
- **Escalabilidade**: Novas operações podem ser adicionadas sem modificar camadas internas.
- **Reuso Operacional**: Casos de uso complexos podem reutilizar SERVICE e RULE já existentes.
- **Consistência Técnica**: O mesmo padrão é aplicado em todos os domínios da plataforma.
- **Facilita Code Review**: A estrutura clara permite revisão e validação mais eficiente.

### 7.8 Trade-offs da Arquitetura

- **Mais Camadas**: A hierarquia de 4 camadas requer mais packages a manter.
- **Curva de Aprendizado**: Desenvolvedores precisam entender o padrão antes de contribuir.
- **Indireção Inicial**: Fluxo simples de leitura pode atravessar múltiplas camadas.
- **Mais Dependências de Packages**: Cada domínio requerer múltiplos packages.

### 7.9 Consequências da Decisão

- **Implementação Obedece Padrão**: Todas as operações implementadas seguem a mesma hierarquia.
- **Mudanças de Regras Localizadas**: Se uma regra muda, a alteração fica em RULE_PKG.
- **Adição de Operações Previsível**: Novas API seguem o mesmo fluxo (API → SERVICE → RULE → REPOSITORY).
- **Transações Sempre Consistentes**: Controle centralizado em camadas externas garante consistência.
- **Facilita Integração com ORDS**: ORDS chama API_PKG e recebe resposta estruturada.
- **Facilita Integração com APEX**: APEX pode chamar SERVICE_PKG ou API_PKG conforme contexto.
- **Domínio Protegido**: RULE_PKG nunca é chamada por consumidores externos, apenas internamente.
- **Evolução Preparada**: Futuros padrões (como Event Bus, Sagas) trabalham com essa hierarquia.

### 7.10 Alinhamento com Documentação Existente

Esta arquitetura de packages é consistente com:

- A modelagem de domínio documentada em **20_DOMAIN_MODEL.md**.
- As convenções de banco definidas em **21_DATABASE_CONVENTIONS.md**.
- Os padrões de naming em **09_NAMING_CONVENTIONS.md** (quando existente).
- A estrutura de módulos: identity, auth, brechó, catálogo, compra, logística, financeiro e pós-venda.
- As decisões de transação e persistência que serão documentadas em seções futuras deste documento.

### 7.11 Princípios de Transparência e Proteção das Camadas

#### Transparência entre Camadas

Cada camada deve ser transparente (opaca) em relação à camada imediatamente superior:

- **API_PKG é opaca para consumidores externos**: Consumidores não conhecem SERVICE, RULE, REPOSITORY ou tabelas. Conhecem apenas contratos REST.

- **SERVICE_PKG é opaca para API_PKG**: API_PKG não conhece nomes de RULE_PKG, lógica de coordenação ou detalhes de orquestração. Conhece apenas que SERVICE_PKG entrega o resultado esperado.

- **RULE_PKG é opaca para SERVICE_PKG**: SERVICE_PKG não conhece tabelas, índices, constraints, Oracle ou detalhes de infraestrutura. Conhece apenas que RULE_PKG implementa regras.

- **REPOSITORY_PKG é opaca para RULE_PKG**: RULE_PKG não conhece se dados vêm de Oracle Tables, Oracle AQ, Object Storage, Cache ou outra infraestrutura. Conhece apenas que REPOSITORY_PKG fornece os dados.

Cada camada esconde detalhes de sua implementação e da camada imediatamente inferior.

#### Proteção das Camadas

Cada camada existe para proteger a camada imediatamente inferior:

- **API_PKG protege SERVICE_PKG**: SERVICE_PKG não precisa se importar com protocolos externos, formatos de transporte, ORDS, JSON ou HTTP. API_PKG traduz esses detalhes.

- **SERVICE_PKG protege RULE_PKG**: RULE_PKG não precisa se importar com orquestração de casos de uso complexos ou coordenação entre domínios. SERVICE_PKG gerencia essas complexidades.

- **RULE_PKG protege REPOSITORY_PKG**: REPOSITORY_PKG não precisa implementar regras de negócio. RULE_PKG encapsula toda lógica, deixando REPOSITORY com apenas acesso e persistência.

- **REPOSITORY_PKG protege Oracle Tables**: Oracle Tables e infraestrutura de persistência não precisam conhecer regras, casos de uso ou protocolos externos. REPOSITORY_PKG isolada essa complexidade.

Este modelo de proteção permite que cada camada evolua com mínimo impacto nas camadas superiores.

---

## 8. Estratégia de Transações

No Brechó Express, uma transação representa um caso de uso completo do negócio, e não uma operação isolada de banco de dados.

A fronteira transacional é definida pelo fluxo de negócio executado, preservando a consistência do domínio de ponta a ponta.

### 8.1 Decisão Arquitetural A-003

O controle transacional será realizado pela camada mais externa da operação.

No fluxo inicial da plataforma:

Flutter  
↓  
ORDS  
↓  
API_PKG  
↓  
SERVICE_PKG  
↓  
RULE_PKG  
↓  
REPOSITORY_PKG  
↓  
Oracle Database

A camada `API_PKG` será responsável pelo `COMMIT` ou `ROLLBACK` das chamadas realizadas via ORDS.

Jobs e rotinas executadas pelo `DBMS_SCHEDULER` serão responsáveis pelo controle transacional das execuções internas.

### 8.2 Regras Obrigatórias

- `SERVICE_PKG` nunca executa `COMMIT` ou `ROLLBACK`.
- `RULE_PKG` nunca executa `COMMIT` ou `ROLLBACK`.
- `REPOSITORY_PKG` nunca executa `COMMIT` ou `ROLLBACK`.
- Cada caso de uso deve possuir uma única decisão transacional.
- Toda operação crítica deve ser confirmada integralmente ou revertida integralmente.
- Não haverá confirmação parcial de regras críticas de negócio.
- A fronteira transacional é determinada pelo caso de uso, não pela tabela, package ou operação SQL.
- Persistência nunca determina a fronteira da transação.

### 8.3 AUTONOMOUS_TRANSACTION

`PRAGMA AUTONOMOUS_TRANSACTION` é permitido apenas para finalidades técnicas, como:

- `ERROR_LOG`
- `JOB_LOG`
- `INTEGRATION_LOG`
- `AUDIT_LOG` técnico
- registros de observabilidade que precisam sobreviver ao rollback da transação principal

O uso de `AUTONOMOUS_TRANSACTION` não deve alterar estado funcional do domínio.

Não deve ser usado para confirmar:

- pedido
- pagamento
- estoque
- saldo
- shipment
- qualquer entidade transacional de negócio

Seu uso deve permanecer encapsulado em packages específicos de log, auditoria ou observabilidade.

### 8.4 SAVEPOINT

`SAVEPOINT` não faz parte da estratégia padrão da plataforma.

Seu uso será permitido apenas em cenários excepcionais, devidamente documentados e justificados.

### 8.5 Benefícios

- Consistência transacional.
- Previsibilidade.
- Manutenção simples.
- Facilidade de testes.
- Menor acoplamento.
- Reutilização dos packages.
- Redução de efeitos colaterais.

### 8.6 Trade-offs

- Menor flexibilidade para commits parciais.
- Maior responsabilidade da camada externa.
- Necessidade de modelar corretamente os casos de uso.
- Necessidade de logs técnicos autônomos para diagnóstico.

### 8.7 Princípio Arquitetural

Toda transação deve refletir uma intenção de negócio completa.

O banco executa operações físicas, mas a transação pertence ao caso de uso.

#### Fluxo Transacional Oficial

```
Flutter
  ↓
ORDS
  ↓
API_PKG (INICIA TRANSAÇÃO)
  ↓
SERVICE_PKG
  ↓
RULE_PKG
  ↓
REPOSITORY_PKG
  ↓
Oracle Database
  ↓
REPOSITORY_PKG
  ↓
RULE_PKG
  ↓
SERVICE_PKG
  ↓
API_PKG (FINALIZA TRANSAÇÃO: COMMIT ou ROLLBACK)
  ↓
ORDS
  ↓
Flutter
```

O controle de COMMIT e ROLLBACK pertence à borda da aplicação e nunca às camadas internas.

#### Consumidores Internos (APEX, Jobs, Scheduler)

Consumidores internos que chamarem SERVICE_PKG ou API_PKG diretamente serão responsáveis pelo controle transacional das operações que dispararem.

### 8.4 Regras Obrigatórias

As seguintes regras definem o comportamento transacional válido no projeto:

1. **API_PKG Controla Transações Externas**: API_PKG é responsável pelo controle transacional de todas as chamadas realizadas através de ORDS. API_PKG inicia a transação antes de chamar SERVICE_PKG e finaliza (COMMIT ou ROLLBACK) após a execução completa.

2. **SERVICE_PKG Não Executa Transações**: SERVICE_PKG nunca executa COMMIT ou ROLLBACK. SERVICE_PKG apenas orquestra o caso de uso, delegando o controle transacional para a camada superior (API_PKG).

3. **RULE_PKG Não Executa Transações**: RULE_PKG nunca executa COMMIT ou ROLLBACK. RULE_PKG implementa apenas regras de negócio, sem responsabilidade sobre consistência transacional.

4. **REPOSITORY_PKG Não Executa Transações**: REPOSITORY_PKG nunca executa COMMIT ou ROLLBACK. REPOSITORY_PKG realiza apenas operações de persistência, deixando o controle transacional para camadas superiores.

5. **Jobs e Scheduler Controlam Suas Transações**: Rotinas internas executadas por DBMS_SCHEDULER ou Jobs são responsáveis pelo controle transacional das operações que realizarem.

6. **Decisão Transacional Única por Caso de Uso**: Cada caso de uso deve resultar em uma única decisão transacional. Ou toda a operação é confirmada (COMMIT), ou toda a operação é revertida (ROLLBACK). Não há confirmações parciais de regras críticas de negócio.

### 8.5 Princípios Transacionais

Os seguintes princípios guiam a estratégia de transações do Brechó Express:

- **Transações Refletem Casos de Uso**: A fronteira transacional é determinada pelo caso de uso, não pela persistência. A transação começa e termina com o caso de uso.

- **Persistência Não Determina Transação**: A estrutura de banco de dados (quantas tabelas, quantas operações SQL) nunca deve determinar o escopo transacional. O escopo é determinado pela lógica de negócio.

- **Consistência de Domínio**: Toda operação crítica deve preservar a integridade e consistência do domínio, garantindo que dados inconsistentes nunca sejam confirmados.

- **Simplicidade Operacional**: O modelo transacional deve ser simples de entender e executar, minimizando complexidade e efeitos colaterais não intencionais.

- **Reutilização de Packages**: Packages internos (SERVICE, RULE, REPOSITORY) podem ser reutilizados por múltiplos casos de uso sem modificação, porque o controle transacional é responsabilidade do consumidor.

### 8.6 Restrições Transacionais

As seguintes restrições são invioláveis:

**COMMIT não pode ser executado por:**

- SERVICE_PKG
- RULE_PKG
- REPOSITORY_PKG

**ROLLBACK não pode ser executado por:**

- SERVICE_PKG
- RULE_PKG
- REPOSITORY_PKG

Essas restrições garantem que apenas a camada mais externa mantenha controle sobre a consistência das operações.

### 8.7 Autonomous Transaction

PRAGMA AUTONOMOUS_TRANSACTION será considerado uma exceção arquitetural no Brechó Express.

Seu uso será evitado ao máximo.

Quando realmente necessário, deverá possuir:

- Justificativa técnica documentada
- Aprovação arquitetural explícita
- Registro em decisão de arquitetura separada

A maioria dos casos que desejam usar AUTONOMOUS_TRANSACTION pode ser resolvida mediante reorganização do código para separar a lógica em packages independentes que não precisam participar da transação principal.

### 8.8 Savepoint

SAVEPOINT não faz parte da estratégia padrão de transações do Brechó Express.

Seu uso será permitido apenas em cenários excepcionais:

- Devidamente documentados
- Com justificativa técnica clara
- Com aprovação arquitetural

SAVEPOINT aumenta complexidade e reduz previsibilidade. Deve ser evitado em favor de reorganização lógica ou execução de operações fora do escopo transacional.

### 8.9 Benefícios da Estratégia

A estratégia de transações orientada por casos de uso oferece diversos benefícios:

- **Simplicidade de Manutenção**: Modelo transacional é simples, direto e fácil de entender. Desenvolvedores sabem onde o controle transacional ocorre.

- **Previsibilidade**: O comportamento transacional é previsível e consistente. Todo caso de uso segue o mesmo padrão.

- **Consistência Transacional Garantida**: Casos de uso complexos podem coordenar múltiplos domínios e regras, mas a confirmação ou reversão é atômica.

- **Facilidade de Testes**: Packages internos podem ser testados isoladamente, sem necessidade de gerenciar transações. Apenas a camada externa (API ou consumidor) controla transações.

- **Menor Acoplamento**: SERVICE, RULE e REPOSITORY não conhecem ou se importam com transações. Podem ser reutilizados por qualquer consumidor sem modificação.

- **Reutilização de Packages**: Packages internos podem ser chamados por diferentes camadas (API_PKG, APEX, Jobs) sem alteração, porque o controle transacional é responsabilidade do chamador.

- **Redução de Efeitos Colaterais**: Transações automáticas em camadas internas frequentemente causam problemas e efeitos colaterais inesperados. Deixando o controle na borda, esses problemas são evitados.

- **Evolução Preparada**: Modelo permite que futuros padrões (sagas distribuídas, event sourcing) sejam implementados sem quebrar as regras transacionais já estabelecidas.

### 8.10 Trade-offs da Estratégia

A estratégia de transações também apresenta limitações e trade-offs:

- **Responsabilidade do Consumidor**: O controle transacional fica inteiramente com o consumidor externo (API_PKG ou equivalente). Se o consumidor não gerenciar corretamente, a consistência pode ser comprometida.

- **Sem Autoproteção nas Camadas Internas**: SERVICE_PKG, RULE_PKG e REPOSITORY_PKG não possuem proteção automática contra inconsistência transacional. Dependem da camada superior.

- **Complexidade em Casos de Uso Aninhados**: Se um caso de uso chama outro caso de uso, o controle transacional pode se tornar complexo e exigir cuidado especial.

- **Sem Suporte a Autonomous Operations**: Operações que realmente precisam executar fora do escopo transacional principal requerem exceções (AUTONOMOUS_TRANSACTION) que devem ser aprovadas e documentadas.

- **Requer Maturidade Operacional**: A estratégia requer que consumidores externos (especialmente consumidores internos como APEX e Jobs) entendam e respeitem as responsabilidades transacionais.

### 8.11 Alinhamento com Arquitetura Existente

Esta estratégia de transações está integrada com:

- A arquitetura de packages descrita em **Seção 7 (Arquitetura dos Packages PL/SQL)**: API_PKG é responsável por controlar transações das operações externas.

- A estratégia de SERVICE_PKG como representante de casos de uso: Cada SERVICE_PKG implementa um caso de uso, que corresponde a uma transação.

- A separação de responsabilidades entre camadas: Cada camada conhece apenas sua responsabilidade, não o controle transacional.

- As convenções de banco de dados: Soft delete, audit fields e PUBLIC_ID são operações transacionais que ocorrem dentro do escopo definido pela camada externa.

## 9. Estratégia de Tratamento de Erros

O Brechó Express adotará uma estratégia centralizada para tratamento de erros.

Nenhuma camada deverá utilizar `RAISE_APPLICATION_ERROR` diretamente de forma espalhada pelo sistema.

Todo erro da plataforma deverá ser lançado por meio de um package centralizado de erro, responsável por padronizar código, categoria, mensagem, severidade, rastreabilidade e resposta para consumidores externos.

### 9.1 Decisão Arquitetural A-004

A plataforma utilizará um package central de erros, chamado conceitualmente de `ERR_PKG`.

Este package será responsável por:

- lançar erros de negócio;
- lançar erros de validação;
- lançar erros de segurança;
- lançar erros de recurso não encontrado;
- lançar erros técnicos;
- padronizar códigos;
- padronizar mensagens;
- registrar logs quando necessário;
- preparar respostas consistentes para ORDS e Flutter.

### 9.2 Catálogo de Erros

Os erros oficiais da plataforma deverão ser catalogados.

Cada erro deverá possuir:

- código único;
- categoria;
- mensagem funcional;
- mensagem técnica quando aplicável;
- severidade;
- indicação se é recuperável;
- indicação se deve gerar log técnico.

Exemplo conceitual de código:

- `BEX-ACC-001`
- `BEX-PRD-001`
- `BEX-ORD-001`
- `BEX-PAY-001`

### 9.3 Categorias de Erro

As categorias iniciais serão:

- BUSINESS_ERROR
- VALIDATION_ERROR
- NOT_FOUND
- SECURITY_ERROR
- AUTHENTICATION_ERROR
- AUTHORIZATION_ERROR
- CONFLICT_ERROR
- TECHNICAL_ERROR
- INTEGRATION_ERROR

### 9.4 Regras Obrigatórias

- `RAISE_APPLICATION_ERROR` não deve ser usado diretamente nas regras de negócio.
- Erros devem ser lançados pelo package central de erro.
- Flutter nunca deve depender de mensagens técnicas Oracle.
- ORDS deve retornar resposta padronizada.
- Erros técnicos devem ser registrados em `ERROR_LOG`.
- Mensagens para usuário e mensagens técnicas devem ser separadas.
- Códigos de erro devem ser estáveis e documentados.
- Cada erro deve possuir uma intenção clara.

### 9.5 Resposta Padronizada

Toda resposta de erro para consumidores externos deverá seguir uma estrutura padronizada, contendo conceitualmente:

- sucesso/falha;
- código do erro;
- mensagem amigável;
- categoria;
- rastreabilidade;
- indicação se pode tentar novamente.

### 9.6 Logs de Erro

Erros técnicos e inesperados deverão ser registrados em estrutura própria de log.

O registro de erro poderá utilizar `AUTONOMOUS_TRANSACTION` para garantir que informações de diagnóstico sobrevivam ao rollback da transação principal.

Essa regra se aplica apenas a logs técnicos e nunca a alterações funcionais do domínio.

### 9.7 Benefícios

- Padronização para Flutter e ORDS.
- Menor acoplamento entre interface e banco.
- Melhor rastreabilidade.
- Facilidade de suporte.
- Facilidade de internacionalização futura.
- Menor risco de mensagens técnicas vazarem ao usuário.
- Catálogo claro de erros oficiais da plataforma.

### 9.8 Trade-offs

- Exige disciplina na criação de novos erros.
- Exige manutenção de catálogo.
- Exige padronização entre packages.
- Pode parecer mais burocrático no início.

### 9.9 Princípio Arquitetural

Erro também é contrato.

Todo erro exposto pela plataforma deve ser previsível, rastreável e compreensível.