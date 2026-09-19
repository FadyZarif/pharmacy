#!/usr/bin/env node
// Minimal App Store Connect API client. No dependencies: Node's crypto can
// produce the ES256 JWT Apple wants if we ask for raw r||s signatures.
//
//   ASC_ISSUER_ID=<uuid> node tool/asc.mjs GET '/v1/apps?limit=200'
//   ASC_ISSUER_ID=<uuid> node tool/asc.mjs POST /v1/bundleIds '{"data":{...}}'
//
// Key id and .p8 location default to the shared COWDLLY key.
import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';

const KEY_ID = process.env.ASC_KEY_ID || 'TAR9L6995V';
const ISSUER = process.env.ASC_ISSUER_ID;
const P8 = process.env.ASC_KEY_PATH ||
  `${homedir()}/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`;

if (!ISSUER) {
  console.error('ASC_ISSUER_ID is required (App Store Connect > Users and Access > Integrations).');
  process.exit(2);
}

const b64 = (o) => Buffer.from(typeof o === 'string' ? o : JSON.stringify(o))
  .toString('base64url');

function token() {
  const now = Math.floor(Date.now() / 1000);
  const body = `${b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })}.` +
    b64({ iss: ISSUER, iat: now, exp: now + 900, aud: 'appstoreconnect-v1' });
  const sig = createSign('SHA256').update(body).end()
    .sign({ key: readFileSync(P8), dsaEncoding: 'ieee-p1363' });
  return `${body}.${sig.toString('base64url')}`;
}

const [method = 'GET', path, payload] = process.argv.slice(2);
if (!path) { console.error('usage: asc.mjs <METHOD> <path> [json-body]'); process.exit(2); }

const res = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
  method,
  headers: {
    Authorization: `Bearer ${token()}`,
    ...(payload ? { 'Content-Type': 'application/json' } : {}),
  },
  ...(payload ? { body: payload } : {}),
});

const text = await res.text();
console.error(`HTTP ${res.status}`);
try { console.log(JSON.stringify(JSON.parse(text), null, 2)); }
catch { console.log(text); }
process.exit(res.ok ? 0 : 1);
