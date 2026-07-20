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

Implementar a primeira versão do módulo ACCOUNT no banco Oracle, limitada à entidade `BEX_ACCOUNT`, aos packages `ACC_RULE_PKG` e `ACC_API_PKG`, aos respectivos instaladores e aos testes automatizados.

A implementação deve materializar apenas contratos já aprovados, respeitando a separação entre credenciais e identidade pessoal e utilizando o Core Framework conforme a responsabilidade de cada componente.

---

## 3. Contexto

A Sprint 8 foi encerrada com o Core Framework concluído e sua suíte consolidada aprovada. O baseline informado para o início desta Sprint é de 274 testes aprovados.

A Sprint 9 inicia a implementação dos módulos de negócio pelo contexto de identidade. Seu objetivo é entregar exclusivamente a infraestrutura Oracle do módulo ACCOUNT prevista neste guia, sem antecipar PROFILE, autenticação completa, transporte ORDS ou clientes Flutter.

Durante a revisão da primeira specification de negócio foram identificadas lacunas sobre regras de ACCOUNT e sua tradução para erros públicos. A correção arquitetural foi aprovada e registrada no `ADR-015_ACCOUNT_DOMAIN_RULES.md` antes da implementação do body.

---

## 4. Escopo

A Sprint 9 implementará exclusivamente:

- tabela `BEX_ACCOUNT`;
- package `ACC_RULE_PKG`;
- package `ACC_API_PKG`;
- instaladores individuais e consolidado do módulo;
- testes automatizados individuais e suíte consolidada do módulo.

Qualquer comportamento implementado deve estar respaldado pelos documentos oficiais relacionados na seção 6 e permanecer dentro dos arquivos autorizados na seção 9.

---

## 5. Fora do Escopo

Não fazem parte da Sprint 9:

- PROFILE;
- JWT;
- Refresh Token;
- MFA;
- Social Login;
- OAuth;
- Flutter;
- ORDS;
- recuperação de senha;
- confirmação de e-mail;
- integrações externas.

Esses itens não devem ser parcialmente implementados, simulados ou antecipados nos objetos desta Sprint.

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
- este guia de implementação.

As dependências acima devem ser referenciadas em sua fonte. Este guia não replica seus contratos detalhados nem altera sua hierarquia documental.

---

## 7. Arquitetura da Sprint

ACCOUNT representa exclusivamente credenciais e estado de acesso. PROFILE representa a identidade da pessoa e será implementado em outro módulo. A separação entre esses conceitos é obrigatória.

As responsabilidades desta Sprint são distribuídas da seguinte forma:

- `BEX_ACCOUNT` materializa a entidade ACCOUNT conforme o Data Dictionary e as convenções físicas vigentes;
- `ACC_RULE_PKG` concentra regras e validações de domínio pertencentes a ACCOUNT;
- `ACC_API_PKG` constitui a fronteira PL/SQL do módulo e coordena os contratos autorizados sem absorver regras de domínio;
- os instaladores criam e validam somente os objetos da Sprint;
- os testes verificam contratos, regras, integração com o Core e ausência de efeitos proibidos.

Nenhuma regra pode contornar o Core Framework. Cada package do Core deve ser utilizado apenas quando necessário à responsabilidade do componente e segundo seus contratos públicos. Não serão criados packages, camadas, tabelas ou componentes além dos previstos neste guia.

---

## 8. Estratégia de Implementação

A sequência obrigatória é:

```text
Arquitetura
    ↓
Specification
    ↓
Body
    ↓
Instaladores
    ↓
Testes
    ↓
Oracle
    ↓
Git
```

Antes da specification, deve ser verificada a coerência entre este guia e os documentos oficiais. Specification e body devem ser revisados antes da execução dos instaladores. A validação no Oracle e a aprovação dos testes precedem qualquer operação de Git que consolide a entrega. Falhas ou divergências devolvem o fluxo à etapa responsável, sem correção arquitetural silenciosa.

---

## 9. Arquivos Autorizados

Somente os arquivos relacionados nesta seção podem ser criados ou modificados durante a Sprint 9.

### 9.1 Entregáveis Executáveis

- `database/packages/account/acc_rule_pkg.pks`;
- `database/packages/account/acc_rule_pkg.pkb`;
- `database/packages/account/install_acc_rule_pkg.sql`;
- `database/tests/account/test_acc_rule_pkg.sql`;
- `database/packages/account/acc_api_pkg.pks`;
- `database/packages/account/acc_api_pkg.pkb`;
- `database/packages/account/install_acc_api_pkg.sql`;
- `database/tests/account/test_acc_api_pkg.sql`;
- `database/packages/account/install_account_module.sql`;
- `database/tests/account/test_account_module.sql`.

A criação de diretórios estritamente necessária para esses caminhos está autorizada. O DDL de `BEX_ACCOUNT` deve permanecer dentro do conjunto de instaladores autorizado, sem criar artefato adicional.

