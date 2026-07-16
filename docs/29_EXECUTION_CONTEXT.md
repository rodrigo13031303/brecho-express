# Execution Context - Brechó Express

## 1. Objetivo

Este documento define o conceito arquitetural de Execution Context do Core Framework Oracle do Brechó Express.

Execution Context representa exclusivamente uma execução da plataforma, desde sua abertura controlada até sua limpeza e descarte. Ele reúne somente os metadados técnicos mínimos necessários para identificar, rastrear e interpretar essa execução ao longo das camadas.

Execution Context não representa:

- usuário;
- sessão de aplicação;
- sessão Oracle;
- request HTTP;
- conexão;
- transação Oracle;
- caso de uso de negócio;
- entidade de domínio.

Uma execução pode ter origem em uma requisição externa, em uma interação interna do APEX, em um job ou em outra entrada futura. A origem dispara a execução, mas não se confunde com o contexto que a acompanha.

Este documento é conceitual. Ele não define interfaces, estruturas físicas ou detalhes de implementação.

---

## 2. Motivação

As mesmas capacidades da plataforma podem ser acionadas por origens diferentes, como ORDS, APEX, Jobs e Scheduler. Sem um conceito comum de execução, cada origem tenderia a transportar metadados de maneira própria, causando duplicação, inconsistência e acoplamento entre as camadas.

O Execution Context resolve os seguintes problemas:

- estabelece uma identidade técnica única para a execução;
- permite propagar rastreabilidade sem misturá-la aos objetos de domínio;
- registra quando a execução começou;
- identifica a origem e o modo da execução;
- disponibiliza identidade autenticada mínima quando aplicável;
- evita que services, rules e repositories conheçam ORDS, APEX ou Scheduler;
- reduz parâmetros técnicos repetidos entre chamadas internas;
- estabelece regras uniformes de inicialização e limpeza;
- previne vazamento de estado entre execuções em sessões reutilizadas;
- cria uma base coerente para erros, respostas, logs e observabilidade.

O contexto existe para tornar a execução tecnicamente compreensível. Ele não deve se transformar em depósito de dados ou mecanismo genérico de comunicação entre componentes.

---

## 3. Core Philosophy

O Execution Context é uma capacidade transversal do Core Framework.

Ele:

- não pertence ao domínio;
- não pertence ao ORDS;
- não pertence ao APEX;
- não pertence ao Flutter;
- não pertence ao Scheduler;
- não pertence a um módulo de negócio;
- pertence apenas à execução corrente.

ORDS, APEX, Jobs e futuras integrações são origens ou bordas de execução. Elas podem participar da criação e da inicialização do contexto, mas não se tornam proprietárias do conceito.

O contexto deve proteger as camadas internas dos detalhes da origem. Uma rule não deve precisar saber se foi acionada por uma requisição externa, por uma tela administrativa ou por um processo agendado, exceto quando um metadado técnico explicitamente aprovado for necessário.

O Execution Context é efêmero, mínimo e não funcional. Ele acompanha a execução, mas não decide seu comportamento de negócio.

---

## 4. Ciclo de Vida

O ciclo de vida conceitual é:

```text
Criação
  ↓
Inicialização
  ↓
Uso
  ↓
Limpeza
  ↓
Destruição
```

### 4.1 Criação

A borda responsável abre uma nova unidade de execução. Nesse momento ainda não deve existir contexto reutilizado de uma execução anterior.

A criação estabelece a intenção de iniciar uma execução independente. Ela não confirma que todos os atributos obrigatórios já estão disponíveis.

### 4.2 Inicialização

A inicialização estabelece os atributos obrigatórios e, quando aplicável, os atributos condicionais. Antes de aceitar o novo contexto, qualquer estado residual deve ser removido defensivamente.

Somente após a inicialização completa o contexto pode ser considerado ativo e consultado pelas camadas autorizadas.

### 4.3 Uso

Durante o uso, o contexto acompanha a execução através das camadas. Seus dados devem ser predominantemente consultivos e estáveis.

