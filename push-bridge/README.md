# Ponte de notificações do Brechó Express

Processo autohospedado que retira mensagens da fila Oracle e as envia pelo
Firebase Cloud Messaging. Não exige o plano Blaze do Firebase.

## Pré-requisitos

- Node.js 22 ou superior.
- Uma conta de serviço do projeto Firebase `brecho-express-162d9`.
- A API Oracle instalada por `database/install_push_bridge_feature.sql`.
- Uma chave com pelo menos 32 caracteres configurada no Oracle.

Nunca copie a conta de serviço para o repositório. Mantenha o JSON em uma
pasta privada fora do projeto.

## Execução

Defina as variáveis listadas em `.env.example`, execute `npm install --omit=optional` e depois
`npm start`. Enquanto o processo estiver ativo, ele consultará a fila a cada
três segundos.

Para interromper a demonstração, pressione `Ctrl+C`. As mensagens continuam
na fila Oracle e serão retomadas quando a ponte for iniciada novamente.
