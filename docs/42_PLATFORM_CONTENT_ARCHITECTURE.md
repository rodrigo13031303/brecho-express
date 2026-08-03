# 42 — Arquitetura de conteúdo da plataforma

## Status

Implementação inicial aprovada para `PLATFORM_BANNER`, conforme ADR-026.

## Limite de domínio

`PLATFORM_BANNER` é comunicação editorial global controlada pela plataforma.
Não representa `STORE_EVENT`, produto, anúncio pago, cupom ou notificação.

## Modelo

Possui Public ID, título administrativo, texto alternativo, URL de imagem,
destino estruturado, início, fim, ordem, estado e auditoria por ACCOUNT.
`BEX_PLATFORM_BANNER_MEDIA` mantém MIME e BLOB em relação 1:1.

## Regras

- início deve ser anterior ao fim;
- ativação exige imagem;
- ordem fica entre 0 e 99999;
- `ARCHIVED` é terminal;
- somente ROLE global `ADMIN` cria, altera ou envia imagem;
- consulta pública aplica estado e vigência no servidor;
- conteúdo binário não integra respostas JSON.

Para o destino `APP_SCREEN`, o aplicativo administra uma chave estável em vez
de texto de apresentação. As chaves iniciais são `inicio`, `comprar`, `vender`,
`carrinho` e `perfil`. O formulário administrativo deve apresentá-las como
opções e a navegação deve manter compatibilidade com aliases legados.

## Packages

- `PLB_REPOSITORY_PKG`;
- `PLB_RULE_PKG`;
- `PLB_SERVICE_PKG`;
- `PLB_API_PKG`.

`IAM_AUTHORIZATION_PKG.require_role(accountId, 'ADMIN')` é a fronteira de
autorização administrativa.

## APIs

| Método | Rota | Autenticação |
|---|---|---|
| GET | `/platform-banners` | anônima |
| GET | `/admin/platform-banners` | ADMIN |
| POST | `/admin/platform-banners` | ADMIN |
| PUT | `/admin/platform-banners/{bannerPublicId}` | ADMIN |
| POST | `/admin/platform-banners/{bannerPublicId}/image` | ADMIN |
| GET | `/platform-banners/{bannerPublicId}/image` | anônima |
| GET | `/me/roles` | autenticada |

Todos os JSON seguem envelope vigente, camelCase, ISO-8601 e PUBLIC_ID.

## Evolução adiada

- métricas de impressão e clique;
- segmentação por público ou região;
- imagens responsivas;
- aprovação em quatro olhos;
- anúncios pagos e cobrança.
