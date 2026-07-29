import dns from 'node:dns';

dns.setDefaultResultOrder('ipv4first');

const baseUrl = process.env.PUSH_BRIDGE_BASE_URL;
const bridgeKey = process.env.PUSH_BRIDGE_KEY;
if (!baseUrl || !bridgeKey) {
  throw new Error('Configure PUSH_BRIDGE_BASE_URL e PUSH_BRIDGE_KEY.');
}

const response = await fetch(
  new URL('notifications/bridge/claim', baseUrl),
  {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      'X-Push-Bridge-Key': bridgeKey,
    },
    body: '{}',
    signal: AbortSignal.timeout(60000),
  },
);
console.log(`${response.status} ${await response.text()}`);
