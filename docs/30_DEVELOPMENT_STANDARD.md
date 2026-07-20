# Padrão Permanente de Desenvolvimento PL/SQL - Brechó Express

## 1. Objetivo

Este documento define o padrão permanente para desenvolvimento, revisão e evolução dos componentes PL/SQL do Brechó Express.

Seu propósito é transformar as decisões arquiteturais já aprovadas em regras operacionais de implementação. Ele não substitui o domínio, o Data Dictionary, as convenções de banco, a arquitetura física, os contratos de API nem o Core Framework. Quando um assunto já estiver detalhado nos documentos oficiais, este padrão estabelece como consultá-lo e aplicá-lo, sem reproduzi-lo integralmente.

Este documento aplica-se a módulos de negócio, componentes internos, integrações, jobs, importações, exportações, instaladores e testes Oracle.

### 1.1 Governança do Documento

Este é o padrão permanente de engenharia PL/SQL do Brechó Express. Sua evolução deve passar por revisão arquitetural compatível com o impacto da mudança e não deve ocorrer apenas por conveniência de uma sprint.

Mudanças materiais no domínio, na arquitetura, no Core Framework, em contratos públicos ou em princípios permanentes de engenharia devem ser formalizadas por ADR quando aplicável. Correções textuais, esclarecimentos sem alteração normativa e ajustes editoriais não exigem ADR por si sós.

---

## 2. Hierarquia e Prioridade Documental

A implementação deve respeitar a seguinte ordem de autoridade:

1. `00_CONSTITUICAO.md`, para identidade, valores e limites fundamentais do projeto;
2. decisões aceitas em `09_DECISIONS.md`;
3. modelo e regras de domínio, especialmente `20_DATA_DICTIONARY.md`, `22_ENTITY_MODELING_STANDARD.md`, `23_DOMAIN_MODEL.md` e `24_SYSTEM_ARCHITECTURE.md`;
4. convenções físicas e de banco em `21_DATABASE_CONVENTIONS.md` e `26_PHYSICAL_ARCHITECTURE.md`;
5. contratos externos em `27_API_STANDARDS.md`;
6. capacidades transversais e lifecycle em `28_CORE_FRAMEWORK.md` e `29_EXECUTION_CONTEXT.md`;
7. este padrão de desenvolvimento;
8. código e testes vigentes, como evidência da implementação atualmente disponível.

`04_ARCHITECTURE.md` e `11_AI_CONTEXT.md` fornecem visão geral e restrições de contexto, mas não substituem documentos posteriores e especializados.

Em caso de conflito:

- uma regra expressa de documento superior prevalece;
- uma decisão aceita prevalece sobre exemplo conceitual, sugestão ou decisão pendente;
- contratos efetivamente aprovados e implementados não devem ser inferidos de exemplos antigos;
- divergências reais não devem ser resolvidas silenciosamente no código: devem ser registradas e submetidas à decisão arquitetural antes da implementação;
- itens marcados como futuros, conceituais ou pendentes não constituem autorização para criar objetos, dependências ou tecnologias.

### 2.1 Decisões que Exigem ADR

Devem ser formalizadas por ADR, quando materiais, mudanças em:

- limites de módulos e direção de dependências;
- modelo de domínio ou estrutura pública de entidades;
- contratos externos;
- Core Framework e lifecycle de execução;
- limites transacionais e regras de segurança;
- tecnologia estrutural ou política permanente de engenharia.

Correções locais, refatorações internas sem alteração de contrato, testes e documentação sem impacto arquitetural não exigem ADR automaticamente. A classificação deve considerar o efeito real da mudança, não apenas o tipo do arquivo alterado.

---

## 3. Princípios de Desenvolvimento

Todo componente PL/SQL deve:

- possuir responsabilidade coesa e nomeada;
- usar a Linguagem Ubíqua e os prefixos oficiais do domínio;
- depender apenas do necessário para cumprir sua responsabilidade;
- manter direção de dependência explícita e acíclica;
- preservar separação entre domínio, caso de uso, persistência e transporte;
- falhar de forma previsível, sem expor detalhes internos;
- ser testável de forma isolada e na suíte consolidada;
- evitar estado global, efeitos colaterais ocultos e abstrações genéricas;
- implementar somente conceitos já aprovados e documentados.

