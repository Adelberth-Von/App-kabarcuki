package id.kabar.app;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.location.*;
import android.os.*;
import java.util.*;

/** A bounded, foreground-only request. Denial, disabled GPS and timeout preserve the status action. */
final class LocationCapture implements LocationListener {
    interface Result {void done(GpsPoint point,String message);}
    private final LocationManager manager;
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final Result result;
    private final Context context;
    private boolean finished,resolving;
    private final Runnable timeout=()->complete(null,"Lokasi belum didapat. Status tetap disimpan tanpa lokasi baru.");
    private LocationCapture(Context c,Result result){context=c.getApplicationContext();manager=c.getSystemService(LocationManager.class);this.result=result;}
    static boolean allowed(Context c){return c.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION)==PackageManager.PERMISSION_GRANTED||c.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)==PackageManager.PERMISSION_GRANTED;}
    static LocationCapture start(Context c,Result result){LocationCapture request=new LocationCapture(c,result);request.handler.post(()->request.begin(c));return request;}
    private void begin(Context c){
        if(finished)return;
        if(!allowed(c)){complete(null,"Izin lokasi belum diberikan. Status tetap disimpan.");return;}
        if(manager==null||!manager.isLocationEnabled()){complete(null,"Lokasi HP sedang mati. Status tetap disimpan tanpa lokasi baru.");return;}
        List<String> providers=new ArrayList<>();
        providers.add(LocationManager.NETWORK_PROVIDER);
        if(c.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION)==PackageManager.PERMISSION_GRANTED)providers.add(LocationManager.GPS_PROVIDER);
        Location best=null;boolean listening=false;
        for(String provider:providers){try{if(!manager.isProviderEnabled(provider))continue;Location cached=manager.getLastKnownLocation(provider);if(fresh(cached)&&(best==null||cached.getAccuracy()<best.getAccuracy()))best=cached;}catch(SecurityException|IllegalArgumentException ignored){}}
        if(best!=null){onLocationChanged(best);return;}
        for(String provider:providers){try{if(manager.isProviderEnabled(provider)){manager.requestLocationUpdates(provider,0,0,this,Looper.getMainLooper());listening=true;}}catch(SecurityException|IllegalArgumentException ignored){}}
        if(!listening){complete(null,"Penyedia lokasi belum tersedia. Status tetap disimpan.");return;}
        handler.postDelayed(timeout,12000);
    }
    static boolean fresh(Location l){if(l==null||!l.hasAccuracy()||l.getAccuracy()<=0)return false;long age=SystemClock.elapsedRealtimeNanos()-l.getElapsedRealtimeNanos();return l.getTime()>0&&age>=0&&age<=120000000000L;}
    @Override public void onLocationChanged(Location l){
        if(finished||resolving||!fresh(l))return;
        resolving=true;handler.removeCallbacks(timeout);
        if(manager!=null)try{manager.removeUpdates(this);}catch(SecurityException ignored){}
        final GpsPoint point=new GpsPoint(l.getLatitude(),l.getLongitude(),l.getAccuracy(),l.getTime(),TimeZone.getDefault().getID());
        handler.postDelayed(()->complete(point,""),2500);
        // One bounded lookup per explicitly shared point; no background tracking.
        Thread lookup=new Thread(()->{
            GpsPoint named=point;
            try{List<Address> found=new Geocoder(context,Locale.getDefault()).getFromLocation(point.lat,point.lon,1);
                if(found!=null&&!found.isEmpty()){Address a=found.get(0);String city=clean(a.getLocality()!=null?a.getLocality():a.getSubAdminArea());String place=clean(a.getSubLocality()!=null?a.getSubLocality():a.getAdminArea());named=new GpsPoint(point.lat,point.lon,point.accuracy,point.at,point.zone,city,place);}
            }catch(Exception ignored){}
            GpsPoint answer=named;handler.post(()->complete(answer,""));
        },"abc-place");lookup.setDaemon(true);lookup.start();
    }
    private static String clean(String raw){if(raw==null)return "";String s=raw.replaceAll("[\\x00-\\x1f]","").trim();return s.substring(0,Math.min(32,s.length()));}
    @Override public void onProviderDisabled(String provider){}
    @Override public void onProviderEnabled(String provider){}
    @Override public void onStatusChanged(String provider,int status,Bundle extras){}
    void cancel(){complete(null,"Pengambilan lokasi dihentikan. Status tetap disimpan.");}
    private void complete(GpsPoint point,String message){if(finished)return;finished=true;handler.removeCallbacks(timeout);if(manager!=null)try{manager.removeUpdates(this);}catch(SecurityException ignored){}result.done(point,message);}
}
