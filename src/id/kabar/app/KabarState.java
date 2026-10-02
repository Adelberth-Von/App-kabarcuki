package id.kabar.app;

import org.json.*;
import java.util.TimeZone;

public final class KabarState {
    public long revision=0, locationAt=0, homeAt=0, mealAt=0;
    public long breakfastAt=0,lunchAt=0,dinnerAt=0;
    public String name="Aku", outside="Keluar", home="Kost", meal="Makan", location="", mealCategory="", zone=TimeZone.getDefault().getID();
    public int[] windows=StatusLogic.DEFAULT_WINDOWS.clone();
    public JSONArray events=new JSONArray();
    public String locationText() { return "home".equals(location)?"Di "+home.toLowerCase(new java.util.Locale("id")):"outside".equals(location)?outside:"Lokasi belum tercatat"; }
    public void record(String kind,long timestamp) throws JSONException {
        if(!kind.equals("outside")&&!kind.equals("home")&&!kind.equals("meal")) throw new IllegalArgumentException("Tombol tidak dikenal");
        if(timestamp<=0) throw new IllegalArgumentException("Waktu tidak valid");
        String label;
        if(kind.equals("meal")) {
            mealAt=timestamp; mealCategory=StatusLogic.mealAt(timestamp,windows,TimeZone.getTimeZone(zone)); label=mealCategory;
            if(mealCategory.equals("Sarapan"))breakfastAt=timestamp;
            if(mealCategory.equals("Makan siang"))lunchAt=timestamp;
            if(mealCategory.equals("Makan malam"))dinnerAt=timestamp;
        } else {
            location=kind; locationAt=timestamp;
            if(kind.equals("home")) homeAt=timestamp;
            label=locationText();
        }
        revision++;
        JSONObject event=new JSONObject().put("kind",kind).put("at",timestamp).put("label",label);
        JSONArray recent=new JSONArray();
        recent.put(event);
        for(int i=0;i<Math.min(11,events.length());i++) recent.put(events.getJSONObject(i));
        events=recent;
    }
    public boolean hasMealToday(String category,long now) {
        TimeZone tz=TimeZone.getTimeZone(zone);
        long at=category.equals("Sarapan")?breakfastAt:category.equals("Makan siang")?lunchAt:category.equals("Makan malam")?dinnerAt:0;
        return at>0&&StatusLogic.dayKey(at,tz).equals(StatusLogic.dayKey(now,tz));
    }
    public JSONObject json() throws JSONException {
        JSONArray schedule=new JSONArray(); for(int w:windows) schedule.put(w);
        return new JSONObject().put("v",1).put("revision",revision).put("name",name)
            .put("outside",outside).put("home",home).put("meal",meal).put("zone",zone).put("windows",schedule)
            .put("location",location).put("locationAt",locationAt).put("homeAt",homeAt).put("mealAt",mealAt)
            .put("breakfastAt",breakfastAt).put("lunchAt",lunchAt).put("dinnerAt",dinnerAt)
            .put("mealCategory",mealCategory).put("events",events);
    }
    private static String label(JSONObject j,String key) throws JSONException {
        String s=j.getString(key).trim();
        if(s.isEmpty()||s.length()>24||s.contains("\n")) throw new JSONException("Nama harus 1–24 karakter");
        return s;
    }
    public static KabarState parse(String raw) throws JSONException {
        if(raw.length()>6000) throw new JSONException("Data terlalu besar");
        JSONObject j=new JSONObject(raw);
        if(j.getInt("v")!=1) throw new JSONException("Versi data tidak didukung");
        KabarState s=new KabarState();
        s.revision=j.getLong("revision"); if(s.revision<0) throw new JSONException("Revisi tidak valid");
        s.name=label(j,"name"); s.outside=label(j,"outside");s.home=label(j,"home");s.meal=label(j,"meal");
        s.zone=j.getString("zone"); if(s.zone.length()>80)throw new JSONException("Zona waktu tidak valid");
        JSONArray w=j.getJSONArray("windows"); if(w.length()!=6)throw new JSONException("Jadwal tidak valid");
        s.windows=new int[6];for(int i=0;i<6;i++)s.windows[i]=w.getInt(i);
        if(!StatusLogic.validWindows(s.windows))throw new JSONException("Jadwal saling tumpang tindih");
        s.location=j.getString("location"); if(!s.location.equals("")&&!s.location.equals("home")&&!s.location.equals("outside"))throw new JSONException("Lokasi tidak valid");
        s.locationAt=j.getLong("locationAt");s.homeAt=j.getLong("homeAt");s.mealAt=j.getLong("mealAt");
        s.breakfastAt=j.getLong("breakfastAt");s.lunchAt=j.getLong("lunchAt");s.dinnerAt=j.getLong("dinnerAt");
        if(s.locationAt<0||s.homeAt<0||s.mealAt<0||s.breakfastAt<0||s.lunchAt<0||s.dinnerAt<0)throw new JSONException("Waktu tidak valid");
        s.mealCategory=j.getString("mealCategory");if(s.mealCategory.length()>24)throw new JSONException("Kategori tidak valid");
        s.events=j.getJSONArray("events");if(s.events.length()>12)throw new JSONException("Riwayat terlalu banyak");
        for(int i=0;i<s.events.length();i++) {
            JSONObject e=s.events.getJSONObject(i);
            String k=e.getString("kind");
            if(!k.equals("home")&&!k.equals("outside")&&!k.equals("meal"))throw new JSONException("Jenis riwayat salah");
            if(e.getLong("at")<=0||e.getString("label").length()>40)throw new JSONException("Riwayat tidak valid");
        }
        return s;
    }
}