Packages genéricos, como `UTIL_PKG`, `COMMON_PKG`, `HELPER_PKG` ou equivalentes sem responsabilidade específica, são proibidos. Uma capacidade compartilhada deve possuir contrato, nome e proprietário claros.

`DBMS_OUTPUT` é proibido em packages de produção. É permitido em instaladores, testes e scripts operacionais, onde constitui saída de execução e diagnóstico controlado.

### 3.1 Fluxo Oficial de Desenvolvimento

```text
Necessidade de negócio
        ↓
Arquitetura e decisão
        ↓
Documentação
        ↓
Implementação pelo Codex
        ↓
Review técnico e arquitetural
        ↓
Execução no Oracle
        ↓
Testes
        ↓
Git
```

O código não deve preceder uma definição arquitetural necessária. O Codex implementa a especificação autorizada e não define silenciosamente arquitetura, domínio ou contrato público. Falhas encontradas no review, na execução ou nos testes podem devolver o fluxo à etapa adequada. Commit somente deve ocorrer após review e validação, e apenas quando autorizado.

### 3.2 Ordem de Leitura para Implementação

Conforme o contexto aplicável, a leitura deve seguir esta ordem:

1. `00_CONSTITUICAO.md`;
2. ADRs aplicáveis;
3. guia da sprint e especificação da tarefa;
4. domínio e Data Dictionary;
5. arquitetura física, padrões de API e contexto de execução;
6. Core Framework;
7. este padrão permanente;
8. código relacionado;
9. testes relacionados.

A leitura pode ser reduzida ao contexto efetivamente aplicável à mudança. O guia da sprint e a especificação da tarefa possuem prioridade operacional dentro do escopo autorizado, sem revogar decisões arquiteturais superiores. Conflitos materiais não devem ser resolvidos por inferência: o Codex deve comunicar a divergência antes de alterar arquitetura ou contrato.

### 3.3 Definition of Ready Mínima

Antes da implementação, devem estar definidos, conforme aplicável:

- objetivo e escopo;
- conceito correspondente no domínio;
- coerência com o Data Dictionary;
- responsabilidades dos packages envolvidos;
- contratos de entrada e saída;
- códigos de erro e estratégia de tratamento;
- dependências permitidas;
- critérios de aceite;
- arquivos autorizados e proibidos;
- decisões ainda pendentes.

Alterações internas simples não exigem endpoint, API externa ou atualização de todos os documentos quando esses elementos não fizerem parte do seu impacto.

---

## 4. Estrutura Padrão dos Módulos de Negócio

Um módulo é organizado pelo prefixo oficial de três letras definido no Data Dictionary. A existência de cada package depende de necessidade real; não se criam packages vazios para completar uma lista.

Estrutura possível:

```text
<PREFIXO>_RULE_PKG
<PREFIXO>_API_PKG
<PREFIXO>_QUERY_PKG
<PREFIXO>_EVENT_PKG
<PREFIXO>_JOB_PKG
<PREFIXO>_IMPORT_PKG
<PREFIXO>_EXPORT_PKG
```

Quando um caso de uso ou uma abstração de persistência exigir `*_SERVICE_PKG` ou `*_REPOSITORY_PKG`, aplicam-se as responsabilidades e a hierarquia definidas em `26_PHYSICAL_ARCHITECTURE.md`. Esses packages não são obrigatórios por entidade e não devem ser criados sem necessidade concreta.

Cada módulo deve manter seus arquivos agrupados por contexto de negócio e possuir instalador e suíte consolidados compatíveis com a ordem real de dependências.

---

## 5. Responsabilidades dos Packages

### 5.1 RULE

`<PREFIXO>_RULE_PKG` concentra regras, invariantes, validações funcionais, transições de estado e cálculos do próprio domínio.

Deve:

- expressar regras na linguagem do domínio;
- validar precondições e postcondições funcionais;
- manter consistência do próprio módulo;
- produzir erros conhecidos por meio do contrato de `CORE_ERROR_PKG`;
- receber dados funcionais por parâmetros explícitos.

Não deve:

- conhecer ORDS, HTTP, JSON ou Flutter;
- montar envelopes de resposta;
- chamar API, JOB, IMPORT ou EXPORT;
- acessar outro domínio diretamente;
- executar `COMMIT` ou `ROLLBACK`;
- usar `DBMS_OUTPUT` ou `RAISE_APPLICATION_ERROR` como contrato público.

