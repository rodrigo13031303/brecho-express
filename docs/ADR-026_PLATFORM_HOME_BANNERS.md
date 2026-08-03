# ADR-026 — Banners globais da Home

## Status

Aceito.

## Contexto

A Home precisa exibir comunicações visuais temporárias configuradas pela
administração da plataforma. `STORE_EVENT` não atende a esse caso: pertence a
uma STORE e representa campanha do brechó, enquanto o banner da Home é conteúdo
editorial global do Brechó Express.

## Decisão

Será criado o agregado `PLATFORM_BANNER`, administrado exclusivamente por uma
ACCOUNT cujo PROFILE possua o ROLE global `ADMIN`.

O banner possui imagem, texto alternativo, vigência, ordem e destino de
navegação estruturado. O Flutter não contém banners promocionais fixos.

Estados: `DRAFT`, `ACTIVE`, `INACTIVE` e `ARCHIVED`. O estado inicial é
`DRAFT`; `ARCHIVED` é terminal.

Destinos iniciais: `PRODUCT`, `STORE`, `CATEGORY`, `STORE_EVENT`, `APP_SCREEN`
e `EXTERNAL_URL`.

## Contratos

O contrato público `GET /api/v1/platform-banners` retorna somente banners
ativos e vigentes. A administração usa `/api/v1/admin/platform-banners` para
listar, criar, atualizar e enviar a imagem. Toda escrita exige ROLE `ADMIN`.

O upload aceita JPEG, PNG ou WebP com até 1 MB. O ator vem do contexto confiável
do ORDS, nunca do payload.

## Flutter

A Home exibe carrossel 2:1, gesto lateral, avanço a cada cinco segundos e
indicador de página. Falha no banner não impede catálogo, login ou compra.

A entrada `Administração` só aparece depois da verificação autenticada de ROLE.
A autorização real permanece no Oracle.

## Auditoria

Criação e alteração registram ACCOUNT. Não há exclusão física pelo aplicativo.
A imagem fica em tabela de mídia 1:1 e o contrato público expõe sua URL ORDS.

## Consequências

- promoções evoluem sem nova versão do aplicativo;
- campanhas globais não contaminam `STORE_EVENT`;
- publicação acidental é reduzida pelo estado inicial `DRAFT`;
- métricas de impressão e clique ficam para contrato posterior.
