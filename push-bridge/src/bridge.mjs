import dns from 'node:dns';
import { applicationDefault, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

dns.setDefaultResultOrder('ipv4first');

const required = (name) => {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`Variavel obrigatoria ausente: ${name}`);
  return value;
};

const baseUrl = new URL(required('PUSH_BRIDGE_BASE_URL'));
const bridgeKey = required('PUSH_BRIDGE_KEY');
const pollMs = Math.max(
  1000,
  Number.parseInt(process.env.PUSH_BRIDGE_POLL_MS ?? '3000', 10) || 3000,
);

if (bridgeKey.length < 32) {
  throw new Error('PUSH_BRIDGE_KEY deve ter pelo menos 32 caracteres.');
}

if (getApps().length === 0) {
  initializeApp({ credential: applicationDefault() });
}

const messaging = getMessaging();
let stopping = false;

const wait = (milliseconds) =>
  new Promise((resolve) => setTimeout(resolve, milliseconds));

const bridgeRequest = async (path, body = {}) => {
  const response = await fetch(new URL(path, baseUrl), {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      'X-Push-Bridge-Key': bridgeKey,
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(60000),
  });
  const text = await response.text();
  let envelope;
  try {
    envelope = JSON.parse(text);
  } catch {
    throw new Error(`ORDS respondeu conteúdo inválido (${response.status}).`);
  }
  if (!response.ok || envelope.success !== true) {
    const message =
      envelope?.error?.message ?? `Falha no ORDS (${response.status}).`;
    throw new Error(message);
  }
  return envelope.data;
};

const stringData = (value) =>
  Object.fromEntries(
    Object.entries(value ?? {}).map(([key, item]) => [key, String(item)]),
  );

const channelFor = (type) =>
  type === 'SELLER_REQUEST'
    ? 'brecho_requests_urgent'
    : 'buyer_purchase_updates';

const invalidTokenCodes = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

const acknowledge = async (
  outboxPublicId,
  success,
  error = null,
  invalidTokens = [],
) =>
  bridgeRequest('notifications/bridge/ack', {
    outboxPublicId,
    success,
    error,
    invalidTokens,
  });

const send = async (message) => {
  const tokens = Array.isArray(message.tokens)
    ? message.tokens.filter((token) => typeof token === 'string' && token)
    : [];
  if (tokens.length === 0) {
    await acknowledge(
      message.outboxPublicId,
      false,
      'Nenhum dispositivo ativo para o perfil.',
    );
    return;
  }

  try {
    const result = await messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: message.title,
        body: message.body,
      },
      data: {
        ...stringData(message.data),
        type: message.type,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: channelFor(message.type),
          sound: 'default',
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            contentAvailable: true,
          },
        },
      },
    });

    const invalidTokens = [];
    const errors = [];
    result.responses.forEach((response, index) => {
      if (response.success) return;
      const code = response.error?.code ?? 'messaging/unknown-error';
      errors.push(code);
      if (invalidTokenCodes.has(code)) invalidTokens.push(tokens[index]);
    });

    const success = result.successCount > 0;
    await acknowledge(
      message.outboxPublicId,
      success,
      success ? null : errors.join(', '),
      invalidTokens,
    );
    const detail = `${result.successCount} entregue(s), ${result.failureCount} falha(s)`;
    console.log(`[push] ${message.type} ${message.outboxPublicId}: ${detail}`);
  } catch (error) {
    const detail =
      error instanceof Error
        ? [error.message, error.cause?.message].filter(Boolean).join(': ')
        : String(error);
    await acknowledge(message.outboxPublicId, false, detail);
    console.error(`[push] envio falhou: ${detail}`);
  }
};

const shutdown = () => {
  stopping = true;
};
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

console.log(`[push] ponte iniciada; consulta a cada ${pollMs} ms`);
while (!stopping) {
  try {
    const message = await bridgeRequest('notifications/bridge/claim');
    if (message) {
      await send(message);
      continue;
    }
  } catch (error) {
    const detail =
      error instanceof Error
        ? [error.message, error.cause?.message].filter(Boolean).join(': ')
        : String(error);
    console.error(`[push] ${detail}`);
  }
  await wait(pollMs);
}
console.log('[push] ponte finalizada');