### 5.2 API

`<PREFIXO>_API_PKG` é a fronteira PL/SQL consumida pelo ORDS. Ele adapta o contrato externo ao caso de uso interno.

Deve:

- receber e validar o contrato técnico de entrada;
- inicializar e finalizar o lifecycle técnico quando for a borda responsável;
- chamar o caso de uso ou regra apropriada;
- construir o payload JSON do contrato;
- usar `CORE_RESPONSE_PKG` para o envelope vigente;
- propagar erro conhecido ou inesperado de forma segura;
- garantir limpeza de contexto em sucesso e falha.

Não deve:

- implementar regra de domínio;
- executar SQL de domínio diretamente;
- expor identificadores internos;
- retornar `SQLERRM`, stack, backtrace ou nomes internos;
- executar `COMMIT` ou `ROLLBACK`.

A decisão transacional pertence ao chamador ou orquestrador responsável pela execução. O adapter ORDS e o package API não devem encerrar silenciosamente uma transação que possa abranger outras operações.

### 5.3 QUERY

`<PREFIXO>_QUERY_PKG` concentra consultas, projeções e read models específicos do módulo. QUERY é uma fronteira de leitura e não representa a camada completa de persistência.

Deve:

- executar somente consultas estáticas, salvo exceção documentada para SQL dinâmico;
- expor resultados tipados e estáveis para consumidores internos;
- aplicar filtros de visibilidade e segurança que pertençam ao contrato da consulta;
- consultar apenas dados autorizados pela fronteira do módulo;
- permanecer livre de efeitos funcionais.

Não deve:

- executar `INSERT`, `UPDATE`, `DELETE` ou `MERGE`;
- alterar estado por meio de função de leitura;
- provocar qualquer mudança funcional de estado;
- implementar transição de domínio;
- montar envelope HTTP;
- executar `COMMIT` ou `ROLLBACK`;
- servir como acesso genérico e irrestrito a tabelas.

Uma futura responsabilidade de persistência de escrita pode pertencer a `*_SERVICE_PKG` ou `*_REPOSITORY_PKG`, conforme arquitetura expressamente aprovada. Este padrão não institui repository genérico nem autoriza sua criação automática.

### 5.4 EVENT

`<PREFIXO>_EVENT_PKG` trata eventos do módulo quando houver arquitetura de eventos aprovada.

Deve:

- representar eventos nomeados no passado e com significado de domínio;
- validar origem, identidade e idempotência do evento;
- encaminhar o processamento para casos de uso e regras existentes;
- preservar rastreabilidade;
- separar payload recebido de entidade persistida.

Não deve:

- criar uma infraestrutura de event bus não aprovada;
- ocultar regra de negócio no handler;
- duplicar efeitos em reprocessamento;
- chamar API externa de outro módulo como atalho arquitetural;
- executar transação autônoma para estado funcional.

### 5.5 JOB

`<PREFIXO>_JOB_PKG` é o executor de processo interno acionado pelo `DBMS_SCHEDULER`.

Deve:

- inicializar Trace, Execution Context e Security Context compatíveis com execução técnica;
- chamar services ou regras já existentes;
- definir fronteira transacional explícita por execução, lote ou item;
- registrar execução conforme a infraestrutura aprovada;
- ser idempotente e reexecutável;
- limpar todo contexto em sucesso e falha.

Não deve:

- colocar regra de domínio no Scheduler;
- permitir que o Scheduler execute SQL diretamente;
- duplicar regra existente;
- registrar credenciais, tokens ou dados sensíveis.

### 5.6 IMPORT

`<PREFIXO>_IMPORT_PKG` adapta dados externos para contratos internos aprovados.

Deve:

- validar formato, origem e integridade da entrada;
- separar parsing, validação técnica e aplicação funcional;
- usar regras e casos de uso existentes;
- definir idempotência, rejeição e reprocessamento;
- manter rastreabilidade por item ou lote conforme necessidade.

Não deve:

- gravar dados sem validação funcional;
- transformar payload externo em SQL dinâmico;
- ignorar itens inválidos silenciosamente;
- expor credenciais ou payload sensível em logs.

### 5.7 EXPORT

