# Padrões de API - Brechó Express

## 1. Objetivo

Este documento tem por objetivo organizar a referência oficial para construção, padronização e consumo das APIs REST do Brechó Express.

Ele servirá como guia estrutural para definição e evolução dos contratos externos da plataforma, preservando consistência entre o aplicativo Flutter, o ORDS e os packages `*_API_PKG`.

A proposta desta versão é consolidar os primeiros padrões aprovados, mantendo a evolução incremental do documento sem antecipar endpoints, regras de negócio ou decisões ainda não consolidadas.

---

## 2. Introdução

As APIs REST constituem o contrato oficial de integração entre o Brechó Express e seus consumidores externos, tendo o aplicativo Flutter como foco inicial.

O ORDS é a única porta oficial para esses consumidores. Sua responsabilidade é receber requisições, chamar `*_API_PKG` e devolver respostas padronizadas, sem executar SQL solto ou implementar regras de negócio.

Os contratos externos utilizam exclusivamente `PUBLIC_ID`, nunca expõem os identificadores internos do Oracle e adotam JSON em `camelCase`, datas em ISO-8601, valores booleanos como `true` ou `false` e enums representados por texto.

Respostas de sucesso e erro devem seguir contratos padronizados e conter `traceId`. Os erros devem respeitar o catálogo oficial da plataforma, e os contratos de API devem ser tratados como ativos governados e evolutivos.

Este documento complementa a Arquitetura Física do Brechó Express, especialmente as definições relacionadas ao ORDS, aos packages de API e à dependência entre camadas, sem reproduzir todo o conteúdo do documento `26_PHYSICAL_ARCHITECTURE.md`.

---

## 3. Índice Inicial

### 3.1 Filosofia REST
- Consolidar os princípios REST que orientarão o desenho e a evolução das APIs da plataforma.
- Preservar contratos orientados a recursos, independentes da implementação interna e consistentes entre diferentes consumidores.

### 3.2 Versionamento
- Organizar a estratégia de identificação e evolução das versões das APIs.
- Definir os critérios para mudanças compatíveis, incompatíveis e criação de novas versões principais.

### 3.3 Base URL
- Definir `/api/v1` como raiz oficial dos contratos REST externos.
- Reservar variações de host e ambiente para configuração operacional, sem alterar o contrato publicado.

### 3.4 Naming de Endpoints
- Padronizar a nomenclatura e a composição dos caminhos expostos pelo ORDS.
- Garantir clareza, previsibilidade e consistência na identificação de recursos e ações de domínio.

### 3.5 Recursos no Plural
- Definir a representação de recursos por substantivos no plural.
- Orientar a uniformidade dos caminhos sem antecipar endpoints reais do produto.

### 3.6 Padrão JSON
- Consolidar as regras gerais para payloads de requisição e resposta.
- Definir os princípios de independência entre contratos JSON e implementação interna Oracle.
- Organizar tipos, ausência de valores, coleções vazias e cuidados com valores monetários.

### 3.7 camelCase
- Estabelecer `camelCase` como padrão de nomenclatura dos atributos JSON.
- Impedir que convenções internas do Oracle sejam refletidas diretamente nos contratos externos.

### 3.8 PUBLIC_ID
- Determinar que APIs externas utilizem exclusivamente `PUBLIC_ID` para identificar recursos.
- Reforçar que IDs internos do Oracle nunca devem ser expostos aos consumidores.

### 3.9 Datas ISO-8601
- Estabelecer ISO-8601 como formato oficial para datas e horários nos contratos de API.
- Definir o uso preferencial de UTC para instantes globais e a separação entre contrato técnico e formatação visual.

### 3.10 Boolean
- Definir que valores booleanos sejam representados em JSON por `true` ou `false`.
- Evitar representações externas baseadas em números, caracteres ou convenções internas do banco.

### 3.11 Enums
- Definir que enums sejam representados por texto nos contratos externos.
- Organizar critérios de estabilidade, evolução e compatibilidade dos valores publicados.

### 3.12 Métodos HTTP
- Documentar o uso semântico dos métodos HTTP nas operações REST.
- Associar cada método à intenção do contrato sem implementar operações nesta versão.

### 3.13 Status HTTP
- Organizar o uso padronizado dos status HTTP nas respostas da plataforma.
- Alinhar os status aos contratos de sucesso, validação, segurança, ausência de recurso e falhas.

