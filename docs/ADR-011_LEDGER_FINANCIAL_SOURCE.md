# ADR-011 — Livro Razão como fonte financeira

## Status

Aceito e implementado

## Data

2026-07-01

## Contexto

Saldo financeiro requer rastreabilidade, retenção, estorno, repasse e
conciliação sem atualização destrutiva de um valor agregado.

## Decisão

STORE_BALANCE_TRANSACTION é a única fonte persistida do saldo. Movimentações
POSTED são imutáveis. STORE_BALANCE é uma view derivada e não uma tabela
atualizada diretamente.

## Consequências

- todo efeito financeiro possui movimento explícito;
- saldo pode ser recalculado e conciliado;
- estorno ocorre por novos lançamentos;
- operações financeiras precisam de idempotência e referência de origem.