`<PREFIXO>_EXPORT_PKG` produz dados para consumidores ou integrações aprovadas.

Deve:

- usar consultas e contratos internos autorizados;
- aplicar filtros de segurança, minimização e visibilidade;
- produzir formato estável e documentado;
- preservar `PUBLIC_ID` nas fronteiras externas;
- permitir processamento em lote quando necessário.

Não deve:

- expor IDs internos, hashes, credenciais ou dados não autorizados;
- alterar estado funcional como efeito oculto da leitura;
- consultar tabelas de outros módulos sem contrato aprovado;
- definir formatos externos a partir da estrutura física das tabelas.

---

## 6. Separação de Responsabilidades

A implementação deve preservar quatro interesses distintos:

| Interesse | Responsabilidade | Não deve conhecer |
|---|---|---|
| Regra de domínio | Invariantes, cálculos e decisões funcionais | HTTP, ORDS, JSON e detalhes de interface |
| Caso de uso | Sequência e coordenação de operações | Formato físico de tabelas e apresentação visual |
| Persistência | SELECT e DML autorizados, mapeamento e concorrência | Regra funcional, HTTP e envelope JSON |
| Apresentação JSON | Contrato externo, tipos JSON e envelope | SQL, tabelas e decisões de domínio |

O fluxo padrão permanece descendente e deve usar apenas as camadas necessárias:

```text
ORDS
  ↓
*_API_PKG
  ↓
caso de uso aprovado
  ↓
*_RULE_PKG
  ↓
persistência autorizada
  ↓
Oracle Database
```

Um fluxo simples pode omitir uma camada sem responsabilidade real, mas nunca misturar suas responsabilidades. A omissão deve reduzir indireção, não transferir regra para API ou JSON para RULE.

Consultas de leitura podem seguir `API → QUERY` quando não executarem regra ou alteração funcional. Fluxos entre módulos devem ser coordenados por um caso de uso/orquestrador, nunca por chamada lateral entre repositories, rules ou queries.

---

## 7. Convenções de Nomenclatura PL/SQL

Todo identificador PL/SQL deve estar em inglês técnico, ser descritivo e usar `snake_case`. Siglas oficiais do Data Dictionary permanecem em maiúsculas nos nomes de objetos Oracle.

### 7.1 Packages

- negócio: `<PREFIXO>_<RESPONSABILIDADE>_PKG`;
- Core: `CORE_<RESPONSABILIDADE>_PKG`;
- não usar nomes genéricos ou abreviações não catalogadas.

### 7.2 Parâmetros

- entrada: `p_<nome>`;
- saída: `o_<nome>`;
- entrada e saída: `io_<nome>`;
- declarar `IN`, `OUT` ou `IN OUT` explicitamente;
- usar `NOCOPY` em records, coleções, objetos JSON e LOBs de saída quando apropriado e seguro;
- não usar parâmetros booleanos ambíguos sem nome funcional claro.

### 7.3 Variáveis e Estado

- variável local: `l_<nome>`;
- estado privado de package: `g_<nome>`;
- cursor local nomeado: `c_<nome>_cur`, quando um cursor explícito for necessário;
- índice de loop curto pode usar `i` quando não houver ambiguidade;
- evitar estado de package em módulos de negócio; quando inevitável, documentar lifecycle, isolamento e limpeza.

### 7.4 Constantes

- constante pública ou privada: `c_<nome>`;
- o nome deve expressar significado, não apenas o valor;
- valores de domínio publicados devem vir de contrato ou catálogo aprovado.

### 7.5 Tipos, Subtypes, Records e Coleções

- type: `t_<nome>`;
- subtype: `t_<nome>`;
- record: `t_<nome>` ou `t_<nome>_record`, conforme necessário para clareza;
- coleção: `t_<nome>_list`, `t_<nome>_table` ou nome funcional equivalente;
- tipos públicos pertencem à specification somente quando integram o contrato;
- tipos privados pertencem ao body;
- usar `%TYPE` e `%ROWTYPE` somente quando o acoplamento físico for intencional e restrito à persistência; não vazá-los para contratos externos.

### 7.6 Exceções

- exceção nominal: `e_<condicao>`;
- condições esperadas devem possuir exceção ou erro catalogado estável;
- `WHEN OTHERS` deve relançar ou normalizar a falha; nunca pode silenciá-la;
- não usar código numérico Oracle como contrato de domínio.