### 3.14 Contrato Padrão de Sucesso
- Estruturar o envelope oficial para respostas bem-sucedidas.
- Garantir uniformidade, previsibilidade e presença de informações de rastreabilidade.

### 3.15 Contrato Padrão de Erro
- Estruturar o envelope oficial para respostas de erro.
- Alinhar códigos, categorias, mensagens e rastreabilidade ao catálogo e ao contrato padronizado de erros.

### 3.16 Paginação
- Organizar a convenção para consultas que retornem coleções paginadas.
- Reservar espaço para parâmetros, metadados e limites que serão definidos posteriormente.

### 3.17 Filtros
- Estruturar regras uniformes para aplicação de filtros em coleções.
- Preservar previsibilidade sem expor detalhes físicos ou estruturas internas do Oracle.

### 3.18 Ordenação
- Organizar a convenção para solicitar e representar critérios de ordenação.
- Reservar o detalhamento dos campos permitidos e do comportamento padrão.

### 3.19 Endpoints de Ação
- Definir o espaço de governança para operações que representem ações além da manipulação direta de recursos.
- Orientar seu uso controlado e coerente com a filosofia REST.

### 3.20 Idempotência
- Registrar os princípios para repetição segura de requisições quando aplicável.
- Organizar futuramente os mecanismos e critérios de idempotência dos contratos.

### 3.21 TraceId
- Determinar a presença de `traceId` nas respostas da API.
- Permitir a rastreabilidade técnica das requisições ao longo das camadas da plataforma.

### 3.22 CorrelationId
- Estruturar a convenção para correlação entre requisições, integrações e fluxos relacionados.
- Definir futuramente sua relação com o `traceId` e com a observabilidade da plataforma.

### 3.23 Headers
- Organizar os headers oficiais de requisição e resposta.
- Reservar espaço para documentar autenticação, rastreabilidade, conteúdo, cache e demais metadados padronizados.

### 3.24 Autenticação
- Estruturar a forma como a identidade dos consumidores será validada nas APIs.
- Manter alinhamento com a estratégia de autenticação definida pela arquitetura da plataforma.

### 3.25 Autorização
- Organizar a aplicação das permissões sobre recursos e operações expostos.
- Preservar o alinhamento com papéis, perfis e regras de acesso do domínio.

### 3.26 Rate Limit
- Reservar a definição dos limites de consumo e do comportamento em caso de excesso de requisições.
- Apoiar a proteção e a estabilidade operacional das APIs.

### 3.27 Cache
- Estruturar as diretrizes para cache de respostas e invalidação quando aplicável.
- Manter coerência com a estratégia de cache da arquitetura física.

### 3.28 Compatibilidade Retroativa
- Definir critérios para evoluir contratos existentes sem interromper consumidores compatíveis.
- Tratar a estabilidade dos contratos como requisito de governança da plataforma.

### 3.29 Depreciação
- Organizar o ciclo de anúncio, manutenção e retirada de contratos obsoletos.
- Definir que a retirada de versões ou endpoints depreciados depende de comunicação, análise de impacto e prazo de manutenção.

### 3.30 OpenAPI
- Estabelecer o espaço para documentação formal e governança dos contratos REST.
- Tratar a especificação das APIs como ativo versionado da plataforma.

### 3.31 Convenções ORDS
- Consolidar as convenções específicas da camada oficial de exposição REST.
- Reforçar que o ORDS chama `*_API_PKG`, não executa SQL solto e não implementa regras de negócio.

### 3.32 Checklist de API
- Organizar uma lista de verificação para desenho, revisão, publicação e evolução de contratos.
- Validar aderência aos padrões de identificação, JSON, respostas, erros, segurança, rastreabilidade e governança.

---

## 4. Padrões Consolidados

Esta seção consolida os padrões já aprovados para estratégia REST e governança de contratos. Os exemplos apresentados são conceituais e não representam criação de endpoints reais do produto.

### 4.1 Filosofia REST

As APIs REST são o contrato oficial entre o Brechó Express e seus consumidores externos.

O aplicativo Flutter é o consumidor inicial, mas os contratos não devem ser acoplados ao Flutter. A arquitetura deve permitir futuros consumidores, como Flutter Web, painel administrativo web, parceiros, integrações externas e aplicações futuras.

