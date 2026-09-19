#!/usr/bin/env node
// Uploads App Store screenshots. Apple's flow is reserve -> PUT parts -> commit,
// so it cannot be done with a single request like the rest of the metadata.
//
//   ASC_ISSUER_ID=<uuid> node tool/asc_screenshots.mjs <versionLocalizationId> <file...>
import { createSign } from 'node:crypto';
import { readFileSync, statSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { homedir } from 'node:os';
import { basename } from 'node:path';

const KEY_ID = process.env.ASC_KEY_ID || 'TAR9L6995V';
const ISSUER = process.env.ASC_ISSUER_ID;
const P8 = `${homedir()}/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`;
const DISPLAY_TYPE = process.env.ASC_DISPLAY_TYPE || 'APP_IPHONE_67';

const b64 = (o) => Buffer.from(typeof o === 'string' ? o : JSON.stringify(o)).toString('base64url');
function token() {
  const now = Math.floor(Date.now() / 1000);
  const body = `${b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })}.` +
    b64({ iss: ISSUER, iat: now, exp: now + 900, aud: 'appstoreconnect-v1' });
  const sig = createSign('SHA256').update(body).end()
    .sign({ key: readFileSync(P8), dsaEncoding: 'ieee-p1363' });
  return `${body}.${sig.toString('base64url')}`;
}

async function api(method, path, body) {
  const res = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    method,
    headers: { Authorization: `Bearer ${token()}`, ...(body ? { 'Content-Type': 'application/json' } : {}) },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status}\n${text}`);
  return text ? JSON.parse(text) : null;
}

const [locId, ...files] = process.argv.slice(2);
if (!locId || !files.length) { console.error('usage: asc_screenshots.mjs <versionLocalizationId> <file...>'); process.exit(2); }

// Reuse the set if a previous run already made one for this display type.
const sets = await api('GET', `/v1/appStoreVersionLocalizations/${locId}/appScreenshotSets`);
let set = sets.data.find((s) => s.attributes.screenshotDisplayType === DISPLAY_TYPE);
if (!set) {
  set = (await api('POST', '/v1/appScreenshotSets', {
    data: {
      type: 'appScreenshotSets',
      attributes: { screenshotDisplayType: DISPLAY_TYPE },
      relationships: { appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: locId } } },
    },
  })).data;
  console.log(`created ${DISPLAY_TYPE} set ${set.id}`);
} else {
  console.log(`using existing ${DISPLAY_TYPE} set ${set.id}`);
}

for (const file of files) {
  const bytes = readFileSync(file);
  const reserved = (await api('POST', '/v1/appScreenshots', {
    data: {
      type: 'appScreenshots',
      attributes: { fileSize: statSync(file).size, fileName: basename(file) },
      relationships: { appScreenshotSet: { data: { type: 'appScreenshotSets', id: set.id } } },
    },
  })).data;

  for (const op of reserved.attributes.uploadOperations) {
    const headers = Object.fromEntries((op.requestHeaders || []).map((h) => [h.name, h.value]));
    const res = await fetch(op.url, { method: op.method, headers, body: bytes.subarray(op.offset, op.offset + op.length) });
    if (!res.ok) throw new Error(`upload part failed ${res.status} ${await res.text()}`);
  }

  const done = await api('PATCH', `/v1/appScreenshots/${reserved.id}`, {
    data: {
      type: 'appScreenshots',
      id: reserved.id,
      attributes: { uploaded: true, sourceFileChecksum: createHash('md5').update(bytes).digest('hex') },
    },
  });
  console.log(`${basename(file)}  ${done.data.attributes.assetDeliveryState?.state ?? 'UPLOADED'}`);
}