### 7.7 Procedures e Functions

- usar verbo ou intenção explícita: `create_account`, `validate_email`, `find_by_public_id`;
- function deve retornar valor e não produzir efeito funcional oculto;
- procedure deve representar comando, alteração ou operação com múltiplas saídas;
- predicados usam forma clara como `is_valid_*`, `has_*` ou `can_*`;
- funções chamadas por SQL devem respeitar as restrições de pureza e não alterar estado;
- evitar overload quando tornar o contrato ambíguo.

---

## 8. Dependências entre Módulos

São permitidas:

- dependências descendentes previstas pela arquitetura;
- consulta ao Core necessária à responsabilidade do componente;
- coordenação entre módulos por caso de uso ou orquestrador aprovado;
- dependência de tipos públicos estáveis quando não introduzir ciclo;
- leitura por contrato público de QUERY ou camada equivalente aprovada.

São proibidas:

- dependências circulares;
- Core dependendo de módulo de negócio;
- RULE chamando API, JOB, IMPORT ou EXPORT;
- package de persistência chamando RULE ou API;
- repository ou query de um módulo acessando diretamente tabelas de outro módulo;
- ORDS chamando RULE, QUERY, Core ou tabela como endpoint de negócio;
- Flutter, integração externa ou script consumidor acessando tabela diretamente;
- dependência criada apenas para reutilizar helper privado de outro módulo.

Dependência entre módulos deve ser menor que dependência interna do próprio módulo. Se uma operação exigir coordenação lateral, ela deve subir para o orquestrador responsável pelo caso de uso.

---

## 9. Uso do Core Framework

O Core Framework é obrigatório como padrão transversal, mas nenhum package de negócio precisa usar todos os packages do Core. Cada dependência deve ser declarada somente quando a responsabilidade do componente a exigir.

### 9.1 CORE_TRACE_PKG

- a borda inicializa um único trace por execução;
- o valor deve ser opaco, não sensível e estável durante a execução;
- componentes internos podem consultá-lo quando precisarem de rastreabilidade;
- não gerar novo trace silenciosamente no meio do fluxo;
- limpar na finalização controlada.

### 9.2 CORE_CONTEXT_PKG

- deve estar inicializado antes do caso de uso que dependa de contexto;
- origem, modo, autenticação e ator devem formar estado coerente;
- consultas fora do estado ativo devem falhar explicitamente;
- não armazenar payload, JSON, LOB, record de domínio ou parâmetro funcional;
- a borda proprietária garante limpeza idempotente em todos os caminhos.

### 9.3 CORE_SECURITY_CONTEXT_PKG

- recebe identidade já autenticada; não autentica nem autoriza;
- deve ser inicializado somente depois do Execution Context;
- RULE ou caso de uso consulta o ator apenas quando necessário;
- `Authenticated` e `ActorType` não substituem verificação de permissão;
- não armazenar senha, token ou credencial;
- limpar antes do contexto geral e do trace.

### 9.4 CORE_ERROR_PKG

- erros públicos conhecidos devem usar código, categoria e mensagem externa segura;
- códigos seguem `BEX-{CONTEXTO}-{NNN}` e não são reutilizados com outro significado;
- `retryable`, severidade e política de log devem refletir o catálogo aprovado;
- detalhes técnicos permanecem internos;
- módulos de negócio não usam `RAISE_APPLICATION_ERROR` diretamente para erros públicos conhecidos;
- `RAISE_APPLICATION_ERROR` permanece legítimo em infraestrutura, instaladores e testes quando não cria contrato público de negócio.

### 9.5 CORE_JSON_PKG

- API usa as primitivas do Core para construir JSON seguro;
- tipos JSON nativos devem ser preservados;
- ausência, JSON `null` e coleção vazia possuem semânticas distintas;
- datas usam os formatadores aprovados;
- não concatenar JSON manualmente;
- RULE, QUERY de persistência e componentes de domínio não devem conhecer apresentação JSON.

### 9.6 CORE_RESPONSE_PKG