O uso não autoriza inclusão arbitrária de atributos, alteração de identidade, troca de `traceId` ou reutilização do contexto para uma segunda execução.

### 4.4 Limpeza

A limpeza remove integralmente os dados associados à execução. Ela é obrigatória em sucesso, erro, cancelamento ou inicialização parcial.

A limpeza não deve depender do resultado funcional, da decisão transacional ou da produção de uma resposta. Também não deve ocultar a falha original da execução.

### 4.5 Destruição

Após a limpeza, a unidade conceitual é descartada e não pode voltar ao estado ativo. Uma nova atividade exige um novo ciclo de vida.

A destruição reforça que o contexto não é sessão, cache ou armazenamento durável.

---

## 5. Ownership

O ownership pertence à borda que controla a execução, nunca às camadas internas de domínio ou persistência.

### 5.1 Quem cria

O componente de borda responsável pela execução cria o contexto:

- a borda de API para chamadas originadas via ORDS;
- o consumidor interno responsável para execuções APEX;
- o componente executor do job para processos internos;
- o adaptador de entrada aprovado para integrações futuras.

### 5.2 Quem inicializa

A mesma borda executora coordena a inicialização a partir de metadados confiáveis. Dados provenientes de entradas externas não devem ser aceitos como confiáveis sem validação prévia da camada responsável.

### 5.3 Quem pode consultar

Componentes internos podem consultar apenas os atributos necessários à própria responsabilidade. A possibilidade de consulta não significa que todos os componentes devam receber ou conhecer o contexto completo.

### 5.4 Quem pode alterar

Alterações são permitidas apenas durante a inicialização controlada ou em transições técnicas explicitamente aprovadas. Depois de ativo, o contexto deve ser imutável sempre que possível.

Identidade, origem, modo, início e rastreabilidade não devem ser sobrescritos silenciosamente durante o uso.

### 5.5 Quem limpa

A borda que criou a execução é responsável por garantir a limpeza em um fluxo de finalização que ocorra tanto em sucesso quanto em falha.

### 5.6 Quem nunca deve modificar

Não devem modificar o contexto:

- Flutter;
- ORDS como camada de transporte;
- Scheduler como mecanismo de agendamento;
- services de negócio;
- rules de domínio;
- repositories;
- tabelas;
- integrações externas;
- mecanismos de resposta;
- mecanismos de logging.

Esses componentes podem fornecer dados confiáveis à borda ou consumir atributos autorizados, mas não assumem o ownership da execução.

---

## 6. Estrutura Conceitual

A estrutura conceitual separa atributos obrigatórios, condicionais e opcionais futuros. Esta classificação não define tipos, tamanhos, interfaces ou armazenamento.

### 6.1 Atributos Obrigatórios

#### TraceId

Identificador técnico opaco e único da execução. Deve acompanhar as camadas e permitir correlação com erros, respostas, logs e observabilidade.

#### StartedAt

Instante técnico em que a execução foi iniciada. Não representa data de negócio, data de criação de entidade ou início de transação Oracle.

#### ExecutionOrigin

Identifica de onde a execução foi disparada em termos arquiteturais, como borda externa, APEX ou processamento interno. O vocabulário definitivo permanece pendente.

#### ExecutionMode

Descreve a natureza operacional da execução, permitindo distinguir cenários como interação síncrona, processamento interno ou execução em lote sem acoplar o domínio à tecnologia de origem. O vocabulário definitivo permanece pendente.

### 6.2 Atributos Condicionais

#### ActorPublicId

Identificador público do ator já autenticado, quando a execução possuir um ator aplicável. Nunca representa o ID interno Oracle e não substitui o contexto de segurança.

#### Authenticated

Indica se existe identidade autenticada confiável associada à execução. Sua presença e coerência devem ser avaliadas em conjunto com `ActorPublicId` e com a natureza da execução.

Execuções anônimas ou técnicas podem não possuir ator público. A ausência de ator não deve ser interpretada automaticamente como falha.

