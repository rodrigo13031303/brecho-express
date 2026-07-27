# ADR-021 — Identidade do ator de auditoria

## Status

Aceito

## Data

2026-07-26

## Contexto

O projeto possui três modelos físicos de auditoria: referência a PROFILE,
referência a ACCOUNT e número técnico sem foreign key. PROFILE representa dados
pessoais, ACCOUNT representa autenticação e atuação operacional, e processos
automáticos ainda não possuem contrato uniforme de identidade.

Auditoria também foi confundida em documentos antigos com propriedade da
entidade e relacionamentos de domínio.

## Decisão

### 1. Ator operacional

ACCOUNT é a identidade operacional oficial de uma pessoa autenticada.
PROFILE permanece responsável por dados pessoais e representação da pessoa no
domínio. STORE representa a organização. Nenhum desses papéis é
intercambiável.

### 2. Campos de auditoria

`*_CREATED_BY` e `*_UPDATED_BY` armazenam o identificador técnico da ACCOUNT
responsável pela operação quando existir ator autenticado aplicável.

Esses campos:

- nunca representam propriedade;
- nunca substituem FK funcional;
- nunca são expostos externamente;
- são preenchidos apenas a partir de contexto confiável;
- não podem ser recebidos livremente em payload;
- podem ser nulos somente em operação anônima ou migração expressamente
  autorizada pelo contrato da entidade.

Novas tabelas com auditoria de usuário devem usar tipo compatível com
`BEX_ACCOUNT.ACC_ID` e foreign key para ACCOUNT, salvo exceção aceita em ADR.

### 3. Processos automáticos

Processos automáticos usam uma ACCOUNT técnica formal do tipo SYSTEM, criada e
governada pelo módulo de identidade. `0`, números negativos, constantes
mágicas, PROFILE fictício ou ausência silenciosa de ator não representam
SYSTEM.

Segredos e autenticação da conta técnica não são armazenados nos campos de
auditoria.

### 4. Operações anônimas

Operação pública anônima pode manter ator nulo apenas quando o caso de uso e o
contrato físico permitirem. `traceId`, origem e instante continuam obrigatórios
na observabilidade técnica, sem serem usados como substitutos do ator.

### 5. Migração

As FKs antigas de auditoria para PROFILE não serão reinterpretadas como ACCOUNT
nem removidas sem migração explícita.

Cada entidade legada será classificada:

- valor já representa ACCOUNT e requer correção de constraint;
- valor representa PROFILE e requer mapeamento por `PROFILE.ACC_ID`;
- valor possui origem ambígua e exige saneamento;
- valor nulo é permitido pelo contrato histórico.

A migração deve preservar histórico, validar órfãos e possuir teste de
reconciliação.

## Estado de implementação

Parcialmente implementado em 2026-07-26. Módulos recentes já recebem ator
técnico confiável, mas as constraints e descrições físicas ainda não são
uniformes. ROLE, PROFILE_ROLE, BUSINESS_CONFIGURATION, pós-venda e social ainda
possuem referências de auditoria para PROFILE; STORE_USER e STORE_EVENT usam
ACCOUNT; diversas entidades mantêm número sem FK.

## Consequências

- estabelece ACCOUNT como ator operacional único;
- preserva PROFILE como entidade de dados pessoais;
- exige identidade SYSTEM formal;
- exige plano de migração por entidade;
- elimina números mágicos e autoria recebida do cliente;
- mantém auditoria separada de propriedade e autorização.
