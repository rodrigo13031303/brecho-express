# 37 — Arquitetura de Ledger, Saldo e Repasse

STORE_BALANCE_TRANSACTION é a única fonte de verdade do saldo. Movimentações
POSTED são imutáveis e usam valores positivos. STORE_BALANCE é uma view
calculada; não existe tabela de saldo nem operação de atualização direta.

Tipos iniciais:

- SALE_HOLD/CREDIT: líquido da venda em retenção;
- HOLD_RELEASE/DEBIT: saída do saldo bloqueado;
- HOLD_RELEASE/CREDIT: entrada no saldo disponível;
- PAYOUT_RESERVE/DEBIT: reserva do disponível e entrada no payout pendente;
- PAYOUT_RESTORE/CREDIT: devolução ao disponível e saída do pendente;
- PAYOUT_PAID/DEBIT: saída do pendente e entrada no total pago.

COMMISSION liquida separadamente a participação de cada STORE no ORDER. Taxa
da plataforma e custo do gateway são entradas explícitas do contrato interno;
nenhuma taxa fica escondida em código.

PAYOUT é solicitado pelo administrador da STORE, desde que o saldo disponível
derivado seja suficiente. Aprovação, pagamento ou rejeição são operações
internas. Cada transição registra movimentos correspondentes na mesma transação.
