import http from 'node:http';
import http2 from 'node:http2';
import { randomBytes } from 'node:crypto';
import { readFile, mkdir, writeFile, rename } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';
import { authorized, validateDevice, verifyEnvelope, verifyAlert, notification, apnsJWT, hash } from './core.mjs';

// HTTPS termination must be configured at a reverse proxy. This listener binds localhost.
const port = Number(process.env.PORT ?? 8787);
const directory = resolve(process.env.KABAR_DATA_DIR ?? './data');
const maxGroups = Number(process.env.MAX_GROUPS ?? 20);
const maxDevices = 10;
const configuration = {
  key:await readFile(process.env.APNS_KEY_FILE ?? '', 'utf8'),
  keyId:process.env.APNS_KEY_ID, teamId:process.env.APNS_TEAM_ID,
};
if (!configuration.keyId || !configuration.teamId || !process.env.PUBLIC_URL?.startsWith('https://')) throw new Error('Configure APNS_KEY_FILE, APNS_KEY_ID, APNS_TEAM_ID and PUBLIC_URL');
const environment = process.env.APNS_ENV ?? 'development';
if (!['development','production'].includes(environment)) throw new Error('APNS_ENV must be development or production');
const apnsHost = environment==='production' ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com';
const apnsTopic = process.env.APNS_TOPIC ?? 'id.kabar.app';
await mkdir(directory,{recursive:true,mode:0o700});
const databasePath = join(directory,'devices.json');
let groups = {};
try { groups = JSON.parse(await readFile(databasePath,'utf8')); } catch (e) { if (e.code!=='ENOENT') throw e; }
let saveChain = Promise.resolve();
function save() {
  const snapshot = JSON.stringify(groups);
  saveChain = saveChain.catch(()=>{}).then(async()=> { const temp=databasePath+'.tmp';await writeFile(temp,snapshot,{mode:0o600});await rename(temp,databasePath); });
  return saveChain;
}
const workers = new Map(), messages = new Map(), rates = new Map();
let jwt = '', jwtAt = 0;
function token() { const now=Math.floor(Date.now()/1000); if (now-jwtAt>45*60 || !jwt) { jwt=apnsJWT(configuration,now);jwtAt=now; } return jwt; }
async function push(device,payload,collapseId) {
  return new Promise((accept,reject)=>{
    const client = http2.connect(apnsHost);
    client.on('error',reject);
    const request = client.request({':method':'POST',':path':'/3/device/'+device,authorization:'bearer '+token(),'apns-topic':apnsTopic,'apns-push-type':'alert','apns-priority':'10','apns-expiration':String(Math.floor(Date.now()/1000)+3600),'apns-collapse-id':collapseId});
    let status = 0, data = '';
    request.on('response',headers=>status=Number(headers[':status']));request.setEncoding('utf8');request.on('data',chunk=>data+=chunk);
    request.setTimeout(15000,()=>{request.close();client.close();reject(new Error('APNs timeout'));});
    request.on('error',reject);
    request.on('end',()=> { client.close(); if(status===200)accept('ok');else if(status===410 || (status===400 && /BadDeviceToken|DeviceTokenNotForTopic/.test(data)))accept('remove');else reject(new Error('APNs HTTP '+status)); });
    request.end(JSON.stringify(payload));
  });
}
async function consume(topic,group,message) {
  if (groups[topic]!==group || message.event!=='message' || typeof message.id!=='string' || !verifyEnvelope(message.message,group.publicKey)) return;
  if (group.recent?.includes(message.id)) return;
  const now=Date.now();
  for (const [device,registered] of Object.entries(group.devices)) { if(now-registered>14*24*3600*1000)delete group.devices[device]; }
  const alert=verifyAlert(message.message,message.title,group.publicKey);
  // Cached status at first registration should update the widget, without an old notification.
  if(alert && message.time*1000>=group.createdAt-2000) {
    const id=randomBytes(16).toString('hex');
    messages.set(id,{text:message.message,topic,expires:now+3600*1000});
    const payload=notification(topic,message.message,id);
    const delivered=group.delivered ??= {};
    const sent=delivered[message.id] ??= [];
    for(const device of Object.keys(group.devices)) {
      if(sent.includes(device))continue;
      const result=await push(device,payload,hash(topic).slice(0,64));
      if(result==='remove')delete group.devices[device];else sent.push(device);
      await save();
    }
    delete delivered[message.id];
  }
  group.cursor=message.id;group.recent=[...(group.recent ?? []),message.id].slice(-64);await save();
}
function watch(topic,group) {
  if(workers.has(topic))return;
  const controller=new AbortController();workers.set(topic,controller);
  (async()=>{
    let delay=1000;
    while(!controller.signal.aborted && groups[topic]===group && Object.keys(group.devices).length) {
      try {
        const since=group.cursor ?? 'latest';
        const response=await fetch('https://ntfy.sh/'+topic+'/json?since='+encodeURIComponent(since),{signal:controller.signal});
        if(response.status===400 && group.cursor){delete group.cursor;continue;}
        if(!response.ok)throw new Error('Relay HTTP '+response.status);
        let buffer='';
        for await(const chunk of response.body) {
          buffer+=Buffer.from(chunk).toString('utf8');
          if(buffer.length>32000)throw new Error('Oversized relay frame');
          let newline;
          while((newline=buffer.indexOf('\n'))>=0) {
            const line=buffer.slice(0,newline);buffer=buffer.slice(newline+1);
            let message;try{message=JSON.parse(line);}catch{continue;}
            await consume(topic,group,message);delay=1000;
          }
        }
      }catch(e){if(controller.signal.aborted)break;console.error('Notification connection will retry:',e.message);}
      await sleep(delay,undefined,{signal:controller.signal}).catch(()=>{});delay=Math.min(delay*2,60000);
    }
  })().catch(e=>console.error('Notification worker stopped:',e.message)).finally(()=>{if(workers.get(topic)===controller)workers.delete(topic);});
}
function rateLimit(ip) {
  const now=Date.now();let rate=rates.get(ip);
  if(!rate || now-rate.since>60000){rate={since:now,count:0};rates.set(ip,rate);}
  return ++rate.count<=30;
}
async function body(request) {
  let bytes=0,chunks=[];
  for await(const chunk of request){bytes+=chunk.length;if(bytes>4096)throw new Error('Request too large');chunks.push(chunk);}
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}
function reply(response,status,value) {response.writeHead(status,{'Content-Type':'application/json','Cache-Control':'no-store'});response.end(JSON.stringify(value));}
const server=http.createServer(async(request,response)=>{
  try {
    const ip=request.socket.remoteAddress;
    if(!rateLimit(ip)){reply(response,429,{error:'Rate limited'});return;}
    const path=new URL(request.url,'http://localhost').pathname;
    if(request.method==='GET' && path==='/health'){reply(response,200,{ok:true});return;}
    const capability=/^Bearer (.+)$/.exec(request.headers.authorization ?? '')?.[1];
    if(request.method==='GET' && /^\/messages\/[a-f0-9]{32}$/.test(path)) {
      const entry=messages.get(path.split('/').at(-1));const group=entry && groups[entry.topic];
      if(!entry || entry.expires<Date.now() || !group || !authorized(capability,group.capabilityHash)){reply(response,404,{error:'Unavailable'});return;}
      response.writeHead(200,{'Content-Type':'text/plain; charset=utf-8','Cache-Control':'no-store'});response.end(entry.text);return;
    }
    if(path!=='/devices' || !['POST','DELETE'].includes(request.method)){reply(response,404,{error:'Not found'});return;}
    const device=validateDevice(await body(request),capability);
    let group=groups[device.topic];
    if(group && (!authorized(capability,group.capabilityHash) || group.publicKey!==device.publicKey)){reply(response,403,{error:'Unauthorized'});return;}
    if(request.method==='DELETE') {
      if(group){delete group.devices[device.token];if(!Object.keys(group.devices).length){delete groups[device.topic];workers.get(device.topic)?.abort();}}
      await save();reply(response,200,{ok:true});return;
    }
    if(!group) {
      if(Object.keys(groups).length>=maxGroups){reply(response,503,{error:'Capacity reached'});return;}
      group={publicKey:device.publicKey,capabilityHash:device.capabilityHash,createdAt:Date.now(),devices:{}};groups[device.topic]=group;
    }
    if(!group.devices[device.token] && Object.keys(group.devices).length>=maxDevices){reply(response,409,{error:'Device limit reached'});return;}
    group.devices[device.token]=Date.now();await save();watch(device.topic,group);reply(response,200,{ok:true});
  }catch{reply(response,400,{error:'Invalid request'});}
});
server.requestTimeout=20000;server.headersTimeout=15000;server.listen(port,'127.0.0.1',()=>console.log('Kabar Apple bridge listening on localhost:'+port));
for(const [topic,group] of Object.entries(groups))watch(topic,group);
const cleanup=setInterval(()=>{const now=Date.now();for(const [id,e] of messages)if(e.expires<now)messages.delete(id);for(const [ip,r] of rates)if(now-r.since>60000)rates.delete(ip);},60000);
function shutdown(){clearInterval(cleanup);for(const worker of workers.values())worker.abort();server.close(()=>{saveChain.finally(()=>process.exit(0));});}
process.on('SIGINT',shutdown);process.on('SIGTERM',shutdown);
