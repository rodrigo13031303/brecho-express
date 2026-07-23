# ADR-018 — Administração de membros da STORE

## Status

Aceito

## Data

2026-07-23

## Contexto

`BEX_STORE_USER` representa o vínculo operacional entre uma STORE e uma
ACCOUNT. Sua estrutura física e as camadas internas `STU_RULE_PKG`,
`STU_REPOSITORY_PKG` e `STU_SERVICE_PKG` já estão implementadas.

O Data Dictionary determina que STORE_USER não possui API pública própria no
MVP. Suas operações devem ser expostas pelas APIs administrativas de Store.
Ainda faltava definir a fronteira pública, a origem confiável do ator, as
permissões de administração e as invariantes que protegem a continuidade
operacional da STORE.

Sem essa decisão, a implementação precisaria confiar em identidade enviada
pelo cliente ou inventar regras de autorização durante o código.

---

## Decisão

### 1. Fronteira pública

As operações administrativas de STORE_USER serão expostas exclusivamente por
`STR_API_PKG`, sob o recurso público de STORE.

Não será criado `STU_API_PKG` nem endpoint público independente para
STORE_USER. `STU_SERVICE_PKG` permanece uma fronteira interna de casos de uso
consumida pela orquestração de Store.

### 2. Identidade operacional

ACCOUNT é a identidade estrutural e operacional de STORE_USER. PROFILE contém
dados pessoais e não participa da propriedade, da autorização nem do vínculo
operacional.

O proprietário da STORE é a ACCOUNT registrada em `BEX_STORE.ACC_ID`. A
propriedade não é representada por STORE_USER e não pode ser transferida,
removida ou alterada por operações de membros.

### 3. Ator confiável

Toda operação administrativa autenticada recebe `p_actor_id NUMBER` do adapter
ORDS conforme `31_API_RUNTIME_CONTRACT.md`.

`p_actor_id`:

- é resolvido pela infraestrutura confiável;
- não vem do body, rota, query parameter ou header controlável pelo cliente;
- é usado para autorização e auditoria;
- não é exposto no contrato JSON.

`actorPublicId` é proibido nos payloads administrativos de membros. A
implementação vigente de `STU_SERVICE_PKG` que recebe public ID do ator deverá
ser refatorada antes da exposição externa.

### 4. Autorização

Podem administrar membros:

- a ACCOUNT proprietária da STORE;
- uma ACCOUNT com vínculo STORE_USER `ACTIVE` e papel `ADMIN` na mesma STORE.

O proprietário pode adicionar, consultar, alterar papel, ativar e desativar
qualquer vínculo da STORE.

Um ADMIN pode executar as mesmas operações sobre STORE_USER, mas:

- não altera a propriedade da STORE;
- não usa STORE_USER para conceder ou retirar propriedade;
- está sujeito à proteção do último ADMIN ativo;
- não pode administrar vínculo pertencente a outra STORE.

`MANAGER`, `ATTENDANT` e `COLLABORATOR` não administram membros no MVP.

Falha de autorização usa resposta `403 Forbidden`. A API não deve revelar
detalhes de vínculos de uma STORE para ator não autorizado.

### 5. Papéis

Os papéis operacionais permanecem:

- `ADMIN`;
- `MANAGER`;
- `ATTENDANT`;
- `COLLABORATOR`.

Nenhum papel representa propriedade. `OWNER` não será criado como papel de
STORE_USER.

### 6. Proteção do último ADMIN ativo

Uma operação não pode reduzir de um para zero a quantidade de vínculos
STORE_USER `ACTIVE` com papel `ADMIN` na STORE.

A proteção aplica-se à alteração do papel do último ADMIN ativo para outro
papel e à desativação do último ADMIN ativo.

A proteção não cria automaticamente vínculos para lojas legadas que ainda não
possuam ADMIN. A inclusão do primeiro ADMIN continua permitida. A futura
regularização de lojas sem ADMIN será tratada separadamente.

A verificação deve ocorrer sob controle de concorrência no Repository. Uma
consulta sem locking não constitui garantia suficiente.

### 7. Casos de uso públicos

| Operação | Método e recurso candidato | Resultado |
|---|---|---|
| Adicionar membro | `POST /stores/{storePublicId}/members` | Cria vínculo `ACTIVE` |
| Listar membros | `GET /stores/{storePublicId}/members` | Lista vínculos autorizados |
| Consultar membro | `GET /stores/{storePublicId}/members/{storeUserPublicId}` | Retorna um vínculo da STORE |
| Alterar papel | `PATCH /stores/{storePublicId}/members/{storeUserPublicId}` | Altera somente `roleCode` |
| Ativar membro | `POST /stores/{storePublicId}/members/{storeUserPublicId}/activate` | Ativa e limpa `leftAt` |
| Desativar membro | `POST /stores/{storePublicId}/members/{storeUserPublicId}/deactivate` | Inativa e define `leftAt` |

