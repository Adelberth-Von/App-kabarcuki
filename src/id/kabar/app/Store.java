package id.kabar.app;

import android.content.*;
import org.json.*;

public final class Store {
    public static final Object LOCK=new Object();
    public static android.content.SharedPreferences prefs(Context c) { return c.getSharedPreferences("kabar",Context.MODE_PRIVATE); }
    public static String role(Context c) { return prefs(c).getString("role",""); }
    public static KabarState state(Context c) {
        synchronized(LOCK) { try {return KabarState.parse(prefs(c).getString("state",""));}catch(Exception e){return new KabarState();} }
    }
    public static Pairing pairing(Context c) throws Exception {
        Pairing p=Pairing.parse(prefs(c).getString("code",""));
        if(role(c).equals("sender")) p=p.withPrivate(prefs(c).getString("private",""));
        return p;
    }
    public static int pending(Context c) {
        synchronized(LOCK) { try{return new JSONArray(prefs(c).getString("queue","[]")).length();}catch(Exception e){return 0;} }
    }
    public static void saveAndQueue(Context c,KabarState s,boolean notify) throws Exception {
        synchronized(LOCK) {
            JSONArray queue=new JSONArray(prefs(c).getString("queue","[]"));
            if(queue.length()>=25)throw new IllegalStateException("25 kabar masih menunggu. Hubungkan internet sebelum menambah kabar.");
            String body=new JSONObject().put("state",s.json()).put("notify",notify).toString();
            Pairing p=pairing(c);String encrypted=p.encrypt(body);
            // ntfy free relay's text body is capped at 4096 bytes.
            if(encrypted.getBytes(java.nio.charset.StandardCharsets.UTF_8).length>4096)throw new IllegalStateException("Kabar terlalu panjang. Pendekkan nama tombol.");
            queue.put(new JSONObject().put("revision",s.revision).put("body",encrypted).put("alertProof",notify?p.alertProof(encrypted):""));
            if(!prefs(c).edit().putString("state",s.json().toString()).putString("queue",queue.toString()).commit())throw new IllegalStateException("Penyimpanan penuh");
        }
        changed(c);
    }
    public static void changed(Context c) {
        Intent i=new Intent("id.kabar.app.CHANGED");i.setPackage(c.getPackageName());c.sendBroadcast(i);
        KabarWidget.updateAll(c);
    }
}