O ORDS é a única porta oficial para consumidores externos. O fluxo externo oficial é:

Consumidor externo  
↓  
ORDS  
↓  
`*_API_PKG`  
↓  
`*_SERVICE_PKG`  
↓  
`*_RULE_PKG`  
↓  
`*_REPOSITORY_PKG`  
↓  
Oracle Database

ORDS não implementa regra de negócio, não executa SQL de domínio diretamente e não chama camadas internas de regra ou persistência. Todo endpoint ORDS deve chamar um `*_API_PKG`, preservando a separação entre contrato externo, orquestração de caso de uso, regra de negócio e persistência.

As APIs devem ser orientadas a recursos, usando substantivos para representar elementos do domínio. A estrutura física do Oracle, nomes de tabelas, prefixos técnicos, packages e identificadores internos não devem determinar o desenho dos contratos REST.

APIs externas devem utilizar exclusivamente `PUBLIC_ID`. Identificadores internos do Oracle nunca devem aparecer na URL, no request, no response, em mensagens de erro ou em headers públicos.

### 4.2 Versionamento

A versão deve existir na URL. A base oficial da primeira versão dos contratos REST é:

```text
/api/v1
```

O número da versão representa a versão principal do contrato. Enquanto não houver necessidade real, a plataforma deve manter apenas `v1`. Não deve ser criada uma `v2` de forma preventiva.

Alterações compatíveis não devem gerar nova versão principal. São exemplos de mudanças normalmente compatíveis:

- adicionar campo opcional em resposta;
- adicionar endpoint;
- adicionar filtro opcional;
- adicionar metadado opcional;
- corrigir comportamento sem alterar o contrato publicado.

Alterações incompatíveis exigem nova versão principal. São exemplos de mudanças incompatíveis:

- remover campo;
- renomear campo;
- alterar tipo;
- alterar significado de um campo;
- tornar obrigatório um campo anteriormente opcional;
- modificar estrutura de resposta de forma incompatível.

### 4.3 Base URL

A URL base oficial dos contratos REST externos é `/api/v1`.

Exemplos conceituais:

```text
GET /api/v1/products
GET /api/v1/products/{publicId}
POST /api/v1/orders
```

Variações de host, domínio, porta, ambiente ou infraestrutura não fazem parte da definição semântica do contrato e devem ser tratadas como configuração operacional.

### 4.4 Naming de Endpoints

Endpoints devem utilizar:

- letras minúsculas;
- palavras em inglês;
- kebab-case quando houver mais de uma palavra;
- substantivos para representar recursos;
- nomes compreensíveis e alinhados ao domínio.

Exemplo conceitual:

```text
/purchase-requests
```

Devem ser evitadas abreviações que prejudiquem a compreensão. Também não devem ser utilizados nomes de tabelas, prefixos físicos, siglas internas ou nomes técnicos Oracle nas URLs.

Exemplos conceituais válidos:

```text
/products
/stores
/orders
/carts
/purchase-requests
```

Exemplos que não devem ser utilizados:

```text
/getProducts
/createProduct
/updateOrder
/product
```

Ações de negócio que não forem representadas adequadamente pelos métodos HTTP podem utilizar um verbo no final do recurso, desde que expressem uma intenção explícita do domínio.

Exemplos conceituais:

```text
POST /api/v1/orders/{publicId}/cancel
POST /api/v1/purchase-requests/{publicId}/confirm
POST /api/v1/products/{publicId}/archive
```

Endpoints de ação devem ser usados apenas quando a operação representar uma intenção clara do domínio. Não devem ser criados endpoints genéricos como:

```text
/execute
/process
/action
/update-status
```

### 4.5 Recursos no Plural

Recursos devem ser representados por substantivos no plural.

Essa convenção torna os caminhos mais previsíveis, evita misturar operação com recurso e mantém consistência entre coleções e itens individuais.

Exemplos conceituais:

```text
GET /api/v1/products
GET /api/v1/products/{publicId}
GET /api/v1/stores
GET /api/v1/stores/{publicId}
```

O identificador de um item específico deve ser sempre o `PUBLIC_ID` do recurso exposto, representado conceitualmente como `{publicId}`.

### 4.6 Compatibilidade Retroativa

Contratos publicados devem preservar compatibilidade retroativa.

