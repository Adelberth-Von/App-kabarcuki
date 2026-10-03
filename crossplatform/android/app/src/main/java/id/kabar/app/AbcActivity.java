package id.kabar.app;

import android.Manifest;
import android.appwidget.AppWidgetManager;
import android.content.*;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.*;
import android.provider.Settings;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.*;
import org.json.*;
import java.util.*;
import java.util.concurrent.*;

/** Native capabilities behind the shared Flutter interface. No GPS collection in background. */
public final class AbcActivity extends FlutterActivity {
    private final ExecutorService io=Executors.newSingleThreadExecutor();
    private final Handler main=new Handler(Looper.getMainLooper());
    private LocationCapture capture;
    private Runnable permitted;
    private String quickAction="";
    @Override public void configureFlutterEngine(FlutterEngine engine){
        super.configureFlutterEngine(engine);
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(),"abc/native").setMethodCallHandler(this::handle);
        quickAction=getIntent().getStringExtra("quickAction");
        SyncService.start(this);
    }
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);quickAction=intent.getStringExtra("quickAction");}
    @Override protected void onPause(){super.onPause();if(capture!=null)capture.cancel();}
    @Override protected void onDestroy(){if(capture!=null)capture.cancel();io.shutdown();super.onDestroy();}
    private interface Job{JSONObject run()throws Exception;}
    private void background(MethodChannel.Result result,Job job){io.execute(()->{try{String value=job.run().toString();main.post(()->result.success(value));}catch(Exception e){main.post(()->fail(result,e));}});}
    private void fail(MethodChannel.Result result,Exception e){String code=e.getMessage()!=null&&e.getMessage().contains("25 kabar")?"queue_full":"error";result.error(code,"Action could not be completed",null);}
    private JSONObject answer(String note)throws Exception{JSONObject j=new JSONObject().put("snapshot",snapshot());if(note!=null&&!note.isEmpty())j.put("note",note);return j;}
    private boolean isSender(){return "sender".equals(Store.role(this));}
    private void requireSender(){if(!isSender())throw new SecurityException("Sender required");}
    private JSONObject snapshot()throws Exception{
        TimeZone.setDefault(null);TimeZone z=TimeZone.getDefault();long now=System.currentTimeMillis();
        KabarState s=Store.state(this);JSONObject state=s.json();
        // Historical daylight saving is resolved separately for every timestamp.
        JSONObject localTimes=new JSONObject();
        for(String field:new String[]{"locationAt","homeAt","mealAt","breakfastAt","lunchAt","dinnerAt"}){long at=state.optLong(field);if(at>0)localTimes.put(Long.toString(at),LocalProfile.zone(this,z,at,false));}
        for(int i=0;i<state.getJSONArray("events").length();i++){
            JSONObject e=state.getJSONArray("events").getJSONObject(i);long at=e.getLong("at");
            localTimes.put(Long.toString(at),LocalProfile.zone(this,z,at,false));
            e.put("originInfo",LocalProfile.zone(this,TimeZone.getTimeZone(e.optString("zone",s.zone)),at,true));
            if(e.optJSONObject("gps")!=null){long g=e.getJSONObject("gps").getLong("at");localTimes.put(Long.toString(g),LocalProfile.zone(this,z,g,false));}
        }
        if(s.gps!=null)localTimes.put(Long.toString(s.gps.at),LocalProfile.zone(this,z,s.gps.at,false));
        SharedPreferences pref=LocalProfile.prefs(this);
        JSONObject profile=new JSONObject().put("nickname",pref.getString("nickname","")).put("language",LocalProfile.language(this)).put("dark",pref.getBoolean("dark",false)).put("relationship",pref.getBoolean("relationship",false)).put("clock12",pref.getBoolean("clock12",false));
        String old=Store.prefs(this).getString("connection","");boolean enabled=Store.prefs(this).getBoolean("enabled",true);
        String connection=!enabled?"paused":old.startsWith("Terhubung")?"online":old.startsWith("Kabar terkirim")?"sent":old.startsWith("Mengirim")?"sending":old.contains("terputus")?"offline":"connecting";
        JSONObject j=new JSONObject().put("state",state).put("profile",profile).put("role",Store.role(this)).put("enabled",enabled).put("pending",Store.pending(this)).put("connection",connection).put("shareLocation",Store.prefs(this).getBoolean("shareLocation",false)).put("zone",LocalProfile.zone(this,z,now,false)).put("localTimes",localTimes).put("platform","android").put("mealsToday",new JSONArray(Arrays.asList(s.hasMealToday("Sarapan",now),s.hasMealToday("Makan siang",now),s.hasMealToday("Makan malam",now))));
        if(quickAction!=null&&!quickAction.isEmpty()){j.put("quickAction",quickAction);quickAction="";}
        return j;
    }
    @SuppressWarnings("unchecked") private void handle(MethodCall call,MethodChannel.Result result){
        try {
            Map<String,Object> args=call.arguments instanceof Map?(Map<String,Object>)call.arguments:Collections.emptyMap();
            switch(call.method){
            case "snapshot":result.success(snapshot().toString());return;
            case "preferences":{
                SharedPreferences.Editor e=LocalProfile.prefs(this).edit();
                if(args.containsKey("nickname")){String v=(String)args.get("nickname");if(!LocalProfile.validName(v)){result.error("invalid_name","Invalid nickname",null);return;}e.putString("nickname",v.trim());}
                if(args.containsKey("language")){String v=(String)args.get("language");if(!Arrays.asList("id","en","de").contains(v))throw new IllegalArgumentException();e.putString("language",v);}
                for(String k:new String[]{"dark","relationship","clock12"})if(args.containsKey(k))e.putBoolean(k,Boolean.TRUE.equals(args.get(k)));
                if(!e.commit())throw new IllegalStateException();KabarWidget.updateAll(this);result.success(answer(null).toString());return;
            }
            case "setupSender":background(result,()->{
                if(!Store.role(this).isEmpty())throw new IllegalStateException();Pairing p=Pairing.create();KabarState s=new KabarState();s.name=LocalProfile.prefs(this).getString("nickname","Aku");s.revision=1;
                Store.prefs(this).edit().clear().putString("role","sender").putString("code",p.code()).putString("private",Pairing.encode(p.privateKey.getEncoded())).putBoolean("enabled",true).commit();
                Store.saveAndQueue(this,s,false);main.post(()->SyncService.start(this));return answer(null);
            });return;
            case "setupReceiver":{
                Pairing p;try{p=Pairing.parse((String)args.get("code"));}catch(Exception e){result.error("invalid_code","Invalid pairing code",null);return;}
                if(!Store.role(this).isEmpty())throw new IllegalStateException();Store.prefs(this).edit().clear().putString("role","receiver").putString("code",p.code()).putBoolean("enabled",true).commit();SyncService.start(this);Store.changed(this);requestAlerts();result.success(answer(null).toString());return;
            }
            case "record":{
                requireSender();if(Store.pending(this)>=25){result.error("queue_full","Queue full",null);return;}
                String kind=(String)args.getOrDefault("kind","");String category=(String)args.get("category");boolean share=Boolean.TRUE.equals(args.get("shareLocation"));String session=Store.prefs(this).getString("code","");
                Store.prefs(this).edit().putBoolean("shareLocation",share).apply();
                LocationCapture.Result save=(point,message)->{capture=null;background(result,()->{
                    if(!isSender()||!session.equals(Store.prefs(this).getString("code","")))throw new SecurityException();
                    if(kind.isEmpty()&&point==null)return answer("locationFailed");
                    synchronized(Store.LOCK){KabarState s=Store.state(this);s.zone=TimeZone.getDefault().getID();if(kind.isEmpty()){s.gps=point;s.revision++;}else s.record(kind,System.currentTimeMillis(),category,point);Store.saveAndQueue(this,s,!kind.isEmpty());}
                    return answer(share&&point==null?"locationFailed":null);
                });};
                if(!share){save.done(null,"");return;}
                if(LocationCapture.allowed(this)){capture=LocationCapture.start(this,save);return;}
                permitted=()->{if(LocationCapture.allowed(this))capture=LocationCapture.start(this,save);else save.done(null,"denied");};
                requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION},44);return;
            }
            case "edit":background(result,()->{requireSender();synchronized(Store.LOCK){KabarState s=Store.state(this);for(String k:new String[]{"name","outside","home","meal"})if(args.containsKey(k)){String v=(String)args.get(k);if(!LocalProfile.validName(v))throw new IllegalArgumentException();switch(k){case "name":s.name=v.trim();break;case "outside":s.outside=v.trim();break;case "home":s.home=v.trim();break;case "meal":s.meal=v.trim();}}
                if(args.containsKey("windows")){List<Number> list=(List<Number>)args.get("windows");int[] windows=new int[list.size()];for(int i=0;i<windows.length;i++)windows[i]=list.get(i).intValue();if(!StatusLogic.validWindows(windows))throw new IllegalArgumentException();s.windows=windows;}
                s.revision++;Store.saveAndQueue(this,s,false);}return answer(null);});return;
            case "pairCode":requireSender();result.success(new JSONObject().put("code",Store.pairing(this).code()).toString());return;
            case "shareCode":requireSender();startActivity(Intent.createChooser(new Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT,Store.pairing(this).code()),"abc"));break;
            case "openMap":{
                double lat=((Number)args.get("lat")).doubleValue(),lon=((Number)args.get("lon")).doubleValue();if(!Double.isFinite(lat)||!Double.isFinite(lon)||Math.abs(lat)>90||Math.abs(lon)>180)throw new IllegalArgumentException();
                String coords=Double.toString(lat)+","+Double.toString(lon);try{startActivity(new Intent(Intent.ACTION_VIEW,Uri.parse("geo:"+coords+"?q="+coords)));}catch(ActivityNotFoundException e){startActivity(new Intent(Intent.ACTION_VIEW,Uri.parse("https://maps.google.com/?q="+coords)));}break;
            }
            case "toggleConnection":if(Store.prefs(this).getBoolean("enabled",true))SyncService.stop(this);else{Store.prefs(this).edit().putBoolean("enabled",true).apply();SyncService.start(this);}break;
            case "notifications":requestAlerts();break;
            case "appSettings":startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:"+getPackageName())));break;
            case "pinWidget":AppWidgetManager wm=AppWidgetManager.getInstance(this);if(wm.isRequestPinAppWidgetSupported())wm.requestPinAppWidget(new ComponentName(this,KabarWidget.class),null,null);break;
            case "clearGps":case "clearHistory":background(result,()->{requireSender();synchronized(Store.LOCK){KabarState s=Store.state(this);s.gps=null;for(int i=0;i<s.events.length();i++)s.events.getJSONObject(i).remove("gps");if(call.method.equals("clearHistory")){s.events=new JSONArray();s.location="";s.locationAt=s.homeAt=s.mealAt=s.breakfastAt=s.lunchAt=s.dinnerAt=0;s.mealCategory="";}s.revision++;Store.saveAndQueue(this,s,false);Store.prefs(this).edit().putBoolean("shareLocation",false).apply();}return answer(null);});return;
            case "rotate":background(result,()->{requireSender();Pairing p=Pairing.create();synchronized(Store.LOCK){KabarState s=Store.state(this);s.revision++;Store.prefs(this).edit().putString("code",p.code()).putString("private",Pairing.encode(p.privateKey.getEncoded())).putString("queue","[]").remove("cursor").remove("publishedAt").commit();Store.saveAndQueue(this,s,false);}main.post(()->SyncService.start(this));return answer(null);});return;
            case "disconnect":stopService(new Intent(this,SyncService.class));Store.prefs(this).edit().clear().commit();Store.changed(this);break;
            case "uninstall":startActivity(new Intent(Intent.ACTION_DELETE,Uri.parse("package:"+getPackageName())));break;
            default:result.notImplemented();return;
            }
            result.success(answer(null).toString());
        }catch(Exception e){fail(result,e);}
    }
    private void requestAlerts(){if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},45);else startActivity(new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE,getPackageName()));}
    @Override public void onRequestPermissionsResult(int request,String[] permissions,int[] grants){super.onRequestPermissionsResult(request,permissions,grants);if(request==44&&permitted!=null){Runnable r=permitted;permitted=null;r.run();}}
}
