package id.kabar.app;

import android.app.*;
import android.content.*;
import android.content.pm.ServiceInfo;
import android.os.*;
import org.json.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;

public class SyncService extends Service {
    private volatile boolean running=false;
    private Thread worker;
    private volatile HttpURLConnection connection;
    private String session;
    public static void start(Context c) {
        if(!Store.role(c).isEmpty()&&Store.prefs(c).getBoolean("enabled",true))
            c.startForegroundService(new Intent(c,SyncService.class));
    }
    public static void stop(Context c) {
        c.startForegroundService(new Intent(c,SyncService.class).setAction("STOP").putExtra("stopSession",Store.prefs(c).getString("code","")));
    }
    @Override public void onCreate() {
        super.onCreate();channels(this);
        // Promote before checking a pause: startForegroundService may still be in flight.
        if(Build.VERSION.SDK_INT>=34)startForeground(1,persistent(),ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
        else startForeground(1,persistent());
    }
    @Override public IBinder onBind(Intent intent){return null;}
    @Override public int onStartCommand(Intent intent,int flags,int startId) {
        // Every pending start must be promoted, including a stop queued during startup.
        if(Build.VERSION.SDK_INT>=34)startForeground(1,persistent(),ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
        else startForeground(1,persistent());
        if(intent!=null&&"STOP".equals(intent.getAction())&&intent.getStringExtra("stopSession")!=null&&intent.getStringExtra("stopSession").equals(Store.prefs(this).getString("code",""))) {
            Store.prefs(this).edit().putBoolean("enabled",false).apply();stopSelf();return START_NOT_STICKY;
        }
        if(Store.role(this).isEmpty()||!Store.prefs(this).getBoolean("enabled",true)){stopSelf();return START_NOT_STICKY;}
        String nextSession=Store.prefs(this).getString("code","");
        if(running&&!nextSession.equals(session)) {
            running=false;if(connection!=null)connection.disconnect();if(worker!=null)worker.interrupt();
        }
        if(!running) {
            running=true;session=Store.prefs(this).getString("code","");
            worker=new Thread(()->runSync(),"KabarSync");worker.start();
        }
        return START_STICKY;
    }
    public static void channels(Context c) {
        NotificationManager nm=c.getSystemService(NotificationManager.class);
        nm.createNotificationChannel(new NotificationChannel("connection","Koneksi Kabar",NotificationManager.IMPORTANCE_LOW));
        nm.createNotificationChannel(new NotificationChannel("updates","Kabar keluarga",NotificationManager.IMPORTANCE_HIGH));
    }
    private Notification persistent() {
        PendingIntent open=PendingIntent.getActivity(this,0,AppEntry.open(this),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);
        PendingIntent stop=PendingIntent.getService(this,1,new Intent(this,SyncService.class).setAction("STOP").putExtra("stopSession",Store.prefs(this).getString("code","")),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);
        return new Notification.Builder(this,"connection").setSmallIcon(R.drawable.notification_icon).setContentTitle(LocalProfile.text(this,"abc aktif","abc is active","abc ist aktiv"))
            .setContentText(Store.role(this).equals("sender")?LocalProfile.text(this,"Siap mengirim kabar","Ready to send updates","Bereit für Updates"):LocalProfile.text(this,"Menunggu kabar","Waiting for updates","Warten auf Updates"))
            .setContentIntent(open).setOngoing(true).addAction(new Notification.Action.Builder(null,LocalProfile.text(this,"Jeda","Pause","Pausieren"),stop).build()).build();
    }
    private boolean current() {return running&&Thread.currentThread()==worker&&Store.prefs(this).getBoolean("enabled",true)&&session.equals(Store.prefs(this).getString("code",""));}
    private void status(String text) {
        synchronized(Store.LOCK) {
        if(!current())return;
        String previous=Store.prefs(this).getString("connection","");
        if(!text.equals(previous)) {
            Store.prefs(this).edit().putString("connection",text).putLong("checkedAt",System.currentTimeMillis()).apply();
            Store.changed(this);
        }
        }
    }
    private void runSync() {
        int failures=0;
        while(current()) {
            try {
                Pairing p=Store.pairing(this);
                if(Store.role(this).equals("sender")) sendLoop(p);else receive(p);
                failures=0;
            }catch(Exception e) {
                if(!current())break;
                status("Koneksi terputus · mencoba lagi");
                failures++;
                try{Thread.sleep(Math.min(60000,2000L*(1L<<Math.min(failures,5))));}catch(InterruptedException ignored){}
            }
        }
    }
    private void sendLoop(Pairing p) throws Exception {
        long heartbeat=Store.prefs(this).getLong("publishedAt",0);
        while(current()) {
            JSONObject item=null;
            synchronized(Store.LOCK) {
                JSONArray q=new JSONArray(Store.prefs(this).getString("queue","[]"));
                if(q.length()>0)item=q.getJSONObject(0);
            }
            if(item!=null) {
                status("Mengirim kabar…");
                Relay.publish(p.topic(),item.getString("body"),item.optString("alertProof",""));
                if(!current())return;
                synchronized(Store.LOCK) {
                    if(!current())return;
                    JSONArray q=new JSONArray(Store.prefs(this).getString("queue","[]")),next=new JSONArray();
                    if(q.length()>0&&q.getJSONObject(0).getLong("revision")==item.getLong("revision"))
                        for(int i=1;i<q.length();i++)next.put(q.getJSONObject(i));
                    else next=q;
                    Store.prefs(this).edit().putString("queue",next.toString()).putLong("publishedAt",System.currentTimeMillis()).commit();
                }
                heartbeat=System.currentTimeMillis();
                status("Kabar terkirim ke relay");Store.changed(this);
            }else if(System.currentTimeMillis()-heartbeat>4L*60*60*1000) {
                String body=new JSONObject().put("state",Store.state(this).json()).put("notify",false).toString();
                Relay.publish(p.topic(),p.encrypt(body));
                synchronized(Store.LOCK) {
                if(!current())return;
                heartbeat=System.currentTimeMillis();
                Store.prefs(this).edit().putLong("publishedAt",heartbeat).apply();
                status("Kabar terkirim ke relay");
                }
            }
            // Sleep until a new queued update, stop/session change, or the 4-hour refresh.
            Store.awaitOutgoing(this,Math.min(4L*60*60*1000,
                Math.max(1000,4L*60*60*1000-(System.currentTimeMillis()-heartbeat))));
        }
    }
    private void receive(Pairing p) throws Exception {
        String cursor=Store.prefs(this).getString("cursor","");
        String since=cursor.isEmpty()?"latest":cursor;
        HttpURLConnection active=Relay.open("/"+p.topic()+"/json?since="+URLEncoder.encode(since,"UTF-8"));
        connection=active;
        try {
            int code=active.getResponseCode();
            if(code==400&&!cursor.isEmpty()) {Store.prefs(this).edit().remove("cursor").apply();return;}
            if(code!=200)throw new IOException("Relay HTTP "+code);
            status("Terhubung ke relay");
            long started=System.currentTimeMillis();
            try(BufferedReader reader=new BufferedReader(new InputStreamReader(active.getInputStream(),StandardCharsets.UTF_8))) {
                String line;
                while(current()&&(line=reader.readLine())!=null) {
                    if(line.length()>9000)continue;
                    JSONObject message;
                    try{message=new JSONObject(line);}catch(JSONException bad){continue;}
                    if(!message.optString("event").equals("message"))continue;
                    try {
                        JSONObject packet=new JSONObject(p.decrypt(message.getString("message")));
                        KabarState next=KabarState.parse(packet.getJSONObject("state").toString());
                        boolean alreadyPaired;
                        synchronized(Store.LOCK) {
                            if(!current())return;
                            KabarState old=Store.state(this);
                            alreadyPaired=old.revision>0;
                            if(next.revision<=old.revision){Store.prefs(this).edit().putString("cursor",message.getString("id")).apply();continue;}
                            boolean saved=Store.prefs(this).edit().putString("state",next.json().toString()).putString("cursor",message.getString("id"))
                                .putLong("receivedAt",System.currentTimeMillis()).putString("connection","Terhubung ke relay").commit();
                            if(!saved)throw new IOException("Penyimpanan penuh");
                        }
                        Store.changed(this);
                        if(packet.optBoolean("notify") && (alreadyPaired||message.optLong("time")*1000>=started-2000))alert(next);
                    }catch(SecurityException|GeneralSecurityException|JSONException|IllegalArgumentException invalid) {
                        // Ignore unauthenticated, malformed, or incompatible messages.
                    }
                }
            }
            if(current())throw new IOException("Stream ditutup");
        }finally{active.disconnect();if(connection==active)connection=null;}
    }
    private void alert(KabarState s) {
        synchronized(Store.LOCK) {
        if(!current())return;
        if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)!=android.content.pm.PackageManager.PERMISSION_GRANTED)return;
        JSONObject last=s.events.optJSONObject(0);if(last==null)return;
        PendingIntent open=PendingIntent.getActivity(this,2,AppEntry.open(this),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);
        Notification n=new Notification.Builder(this,"updates").setSmallIcon(R.drawable.notification_icon)
            .setContentTitle(s.name+" · "+LocalProfile.label(this,last.optString("label")))
            .setContentText(LocalProfile.stamp(this,last.optLong("at")))
            .setContentIntent(open).setAutoCancel(true)
            .addExtras(alertData(s.name,last.optString("label"),last.optLong("at"))).build();
        getSystemService(NotificationManager.class).notify(2,n);
        }
    }
    private static Bundle alertData(String name,String label,long at){
        Bundle b=new Bundle();b.putString("abcName",name);b.putString("abcLabel",label);b.putLong("abcAt",at);return b;
    }
    public static void refreshNotifications(Context c) {
        java.util.TimeZone.setDefault(null);
        NotificationManager nm=c.getSystemService(NotificationManager.class);
        for(android.service.notification.StatusBarNotification delivered:nm.getActiveNotifications()) {
            Notification old=delivered.getNotification();
            Notification.Builder b=Notification.Builder.recoverBuilder(c,old)
                .setOnlyAlertOnce(true).setSound(null).setVibrate(null).setDefaults(0);
            if(delivered.getId()==2) {
                Bundle data=old.extras;
                if(data.containsKey("abcAt"))data=alertData(data.getString("abcName",""),data.getString("abcLabel",""),data.getLong("abcAt"));
                else {
                    KabarState s=Store.state(c);JSONObject last=s.events.optJSONObject(0);
                    if(last==null)continue;data=alertData(s.name,last.optString("label"),last.optLong("at"));
                }
                b.setContentTitle(data.getString("abcName","")+" · "+LocalProfile.label(c,data.getString("abcLabel","")))
                    .setContentText(LocalProfile.stamp(c,data.getLong("abcAt"))).addExtras(data);
            } else if(delivered.getId()==1) {
                b.setContentTitle(LocalProfile.text(c,"abc aktif","abc is active","abc ist aktiv"))
                    .setContentText(Store.role(c).equals("sender")?LocalProfile.text(c,"Siap mengirim kabar","Ready to send updates","Bereit für Updates"):LocalProfile.text(c,"Menunggu kabar","Waiting for updates","Warten auf Updates"));
            } else continue;
            nm.notify(delivered.getTag(),delivered.getId(),b.build());
        }
    }
    @Override public void onDestroy() {
        running=false;if(connection!=null)connection.disconnect();if(worker!=null)worker.interrupt();
        Store.wakeSync();
        if(!Store.role(this).isEmpty())Store.prefs(this).edit().putString("connection","Koneksi dijeda · buka aplikasi untuk melanjutkan").apply();
        Store.changed(this);super.onDestroy();
    }
}