Campos existentes não devem ser renomeados, removidos ou reutilizados com outro significado dentro da mesma versão principal. Consumidores externos podem depender desses campos, mesmo quando o consumidor inicial for apenas o aplicativo Flutter.

A evolução de uma API deve considerar que contratos REST são ativos oficiais da plataforma. Toda API deve ser documentada, versionada, revisada e governada.

As APIs devem seguir abordagem Contract First. Antes da implementação, devem estar definidos:

- método HTTP;
- URL;
- autenticação, quando definida em documento próprio;
- autorização, quando definida em documento próprio;
- parâmetros;
- request;
- response;
- status HTTP;
- erros possíveis;
- paginação, quando aplicável;
- regras de idempotência, quando aplicável.

A implementação Oracle e Flutter deve respeitar o contrato aprovado. O contrato não deve ser criado automaticamente a partir da estrutura física das tabelas.

### 4.7 Depreciação

A depreciação de uma API deve ser explícita, documentada e comunicada.

Uma versão ou endpoint depreciado não deve ser removido imediatamente. O prazo de manutenção e retirada deve ser definido conforme impacto, consumidores ativos e estratégia operacional da plataforma.

A depreciação deve registrar, no mínimo:

- contrato afetado;
- motivo da depreciação;
- alternativa recomendada, quando existir;
- impacto esperado;
- prazo de manutenção;
- critério de retirada.

Enquanto um contrato depreciado estiver disponível, ele deve continuar respeitando seus compromissos publicados de compatibilidade, segurança, rastreabilidade e resposta padronizada.

### 4.8 Decisão Arquitetural A-007

**A-007 — Estratégia REST e Governança de Contratos**

O Brechó Express adotará APIs REST orientadas a recursos como contrato oficial de integração com consumidores externos.

O ORDS será a única porta oficial para consumidores externos e todo endpoint ORDS deverá chamar um `*_API_PKG`. O contrato REST será definido de forma independente da estrutura física do Oracle, preservando a separação entre consumidores, transporte HTTP, camada de API, services, regras de negócio, repositories e tabelas.

Os contratos externos utilizarão `/api/v1` como base URL inicial, versão principal na URL, recursos em inglês no plural, kebab-case para nomes compostos e `PUBLIC_ID` como único identificador exposto.

#### Benefícios

- Contratos externos estáveis e independentes do Flutter.
- Preparação para futuros consumidores web, administrativos, parceiros e integrações externas.
- Menor acoplamento entre APIs, estrutura física Oracle e implementação interna.
- Clareza de responsabilidade entre ORDS, `*_API_PKG`, services, regras e repositories.
- Evolução governada dos contratos, com critérios explícitos para compatibilidade, versionamento e depreciação.
- Redução do risco de exposição de IDs internos, nomes técnicos Oracle ou detalhes de persistência.

#### Trade-offs

- Exige disciplina de documentação e revisão antes da implementação.
- Pode aumentar o esforço inicial de desenho dos contratos.
- Mudanças aparentemente simples precisam ser avaliadas quanto a compatibilidade retroativa.
- A criação de endpoints de ação demanda cuidado para não transformar intenções de domínio em operações genéricas.

#### Consequências

- Toda API externa deve ser tratada como contrato oficial da plataforma.
- ORDS não deve conter regra de negócio nem SQL de domínio.
- `*_API_PKG` passa a ser a fronteira técnica entre ORDS e os casos de uso internos.
- Novos contratos devem ser definidos antes da implementação Oracle ou Flutter.
- Alterações incompatíveis exigem nova versão principal.
- A versão `v1` deve ser mantida enquanto atender às necessidades reais da plataforma.

### 4.9 Padrão JSON

JSON é o formato oficial de comunicação das APIs REST externas do Brechó Express.

Os contratos JSON devem representar conceitos do domínio e necessidades dos consumidores. Eles não devem reproduzir automaticamente:

- estrutura física das tabelas;
- nomes de colunas;
- prefixos Oracle;
- tipos internos do banco;
- estrutura interna dos packages;
- detalhes de persistência.

O contrato JSON deve permanecer independente da implementação interna. Alterações internas no Oracle não devem obrigar alteração do contrato externo quando o significado funcional permanecer o mesmo.

Os contratos devem utilizar tipos JSON nativos:

- `string`;
- `number`;
- `boolean`;
- `object`;
- `array`;
- `null`.

