import test from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPairSync, randomBytes, sign, verify, createECDH, createPublicKey, createHash } from 'node:crypto';
import { hash, authorized, validateDevice, verifyEnvelope, verifyAlert, notification, apnsJWT } from '../core.mjs';
const keys=generateKeyPairSync('ec',{namedCurve:'prime256v1'});
const publicKey=keys.publicKey.export({type:'spki',format:'der'}).toString('base64url');
const capability=randomBytes(32).toString('base64url');const topic='kabar-'+randomBytes(32).toString('base64url');
const signed='K1.'+randomBytes(12).toString('base64url')+'.'+randomBytes(50).toString('base64url');
const envelope=signed+'.'+sign('sha256',Buffer.from(signed),keys.privateKey).toString('base64url');
test('registration validates topic, P-256 key, token and capability',()=>{
  assert.equal(validateDevice({topic,publicKey,token:'a'.repeat(64)},capability).topic,topic);
  for(const change of [{topic:'public'},{token:'invalid'},{publicKey:'a'.repeat(100)}])assert.throws(()=>validateDevice({topic,publicKey,token:'a'.repeat(64),...change},capability));
});
test('capability authorization rejects a different family and missing token',()=>{
  assert.ok(authorized(capability,hash(capability)));assert.equal(authorized(randomBytes(32).toString('base64url'),hash(capability)),false);assert.equal(authorized('',hash(capability)),false);
});
test('server verifies sender without holding AES key',()=>{
  assert.ok(verifyEnvelope(envelope,publicKey));assert.equal(verifyEnvelope(envelope+'x',publicKey),false);
  assert.equal(verifyEnvelope(envelope.replace('K1.','K2.'),publicKey),false);assert.equal(verifyEnvelope('x'.repeat(9000),publicKey),false);
});
test('alert proof excludes silent snapshots and is bound to envelope',()=>{
  const proof='KB1.'+sign('sha256',Buffer.from('kabar-alert-v1:'+envelope),keys.privateKey).toString('base64url');
  assert.ok(verifyAlert(envelope,proof,publicKey));assert.equal(verifyAlert(envelope+'x',proof,publicKey),false);assert.equal(verifyAlert(envelope,'',publicKey),false);
});
test('APNs payload fits 4096 bytes and uses reference for large ciphertext',()=>{
  const a=notification(topic,envelope,'b'.repeat(32));assert.equal(a.envelope,envelope);assert.equal(a.aps['mutable-content'],1);assert.equal(a.aps.sound,'abc_chime.wav');
  const b=notification(topic,'x'.repeat(4096),'b'.repeat(32));assert.equal(b.envelope,undefined);assert.equal(b.messageId,'b'.repeat(32));assert.ok(Buffer.byteLength(JSON.stringify(b))<=4096);
});
test('APNs JWT uses ES256 raw 64-byte signature and correct claims',()=>{
  const jwt=apnsJWT({key:keys.privateKey,keyId:'TESTKEY',teamId:'TESTTEAM'},12345);const p=jwt.split('.');
  assert.equal(JSON.parse(Buffer.from(p[0],'base64url')).alg,'ES256');assert.deepEqual(JSON.parse(Buffer.from(p[1],'base64url')),{iss:'TESTTEAM',iat:12345});
  assert.equal(Buffer.from(p[2],'base64url').length,64);assert.ok(verify('sha256',Buffer.from(p.slice(0,2).join('.')),{key:keys.publicKey,dsaEncoding:'ieee-p1363'},Buffer.from(p[2],'base64url')));
});
test('short but valid DER integers are accepted, extra DER bytes are rejected',()=>{
  // Test-only ECDSA vector with nonce k=1 and s=1; production signing uses CryptoKit/JCA.
  const n=BigInt('0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551');
  const rHex='6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296';const r=BigInt('0x'+rHex);
  function pow(a,b){let result=1n;while(b){if(b&1n)result=result*a%n;a=a*a%n;b>>=1n;}return result;}
  function vector(text){
    const z=BigInt('0x'+createHash('sha256').update(text).digest('hex'));const d=((1n-z)%n+n)%n*pow(r,n-2n)%n;
    const ec=createECDH('prime256v1');ec.setPrivateKey(Buffer.from(d.toString(16).padStart(64,'0'),'hex'));
    const der=Buffer.concat([Buffer.from('3059301306072a8648ce3d020106082a8648ce3d030107034200','hex'),ec.getPublicKey()]);
    const signature=Buffer.from('30250220'+rHex+'020101','hex');
    assert.ok(verify('sha256',Buffer.from(text),createPublicKey({key:der,format:'der',type:'spki'}),signature));
    return {pub:der.toString('base64url'),sig:signature.toString('base64url')};
  }
  const a=vector(signed);const shortEnvelope=signed+'.'+a.sig;
  assert.ok(verifyEnvelope(shortEnvelope,a.pub));assert.equal(verifyEnvelope(shortEnvelope+'x',a.pub),false);
  const b=vector('kabar-alert-v1:'+shortEnvelope);assert.ok(verifyAlert(shortEnvelope,'KB1.'+b.sig,b.pub));
});
