import { createHash, createPublicKey, sign, timingSafeEqual, verify } from 'node:crypto';
export const hash = text => createHash('sha256').update(text).digest('hex');
function strictSignature(text) {
  const data=Buffer.from(text,'base64url');
  if(data.toString('base64url')!==text || data.length<8 || data.length>72 || data[0]!==0x30 || data[1]!==data.length-2)throw new Error('Invalid DER signature');
  return data;
}
export function authorized(capability, expectedHash) {
  if (!/^[A-Za-z0-9_-]{43}$/.test(capability ?? '') || !/^[a-f0-9]{64}$/.test(expectedHash ?? '')) return false;
  return timingSafeEqual(Buffer.from(hash(capability)), Buffer.from(expectedHash));
}
export function validateDevice(body, capability) {
  if (!body || !/^kabar-[A-Za-z0-9_-]{43}$/.test(body.topic ?? '') || !/^[a-fA-F0-9]{32,256}$/.test(body.token ?? '') || !/^[A-Za-z0-9_-]{43}$/.test(capability ?? '') || !/^[A-Za-z0-9_-]{80,160}$/.test(body.publicKey ?? '')) throw new Error('Invalid registration');
  const key = createPublicKey({key: Buffer.from(body.publicKey,'base64url'), format:'der', type:'spki'});
  if (key.asymmetricKeyType !== 'ec' || key.asymmetricKeyDetails?.namedCurve !== 'prime256v1') throw new Error('P-256 required');
  return {topic:body.topic, token:body.token.toLowerCase(), publicKey:body.publicKey, capabilityHash:hash(capability)};
}
export function verifyEnvelope(envelope, publicDER) {
  try {
    if (typeof envelope !== 'string' || Buffer.byteLength(envelope)>8192) return false;
    const p = envelope.split('.');
    if (p.length!==4 || p[0]!=='K1' || !p.slice(1).every(x=>/^[A-Za-z0-9_-]+$/.test(x)) || Buffer.from(p[1],'base64url').length!==12 || Buffer.from(p[2],'base64url').length<16) return false;
    return verify('sha256',Buffer.from(p.slice(0,3).join('.')),createPublicKey({key:Buffer.from(publicDER,'base64url'),format:'der',type:'spki'}),strictSignature(p[3]));
  } catch { return false; }
}
export function verifyAlert(envelope, proof, publicDER) {
  try {
    if (!/^KB1\.[A-Za-z0-9_-]{11,96}$/.test(proof ?? '')) return false;
    return verify('sha256',Buffer.from('kabar-alert-v1:'+envelope),createPublicKey({key:Buffer.from(publicDER,'base64url'),format:'der',type:'spki'}),strictSignature(proof.slice(4)));
  } catch { return false; }
}
export function notification(topic,envelope,messageId) {
  const base = {aps:{alert:{title:'Kabar keluarga',body:'Ada kabar baru.'},sound:'abc_chime.wav','mutable-content':1},topic};
  const inline = {...base,envelope};
  if (Buffer.byteLength(JSON.stringify(inline))<=4096) return inline;
  return {...base,messageId};
}
export function apnsJWT({key,keyId,teamId},now = Math.floor(Date.now()/1000)) {
  const header = Buffer.from(JSON.stringify({alg:'ES256',kid:keyId})).toString('base64url');
  const claims = Buffer.from(JSON.stringify({iss:teamId,iat:now})).toString('base64url');
  const unsigned = header+'.'+claims;
  return unsigned+'.'+sign('sha256',Buffer.from(unsigned),{key,dsaEncoding:'ieee-p1363'}).toString('base64url');
}