- deve ser usado pela borda API para construir envelopes com corpo;
- o contrato vigente é definido pela specification, body e testes instalados;
- `traceId` deve coincidir com o Execution Context ativo;
- payloads não devem ser alterados pelo envelope;
- não incluir metadados, políticas internas ou detalhes técnicos não previstos;
- não usar em RULE, QUERY, EVENT interno ou persistência;
- status HTTP e headers continuam responsabilidade da integração de borda, conforme contrato aprovado.

### 9.7 Ordem de Inicialização e Limpeza

Ordem padrão de inicialização:

```text
CORE_TRACE_PKG
  ↓
CORE_CONTEXT_PKG
  ↓
CORE_SECURITY_CONTEXT_PKG, quando necessário
```

Ordem padrão de limpeza:

```text
CORE_SECURITY_CONTEXT_PKG
  ↓
CORE_CONTEXT_PKG
  ↓
CORE_TRACE_PKG
```

A limpeza deve ocorrer em sucesso, erro e inicialização parcial, sem mascarar a falha original.

---

## 10. Limites Transacionais

- packages de domínio e API não executam `COMMIT` ou `ROLLBACK`;
- QUERY, EVENT handler interno, IMPORT, EXPORT e packages de persistência também não encerram transações por conta própria;
- a transação pertence ao chamador ou orquestrador que conhece a unidade completa de trabalho;
- cada caso de uso deve possuir uma decisão transacional única e explícita;
- uma exceção deve ser documentada, justificada e aprovada antes da implementação;
- `PRAGMA AUTONOMOUS_TRANSACTION` é restrito a infraestrutura técnica aprovada que precise sobreviver ao rollback e nunca pode confirmar estado funcional;
- `SAVEPOINT` não é padrão e exige decisão explícita;
- testes devem controlar sua limpeza sem introduzir `COMMIT` ou `ROLLBACK` em packages de produção.

Jobs são orquestradores internos e podem controlar a transação da própria execução, lote ou item quando essa fronteira estiver documentada. O `DBMS_SCHEDULER` apenas dispara o JOB e não contém a decisão funcional.

---

## 11. Tratamento de Erros

### 11.1 Erros Conhecidos

Para uma condição funcional prevista:

1. a camada responsável identifica a violação;
2. usa código oficial do módulo;
3. constrói erro público com `CORE_ERROR_PKG`;
4. preserva a exceção ou sinalização nominal até a borda;
5. a borda produz resposta segura com o mesmo `traceId`;
6. o chamador/orquestrador decide a transação.

A mensagem externa deve ser estável, segura e compreensível. Não deve conter SQL, nomes internos ou dados sensíveis.

### 11.2 Erros Inesperados

Falhas inesperadas devem:

- preservar diagnóstico técnico somente em mecanismo interno autorizado;
- ser convertidas na borda em erro técnico externo genérico;
- manter o `traceId` original;
- respeitar a política de log sem duplicar o mesmo erro em cada camada;
- relançar a falha quando a camada não puder tratá-la integralmente;
- nunca retornar sucesso parcial silencioso.

`WHEN OTHERS THEN NULL` e equivalentes são proibidos.

---

## 12. Segurança

São regras obrigatórias:

- nunca armazenar senha em texto puro; armazenar somente hash produzido por mecanismo aprovado;
- nunca armazenar token ou refresh token em texto puro quando houver persistência;
- nunca registrar senha, hash de senha, token, credencial, segredo ou dado sensível em trace, contexto, log ou mensagem de erro;
- nunca expor identificador interno Oracle em URL, request, response, header ou erro;
- usar exclusivamente `PUBLIC_ID` nas fronteiras externas;
- validar autorização no caso de uso ou regra responsável; autenticação não implica autorização;
- minimizar dados transportados entre camadas;
- evitar revelar existência de recurso quando o contrato de segurança exigir ocultação;
- não confiar automaticamente em metadados recebidos externamente;
- aplicar bind variables e validação positiva em qualquer SQL dinâmico autorizado.

ACCOUNT representa credenciais; PROFILE representa a pessoa. Essa separação do Data Dictionary é obrigatória e não pode ser desfeita por conveniência de implementação.

---

## 13. SQL Estático e SQL Dinâmico

SQL estático é o padrão obrigatório porque oferece contratos verificáveis, bind explícito, análise de dependência e menor superfície de injeção.

SQL deve:

- permanecer na camada de persistência ou consulta autorizada;
- listar colunas explicitamente;
- usar aliases claros em joins;
- usar bind variables para valores;
- respeitar soft delete, visibilidade e auditoria;
- selecionar somente os dados necessários;
- tratar concorrência e cardinalidade de forma explícita;
- evitar `SELECT *` em código de produção.

SQL dinâmico somente é permitido quando a estrutura da instrução realmente variar e não puder ser expressa com SQL estático razoável.

Quando autorizado, deve:

- possuir justificativa técnica documentada;
- usar bind variables para todos os valores;
- validar identificadores por allowlist;
- usar `DBMS_ASSERT` quando aplicável, sem tratá-lo como substituto da allowlist;
- não concatenar entrada externa;
- permanecer encapsulado na camada responsável;
- possuir testes de entradas válidas, inválidas e tentativas de injeção;
- nunca ser usado apenas para reduzir linhas de código.

DDL dinâmico em runtime de módulo de negócio é proibido.

---

## 14. Instaladores e Idempotência

Cada instalador individual deve:

- iniciar com `WHENEVER SQLERROR EXIT SQL.SQLCODE`;
- instalar specification antes do body;
- executar `SHOW ERRORS` para cada objeto compilado;
- validar `USER_ERRORS` e falhar explicitamente quando houver erro;
- não executar `EXIT SUCCESS` quando for script-folha;
- não executar `COMMIT` ou `ROLLBACK` sem necessidade aprovada;
- poder ser executado novamente para recompilar os mesmos objetos sem criar duplicidade funcional.

O instalador consolidado deve:

- chamar instaladores individuais em ordem topológica de dependência;
- validar presença e status em `USER_OBJECTS`;
- validar erros em `USER_ERRORS`;
- ser o único responsável por encerrar a execução do cliente quando esse comportamento for necessário;
- não ocultar falha de instalador-folha.

Seeds e dados de configuração não fazem parte automaticamente do instalador de package. Quando necessários, exigem script e estratégia de idempotência próprios, com chaves naturais ou identificadores estáveis.

---

## 15. Organização Obrigatória dos Arquivos

Para cada package de produção:

```text
database/packages/<modulo>/<package>.pks
database/packages/<modulo>/<package>.pkb
database/packages/<modulo>/install_<package>.sql
```

Para o módulo:

```text
database/packages/<modulo>/install_<modulo>.sql
```

Para testes:

```text
database/tests/<modulo>/test_<package>.sql
database/tests/<modulo>/test_<modulo>.sql
```

Regras:

- specification contém somente contrato público necessário;
- body contém implementação e tipos privados;
- instalador individual instala e valida um package;
- instalador consolidado respeita dependências;
- teste individual cobre contrato, invariantes, falhas e efeitos colaterais;
- suíte consolidada chama testes individuais em ordem compatível;
- nomes de arquivos devem acompanhar exatamente o nome do objeto em minúsculas;
- arquivos não devem misturar módulos ou responsabilidades.

---

## 16. Padrão de Testes PL/SQL

Os testes devem seguir o padrão nativo já usado pelo Core enquanto não houver decisão aprovada por outro mecanismo.

Cada suíte deve:

- usar `WHENEVER SQLERROR EXIT SQL.SQLCODE`;
- ser determinística e independente de ordem externa não documentada;
- nomear e contar casos executados;
- preparar estado antes de cada teste;
- limpar estado em sucesso e exceção;
- validar exceções nominais, não apenas `WHEN OTHERS`;
- verificar que falhas não deixam estado parcial;
- testar entradas válidas, limites, nulos e combinações inválidas relevantes;
- liberar CLOBs temporários e outros recursos explícitos;
- não depender da ordem física de atributos JSON;
- usar `DBMS_OUTPUT` apenas para resultado da suíte;
- usar `RAISE_APPLICATION_ERROR` apenas como mecanismo de assertion do script;
- não depender de framework externo inexistente no repositório.

Chamadas que possam falhar não devem permanecer em inicializações declarativas quando isso impedir a identificação correta do teste corrente. O nome do teste deve ser estabelecido antes da operação sob teste.

---

## 17. Critérios Mínimos de Revisão e Aceite

Uma mudança somente pode ser aceita quando:

- está no escopo autorizado;
- respeita a hierarquia documental e não antecipa decisão pendente;
- mantém responsabilidade única e direção de dependência;
- não expõe IDs internos ou detalhes Oracle;
- não armazena nem registra credenciais ou dados sensíveis;
- não introduz `DBMS_OUTPUT` em package de produção;
- não usa `RAISE_APPLICATION_ERROR` como contrato público conhecido;
- não introduz controle transacional em camada proibida;
- usa SQL estático ou justifica e protege SQL dinâmico;
- usa somente os componentes Core necessários;
- inicializa e limpa contexto em todos os caminhos aplicáveis;
- possui instaladores idempotentes e validação de compilação;
- possui teste individual e inclusão na suíte consolidada;
- cobre sucesso, erros conhecidos, falhas inesperadas relevantes e atomicidade;
- não deixa CLOB temporário, contexto ou estado residual;
- passa em `USER_ERRORS`, `USER_OBJECTS`, testes individuais e suíte consolidada;
- não contém alterações não relacionadas;
- documentação e código permanecem coerentes.

Revisões devem avaliar comportamento, segurança, dependências, transação, observabilidade, testabilidade e compatibilidade, não apenas compilação.

---

## 18. Responsabilidade do Codex

Ao implementar uma mudança no Brechó Express, o Codex deve:

1. ler integralmente os documentos e arquivos indicados antes de editar;
2. inspecionar o padrão real do módulo e do Core;
3. verificar o estado do worktree e preservar alterações preexistentes;
4. confirmar o escopo permitido e os arquivos proibidos;
5. explicitar conflitos, lacunas e suposições materialmente relevantes;
6. alterar somente os arquivos autorizados;
7. não inventar tabelas, packages, endpoints, frameworks, dependências ou decisões;
8. não executar alterações no banco sem autorização expressa;
9. não fazer commit sem solicitação expressa;
10. validar sintaxe, dependências, contagens, proibições e diffs;
11. executar testes proporcionais ao risco quando houver ambiente autorizado;
12. informar claramente o que foi criado, alterado, validado e não executado;
13. não declarar sucesso de execução que não tenha sido observado;
14. interromper e solicitar decisão quando uma divergência documental puder mudar a arquitetura ou o contrato.

O Codex deve preferir correções mínimas, evidência verificável e continuidade do padrão existente. Autonomia de implementação não autoriza ampliar escopo nem resolver decisões arquiteturais pendentes por inferência.

---

## 19. Checklist Operacional

Antes de concluir qualquer entrega PL/SQL:

- [ ] Escopo e arquivos autorizados conferidos.
- [ ] Documentos aplicáveis lidos na ordem de autoridade.
- [ ] Conceito existente no Data Dictionary e no domínio.
- [ ] Responsabilidade do package definida.
- [ ] Dependências necessárias, acíclicas e permitidas.
- [ ] Specification mínima e body encapsulado.
- [ ] Sem JSON ou HTTP em regra e persistência.
- [ ] Sem SQL de domínio em API ou ORDS.
- [ ] Sem ID interno em contrato externo.
- [ ] Sem senha, token, credencial ou dado sensível em logs e contexto.
- [ ] Sem `DBMS_OUTPUT` em package de produção.
- [ ] Sem `RAISE_APPLICATION_ERROR` para erro público conhecido.
- [ ] Sem `COMMIT` ou `ROLLBACK` em package proibido.
- [ ] Core utilizado somente onde necessário.
- [ ] Lifecycle inicializado e limpo corretamente.
- [ ] Instaladores individuais e consolidado atualizados.
- [ ] Teste individual e suíte consolidada atualizados.
- [ ] Recursos temporários liberados.
- [ ] Compilação, erros e testes verificados.
- [ ] Diff restrito ao objetivo.
- [ ] Nenhum commit realizado sem autorização.

---

## 20. Observações Finais

Este documento é a referência operacional permanente para desenvolvimento PL/SQL do Brechó Express. Ele deve permanecer conciso em relação aos documentos especializados: detalhes de entidades pertencem ao Data Dictionary; modelagem pertence ao padrão de entidades; arquitetura de camadas pertence à Arquitetura Física; contratos externos pertencem aos Padrões de API; e lifecycle, erros, JSON e respostas pertencem ao Core Framework e ao Execution Context.

Toda evolução deste padrão deve preservar a Constituição, as ADRs aceitas, o domínio oficial e os contratos efetivamente aprovados e implementados.
