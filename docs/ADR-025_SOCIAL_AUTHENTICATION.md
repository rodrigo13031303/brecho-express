# ADR-025 — Autenticação Social e Identidades Externas

## Status

Aceito para materialização incremental

## Data

2026-07-26

## Contexto

O Brechó Express precisa autenticar por e-mail e senha, Google, Apple e,
posteriormente, Facebook. ACCOUNT representa a identidade técnica interna e
SESSION representa a sessão emitida pela plataforma. Tokens externos não podem
substituir a sessão própria nem transformar e-mail em identificador de
provedor.

O modelo vigente exige senha em toda ACCOUNT, o que impediria contas criadas
exclusivamente por um provedor. Também é necessário impedir vinculação
automática insegura quando uma identidade externa informa um e-mail já usado.

## Decisão

### 1. Provedores

Os códigos inicialmente aprovados são:

- `GOOGLE`, prioridade do MVP;
- `APPLE`, prioridade do MVP e da distribuição iOS;
- `FACEBOOK`, previsto estruturalmente e implementado após Google e Apple.

### 2. Validação no backend

Flutter obtém uma credencial de curta duração do SDK oficial e a envia por
HTTPS ao ORDS. O backend valida assinatura, emissor, audiência, expiração,
nonce quando aplicável e demais claims obrigatórios antes de confiar em
qualquer dado.

ID, e-mail, nome ou outro claim enviado isoladamente pelo cliente nunca prova
identidade. Token inválido, expirado ou destinado a outro client ID é rejeitado.
Tokens e authorization codes de provedor nunca são persistidos nem registrados
em log.

### 3. Identificador da identidade

A identidade externa é localizada exclusivamente pela composição:

```text
provider + issuer + subject
```

`subject` é o identificador imutável validado do provedor. E-mail é atributo
informativo e mutável; nunca é chave de autenticação social.

### 4. ACCOUNT e credencial local

`ACC_PASSWORD_HASH` passa a aceitar `NULL`. Conta social não recebe senha
aleatória, reversível ou desconhecida pelo usuário. Login local continua
exigindo uma credencial válida e falha de forma genérica quando ela não existe.

Uma ACCOUNT autenticável deve possuir pelo menos:

- credencial local válida; ou
- uma identidade externa `ACTIVE`.

Essa invariável atravessa duas tabelas e será garantida pelos casos de uso de
criação, vinculação, desvinculação e definição de senha, não por trigger.

### 5. Criação por login social

Após validação do provedor:

- identidade já vinculada autentica a ACCOUNT correspondente, se ela estiver
  `ACTIVE`;
- identidade desconhecida com e-mail ausente ou não confiável não cria conta;
- identidade desconhecida com e-mail elegível e ainda não usado pode criar
  ACCOUNT `ACTIVE`, com e-mail verificado e senha nula, na mesma transação da
  vinculação;
- e-mail já pertencente a outra ACCOUNT não causa vinculação automática.

Quando o e-mail já existe, o usuário deve autenticar a ACCOUNT existente por
um método já confiável e executar vinculação explícita. A resposta externa não
expõe detalhes que facilitem enumeração de contas.

### 6. Vinculação e desvinculação

Vinculação exige sessão Brechó Express válida e nova prova criptográfica do
provedor. Uma identidade externa pertence a exatamente uma ACCOUNT.

Desvinculação é lógica por status `INACTIVE`. Ela é recusada quando removeria o
último método de autenticação da ACCOUNT. Nova vinculação da mesma composição
reativa o registro histórico.

### 7. Sessão própria

Após autenticação social, `ACC_SESSION_API_PKG` emite o mesmo access token do
Brechó Express usado no login local. Consumidores usam somente:

```http
Authorization: Bearer <brecho-express-session-token>
```

Token Google, Apple ou Facebook não autoriza endpoints de negócio.

### 8. Persistência

`BEX_ACCOUNT_IDENTITY` registra Public ID, ACCOUNT, provedor, emissor,
subject, e-mail observado, indicação de e-mail verificado, status, datas de
vinculação, último login, desvinculação e auditoria.

Unicidades obrigatórias:

- Public ID;
- `(AID_PROVIDER, AID_ISSUER, AID_SUBJECT)`;
- `(ACC_ID, AID_PROVIDER)`.

### 9. Contrato HTTP planejado

```text
POST   /auth/social/{provider}
POST   /account/identities/{provider}
DELETE /account/identities/{identityPublicId}
GET    /account/identities
```

O endpoint de login recebe somente a credencial necessária ao fluxo aprovado,
além de nonce ou authorization code quando o provedor exigir. Claims confiáveis
são produzidos exclusivamente pelo verificador do backend.

## Estado de implementação

Em 2026-07-26, no Oracle AI Database 26ai Free:

- decisão e modelo físico aprovados e instalados;
- `BEX_ACCOUNT_IDENTITY` criada com constraints e índices válidos;
- `ACC_PASSWORD_HASH` alterada para aceitar conta exclusivamente social;
- cinco testes físicos aprovados, incluindo conta sem senha, persistência de
  identidade, unicidade por provedor e rejeição de provedor desconhecido;
- domínio Google instalado com duração de sessão e audience parametrizadas;
- cinco testes transacionais do Service aprovados: criação social-only,
  idempotência, não duplicação, bloqueio de auto-link e rejeição de e-mail não
  verificado;
- o `DBMS_CRYPTO` do Oracle 23.26 rejeitou chaves RSA externas em SPKI,
  PKCS#1 e certificado X.509; por isso a assinatura não é validada em PL/SQL;
- plugin oficial do ORDS 25.4 materializado em Java 17 para validar `RS256`,
  rotação de chaves, emissor, audience, datas e subject;
- health check do plugin aprovado externamente e token inválido rejeitado com
  `401 BEX-AUTH-003`;
- autenticação com token Google real e integração Flutter ainda pendentes;
- Apple e Facebook ainda não possuem verificadores.

## Consequências

- login social não enfraquece a sessão própria;
- e-mail coincidente não vincula contas silenciosamente;
- contas exclusivamente sociais são representadas sem senha artificial;
- Apple Private Relay é compatível com o modelo;
- troca de e-mail no provedor não altera a identidade;
- inclusão futura de provedor exige evolução explícita do domínio aceito;
- implementação Flutter pode adotar SDKs oficiais sem conhecer IDs internos.
