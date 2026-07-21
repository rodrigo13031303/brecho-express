# Guia de Implementação da Sprint 9 - Módulo ACCOUNT

## 1. Informações Gerais

| Item | Definição |
|---|---|
| Sprint | Sprint 9 |
| Status | Planejada - contrato oficial de implementação |
| Dependência | Sprint 8 concluída e Core Framework validado |
| Módulo | ACCOUNT |
| Ambiente de validação | Oracle AI Database |
| Responsáveis | Codex pela implementação autorizada; responsável humano pelo review técnico e arquitetural; responsável pelo ambiente pela execução e validação no Oracle |

Este documento é o contrato oficial da Sprint 9. Ele orienta a implementação pelo Codex e a revisão humana sem substituir os documentos permanentes do projeto.

---

## 2. Objetivo

Implementar a infraestrutura Oracle completa da primeira versão do módulo ACCOUNT, compreendendo `BEX_ACCOUNT`, `ACC_RULE_PKG`, `ACC_PASSWORD_PKG`, `ACC_REPOSITORY_PKG`, `ACC_SERVICE_PKG`, `ACC_API_PKG`, seus instaladores e testes individuais e a consolidação do módulo.

A implementação deve materializar somente contratos aprovados, preservar a separação entre credenciais e identidade pessoal e utilizar o Core Framework apenas nas responsabilidades em que ele seja necessário.

---

## 3. Contexto

A Sprint 8 foi encerrada com o Core Framework concluído e sua suíte consolidada aprovada. O baseline informado para o início desta Sprint é de 274 testes aprovados.

A Sprint 9 inicia os módulos de negócio pelo contexto de identidade técnica. ACCOUNT representa credenciais e estado de acesso; PROFILE representa a identidade da pessoa e permanece reservado para outra Sprint.

As regras de domínio foram formalizadas em `ADR-015_ACCOUNT_DOMAIN_RULES.md`. As decisões físicas, de concorrência, geração de public ID e fronteiras de persistência foram formalizadas em `ADR-016_ACCOUNT_PERSISTENCE.md` antes do DDL e das packages dependentes.

`ACC_PASSWORD_PKG` pertence ao módulo ACCOUNT nesta Sprint. Sua eventual extração futura para o Core dependerá de reutilização comprovada, ADR e evolução arquitetural próprios.

---

## 4. Escopo

A Sprint 9 implementará exclusivamente:

- DDL de `BEX_ACCOUNT`, suas constraints e índices diretamente necessários;
- `ACC_RULE_PKG`;
- `ACC_PASSWORD_PKG`, limitada à geração e verificação segura de hash de senha;
- `ACC_REPOSITORY_PKG`;
- `ACC_SERVICE_PKG`;
- `ACC_API_PKG`;
- instaladores individuais das packages;
- instalador consolidado do módulo;
- teste individual da tabela e testes individuais das packages;
- suíte consolidada de ACCOUNT;
- validação completa dos objetos e testes no Oracle AI Database.

Qualquer comportamento deve estar respaldado pelos documentos da seção 6 e permanecer nos arquivos autorizados na seção 9.

---

## 5. Fora do Escopo

Não fazem parte da Sprint 9:

- PROFILE;
- login ou autenticação completa;
- sessão;
- JWT e Refresh Token;
- MFA;
- Social Login;
- OAuth;
- Flutter;
- ORDS;
- confirmação de e-mail;
- recuperação de senha;
- integrações externas.

`ACC_PASSWORD_PKG` não representa login, sessão ou autorização. Os itens fora do escopo não devem ser parcialmente implementados, simulados ou antecipados.

---

## 6. Dependências Documentais

Durante a implementação devem ser consultados, conforme a responsabilidade do artefato:

- `docs/00_CONSTITUICAO.md`;
- `docs/09_DECISIONS.md`;
- `docs/11_AI_CONTEXT.md`;
- `docs/20_DATA_DICTIONARY.md`;
- `docs/21_DATABASE_CONVENTIONS.md`;
- `docs/22_ENTITY_MODELING_STANDARD.md`;
- `docs/23_DOMAIN_MODEL.md`;
- `docs/24_SYSTEM_ARCHITECTURE.md`;
- `docs/26_PHYSICAL_ARCHITECTURE.md`;
- `docs/27_API_STANDARDS.md`;
- `docs/28_CORE_FRAMEWORK.md`;
- `docs/29_EXECUTION_CONTEXT.md`;
- `docs/30_DEVELOPMENT_STANDARD.md`;
- `docs/ADR-015_ACCOUNT_DOMAIN_RULES.md`;
- `docs/ADR-016_ACCOUNT_PERSISTENCE.md`;
- este guia de implementação.

