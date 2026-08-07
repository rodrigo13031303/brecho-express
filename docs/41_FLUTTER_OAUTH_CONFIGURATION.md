# 41 — Configuração Flutter e OAuth

## 1. Status

Identificadores móveis, clientes OAuth e verificador Google oficializados.
Backend instalado; integração Flutter e teste com ID token real pendentes.

Em 2026-07-27, a integração Flutter com `google_sign_in 7.2.0` foi
materializada, aprovada por `flutter analyze` e testes, e gerou o primeiro APK
debug com sucesso. O aplicativo solicita um ID token destinado ao Client ID do
backend e o troca pela sessão própria no plugin ORDS.

## 2. Identidade oficial do aplicativo

```text
Application ID Android: br.com.rodrigosburguer.brechoexpress
Namespace Android:      br.com.rodrigosburguer.brechoexpress
Bundle ID iOS:          br.com.rodrigosburguer.brechoexpress
Nome público:           Brechó Express
```

Identificadores `com.example` são proibidos. Mudança futura após publicação
representa outro aplicativo nas lojas e exige decisão explícita.

## 3. Ambientes

O MVP inicia com um projeto Google Cloud controlado. Credenciais devem ser
separadas por tipo de consumidor:

- OAuth Client Android;
- OAuth Client iOS;
- OAuth Client Web destinado ao backend.

Produção e desenvolvimento não compartilham certificados de assinatura.
Quando houver ambientes separados, cada audience aprovada será configurada
explicitamente no backend.

## 4. Google — ordem de configuração

O certificado Android debug local foi criado em 2026-07-26:

```text
OAuth Client Android Debug:
77055318166-aai2lpnk0otaq18235qbt69b7h8e7i9j.apps.googleusercontent.com

SHA-1:
18:3B:FB:D2:7D:E6:A3:3F:DD:70:39:B1:B1:69:41:93:E7:48:25:AC

SHA-256:
42:E9:16:03:0F:57:F7:94:B3:E6:0D:4D:2E:C9:5D:A3:BF:EF:DE:CE:E1:09:00:87:46:C0:9C:B3:71:FB:C4:E5
```

Essas impressões são exclusivas do certificado debug desta estação. Produção
utilizará certificado próprio e novas impressões digitais.

O cliente Android foi criado no projeto Google Cloud `brecho-express`. O JSON
baixado foi inspecionado apenas para confirmar o tipo e não contém
`client_secret`; ele não é necessário no repositório Flutter.

O cliente iOS também foi criado com o Bundle ID oficial:

```text
OAuth Client iOS:
77055318166-815viv1t22035m50v00htkvklqhqvg18.apps.googleusercontent.com

Reversed Client ID:
com.googleusercontent.apps.77055318166-815viv1t22035m50v00htkvklqhqvg18

Bundle ID:
br.com.rodrigosburguer.brechoexpress
```

O `.plist` baixado não contém `client_secret`. Sua incorporação ao target iOS
ocorrerá junto da integração Google Sign-In no Flutter, incluindo o URL scheme
reverso no projeto Xcode.

O cliente Web que representa o backend foi criado sem origens JavaScript ou
redirect URIs:

```text
OAuth Client Backend:
77055318166-jr5lsmj17trmgt651ne3ismc7r7t1tli.apps.googleusercontent.com
```

Esse Client ID será a audience solicitada pelo Flutter e permitida pelo
verificador Google. Embora o Google tenha emitido um Client Secret para o tipo
Web, o fluxo de validação de ID token não o utiliza. O secret não será
persistido no Oracle, incluído no Flutter, documentado ou versionado.

Ordem:

1. Criar ou selecionar o projeto Google Cloud do Brechó Express.
2. Configurar a OAuth consent screen.
3. Criar OAuth Client Android com package e SHA-1 debug.
4. Criar OAuth Client iOS com o Bundle ID.
5. Criar OAuth Client Web para representar o backend.
6. Registrar somente Client IDs públicos na configuração apropriada.
7. Configurar audiences permitidas no backend.
8. Testar um ID token real de ponta a ponta.

## 5. Segredos e arquivos locais

- Client ID não é segredo, mas deve ser configurado por ambiente.
- Client secret nunca entra no Flutter.
- Chave Apple `.p8`, Facebook App Secret e segredos equivalentes nunca entram
  no Git.
- Tokens reais não aparecem em logs, fixtures, screenshots ou documentação.
- Arquivos gerados por console somente entram no projeto quando o SDK exigir e
  quando sua classificação permitir versionamento seguro.

## 6. Validação Google no backend

O backend aceita apenas ID token íntegro e valida:

- assinatura contra chaves oficiais com rotação e cache;
- `iss` aprovado;
- `aud` pertencente à allowlist do Brechó Express;
- `exp` e demais datas;
- `sub` presente e estruturalmente válido;
- nonce quando o fluxo utilizado exigir;
- e-mail e `email_verified` apenas como atributos auxiliares.
- `name` como dado de apresentação opcional, usado para provisionar o PROFILE
  somente depois da validação integral do token.

O nome verificado não substitui posteriormente um nome personalizado pelo
usuário. Perfis legados cujo nome ainda seja o prefixo técnico do e-mail podem
ser corrigidos no login seguinte.

O endpoint de debugging `tokeninfo` não é mecanismo de produção.

## 7. Apple e Facebook

Apple reutiliza o mesmo Bundle ID e exige configuração no Apple Developer,
capability Sign in with Apple e validação no backend. Chave privada permanece
fora do aplicativo e do repositório.

Facebook utilizará o mesmo identificador Android/iOS, App ID público no
cliente e App Secret exclusivamente no backend. Sua implementação ocorrerá
depois de Google e Apple.

## 8. Pendências

- concluir a configuração de distribuição/testadores do consentimento Google;
- validar um ID token real de ponta a ponta;
- criar credenciais Android de release antes da publicação;
- implementar Sign in with Apple depois do fluxo Google aprovado.
