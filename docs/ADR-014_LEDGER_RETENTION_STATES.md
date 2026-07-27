# ADR-014 — Retenção financeira representada no Ledger

## Status

Aceito e implementado

## Data

2026-07-01

## Contexto

Valores de venda permanecem temporariamente bloqueados antes de ficarem
disponíveis para repasse, inclusive para suportar devoluções e disputas.

## Decisão

Retenção e liberação são pares explícitos de movimentos no Ledger. Não existe
tabela paralela de valor retido.

Os movimentos iniciais incluem entrada em retenção, saída do bloqueado e
entrada no disponível. Liberação, restauração e pagamento preservam origem e
participam da mesma transação do caso de uso.

## Consequências

- saldo bloqueado e disponível são projeções;
- retenção é auditável e reversível por novos movimentos;
- prazo é política configurável, não estrutura financeira;
- nenhuma atualização direta de STORE_BALANCE é permitida.