Os caminhos são o contrato candidato para a futura configuração ORDS. A
implementação PL/SQL estabiliza primeiro as assinaturas e payloads desta ADR.

### 8. Payloads e projeção

Adicionar membro recebe:

```json
{
  "accountPublicId": "char32",
  "roleCode": "ADMIN"
}
```

Alterar papel recebe:

```json
{
  "roleCode": "MANAGER"
}
```

Ativação e desativação não recebem identidade do ator no body nem status
arbitrário. Cada ação determina a transição solicitada.

As respostas usam `storeUserPublicId`, `storePublicId`, `accountPublicId`,
`roleCode`, `status`, `joinedAt`, `leftAt`, `createdAt` e `updatedAt`. IDs
internos e campos técnicos de auditoria não são expostos.

### 9. Consistência do recurso

O `storeUserPublicId` informado deve pertencer à STORE identificada por
`storePublicId`. Divergência é tratada como recurso não encontrado para evitar
exposição cruzada entre lojas.

A criação rejeita um segundo vínculo `ACTIVE` para a mesma combinação STORE e
ACCOUNT. O histórico `INACTIVE` permanece preservado.

### 10. Camadas

```text
ORDS
  ↓
STR_API_PKG
  ↓
STR_SERVICE_PKG
  ↓
STU_SERVICE_PKG
  ↓
STU_RULE_PKG / STU_REPOSITORY_PKG
  ↓
BEX_STORE_USER
```

`STR_API_PKG` conhece somente exceções públicas de `STR_SERVICE_PKG`.
`STR_SERVICE_PKG` traduz as exceções internas de `STU_SERVICE_PKG` para seu
próprio contrato nominal. A API não acessa `STU_SERVICE_PKG`, Repository, Rule
ou tabela diretamente.

Para preservar direção acíclica, `STU_SERVICE_PKG` não dependerá de
`STR_SERVICE_PKG`. A orquestração de Store resolve e autoriza a STORE antes de
chamar os casos internos de STU, fornecendo os identificadores estritamente
necessários. A specification interna de STU pode receber `STR_ID`, pois não é
fronteira externa; esse identificador nunca alcança API, ORDS ou payload JSON.

A operação interna existente que lista lojas por ACCOUNT e a conversão de
registros STU por meio de `STR_SERVICE_PKG` deverão ser removidas ou
reorganizadas antes da implementação pública. O fluxo administrativo aprovado
lista membros no contexto de uma STORE já resolvida e não exige navegação
STU → STR.

### 11. Transação

Operações de escrita seguem `31_API_RUNTIME_CONTRACT.md`: a API controla
`COMMIT` e `ROLLBACK`; Service, Rule e Repository não encerram transação; e
autorização, locking, alteração e auditoria participam da mesma transação.
Leituras não executam `COMMIT` ou `ROLLBACK`.

### 12. Erros públicos

Os códigos públicos pertencem ao namespace vigente `BEX-STORE`.

| Código | Condição | HTTP |
|---|---|---:|
| `BEX-STORE-019` | Membro não encontrado na STORE | 404 |
| `BEX-STORE-020` | Papel operacional inválido | 422 |
| `BEX-STORE-021` | Status operacional inválido | 422 |
| `BEX-STORE-022` | Transição de membro inválida | 409 |
| `BEX-STORE-023` | Vínculo ACTIVE já existente | 409 |
| `BEX-STORE-024` | Ator não autorizado a administrar membros | 403 |
| `BEX-STORE-025` | Operação removeria o último ADMIN ativo | 409 |

Erros de STORE ou ACCOUNT inexistentes reutilizam os códigos públicos já
vigentes quando a semântica for idêntica.

---

## Consequências

- STORE_USER permanece um agregado interno sem API própria.
- A administração fica coesa na fronteira pública de Store.
- O cliente não escolhe nem informa a identidade do ator.
- Propriedade e papel operacional permanecem conceitos distintos.
- Lojas não perdem acidentalmente seu último ADMIN ativo.
- `STU_SERVICE_PKG` evoluirá para autorização e concorrência antes da exposição.
- A dependência vigente `STU_SERVICE_PKG` → `STR_SERVICE_PKG` será eliminada
  para impedir ciclo entre Services.
- `STR_SERVICE_PKG` ganhará casos de uso administrativos que traduzem o
  contrato interno de STORE_USER.
- A implementação exigirá testes de autorização, isolamento entre lojas,
  concorrência, auditoria, transação e contrato JSON.

---

## Fora de escopo

- transferência de propriedade da STORE;
- convite pendente ou aceite de membro;
- permissões configuráveis por papel;
- papéis personalizados;
- remoção física de histórico;
- administração por `MANAGER`, `ATTENDANT` ou `COLLABORATOR`;
- configuração ORDS e autenticação definitiva.
