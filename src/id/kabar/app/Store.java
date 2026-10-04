package id.kabar.app;

import android.content.*;
import org.json.*;

public final class Store {
    public static final Object LOCK=new Object();
    public static android.content.SharedPreferences prefs(Context c) { return c.getSharedPreferences("kabar",Context.MODE_PRIVATE); }
    public static String role(Context c) { return prefs(c).getString("role",""); }
    public static boolean isTwoWay(Context c){return role(c).equals("duplex");}
    public static boolean isDuplex(Context c){return isTwoWay(c);}
    public static boolean canSend(Context c){return role(c).equals("sender")||isTwoWay(c);}
    public static String mode(Context c){return isTwoWay(c)?"seirama":"oneWay";}
    public static KabarState selfState(Context c){return state(c);}
    public static KabarState peerState(Context c){
        synchronized(LOCK){if(!isTwoWay(c)||prefs(c).getString("peerCode","").isEmpty())return null;
            try{return KabarState.parse(prefs(c).getString("peerState",""));}catch(Exception ignored){return new KabarState();}}
    }
    public static Pairing incomingPairing(Context c)throws Exception {
        if(isTwoWay(c)){String code=prefs(c).getString("peerCode","");return code.isEmpty()?null:Pairing.parse(code);}
        return role(c).equals("receiver")?pairing(c):null;
    }
    public static String reciprocity(Context c){return !isTwoWay(c)?"none":prefs(c).getString("peerCode","").isEmpty()?"unlinked":prefs(c).getBoolean("peerRevoked",false)?"inactive":prefs(c).getBoolean("peerConfirmed",false)?"active":"waiting";}
    public static String session(Context c){return role(c)+":"+prefs(c).getString("code","")+":"+prefs(c).getString("peerCode","");}
    public static KabarState state(Context c) {
        synchronized(LOCK) { try {return KabarState.parse(prefs(c).getString("state",""));}catch(Exception e){return new KabarState();} }
    }
    public static Pairing pairing(Context c) throws Exception {
        Pairing p=Pairing.parse(prefs(c).getString("code",""));
        if(canSend(c)) p=p.withPrivate(prefs(c).getString("private",""));
        return p;
    }
    public static int pending(Context c) {
        synchronized(LOCK) { try{return new JSONArray(prefs(c).getString("queue","[]")).length();}catch(Exception e){return 0;} }
    }
    public static void saveAndQueue(Context c,KabarState s,boolean notify) throws Exception {
        synchronized(LOCK) {
            JSONArray queue=new JSONArray(prefs(c).getString("queue","[]"));
            if(queue.length()>=25)throw new IllegalStateException("25 kabar masih menunggu. Hubungkan internet sebelum menambah kabar.");
            s.fitRelay();
            if(!canSend(c))throw new SecurityException("Sender required");
            String body=Seirama.packet(s,notify,isTwoWay(c)?incomingPairing(c):null).toString();
            Pairing p=pairing(c);String encrypted=p.encrypt(body);
            // ntfy free relay's text body is capped at 4096 bytes.
            if(encrypted.getBytes(java.nio.charset.StandardCharsets.UTF_8).length>4096)throw new IllegalStateException("Kabar terlalu panjang. Pendekkan nama tombol.");
            queue.put(new JSONObject().put("revision",s.revision).put("body",encrypted).put("alertProof",notify?p.alertProof(encrypted):""));
            if(!prefs(c).edit().putString("state",s.json().toString()).putString("queue",queue.toString()).commit())throw new IllegalStateException("Penyimpanan penuh");
        }
        changed(c);
    }
    /** Incoming stream has its own replay counter and cannot write the local person's state. */
    public static boolean receive(Context c,JSONObject packet,String topic,String cursor)throws Exception {
        synchronized(LOCK){
            Pairing source=incomingPairing(c);if(source==null||!source.topic().equals(topic))return false;
            String stateKey=isTwoWay(c)?"peerState":"state";
            KabarState old=isTwoWay(c)?peerState(c):state(c);
            KabarState next=Seirama.next(packet,old);if(next==null)return false;
            android.content.SharedPreferences.Editor edit=prefs(c).edit().putString(stateKey,next.json().toString()).putString("cursor",cursor).putLong("receivedAt",System.currentTimeMillis()).putString("connection","Terhubung ke relay");
            if(isTwoWay(c))edit.putBoolean("peerConfirmed",Seirama.reciprocates(packet,pairing(c))).putBoolean("peerRevoked",packet.has("seirama")&&!packet.optBoolean("seirama",true));
            if(!edit.commit())throw new java.io.IOException("Penyimpanan penuh");return true;
        }
    }
    /** Signed shutdown messages can outlive the retired writer without retaining its private key. */
    public static void retire(Context c,Pairing writer,KabarState state)throws Exception {
        synchronized(LOCK){JSONArray q=new JSONArray(prefs(c).getString("retiredQueue","[]"));if(q.length()>=4)throw new IllegalStateException("Hubungkan internet sebelum menghentikan pasangan lainnya");
            KabarState next=KabarState.parse(state.json().toString());next.revision++;
            q.put(new JSONObject().put("topic",writer.topic()).put("body",writer.encrypt(Seirama.revocation(next).toString())));
            if(!prefs(c).edit().putString("retiredQueue",q.toString()).commit())throw new IllegalStateException("Penyimpanan penuh");}
    }
    public static void revokeOwn(Context c)throws Exception {
        synchronized(LOCK){KabarState state=state(c);state.revision++;JSONArray q=new JSONArray(prefs(c).getString("queue","[]"));if(q.length()>=25)throw new IllegalStateException("25 kabar masih menunggu");
            q.put(new JSONObject().put("revision",state.revision).put("body",pairing(c).encrypt(Seirama.revocation(state).toString())).put("alertProof",""));
            if(!prefs(c).edit().putString("state",state.json().toString()).putString("queue",q.toString()).commit())throw new IllegalStateException("Penyimpanan penuh");}
        changed(c);
    }
    public static void changed(Context c) {
        wakeSync();
        Intent i=new Intent("id.kabar.app.CHANGED");i.setPackage(c.getPackageName());c.sendBroadcast(i);
        KabarWidget.updateAll(c);
    }
    public static void wakeSync(){synchronized(LOCK){LOCK.notifyAll();}}
    public static void awaitOutgoing(Context c,long millis)throws InterruptedException {
        synchronized(LOCK){if(pending(c)==0)LOCK.wait(Math.max(1000,millis));}
    }
}