### 6.3 Atributos Opcionais Futuros

Os seguintes atributos são candidatos futuros e não estão aprovados para implementação nesta etapa:

- Locale;
- TimeZone;
- ClientVersion;
- Device;
- CorrelationId;
- Custom Attributes.

Cada atributo futuro somente poderá ser incorporado com finalidade clara, fonte confiável, regra de validação e consumidores conhecidos.

`Custom Attributes` não significa um mapa irrestrito de chave e valor. Caso essa capacidade seja aprovada, deverá possuir vocabulário governado, limites explícitos e atributos previamente autorizados.

---

## 7. Dados Proibidos

O Execution Context nunca deve armazenar:

- senha;
- token de acesso;
- JWT;
- refresh token;
- credenciais;
- segredo;
- dados pessoais desnecessários;
- perfil completo de usuário;
- objetos ou entidades de domínio;
- estado funcional de negócio;
- records Oracle;
- cursores;
- LOBs;
- JSON;
- SQL;
- resultados de consulta;
- objetos APEX;
- objetos ORDS;
- conexões;
- sessão Oracle;
- resposta HTTP;
- stack trace;
- backtrace;
- `SQLERRM`;
- estruturas arbitrárias definidas pelo consumidor.

Referências técnicas mínimas e aprovadas devem ser preferidas a objetos completos. O contexto não é mecanismo de cache, payload, sessão, logging ou passagem genérica de parâmetros.

---

## 8. Regras

As regras arquiteturais obrigatórias são:

1. Deve existir no máximo um contexto ativo por execução.
2. Um contexto não pode ser reutilizado em outra execução.
3. Toda execução deve inicializar seu próprio contexto.
4. A inicialização deve remover defensivamente qualquer estado residual.
5. Todos os atributos obrigatórios devem estar válidos antes do estado ativo.
6. A limpeza deve ocorrer em sucesso e em falha.
7. A limpeza deve remover integralmente os dados da execução.
8. O contexto não pode sobreviver entre execuções.
9. O contexto não pode alterar estado funcional do domínio.
10. O contexto não controla transações.
11. O contexto não autentica nem autoriza.
12. O contexto não gera respostas nem executa logging.
13. O contexto não substitui parâmetros funcionais explícitos.
14. O contexto não pode depender de tabelas ou packages de domínio.
15. A ausência de inicialização deve causar falha explícita, nunca criação silenciosa durante uma consulta.
16. Reentrada, aninhamento e paralelismo não devem compartilhar estado sem uma decisão arquitetural específica.

---

## 9. Estados

O ciclo de estados conceitual é:

```text
Não inicializado
  ↓
Ativo
  ↓
Limpo
  ↓
Descartado
```

### 9.1 Não inicializado

A unidade de execução existe, mas os atributos obrigatórios ainda não foram estabelecidos. Nenhum consumidor deve obter dados como se o contexto estivesse pronto.

Uma tentativa de uso neste estado deve falhar de forma explícita.

### 9.2 Ativo

Todos os atributos obrigatórios estão válidos e o contexto pode ser consultado durante a execução. Alterações devem ser restritas e controladas.

Somente um contexto pode estar ativo para a execução corrente.

### 9.3 Limpo

Os dados da execução foram removidos. O estado limpo deve ser seguro mesmo quando alcançado após falha ou inicialização parcial.

Um contexto limpo não pode responder como ativo nem fornecer dados residuais.

### 9.4 Descartado

O ciclo de vida terminou. A unidade não pode ser reativada ou reutilizada. Uma nova execução começa com um novo contexto não inicializado.

Os estados são conceituais. A forma de representá-los futuramente permanece pendente.

---

## 10. Integração

### 10.1 ORDS

ORDS recebe a requisição externa e encaminha dados de transporte para a borda de API. A borda cria e inicializa o Execution Context antes do caso de uso e garante sua limpeza ao final.

ORDS não é proprietário do contexto, não o persiste e não o utiliza como substituto do contrato REST.