### 9.2 Correção Arquitetural Aprovada

Exclusivamente para formalizar as decisões anteriores à implementação do body, estão autorizados:

- `docs/ADR-015_ACCOUNT_DOMAIN_RULES.md`;
- `docs/20_DATA_DICTIONARY.md`;
- `docs/sprints/SPRINT_09_IMPLEMENTATION_GUIDE.md`;
- `database/packages/account/acc_rule_pkg.pks`.

Esses documentos e a atualização da specification não constituem novos packages nem ampliam os dez entregáveis executáveis da seção 14.

---

## 10. Arquivos Proibidos

Não podem ser criados ou modificados durante a Sprint 9:

- arquivos de PROFILE ou de qualquer outro módulo de negócio;
- packages, bodies, specifications, instaladores e testes do Core Framework;
- documentos `00` a `30`, exceto o ajuste autorizado em `docs/20_DATA_DICTIONARY.md`;
- Data Dictionary e documentos de modelagem de domínio;
- documentos de arquitetura, padrões de API e contexto de execução;
- artefatos ORDS, Flutter, autenticação por token ou integrações externas;
- qualquer arquivo não listado na seção 9.

Este guia também não autoriza alteração retroativa em migrations, scripts operacionais ou configurações do projeto.

---

## 11. Critérios de Interrupção

A implementação deve parar e solicitar revisão quando:

- existir conflito entre documentos aplicáveis;
- for necessária alteração arquitetural;
- for necessária alteração no Core Framework;
- surgir decisão material que exija nova ADR;
- existir inconsistência entre domínio, Data Dictionary e implementação pretendida;
- um requisito somente puder ser atendido mediante arquivo não autorizado;
- o contrato necessário não estiver suficientemente aprovado para implementação segura.

Nenhuma dessas situações pode ser resolvida por suposição, ampliação de escopo ou alteração silenciosa de contrato.

---

## 12. Critérios de Aceite

A Sprint somente será considerada aprovada quando:

- todos os objetos autorizados compilarem com sucesso;
- `USER_ERRORS` estiver vazio para os objetos da Sprint;
- os testes individuais de `ACC_RULE_PKG` e `ACC_API_PKG` estiverem aprovados;
- a suíte consolidada de ACCOUNT estiver aprovada;
- os 274 testes do baseline permanecerem aprovados;
- o review técnico e arquitetural estiver aprovado;
- a implementação estiver validada no Oracle AI Database;
- não houver alteração fora do escopo autorizado.

---

## 13. Definition of Done

A Sprint 9 estará concluída somente quando, conforme os padrões permanentes do projeto:

- os dez entregáveis da seção 14 existirem e estiverem coerentes entre si;
- specifications precederem e delimitarem seus respectivos bodies;
- `BEX_ACCOUNT`, `ACC_RULE_PKG` e `ACC_API_PKG` respeitarem domínio, nomenclatura, segurança e direção de dependências;
- credenciais não forem armazenadas em texto puro nem registradas em trace;
- identificadores internos não forem expostos por contratos públicos;
- erros conhecidos utilizarem o contrato público aprovado e erros inesperados forem tratados de forma segura;
- packages de domínio e API não executarem `COMMIT` ou `ROLLBACK`;
- SQL dinâmico, se excepcionalmente necessário, possuir justificativa e proteção conforme o padrão permanente;
- instaladores forem idempotentes, falharem diante de erro de compilação e validarem os objetos instalados;
- testes cobrirem regras, contratos, cenários de sucesso, erros conhecidos, falhas inesperadas relevantes e integração necessária com o Core;
- testes não dependerem de frameworks externos e liberarem recursos temporários que criarem;
- testes individuais e consolidados estiverem aprovados no Oracle AI Database;
- o baseline anterior permanecer íntegro;
- o review técnico e arquitetural não possuir pendências bloqueantes;
- o worktree não contiver mudanças da Sprint fora dos arquivos autorizados;
- a consolidação em Git ocorrer somente após validação e autorização.

---

## 14. Entregáveis

Os entregáveis da Sprint 9 são exatamente:

1. `acc_rule_pkg.pks`;
2. `acc_rule_pkg.pkb`;
3. `install_acc_rule_pkg.sql`;
4. `test_acc_rule_pkg.sql`;
5. `acc_api_pkg.pks`;
6. `acc_api_pkg.pkb`;
7. `install_acc_api_pkg.sql`;
8. `test_acc_api_pkg.sql`;
9. `install_account_module.sql`;
10. `test_account_module.sql`.

---

## 15. Próximos Passos

Após a conclusão e aprovação da Sprint 9, a Sprint 10 iniciará o módulo PROFILE. Este registro não autoriza antecipar qualquer artefato ou requisito de PROFILE durante a Sprint 9.