Números não devem ser representados como texto sem necessidade contratual. Valores monetários exigem cuidado para evitar perda de precisão, mas o padrão definitivo de representação monetária ainda não será definido nesta etapa. Essa representação deverá ser consolidada antes da implementação dos endpoints financeiros.

#### Null, Campos Ausentes e Coleções Vazias

Cada contrato deve definir claramente a diferença entre campo ausente, campo com valor `null` e coleção vazia.

Campo ausente significa que a propriedade não foi retornada naquele contrato ou contexto.

`null` significa ausência conhecida de valor para uma propriedade aplicável.

Coleções sem elementos devem ser retornadas como:

```json
[]
```

e nunca como:

```json
null
```

Objetos opcionais sem valor podem ser `null` quando isso fizer parte do contrato. Propriedades sem significado não devem ser retornadas apenas para preencher o payload. A semântica de ausência deve ser documentada por contrato.

### 4.10 camelCase

Todos os atributos JSON devem utilizar `camelCase`.

Exemplos conceituais:

```text
publicId
createdAt
updatedAt
storeId
purchaseRequestId
isActive
```

Não devem ser utilizados nomes como:

```text
PUBLIC_ID
CREATED_AT
STORE_ID
purchase_request_id
```

Prefixos físicos, siglas de coluna e abreviações técnicas internas não devem ser expostos nos contratos JSON.

### 4.11 PUBLIC_ID

APIs externas utilizam exclusivamente `PUBLIC_ID` para identificação de recursos.

No contrato JSON, o identificador público do próprio recurso deve ser representado como:

```text
publicId
```

Quando um recurso referenciar outro recurso, deve ser utilizado um nome funcional em `camelCase`.

Exemplos conceituais:

```text
storeId
productId
orderId
```

Esses atributos representam o `PUBLIC_ID` externo do recurso relacionado. Eles nunca representam o identificador numérico interno do Oracle.

IDs internos não podem ser expostos:

- em requests;
- em responses;
- em URLs;
- em headers públicos;
- em mensagens de erro.

### 4.12 Datas ISO-8601

Datas e horários devem utilizar ISO-8601.

Instantes globais devem ser retornados preferencialmente em UTC, utilizando o sufixo `Z`.

Exemplo conceitual:

```text
2026-07-13T18:30:15Z
```

Quando o offset for funcionalmente relevante, ele poderá ser informado explicitamente.

Exemplo conceitual:

```text
2026-07-13T15:30:15-03:00
```

Datas sem componente de horário devem utilizar `YYYY-MM-DD`.

Exemplo conceitual:

```text
2026-07-13
```

Não devem ser utilizados formatos locais ou ambíguos, como:

```text
13/07/2026
07/13/2026
```

Datas formatadas para exibição não pertencem ao contrato técnico. A formatação visual é responsabilidade do consumidor.

### 4.13 Boolean

Valores booleanos devem ser representados exclusivamente pelos tipos JSON:

```json
true
false
```

Não devem ser utilizadas representações como:

```text
"S"
"N"
"Y"
"1"
"0"
1
0
```

O modo de armazenamento interno no Oracle não deve aparecer no contrato externo.

### 4.14 Enums

Enums devem ser representados por valores textuais estáveis e semanticamente claros.

Exemplos conceituais:

```text
"ACTIVE"
"PENDING"
"APPROVED"
"CANCELLED"
```

Não devem ser utilizados códigos numéricos sem significado explícito, códigos físicos ou abreviações internas do Oracle.

Valores de enum fazem parte do contrato público. Um valor publicado não deve ser renomeado ou reutilizado com outro significado dentro da mesma versão principal.

Novos valores de enum devem ser avaliados quanto à compatibilidade dos consumidores. Consumidores devem ser preparados para tratar valores futuros desconhecidos de forma segura.

### 4.15 Contrato Padrão de Sucesso

Toda resposta de sucesso com conteúdo deve utilizar envelope padronizado.

Estrutura conceitual:

```json
{
  "success": true,
  "data": {},
  "meta": {
    "traceId": "..."
  }
}
```

Para coleções:

```json
{
  "success": true,
  "data": [],
  "meta": {
    "traceId": "..."
  }
}
```

O atributo `success` deve ser boolean. `data` representa o resultado funcional da operação. `meta` contém metadados técnicos ou de navegação que não pertencem ao domínio.

