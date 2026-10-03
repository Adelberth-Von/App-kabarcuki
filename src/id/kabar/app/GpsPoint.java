package id.kabar.app;

import org.json.*;
import java.util.Locale;
import java.util.TimeZone;

/** Optional point captured on the sender; it is never inferred from a status label. */
public final class GpsPoint {
    public final double lat,lon,accuracy;
    public final long at;
    public final String zone;
    public final String city,place;
    public GpsPoint(double lat,double lon,double accuracy,long at,String zone) {
        this(lat,lon,accuracy,at,zone,"","");
    }
    public GpsPoint(double lat,double lon,double accuracy,long at,String zone,String city,String place) {
        if(!Double.isFinite(lat)||!Double.isFinite(lon)||!Double.isFinite(accuracy)||Math.abs(lat)>90||Math.abs(lon)>180||accuracy<=0||accuracy>1000000||at<=0||!validZone(zone))throw new IllegalArgumentException("Lokasi tidak valid");
        this.lat=Math.round(lat*1000000)/1000000.0;this.lon=Math.round(lon*1000000)/1000000.0;
        this.accuracy=Math.ceil(accuracy);this.at=at;this.zone=zone;
        this.city=validLabel(city);this.place=validLabel(place);
    }
    private static String validLabel(String text){if(text==null)return "";if(text.length()>32||text.matches("(?s).*[\\x00-\\x1f].*"))throw new IllegalArgumentException("Nama lokasi tidak valid");return text;}
    public static boolean validZone(String zone){return zone!=null&&zone.length()<=80&&(java.util.Arrays.asList(TimeZone.getAvailableIDs()).contains(zone)||zone.matches("GMT[+-](0[0-9]|1[0-4]):?[0-5][0-9]"));}
    public JSONObject json() throws JSONException {JSONObject j=new JSONObject().put("lat",lat).put("lon",lon).put("accuracy",accuracy).put("at",at).put("zone",zone);if(!city.isEmpty())j.put("city",city);if(!place.isEmpty())j.put("place",place);return j;}
    public static GpsPoint parse(JSONObject j) throws JSONException {try{return new GpsPoint(j.getDouble("lat"),j.getDouble("lon"),j.getDouble("accuracy"),j.getLong("at"),j.getString("zone"),j.optString("city",""),j.optString("place",""));}catch(IllegalArgumentException e){throw new JSONException("Lokasi tidak valid");}}
    public String coordinates(){return String.format(Locale.ROOT,"%.5f, %.5f",lat,lon);}
    public boolean old(long now){return now-at>=15*60*1000L;}
}