As fontes devem ser consultadas segundo a hierarquia documental vigente. Este guia não replica seus contratos detalhados nem altera a autoridade dos documentos permanentes e das ADRs aceitas.

---

## 7. Arquitetura da Sprint

ACCOUNT representa identidade técnica, credenciais e estado de acesso. PROFILE representa identidade da pessoa. Essa separação é obrigatória.

```text
ACC_API_PKG
    ↓
ACC_SERVICE_PKG
    ├── ACC_RULE_PKG
    ├── ACC_PASSWORD_PKG
    └── ACC_REPOSITORY_PKG
            ↓
        BEX_ACCOUNT
```

### 7.1 BEX_ACCOUNT

Materializa fisicamente ACCOUNT, armazena seu estado e protege constraints e integridade física. Não contém regras procedurais de domínio.

### 7.2 ACC_RULE_PKG

Executa regras puras, validações, normalizações e decisões de domínio. Não executa SQL e não conhece Core, JSON ou HTTP.

### 7.3 ACC_PASSWORD_PKG

Gera hashes seguros e verifica uma senha contra um hash armazenado. Não acessa `BEX_ACCOUNT`, não executa SQL, não representa autenticação completa e nunca registra senha ou hash em trace ou logs.

### 7.4 ACC_REPOSITORY_PKG

Contém exclusivamente SQL de ACCOUNT e recebe valores já preparados. Não gera `ACC_PUBLIC_ID`, não normaliza e-mail, não valida senha ou transições, não gera hash, não monta respostas públicas e não utiliza `CORE_RESPONSE_PKG`. Não executa `COMMIT` ou `ROLLBACK`.

### 7.5 ACC_SERVICE_PKG

Coordena os casos de uso utilizando RULE, PASSWORD e REPOSITORY. Normaliza e valida dados, gera `ACC_PUBLIC_ID`, produz o hash antes da persistência, interpreta resultados físicos e trata concorrência segundo os contratos aprovados. Não conhece ORDS ou HTTP e não monta resposta pública do Core.

### 7.6 ACC_API_PKG

Constitui a fronteira pública PL/SQL do módulo. Chama o Service, traduz exceções conhecidas para o contrato público, utiliza o Core Framework conforme necessário e retorna `CORE_RESPONSE_PKG.t_response_body`. Não executa SQL, não contém regras de domínio, não gera hash e não conhece ORDS ou Flutter.

---

## 8. Estratégia de Implementação

A sequência obrigatória é:

```text
1. ACC_RULE_PKG
2. ADR de persistência ACCOUNT
3. DDL BEX_ACCOUNT
4. ACC_PASSWORD_PKG
5. ACC_REPOSITORY_PKG
6. ACC_SERVICE_PKG
7. ACC_API_PKG
8. validação consolidada no Oracle
9. Git
```

Cada componente PL/SQL deve cumprir, antes do avanço à etapa seguinte:

```text
arquitetura
    ↓
specification
    ↓
body
    ↓
installer
    ↓
testes
    ↓
Oracle
    ↓
aprovação
```

O DDL deve materializar `ADR-016_ACCOUNT_PERSISTENCE.md` e o Data Dictionary. Falhas ou divergências devolvem o fluxo à etapa responsável, sem correção arquitetural silenciosa. Git somente sucede a validação consolidada e a aprovação.

---

## 9. Arquivos Autorizados

Somente os arquivos desta seção podem ser criados ou modificados durante a Sprint 9.

### 9.1 Entregáveis Executáveis

#### Tabela

1. `database/tables/account/bex_account.sql`;
2. `database/tests/account/test_bex_account.sql`.

#### ACC_RULE_PKG

3. `database/packages/account/acc_rule_pkg.pks`;
4. `database/packages/account/acc_rule_pkg.pkb`;
5. `database/packages/account/install_acc_rule_pkg.sql`;
6. `database/tests/account/test_acc_rule_pkg.sql`.