`traceId` deve estar presente em `meta`.

Metadados específicos, como paginação, poderão ser adicionados ao contrato quando aplicáveis. O padrão definitivo de paginação ainda não será definido nesta etapa.

Para operações HTTP que não retornem conteúdo, o uso semântico de HTTP 204 deverá ser avaliado quando as seções de métodos e status HTTP forem consolidadas. Respostas HTTP 204 não devem ser obrigadas a retornar envelope JSON.

### 4.16 Contrato Padrão de Erro

Toda resposta de erro deve utilizar envelope padronizado.

Estrutura conceitual:

```json
{
  "success": false,
  "error": {
    "code": "BEX-ORD-001",
    "category": "BUSINESS_ERROR",
    "message": "Não foi possível concluir o pedido.",
    "retryable": false
  },
  "meta": {
    "traceId": "..."
  }
}
```

`success` deve ser `false`.

`error.code` é o código estável do catálogo oficial de erros. `error.category` identifica a categoria padronizada. `error.message` é uma mensagem segura e compreensível para o consumidor. `error.retryable` informa se uma nova tentativa poderá ser realizada. `meta.traceId` permite localizar a execução nos mecanismos de observabilidade.

Nunca devem ser retornados ao consumidor:

- SQL;
- `SQLERRM` bruto;
- stack trace;
- backtrace;
- nome interno de package;
- nome de procedure;
- nome de tabela;
- nome de coluna;
- identificador interno;
- detalhes de infraestrutura;
- informações sensíveis.

Mensagens técnicas completas devem permanecer nos logs internos. A mensagem externa e a mensagem técnica podem ser diferentes.

Erros de validação poderão futuramente possuir uma coleção de detalhes por campo. A estrutura definitiva dessa coleção ainda não será definida nesta etapa.

### 4.17 TraceId

Toda requisição processada deve possuir um `traceId`.

O `traceId` deve:

- identificar tecnicamente uma execução;
- acompanhar a requisição pelas camadas;
- ser incluído nas respostas de sucesso;
- ser incluído nas respostas de erro;
- permitir correlação com `ERROR_LOG`;
- permitir correlação com `INTEGRATION_LOG`;
- permitir correlação com auditoria e observabilidade quando aplicável.

O `traceId` não deve conter informação de negócio, dado pessoal ou informação sensível.

O `traceId` deve ser tratado como identificador técnico opaco. O consumidor pode informar o `traceId` ao suporte, mas não deve interpretar sua estrutura.

Nesta etapa, não serão definidos algoritmo definitivo de geração, tamanho definitivo, formato definitivo ou relação definitiva entre `traceId` e `correlationId`. Esses detalhes serão consolidados na seção de rastreabilidade e observabilidade.

### 4.18 Compatibilidade dos Contratos JSON

Adicionar campos opcionais em objetos de resposta é considerado normalmente compatível.

Consumidores devem ignorar propriedades JSON desconhecidas.

A ordem dos atributos JSON não faz parte do contrato. Consumidores não devem depender da ordem das propriedades.

Remover, renomear ou alterar o tipo de um campo continua sendo mudança incompatível. Alterar o significado funcional de um campo também é mudança incompatível.

### 4.19 Benefícios e Trade-offs dos Contratos JSON

Os padrões de contrato JSON trazem os seguintes benefícios:

- contratos previsíveis;
- menor acoplamento com Oracle;
- consumo simplificado no Flutter;
- melhor rastreabilidade;
- tratamento uniforme de erros;
- evolução mais segura;
- preparação para consumidores futuros.

Também introduzem os seguintes trade-offs:

- necessidade de mapeamento entre Oracle e JSON;
- disciplina na evolução dos contratos;
- manutenção dos envelopes padronizados;
- necessidade de documentação dos campos e enums;
- maior cuidado com compatibilidade.

---

## 5. Observações

Este documento possui caráter evolutivo e deverá ser preenchido progressivamente conforme novos padrões de API forem detalhados e aprovados.

Ele não define endpoints reais, payloads definitivos, regras de negócio ou implementação técnica. Toda evolução deverá preservar coerência com a Arquitetura Física e com os demais documentos oficiais do Brechó Express.

Contratos de API são ativos da plataforma e devem permanecer padronizados, documentados, versionados e governados durante todo o seu ciclo de vida.
