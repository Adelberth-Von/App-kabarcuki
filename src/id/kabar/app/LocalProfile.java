package id.kabar.app;
import android.content.*;
import org.json.*;
import java.text.SimpleDateFormat;
import java.util.*;
/** Phone preferences never enter encrypted shared status packets. */
public final class LocalProfile {
    public static SharedPreferences prefs(Context c){return c.getSharedPreferences("appearance",Context.MODE_PRIVATE);}
    public static String language(Context c){String v=prefs(c).getString("language","id");return Arrays.asList("id","en","de").contains(v)?v:"id";}
    public static String text(Context c,String id,String en,String de){return language(c).equals("en")?en:language(c).equals("de")?de:id;}
    public static String label(Context c,String raw){
        switch(raw){case "Keluar":return text(c,"Keluar","Out","Unterwegs");case "Kost":return text(c,"Kost","Home","Zuhause");case "Di kost":return text(c,"Di kost","At home","Zuhause");case "Makan":return text(c,"Makan","Meal","Essen");case "Sarapan":return text(c,"Sarapan","Breakfast","Frühstück");case "Makan siang":return text(c,"Makan siang","Lunch","Mittagessen");case "Makan malam":return text(c,"Makan malam","Dinner","Abendessen");default:return raw;}
    }
    public static boolean validName(String raw){if(raw==null)return false;String s=raw.trim();if(s.isEmpty()||s.length()>24)return false;for(int i=0;i<s.length();i++)if(s.charAt(i)<32||s.charAt(i)==127)return false;return true;}
    public static JSONObject zone(Context c,TimeZone zone,long at,boolean withOffset)throws JSONException{
        String country=ZoneCountries.ALL.get(zone.getID());
        JSONObject j=new JSONObject().put("id",zone.getID()).put("short",StatusLogic.shortZone(zone,at)).put("country",country==null?text(c,"Zona waktu HP","Phone time zone","Zeitzone des Telefons"):new Locale("",country).getDisplayCountry(new Locale(language(c))));
        if(withOffset)j.put("offsetMinutes",zone.getOffset(at)/60000);
        return j;
    }
    public static String stamp(Context c,long at){
        if(at<=0)return text(c,"Belum tercatat","Not recorded","Nicht erfasst");
        TimeZone z=TimeZone.getDefault();SimpleDateFormat f=new SimpleDateFormat(prefs(c).getBoolean("clock12",false)?"h.mm a":"HH.mm",Locale.US);f.setTimeZone(z);
        SimpleDateFormat d=new SimpleDateFormat("dd.MM.yyyy",Locale.US);d.setTimeZone(z);
        return d.format(at)+" · "+f.format(at)+" "+StatusLogic.shortZone(z,at);
    }
}
