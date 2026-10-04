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
    private boolean quickPeer;
    private EventChannel.EventSink updates;
    private boolean watching=false;
    private MethodChannel.Result locationSettingsResult;
    private final BroadcastReceiver changed=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent i){
        if(Intent.ACTION_TIMEZONE_CHANGED.equals(i.getAction())||Intent.ACTION_TIME_CHANGED.equals(i.getAction())) {
            TimeZone.setDefault(null);KabarWidget.updateAll(c);SyncService.refreshNotifications(c);
        }
        emitUpdate();
    }};
    private void emitUpdate(){if(updates!=null)updates.success(null);}
    private void stopWatching(){if(watching){unregisterReceiver(changed);watching=false;}updates=null;}
    @Override public void configureFlutterEngine(FlutterEngine engine){
        super.configureFlutterEngine(engine);
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(),"abc/native").setMethodCallHandler(this::handle);
        new EventChannel(engine.getDartExecutor().getBinaryMessenger(),"abc/updates").setStreamHandler(new EventChannel.StreamHandler(){
            @Override public void onListen(Object args,EventChannel.EventSink sink){
                stopWatching();updates=sink;
                IntentFilter filter=new IntentFilter("id.kabar.app.CHANGED");
                filter.addAction(Intent.ACTION_TIME_CHANGED);filter.addAction(Intent.ACTION_TIMEZONE_CHANGED);
                filter.addAction(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED);
                if(Build.VERSION.SDK_INT>=33)registerReceiver(changed,filter,Context.RECEIVER_NOT_EXPORTED);else registerReceiver(changed,filter);
                watching=true;emitUpdate();
            }
            @Override public void onCancel(Object args){stopWatching();}
        });
        quickAction=getIntent().getStringExtra("quickAction");quickPeer=getIntent().getBooleanExtra("showPeer",false);
        SyncService.start(this);
    }
    @Override protected void onNewIntent(Intent intent){super.onNewIntent(intent);setIntent(intent);quickAction=intent.getStringExtra("quickAction");quickPeer=intent.getBooleanExtra("showPeer",false);emitUpdate();}
    @Override protected void onPause(){super.onPause();if(capture!=null)capture.cancel();}
    @Override protected void onDestroy(){stopWatching();if(capture!=null)capture.cancel();io.shutdown();super.onDestroy();}
    private interface Job{JSONObject run()throws Exception;}
    private void background(MethodChannel.Result result,Job job){io.execute(()->{try{JSONObject answer=job.run();if(answer==null)return;String value=answer.toString();main.post(()->result.success(value));}catch(Exception e){main.post(()->fail(result,e));}});}
    private void fail(MethodChannel.Result result,Exception e){if((getApplicationInfo().flags&android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE)!=0)android.util.Log.e("abc-QA","Native action failed",e);String code=e.getMessage()!=null&&e.getMessage().contains("25 kabar")?"queue_full":"error";result.error(code,"Action could not be completed",null);}
    private JSONObject answer(String note)throws Exception{JSONObject j=new JSONObject().put("snapshot",snapshot());if(note!=null&&!note.isEmpty())j.put("note",note);return j;}
    private boolean isSender(){return Store.canSend(this);}
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
        JSONObject profile=new JSONObject().put("nickname",pref.getString("nickname","")).put("language",LocalProfile.language(this)).put("dark",pref.getBoolean("dark",false)).put("relationship",pref.getBoolean("relationship",false)).put("clock12",pref.getBoolean("clock12",false)).put("animations",pref.getBoolean("animations",true));
        String old=Store.prefs(this).getString("connection","");boolean enabled=Store.prefs(this).getBoolean("enabled",true);
        String connection=!enabled?"paused":old.startsWith("Terhubung")?"online":old.startsWith("Kabar terkirim")?"sent":old.startsWith("Mengirim")?"sending":old.contains("terputus")?"offline":"connecting";
        JSONObject j=new JSONObject().put("mode",Store.mode(this)).put("reciprocity",Store.reciprocity(this)).put("modeUpgradeSuggested",!Store.isTwoWay(this)&&pref.getBoolean("relationship",false)).put("state",state).put("profile",profile).put("role",Store.role(this)).put("enabled",enabled).put("pending",Store.pending(this)).put("connection",connection).put("shareLocation",Store.prefs(this).getBoolean("shareLocation",false)).put("zone",LocalProfile.zone(this,z,now,false)).put("localTimes",localTimes).put("platform","android").put("mealsToday",new JSONArray(Arrays.asList(s.hasMealToday("Sarapan",now),s.hasMealToday("Makan siang",now),s.hasMealToday("Makan malam",now))));
        KabarState peer=Store.peerState(this);
        if(peer!=null){JSONObject peerTimes=new JSONObject(),peerJson=decorate(peer,peerTimes,z);j.put("peerState",peerJson).put("peerLocalTimes",peerTimes).put("peerZone",LocalProfile.zone(this,TimeZone.getTimeZone(peer.zone),now,true)).put("peerMealsToday",new JSONArray(Arrays.asList(peer.hasMealToday("Sarapan",now),peer.hasMealToday("Makan siang",now),peer.hasMealToday("Makan malam",now))));}
        if(quickAction!=null&&!quickAction.isEmpty()){j.put("quickAction",quickAction);quickAction="";}
        if(quickPeer&&Store.isTwoWay(this)&&Store.peerState(this)!=null){j.put("quickPeer",true);quickPeer=false;}
        j.put("energySaver",getSystemService(PowerManager.class).isPowerSaveMode());
        return j;
    }
    private JSONObject decorate(KabarState s,JSONObject times,TimeZone viewer)throws Exception {
        JSONObject j=s.json();
        for(String key:new String[]{"locationAt","homeAt","mealAt","breakfastAt","lunchAt","dinnerAt"}){long at=j.optLong(key);if(at>0)times.put(Long.toString(at),LocalProfile.zone(this,viewer,at,false));}
        JSONArray events=j.getJSONArray("events");
        for(int i=0;i<events.length();i++){JSONObject e=events.getJSONObject(i);long at=e.getLong("at");times.put(Long.toString(at),LocalProfile.zone(this,viewer,at,false));e.put("originInfo",LocalProfile.zone(this,TimeZone.getTimeZone(e.optString("zone",s.zone)),at,true));if(e.optJSONObject("gps")!=null){long g=e.getJSONObject("gps").getLong("at");times.put(Long.toString(g),LocalProfile.zone(this,viewer,g,false));}}
        if(s.gps!=null)times.put(Long.toString(s.gps.at),LocalProfile.zone(this,viewer,s.gps.at,false));return j;
    }
    private void consent(Map<String,Object> args){if(!Boolean.TRUE.equals(args.get("confirmed")))throw new SecurityException("Explicit confirmation required");}
    @SuppressWarnings("unchecked") private void handle(MethodCall call,MethodChannel.Result result){
        try {
            Map<String,Object> args=call.arguments instanceof Map?(Map<String,Object>)call.arguments:Collections.emptyMap();
            switch(call.method){
            case "qaSeiramaProbe":
                if((getApplicationInfo().flags&android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE)==0){result.notImplemented();return;}
                result.success(Class.forName("id.kabar.app.SeiramaProbe").getMethod("run",Context.class,boolean.class).invoke(null,this,false).toString());return;
            case "qaCleanupProbe":case "qaSurfaceProbe":
                if((getApplicationInfo().flags&android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE)==0){result.notImplemented();return;}
                Object probe=Class.forName("id.kabar.app.QaProbe").getMethod(call.method.equals("qaCleanupProbe")?"cleanup":"surfaces",Context.class,boolean.class).invoke(null,this,Boolean.TRUE.equals(args.get("seed")));
                result.success(probe.toString());return;
            case "snapshot":result.success(snapshot().toString());return;
            case "locationServices":result.success(new JSONObject().put("enabled",getSystemService(android.location.LocationManager.class).isLocationEnabled()).toString());return;
            case "locationSettings":
                if(locationSettingsResult!=null)throw new IllegalStateException();
                locationSettingsResult=result;startActivityForResult(new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS),46);return;
            case "preferences":{
                SharedPreferences.Editor e=LocalProfile.prefs(this).edit();
                if(args.containsKey("nickname")){String v=(String)args.get("nickname");if(!LocalProfile.validName(v)){result.error("invalid_name","Invalid nickname",null);return;}e.putString("nickname",v.trim());}
                if(args.containsKey("language")){String v=(String)args.get("language");if(!Arrays.asList("id","en","de").contains(v))throw new IllegalArgumentException();e.putString("language",v);}
                for(String k:new String[]{"dark","relationship","clock12","animations"})if(args.containsKey(k))e.putBoolean(k,Boolean.TRUE.equals(args.get(k)));
                if(!e.commit())throw new IllegalStateException();Store.changed(this);SyncService.refreshNotifications(this);result.success(answer(null).toString());return;
            }
            case "setupSender":background(result,()->{
                if(!Store.role(this).isEmpty())throw new IllegalStateException();Pairing p=Pairing.create();KabarState s=new KabarState();s.name=LocalProfile.prefs(this).getString("nickname","Aku");s.revision=1;
                Store.prefs(this).edit().clear().putString("role","sender").putString("code",p.code()).putString("private",Pairing.encode(p.privateKey.getEncoded())).putBoolean("enabled",true).commit();
                Store.saveAndQueue(this,s,false);main.post(()->SyncService.start(this));return answer(null);
            });return;
            case "setupReceiver":{
                Pairing p;try{p=Pairing.parse((String)args.get("code"));}catch(Exception e){result.error("invalid_code","Invalid pairing code",null);return;}
                if(!Store.role(this).isEmpty())throw new IllegalStateException();Store.prefs(this).edit().clear().putString("role","receiver").putString("code",p.code()).putBoolean("enabled",true).commit();SyncService.start(this);Store.changed(this);if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},45);result.success(answer(null).toString());return;
            }
            case "enableSeirama":background(result,()->{
                consent(args);if(Store.isTwoWay(this))return answer(null);
                synchronized(Store.LOCK){
                    String oldRole=Store.role(this);boolean oldSender=oldRole.equals("sender");
                    if(oldSender&&Store.pending(this)>=25)throw new IllegalStateException("25 kabar masih menunggu");
                    KabarState original=Store.state(this),own=oldSender?original:new KabarState();
                    Pairing ownPair=oldSender?Store.pairing(this):Pairing.create();
                    if(!oldSender){own.name=LocalProfile.prefs(this).getString("nickname","Aku");own.revision=0;}
                    SharedPreferences.Editor edit=Store.prefs(this).edit().putString("oneWayRole",oldRole.equals("receiver")?"receiver":"sender").putString("role","duplex").putString("code",ownPair.code()).putString("private",Pairing.encode(ownPair.privateKey.getEncoded())).putBoolean("enabled",true).putBoolean("peerConfirmed",false).putBoolean("peerRevoked",false);
                    if(oldRole.equals("receiver")){String incoming=Store.prefs(this).getString("code","");edit.putString("peerCode",incoming).putString("peerState",original.json().toString()).putString("oneWayCode",incoming).putString("oneWayState",original.json().toString()).putString("queue","[]");}
                    if(!edit.commit())throw new IllegalStateException();own.revision++;Store.saveAndQueue(this,own,false);
                }
                LocalProfile.prefs(this).edit().putBoolean("relationship",true).commit();main.post(()->{SyncService.start(this);if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},45);});return answer(null);
            });return;
            case "joinSeirama":background(result,()->{
                consent(args);if(!Store.isTwoWay(this))throw new SecurityException("Enable Seirama first");
                Pairing incoming;try{incoming=Seirama.parseInvite((String)args.get("code"));}catch(Exception e){main.post(()->result.error("invalid_code","Invalid Seirama code",null));return null;}
                if(Seirama.isOwn(Store.pairing(this),incoming)){main.post(()->result.error("own_code","Use your partner's code",null));return null;}
                synchronized(Store.LOCK){
                    if(Store.pending(this)>=25)throw new IllegalStateException("25 kabar masih menunggu");
                    boolean same=incoming.code().equals(Store.prefs(this).getString("peerCode",""));
                    SharedPreferences.Editor edit=Store.prefs(this).edit().putString("peerCode",incoming.code()).putBoolean("peerConfirmed",false).putBoolean("peerRevoked",false).remove("cursor");if(!same)edit.putString("peerState",new KabarState().json().toString());
                    if(!edit.commit())throw new IllegalStateException();KabarState own=Store.state(this);own.revision++;Store.saveAndQueue(this,own,false);
                }
                main.post(()->SyncService.start(this));return answer(null);
            });return;
            case "disableSeirama":background(result,()->{
                consent(args);if(!Store.isTwoWay(this))return answer(null);
                synchronized(Store.LOCK){
                    String previous=Store.prefs(this).getString("oneWayRole","sender");if(previous.equals("sender")&&Store.pending(this)>=25)throw new IllegalStateException("25 kabar masih menunggu");SharedPreferences.Editor edit=Store.prefs(this).edit();
                    if(previous.equals("receiver")){Store.retire(this,Store.pairing(this),Store.state(this));String code=Store.prefs(this).getString("oneWayCode","");KabarState old=code.equals(Store.prefs(this).getString("peerCode",""))?Store.peerState(this):KabarState.parse(Store.prefs(this).getString("oneWayState",""));edit.putString("code",code).putString("state",old.json().toString()).remove("private").putString("queue","[]");}
                    edit.putString("role",previous).remove("peerCode").remove("peerState").remove("peerConfirmed").remove("peerRevoked").remove("oneWayRole").remove("oneWayCode").remove("oneWayState").remove("cursor").remove("publishedAt").commit();
                    if(previous.equals("sender"))Store.revokeOwn(this);
                }
                LocalProfile.prefs(this).edit().putBoolean("relationship",false).commit();Store.changed(this);main.post(()->SyncService.start(this));return answer(null);
            });return;
            case "record":{
                requireSender();if(Store.pending(this)>=25){result.error("queue_full","Queue full",null);return;}
                String kind=(String)args.getOrDefault("kind","");String category=(String)args.get("category");boolean share=Boolean.TRUE.equals(args.get("shareLocation"));String session=Store.prefs(this).getString("code","");
                Store.prefs(this).edit().putBoolean("shareLocation",share).apply();
                LocationCapture.Result save=(point,message)->{capture=null;background(result,()->{
                    if(!isSender()||!session.equals(Store.prefs(this).getString("code","")))throw new SecurityException();
                    if(kind.isEmpty()&&point==null)return answer("locationFailed");
                    synchronized(Store.LOCK){KabarState s=Store.state(this);s.zone=TimeZone.getDefault().getID();if(kind.isEmpty()){s.gps=point;s.revision++;}else s.record(kind,System.currentTimeMillis(),category,point);Store.saveAndQueue(this,s,!kind.isEmpty());}
                    return answer(share&&point==null?(LocationCapture.allowed(this)?"locationUnavailable":"locationDenied"):null);
                });};
                if(!share){save.done(null,"");return;}
                if(LocationCapture.allowed(this)){capture=LocationCapture.start(this,save);return;}
                permitted=()->{if(LocationCapture.allowed(this))capture=LocationCapture.start(this,save);else save.done(null,"denied");};
                requestPermissions(new String[]{Manifest.permission.ACCESS_FINE_LOCATION,Manifest.permission.ACCESS_COARSE_LOCATION},44);return;
            }
            case "edit":background(result,()->{requireSender();synchronized(Store.LOCK){KabarState s=Store.state(this);for(String k:new String[]{"name","outside","home","meal"})if(args.containsKey(k)){String v=(String)args.get(k);if(!LocalProfile.validName(v))throw new IllegalArgumentException();switch(k){case "name":s.name=v.trim();break;case "outside":s.outside=v.trim();break;case "home":s.home=v.trim();break;case "meal":s.meal=v.trim();}}
                if(args.containsKey("windows")){List<Number> list=(List<Number>)args.get("windows");int[] windows=new int[list.size()];for(int i=0;i<windows.length;i++)windows[i]=list.get(i).intValue();if(!StatusLogic.validWindows(windows))throw new IllegalArgumentException();s.windows=windows;}
                s.revision++;Store.saveAndQueue(this,s,false);}return answer(null);});return;
            case "pairCode":requireSender();result.success(new JSONObject().put("code",Store.isTwoWay(this)?Seirama.invite(Store.pairing(this)):Store.pairing(this).code()).toString());return;
            case "shareCode":requireSender();startActivity(Intent.createChooser(new Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT,Store.isTwoWay(this)?Seirama.invite(Store.pairing(this)):Store.pairing(this).code()),"abc"));break;
            case "openMap":{
                double lat=((Number)args.get("lat")).doubleValue(),lon=((Number)args.get("lon")).doubleValue();if(!Double.isFinite(lat)||!Double.isFinite(lon)||Math.abs(lat)>90||Math.abs(lon)>180)throw new IllegalArgumentException();
                String coords=Double.toString(lat)+","+Double.toString(lon);try{startActivity(new Intent(Intent.ACTION_VIEW,Uri.parse("geo:"+coords+"?q="+coords)));}catch(ActivityNotFoundException e){startActivity(new Intent(Intent.ACTION_VIEW,Uri.parse("https://maps.google.com/?q="+coords)));}break;
            }
            case "toggleConnection":if(Store.prefs(this).getBoolean("enabled",true))SyncService.stop(this);else{Store.prefs(this).edit().putBoolean("enabled",true).apply();SyncService.start(this);}break;
            case "notifications":requestAlerts();break;
            case "appSettings":startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:"+getPackageName())));break;
            case "pinWidget":AppWidgetManager wm=AppWidgetManager.getInstance(this);if(wm.isRequestPinAppWidgetSupported())wm.requestPinAppWidget(new ComponentName(this,KabarWidget.class),null,null);break;
            case "clearGps":case "clearHistory":background(result,()->{requireSender();synchronized(Store.LOCK){KabarState s=Store.state(this);s.gps=null;for(int i=0;i<s.events.length();i++)s.events.getJSONObject(i).remove("gps");if(call.method.equals("clearHistory")){s.events=new JSONArray();s.location="";s.locationAt=s.homeAt=s.mealAt=s.breakfastAt=s.lunchAt=s.dinnerAt=0;s.mealCategory="";}s.revision++;Store.saveAndQueue(this,s,false);Store.prefs(this).edit().putBoolean("shareLocation",false).apply();}return answer(null);});return;
            case "rotate":background(result,()->{requireSender();if(Store.isTwoWay(this))throw new SecurityException("Disable Seirama before rotating a one-way code");Pairing p=Pairing.create();synchronized(Store.LOCK){KabarState s=Store.state(this);s.revision++;Store.prefs(this).edit().putString("code",p.code()).putString("private",Pairing.encode(p.privateKey.getEncoded())).putString("queue","[]").remove("cursor").remove("publishedAt").commit();Store.saveAndQueue(this,s,false);}main.post(()->SyncService.start(this));return answer(null);});return;
            case "disconnect":stopService(new Intent(this,SyncService.class));Store.prefs(this).edit().clear().commit();Store.changed(this);break;
            case "prepareUninstall":
                if(capture!=null)capture.cancel();permitted=null;
                background(result,()->{AppDataCleaner.clear(this);return answer(null);});return;
            case "uninstall":startActivity(new Intent(Intent.ACTION_DELETE,Uri.parse("package:"+getPackageName())));break;
            default:result.notImplemented();return;
            }
            result.success(answer(null).toString());
        }catch(Exception e){fail(result,e);}
    }
    private void requestAlerts(){if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)requestPermissions(new String[]{Manifest.permission.POST_NOTIFICATIONS},45);else startActivity(new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE,getPackageName()));}
    @Override protected void onActivityResult(int request,int code,Intent data){super.onActivityResult(request,code,data);if(request==46&&locationSettingsResult!=null){MethodChannel.Result result=locationSettingsResult;locationSettingsResult=null;try{result.success(answer(null).toString());}catch(Exception e){fail(result,e);}}}
    @Override public void onRequestPermissionsResult(int request,String[] permissions,int[] grants){super.onRequestPermissionsResult(request,permissions,grants);if(request==44&&permitted!=null){Runnable r=permitted;permitted=null;r.run();}}
}
