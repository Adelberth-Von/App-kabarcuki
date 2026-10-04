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
    public static final String UPDATES_CHANNEL="updates_pixel_v1";
    private static volatile SyncService live;
    private volatile boolean running=false;
    private Thread worker, incomingWorker;
    private volatile HttpURLConnection connection,outgoingConnection;
    private String session;
    private final BroadcastReceiver widgetPower=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent i){KabarWidget.updateAll(c);}};
    public static void start(Context c) {
        if(!Store.role(c).isEmpty()&&Store.prefs(c).getBoolean("enabled",true))
            c.startForegroundService(new Intent(c,SyncService.class));
    }
    public static void stop(Context c) {
        c.startForegroundService(new Intent(c,SyncService.class).setAction("STOP").putExtra("stopSession",Store.prefs(c).getString("code","")));
    }
    /** Stop foreground ownership on the service's main thread before deleting preferences. */
    public static void stopForRemoval(Context c)throws IOException {
        java.util.concurrent.CountDownLatch done=new java.util.concurrent.CountDownLatch(1);
        Runnable remove=()->{try{SyncService service=live;if(service!=null)service.stopRuntime();c.stopService(new Intent(c,SyncService.class));c.getSystemService(NotificationManager.class).cancelAll();}finally{done.countDown();}};
        if(Looper.myLooper()==Looper.getMainLooper())remove.run();
        else {
            if(!new Handler(Looper.getMainLooper()).post(remove))throw new IOException("Cannot stop application service");
            try{if(!done.await(5,java.util.concurrent.TimeUnit.SECONDS))throw new IOException("Application service did not stop");}catch(InterruptedException e){Thread.currentThread().interrupt();throw new IOException("Application cleanup interrupted",e);}
        }
    }
    private void promote() {
        if(Build.VERSION.SDK_INT>=34)startForeground(1,persistent(),ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE);
        else startForeground(1,persistent());
    }
    private void stopRuntime() {
        running=false;if(connection!=null)connection.disconnect();if(outgoingConnection!=null)outgoingConnection.disconnect();if(worker!=null)worker.interrupt();if(incomingWorker!=null)incomingWorker.interrupt();
        Store.wakeSync();stopForeground(STOP_FOREGROUND_REMOVE);
    }
    @Override public void onCreate() {
        super.onCreate();live=this;channels(this);
        IntentFilter power=new IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED);
        if(Build.VERSION.SDK_INT>=33)registerReceiver(widgetPower,power,Context.RECEIVER_NOT_EXPORTED);else registerReceiver(widgetPower,power);
        // Promote before checking a pause: startForegroundService may still be in flight.
        promote();
    }
    @Override public IBinder onBind(Intent intent){return null;}
    @Override public int onStartCommand(Intent intent,int flags,int startId) {
        // Every pending start must be promoted, including a stop queued during startup.
        promote();
        if(intent!=null&&"STOP".equals(intent.getAction())&&intent.getStringExtra("stopSession")!=null&&intent.getStringExtra("stopSession").equals(Store.prefs(this).getString("code",""))) {
            Store.prefs(this).edit().putBoolean("enabled",false).apply();stopRuntime();stopSelf();return START_NOT_STICKY;
        }
        if(Store.role(this).isEmpty()||!Store.prefs(this).getBoolean("enabled",true)){stopRuntime();stopSelf();return START_NOT_STICKY;}
        String nextSession=Store.session(this);
        if(running&&!nextSession.equals(session)) {
            running=false;if(connection!=null)connection.disconnect();if(outgoingConnection!=null)outgoingConnection.disconnect();if(worker!=null)worker.interrupt();if(incomingWorker!=null)incomingWorker.interrupt();incomingWorker=null;
        }
        if(!running) {
            running=true;session=Store.session(this);
            boolean outgoing=Store.canSend(this);
            worker=new Thread(()->runSync(!outgoing),"KabarSync");worker.start();
            if(outgoing&&Store.isTwoWay(this)&&!Store.prefs(this).getString("peerCode","").isEmpty()){incomingWorker=new Thread(()->runSync(true),"KabarPeerSync");incomingWorker.start();}
        }
        return START_STICKY;
    }
    public static void channels(Context c) {
        NotificationManager nm=c.getSystemService(NotificationManager.class);
        nm.createNotificationChannel(new NotificationChannel("connection","Koneksi Kabar",NotificationManager.IMPORTANCE_LOW));
        NotificationChannel previous=nm.getNotificationChannel("updates");
        NotificationChannel updates=new NotificationChannel(UPDATES_CHANNEL,LocalProfile.text(c,"Kabar · nada pixel","Updates · pixel chime","Updates · Pixelton"),previous==null?NotificationManager.IMPORTANCE_HIGH:previous.getImportance());
        updates.setDescription(LocalProfile.text(c,"Suara singkat untuk kabar baru dari pasangan perangkat.","A short chime for new updates from your paired device.","Ein kurzer Ton für neue Updates vom verbundenen Gerät."));
        android.media.AudioAttributes audio=new android.media.AudioAttributes.Builder().setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION).setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION).build();
        // Use the stable resource name, not its generated integer ID, across upgrades.
        android.net.Uri sound=android.net.Uri.parse("android.resource://"+c.getPackageName()+"/raw/abc_chime");
        if(previous!=null&&(previous.getSound()==null||(Build.VERSION.SDK_INT>=30&&previous.hasUserSetSound())))sound=previous.getSound();
        updates.setSound(sound,audio);
        if(previous!=null){updates.enableVibration(previous.shouldVibrate());updates.setVibrationPattern(previous.getVibrationPattern());}
        updates.setLockscreenVisibility(Notification.VISIBILITY_PRIVATE);
        nm.createNotificationChannel(updates);
    }
    private Notification persistent() {
        PendingIntent open=PendingIntent.getActivity(this,0,AppEntry.open(this),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);
        PendingIntent stop=PendingIntent.getService(this,1,new Intent(this,SyncService.class).setAction("STOP").putExtra("stopSession",Store.prefs(this).getString("code","")),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);
        return new Notification.Builder(this,"connection").setSmallIcon(R.drawable.notification_icon).setContentTitle(LocalProfile.text(this,"abc aktif","abc is active","abc ist aktiv"))
            .setContentText(Store.isTwoWay(this)?LocalProfile.text(this,"Saling berbagi kabar","Sharing updates both ways","Updates in beide Richtungen"):Store.canSend(this)?LocalProfile.text(this,"Siap mengirim kabar","Ready to send updates","Bereit für Updates"):LocalProfile.text(this,"Menunggu kabar","Waiting for updates","Warten auf Updates"))
            .setContentIntent(open).setOngoing(true).addAction(new Notification.Action.Builder(null,LocalProfile.text(this,"Jeda","Pause","Pausieren"),stop).build()).build();
    }
    private boolean current() {return running&&(Thread.currentThread()==worker||Thread.currentThread()==incomingWorker)&&Store.prefs(this).getBoolean("enabled",true)&&session.equals(Store.session(this));}
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
    private void runSync(boolean incoming) {
        int failures=0;
        while(current()) {
            try {
                if(Thread.currentThread()==worker)drainRetired();
                Pairing p=incoming?Store.incomingPairing(this):Store.pairing(this);
                if(p==null)return;
                if(incoming)receive(p);else sendLoop(p);
                failures=0;
            }catch(Exception e) {
                if(!current())break;
                status("Koneksi terputus · mencoba lagi");
                failures++;
                try{Thread.sleep(Math.min(60000,2000L*(1L<<Math.min(failures,5))));}catch(InterruptedException ignored){}
            }
        }
    }
    private void publish(String topic,String body,String proof)throws IOException {
        Relay.publish(topic,body,proof,new Relay.PublishControl(){
            @Override public boolean open(HttpURLConnection active){synchronized(Store.LOCK){if(!current())return false;outgoingConnection=active;return true;}}
            @Override public void close(HttpURLConnection active){if(outgoingConnection==active)outgoingConnection=null;}
        });
    }
    private void drainRetired()throws Exception {
        while(current()){
            JSONObject item;synchronized(Store.LOCK){JSONArray q=new JSONArray(Store.prefs(this).getString("retiredQueue","[]"));if(q.length()==0)return;item=q.getJSONObject(0);}
            publish(item.getString("topic"),item.getString("body"),"");
            synchronized(Store.LOCK){if(!current())return;JSONArray q=new JSONArray(Store.prefs(this).getString("retiredQueue","[]")),next=new JSONArray();if(q.length()>0&&q.getJSONObject(0).getString("body").equals(item.getString("body"))){for(int i=1;i<q.length();i++)next.put(q.getJSONObject(i));Store.prefs(this).edit().putString("retiredQueue",next.toString()).commit();}}
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
                publish(p.topic(),item.getString("body"),item.optString("alertProof",""));
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
                String body=Seirama.packet(Store.state(this),false,Store.isTwoWay(this)?Store.incomingPairing(this):null).toString();
                publish(p.topic(),p.encrypt(body),"");
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
                            KabarState old=Store.isTwoWay(this)?Store.peerState(this):Store.state(this);
                            alreadyPaired=old!=null&&old.revision>0;
                            if(!Store.receive(this,packet,p.topic(),message.getString("id"))){Store.prefs(this).edit().putString("cursor",message.getString("id")).apply();continue;}
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
        PendingIntent open=PendingIntent.getActivity(this,2,AppEntry.open(this).putExtra("showPeer",Store.isTwoWay(this)),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);
        Notification n=new Notification.Builder(this,UPDATES_CHANNEL).setSmallIcon(R.drawable.notification_icon)
            .setContentTitle(s.name+" · "+LocalProfile.label(this,last.optString("label")))
            .setContentText(LocalProfile.stamp(this,last.optLong("at")))
            .setContentIntent(open).setAutoCancel(true)
            .setLargeIcon(KabarWidget.art(this,s,0)).setColor(new Appearance(Store.isTwoWay(this),new Appearance(this).dark).accent)
            .setStyle(new Notification.BigTextStyle().bigText(notificationDetail(this,last)))
            .setCategory(Notification.CATEGORY_SOCIAL).setVisibility(Notification.VISIBILITY_PRIVATE)
            .setSubText(Store.isTwoWay(this)?"Seirama":"abc")
            .addAction(new Notification.Action.Builder(null,LocalProfile.text(this,"Lihat kabar","View update","Update ansehen"),open).build())
            .addExtras(alertData(s.name,last.optString("label"),last.optLong("at"),last.optJSONObject("gps")==null?"":last.optJSONObject("gps").optString("city"))).build();
        getSystemService(NotificationManager.class).notify(2,n);
        }
    }
    private static Bundle alertData(String name,String label,long at){
        return alertData(name,label,at,"");
    }
    private static Bundle alertData(String name,String label,long at,String city){
        Bundle b=new Bundle();b.putString("abcName",name);b.putString("abcLabel",label);b.putLong("abcAt",at);b.putString("abcCity",city);return b;
    }
    private static String notificationDetail(Context c,JSONObject e){
        String text=LocalProfile.label(c,e.optString("label"))+"\n"+LocalProfile.stamp(c,e.optLong("at"));
        JSONObject gps=e.optJSONObject("gps");if(gps!=null&&!gps.optString("city").isEmpty())text+="\n"+LocalProfile.text(c,"Lokasi terakhir · ","Last location · ","Letzter Standort · ")+gps.optString("city");
        return text;
    }
    public static void refreshNotifications(Context c) {
        java.util.TimeZone.setDefault(null);
        NotificationManager nm=c.getSystemService(NotificationManager.class);
        synchronized(Store.LOCK) {
        if(Store.role(c).isEmpty())return;
        for(android.service.notification.StatusBarNotification delivered:nm.getActiveNotifications()) {
            Notification old=delivered.getNotification();
            Notification.Builder b=Notification.Builder.recoverBuilder(c,old)
                .setOnlyAlertOnce(true).setSound(null).setVibrate(null).setDefaults(0);
            if(delivered.getId()==2) {
                Bundle data=old.extras;
                if(data.containsKey("abcAt"))data=alertData(data.getString("abcName",""),data.getString("abcLabel",""),data.getLong("abcAt"),data.getString("abcCity",""));
                else {
                    KabarState s=Store.state(c);JSONObject last=s.events.optJSONObject(0);
                    if(last==null)continue;data=alertData(s.name,last.optString("label"),last.optLong("at"));
                }
                b.setContentTitle(data.getString("abcName","")+" · "+LocalProfile.label(c,data.getString("abcLabel","")))
                    .setContentText(LocalProfile.stamp(c,data.getLong("abcAt"))).addExtras(data);
                String expanded=LocalProfile.label(c,data.getString("abcLabel",""))+"\n"+LocalProfile.stamp(c,data.getLong("abcAt"));
                if(!data.getString("abcCity","").isEmpty())expanded+="\n"+LocalProfile.text(c,"Lokasi terakhir · ","Last location · ","Letzter Standort · ")+data.getString("abcCity");
                b.setStyle(new Notification.BigTextStyle().bigText(expanded)).setSubText(Store.isTwoWay(c)?"Seirama":"abc").setColor(new Appearance(Store.isTwoWay(c),new Appearance(c).dark).accent);
            } else if(delivered.getId()==1) {
                // NotificationManager must never recreate an orphan FGS notification.
                // Only its live service may update foreground ownership.
                SyncService service=live;
                if(service!=null&&service.running&&Store.prefs(c).getBoolean("enabled",true))service.promote();
                continue;
            } else continue;
            nm.notify(delivered.getTag(),delivered.getId(),b.build());
        }
        }
    }
    @Override public void onDestroy() {
        unregisterReceiver(widgetPower);
        stopRuntime();if(live==this)live=null;
        if(!Store.role(this).isEmpty())Store.prefs(this).edit().putString("connection","Koneksi dijeda · buka aplikasi untuk melanjutkan").apply();
        Store.changed(this);super.onDestroy();
    }
}
