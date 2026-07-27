# ADR-013 — Chave PIX diretamente no repasse inicial

## Status

Aceito e implementado

## Data

2026-07-01

## Contexto

O repasse inicial necessita de um destino simples, embora o produto possa
suportar múltiplas contas e provedores futuramente.

## Decisão

PAYOUT preserva diretamente chave e tipo PIX no MVP. Não existe
STORE_PAYMENT_ACCOUNT neste ciclo.

Uma evolução para contas bancárias, múltiplos destinos ou provedores exige
contrato próprio, segurança de dados, versionamento do destino aplicado e
migração.

## Consequências

- o fluxo inicial evita agregado financeiro prematuro;
- o destino usado fica preservado no repasse;
- dados PIX exigem proteção e exposição mínima;
- novas modalidades não serão adicionadas apenas como colunas dispersas.