### 10.2 APEX

Uma execução iniciada por APEX deve possuir contexto próprio. O consumidor interno responsável cria, inicializa e limpa o contexto, inclusive quando chama um service diretamente.

Objetos, sessão e estado de tela do APEX não devem ser armazenados no contexto.

### 10.3 Jobs

Cada execução de job deve possuir contexto independente, com rastreabilidade e origem técnica próprias. O componente executor do job controla o ciclo de vida do contexto.

Lotes e itens internos não devem criar ou compartilhar contextos adicionais sem decisão explícita sobre granularidade.

### 10.4 Scheduler

Scheduler apenas agenda e dispara o componente responsável. Ele não cria, inicializa ou altera diretamente o Execution Context.

O ownership começa no executor acionado pelo Scheduler.

### 10.5 Integrações Futuras

Webhooks, filas, eventos e outros adaptadores futuros devem abrir uma execução independente e estabelecer contexto próprio antes de chamar casos de uso internos.

Metadados recebidos de outros sistemas não devem ser tratados como confiáveis automaticamente. A propagação de rastreabilidade externa e a relação com `CorrelationId` dependem de decisão futura.

---

## 11. Diagramas

### 11.1 Execução Originada por Request

```text
Request
  ↓
Execution Context
  ↓
Service
  ↓
Rule
  ↓
Repository
  ↓
Response
  ↓
Limpeza e Descarte do Execution Context
```

O request origina a execução, mas não é armazenado nem representado pelo contexto.

### 11.2 Execução Originada por Job

```text
Job
  ↓
Execution Context
  ↓
Service
  ↓
Rule
  ↓
Repository
  ↓
Resultado Técnico
  ↓
Limpeza e Descarte do Execution Context
```

O mesmo conceito acompanha origens externas e internas sem alterar as responsabilidades das camadas.

### 11.3 Fronteiras Conceituais

```text
Origem da Execução
        ↓
┌──────────────────────────────┐
│ Execution Context            │
│                              │
│ Rastreabilidade              │
│ Tempo de início              │
│ Origem e modo                │
│ Identidade mínima aplicável  │
└──────────────────────────────┘
        ↓
Camadas da Plataforma
```

O contexto transporta metadados técnicos mínimos. Payloads, objetos de domínio e detalhes da tecnologia de origem permanecem fora dessa fronteira.

---

## 12. Princípios

### 12.1 Imutabilidade quando possível

Depois de ativo, o contexto deve permanecer estável. Mudanças silenciosas comprometem rastreabilidade e previsibilidade.

### 12.2 Fail Fast

Ausência de inicialização, atributos obrigatórios inválidos ou transição de estado proibida devem ser detectados antes do caso de uso prosseguir.

### 12.3 Mínimo necessário

Somente dados necessários a responsabilidades transversais aprovadas devem fazer parte do contexto.

### 12.4 Não compartilhar estado

Execuções distintas não compartilham contexto. Reutilização de conexão ou sessão técnica não autoriza reutilização de estado.

### 12.5 Baixo acoplamento

O conceito deve permanecer independente de ORDS, APEX, Flutter, Scheduler, módulos de negócio e mecanismos de persistência.

### 12.6 Alta coesão

Todos os atributos devem descrever a execução corrente. Informações que não respondam a essa finalidade pertencem a outro componente.

### 12.7 Fonte confiável

Cada atributo deve possuir origem conhecida. Dados externos precisam ser validados antes de integrar o contexto.

### 12.8 Encapsulamento

Consumidores devem acessar apenas o necessário. O contexto completo não deve circular indiscriminadamente pelas camadas.

### 12.9 Limpeza garantida

A finalização do contexto é parte obrigatória do lifecycle, não uma otimização opcional.

---

## 13. Anti-patterns

São anti-patterns proibidos:

- guardar SQL no contexto;
- guardar JSON ou payload completo;
- guardar objetos ou entidades de domínio;
- guardar sessão Oracle;
- guardar usuário ou perfil completo;
- guardar tokens, credenciais ou dados pessoais;
- guardar objetos APEX ou ORDS;
- guardar resultados de consultas;
- guardar cursores ou LOBs;
- guardar estado transacional;
- usar o contexto como cache;
- usar o contexto como service locator;
- usar o contexto para passar parâmetros de negócio ocultos;
- permitir atributos arbitrários sem governança;
- oferecer operação genérica equivalente a `set_value(name, value)`;
- oferecer acesso genérico equivalente a `get_context()` retornando tudo;
- inicializar o contexto durante uma consulta;
- gerar novo `traceId` silenciosamente quando o contexto deveria estar ativo;
- reutilizar o contexto anterior por conveniência;
- permitir que rules ou repositories alterem o contexto;
- associar o contexto ao tempo de vida da sessão Oracle;
- confundir `ExecutionOrigin` com autorização;
- usar `Authenticated` como prova suficiente de permissão.

Esses padrões criam dependência oculta, reduzem testabilidade e transformam uma capacidade coesa em armazenamento global genérico.

---

## 14. Relação com CORE_CONTEXT_PKG

Execution Context é o conceito arquitetural descrito neste documento.

`CORE_CONTEXT_PKG` será apenas uma implementação futura desse conceito no ambiente Oracle. O package deverá respeitar o modelo, o lifecycle, o ownership, os estados, as restrições e os dados proibidos definidos aqui.

O conceito não depende da existência do package. Uma futura mudança de mecanismo técnico não deve alterar o significado arquitetural do Execution Context.

Este documento não define a interface pública, a estrutura interna, o armazenamento ou as operações de `CORE_CONTEXT_PKG`. Essas decisões exigem etapa própria de desenho e aprovação.

---

## 15. Relação com Outros Componentes

### 15.1 CORE_TRACE_PKG

`CORE_TRACE_PKG` é a fonte técnica da rastreabilidade. O Execution Context exige um `TraceId` válido e o associa à execução corrente, sem gerar uma segunda identidade de rastreamento.

O lifecycle do trace deve permanecer coerente com o lifecycle do contexto. A ordem exata de coordenação será definida futuramente.

### 15.2 CORE_ERROR_PKG

`CORE_ERROR_PKG` utiliza o `TraceId` disponível para associar erros seguros à execução. O Execution Context não armazena catálogo, mensagem de erro, política de logging ou diagnóstico técnico.

Uma falha do contexto pode ser representada pelo mecanismo central de erros, mas o contexto não se transforma em tratador de exceções.

### 15.3 CORE_SECURITY_CONTEXT_PKG

`CORE_SECURITY_CONTEXT_PKG` será responsável pela identidade já autenticada e pelo contexto mínimo de segurança. Execution Context referencia apenas os indicadores condicionais necessários à execução, sem implementar login, token, sessão ou autorização.

A divisão definitiva de ownership de `ActorPublicId` e `Authenticated` entre os dois conceitos permanece pendente. Não deve haver duplicação divergente de identidade.

### 15.4 CORE_RESPONSE_PKG

`CORE_RESPONSE_PKG` poderá consumir metadados seguros da execução, especialmente `TraceId`, para construir respostas padronizadas na borda.

Execution Context não conhece HTTP, não gera JSON e não monta respostas. A produção da resposta não encerra, por si só, a obrigação de limpar o contexto.

### 15.5 Direção das Relações

```text
CORE_TRACE_PKG
      ↓
Execution Context
      ├── fornece rastreabilidade a CORE_ERROR_PKG
      ├── coordena identidade mínima com CORE_SECURITY_CONTEXT_PKG
      └── fornece metadados seguros a CORE_RESPONSE_PKG
```

O diagrama representa colaboração conceitual. Ele não aprova dependências físicas ou interfaces.

---

## 16. Decisões Pendentes

Permanecem pendentes:

1. mecanismo técnico de armazenamento do contexto por execução;
2. representação futura dos estados do lifecycle;
3. interface pública de `CORE_CONTEXT_PKG`;
4. tipos, tamanhos e formatos dos atributos;
5. fonte e precisão de `StartedAt`;
6. vocabulário oficial de `ExecutionOrigin`;
7. vocabulário oficial de `ExecutionMode`;
8. combinações válidas entre origem e modo;
9. ownership definitivo de `ActorPublicId` e `Authenticated`;
10. representação de execuções anônimas, técnicas e autenticadas;
11. comportamento diante de inicialização repetida;
12. comportamento diante de limpeza repetida;
13. tratamento de inicialização parcial;
14. comportamento de consulta fora do estado ativo;
15. estratégia para sessões Oracle reutilizadas;
16. estratégia para execuções aninhadas ou reentrantes;
17. isolamento em processamento paralelo;
18. granularidade do contexto para job, lote e item;
19. política para `Locale`, `TimeZone`, `ClientVersion` e `Device`;
20. adoção e semântica de `CorrelationId`;
21. governança de eventuais `Custom Attributes`;
22. propagação de metadados para integrações externas;
23. política de confiança para metadados recebidos;
24. relação entre encerramento da resposta, decisão transacional e limpeza;
25. estratégia de testes arquiteturais e de isolamento;
26. mecanismo de detecção de vazamento entre execuções;
27. dependências físicas permitidas para a implementação futura.

Nenhuma decisão desta lista deve ser inferida a partir dos exemplos conceituais deste documento.

---

## 17. Checklist Arquitetural

Antes de aprovar o modelo ou sua futura implementação, verificar:

- [ ] O contexto representa uma execução, não usuário, sessão, request ou transação.
- [ ] Existe no máximo um contexto ativo por execução.
- [ ] A inicialização é obrigatória e ocorre antes do uso.
- [ ] Estado residual é removido antes de nova inicialização.
- [ ] Todos os atributos obrigatórios estão válidos no estado ativo.
- [ ] A limpeza ocorre em sucesso, erro e inicialização parcial.
- [ ] O contexto não sobrevive entre execuções.
- [ ] O contexto limpo não pode ser reutilizado.
- [ ] O ownership pertence à borda executora.
- [ ] Services, rules e repositories não alteram o contexto.
- [ ] Scheduler apenas dispara o executor responsável.
- [ ] O contexto permanece independente de ORDS, APEX e Flutter.
- [ ] Não existem dados pessoais, credenciais ou tokens no contexto.
- [ ] Não existem SQL, JSON, LOBs, cursores ou records Oracle no contexto.
- [ ] Não existem objetos de domínio, APEX ou ORDS no contexto.
- [ ] O contexto não é usado como cache, sessão ou service locator.
- [ ] Não existe mecanismo genérico de chave e valor.
- [ ] Não existe acesso irrestrito ao contexto completo.
- [ ] `TraceId` permanece único, opaco e não sensível.
- [ ] `ActorPublicId` nunca representa ID interno Oracle.
- [ ] `Authenticated` não é usado como autorização.
- [ ] A imutabilidade é preservada sempre que possível.
- [ ] Falhas de lifecycle são detectadas de forma explícita.
- [ ] O contexto não controla transações.
- [ ] O contexto não gera respostas, JSON ou logs.
- [ ] Não existem dependências de tabelas ou packages de domínio.
- [ ] A relação com os demais componentes do Core permanece acíclica.
- [ ] Decisões não aprovadas continuam marcadas como pendentes.
- [ ] Nenhum detalhe de implementação foi antecipado pelo contrato conceitual.

---

## 18. Observações

Execution Context deve permanecer uma abstração pequena e rigorosa. Seu propósito é dar identidade técnica e coerência à execução, não concentrar dados ou responsabilidades transversais indiscriminadas.

Toda futura implementação deverá preservar a separação entre execução, identidade, segurança, transporte, resposta, persistência e domínio. `CORE_CONTEXT_PKG` somente será válido se materializar esse conceito sem ampliá-lo silenciosamente.