#### ACC_PASSWORD_PKG

7. `database/packages/account/acc_password_pkg.pks`;
8. `database/packages/account/acc_password_pkg.pkb`;
9. `database/packages/account/install_acc_password_pkg.sql`;
10. `database/tests/account/test_acc_password_pkg.sql`.

#### ACC_REPOSITORY_PKG

11. `database/packages/account/acc_repository_pkg.pks`;
12. `database/packages/account/acc_repository_pkg.pkb`;
13. `database/packages/account/install_acc_repository_pkg.sql`;
14. `database/tests/account/test_acc_repository_pkg.sql`.

#### ACC_SERVICE_PKG

15. `database/packages/account/acc_service_pkg.pks`;
16. `database/packages/account/acc_service_pkg.pkb`;
17. `database/packages/account/install_acc_service_pkg.sql`;
18. `database/tests/account/test_acc_service_pkg.sql`.

#### ACC_API_PKG

19. `database/packages/account/acc_api_pkg.pks`;
20. `database/packages/account/acc_api_pkg.pkb`;
21. `database/packages/account/install_acc_api_pkg.sql`;
22. `database/tests/account/test_acc_api_pkg.sql`.

#### Consolidados

23. `database/packages/account/install_account_module.sql`;
24. `database/tests/account/test_account_module.sql`.

A criação dos diretórios estritamente necessários a esses caminhos está autorizada. O caminho `database/tables/account/` é uma convenção local explícita desta Sprint para ACCOUNT e não institui regra automática para módulos futuros.

### 9.2 Arquivos Documentais

As correções documentais aprovadas da Sprint podem alcançar somente:

- `docs/ADR-015_ACCOUNT_DOMAIN_RULES.md`;
- `docs/ADR-016_ACCOUNT_PERSISTENCE.md`;
- `docs/20_DATA_DICTIONARY.md`;
- `docs/sprints/SPRINT_09_IMPLEMENTATION_GUIDE.md`.

Esses arquivos documentais não integram a contagem dos 24 entregáveis executáveis.

---

## 10. Arquivos Proibidos

Não podem ser criados ou modificados durante a Sprint 9:

- arquivos de PROFILE ou de qualquer outro módulo de negócio;
- packages, bodies, specifications, instaladores e testes do Core Framework;
- documentos `00` a `30`, exceto `docs/20_DATA_DICTIONARY.md` conforme autorização específica;
- documentos de arquitetura, padrões de API e contexto de execução;
- artefatos de login, sessão, token, ORDS, Flutter ou integrações externas;
- migrations, scripts operacionais ou configurações não relacionados na seção 9;
- qualquer arquivo não listado na seção 9.

`ACC_PASSWORD_PKG` pertence ao módulo ACCOUNT e não constitui alteração do Core Framework.

---

## 11. Critérios de Interrupção

A implementação deve parar e solicitar revisão quando:

- existir conflito entre documentos aplicáveis;
- for necessária alteração arquitetural ou evolução do Core Framework;
- surgir decisão material que exija nova ADR;
- existir divergência entre o DDL, o Data Dictionary e `ADR-016_ACCOUNT_PERSISTENCE.md`;
- o contrato criptográfico de `ACC_PASSWORD_PKG` permanecer indefinido na etapa de sua implementação;
- for necessária package em camada não autorizada;
- o número ou a localização dos entregáveis precisar mudar sem autorização;
- surgir regra de negócio não registrada em ADR ou documento superior;
- um requisito somente puder ser atendido mediante arquivo não autorizado;
- o contrato necessário não estiver suficientemente aprovado para implementação segura.

Nenhuma dessas situações pode ser resolvida por suposição, ampliação de escopo ou alteração silenciosa de contrato.

---

## 12. Critérios de Aceite

A Sprint somente será considerada aprovada quando:

- `BEX_ACCOUNT` estiver materializada conforme o Data Dictionary e `ADR-016_ACCOUNT_PERSISTENCE.md`;
- tabela e packages compilarem ou forem criados com sucesso;
- `USER_ERRORS` estiver vazio para todos os packages da Sprint;
- constraints e índices estiverem aprovados e validados;
- os testes individuais de tabela, RULE, PASSWORD, REPOSITORY, SERVICE e API estiverem aprovados;
- a suíte consolidada de ACCOUNT estiver aprovada;
- os 274 testes do baseline permanecerem aprovados;
- nenhuma senha em texto puro for armazenada;
- nenhuma senha ou hash for registrado em trace ou logs;
- `ACC_ID` não for exposto às camadas superiores;
- RULE e API não contiverem SQL de persistência;
- as packages da Sprint não executarem `COMMIT` ou `ROLLBACK`;
- os instaladores forem idempotentes e não ocultarem falhas;
- a implementação estiver validada no Oracle AI Database;
- o review técnico e arquitetural estiver aprovado;
- não houver alteração fora dos arquivos autorizados.

---

## 13. Definition of Done

A Sprint 9 estará concluída somente quando:

- os 24 entregáveis executáveis da seção 14 existirem e estiverem coerentes entre si;
- specifications públicas precederem e delimitarem seus respectivos bodies;
- o DDL estiver coerente com o Data Dictionary e `ADR-016_ACCOUNT_PERSISTENCE.md`;
- identity, constraints, índices, defaults e nulabilidade de `BEX_ACCOUNT` estiverem validados;
- o mecanismo seguro de senha possuir contrato criptográfico aprovado, implementação e testes;
- RULE, PASSWORD, REPOSITORY, SERVICE e API preservarem suas responsabilidades e dependências;
- o Service gerar `ACC_PUBLIC_ID` e o Repository apenas persistir valores preparados;
- concorrência e violações de unicidade forem tratadas nas camadas aprovadas;
- senha em texto puro nunca for persistida e senha ou hash nunca forem registrados;
- `ACC_ID` permanecer encapsulado na persistência;
- SQL não existir em RULE ou API;
- nenhuma package da Sprint executar `COMMIT` ou `ROLLBACK`;
- instaladores individuais e consolidado forem idempotentes, previsíveis e validarem os objetos instalados;
- testes individuais e consolidados cobrirem os contratos aprovados e liberarem os dados e recursos que criarem;
- todos os testes estiverem aprovados no Oracle AI Database e `USER_ERRORS` estiver vazio;
- o baseline de 274 testes permanecer íntegro;
- o review técnico e arquitetural não possuir pendências bloqueantes;
- o worktree não contiver mudanças da Sprint fora dos arquivos autorizados;
- Git ocorrer somente depois da validação e autorização.

---

## 14. Entregáveis

Os entregáveis executáveis da Sprint 9 são exatamente:

1. `database/tables/account/bex_account.sql`;
2. `database/tests/account/test_bex_account.sql`;
3. `database/packages/account/acc_rule_pkg.pks`;
4. `database/packages/account/acc_rule_pkg.pkb`;
5. `database/packages/account/install_acc_rule_pkg.sql`;
6. `database/tests/account/test_acc_rule_pkg.sql`;
7. `database/packages/account/acc_password_pkg.pks`;
8. `database/packages/account/acc_password_pkg.pkb`;
9. `database/packages/account/install_acc_password_pkg.sql`;
10. `database/tests/account/test_acc_password_pkg.sql`;
11. `database/packages/account/acc_repository_pkg.pks`;
12. `database/packages/account/acc_repository_pkg.pkb`;
13. `database/packages/account/install_acc_repository_pkg.sql`;
14. `database/tests/account/test_acc_repository_pkg.sql`;
15. `database/packages/account/acc_service_pkg.pks`;
16. `database/packages/account/acc_service_pkg.pkb`;
17. `database/packages/account/install_acc_service_pkg.sql`;
18. `database/tests/account/test_acc_service_pkg.sql`;
19. `database/packages/account/acc_api_pkg.pks`;
20. `database/packages/account/acc_api_pkg.pkb`;
21. `database/packages/account/install_acc_api_pkg.sql`;
22. `database/tests/account/test_acc_api_pkg.sql`;
23. `database/packages/account/install_account_module.sql`;
24. `database/tests/account/test_account_module.sql`.

Os quatro arquivos documentais da seção 9.2 são autorizações de suporte e não alteram essa quantidade.

---

## 15. Próximos Passos

Após a conclusão e aprovação da Sprint 9, a Sprint 10 iniciará o módulo PROFILE. Este registro não autoriza antecipar qualquer artefato ou requisito de PROFILE durante a Sprint 9.
