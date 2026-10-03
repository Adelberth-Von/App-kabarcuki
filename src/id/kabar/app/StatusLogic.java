package id.kabar.app;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Locale;
import java.util.TimeZone;

/** Pure Java domain rules, also exercised on the desktop JVM. */
public final class StatusLogic {
    public static final int[] DEFAULT_WINDOWS = {5,10,10,15,17,22};
    private StatusLogic() {}
    public static String mealAt(long timestamp, int[] windows, TimeZone zone) {
        Calendar c = Calendar.getInstance(zone);
        c.setTimeInMillis(timestamp);
        int hour = c.get(Calendar.HOUR_OF_DAY);
        String[] names = {"Sarapan", "Makan siang", "Makan malam"};
        for (int i=0; i<3; i++) if (hour >= windows[i*2] && hour < windows[i*2+1]) return names[i];
        return "Makan";
    }
    public static boolean validWindows(int[] w) {
        if (w == null || w.length != 6) return false;
        for (int i=0; i<3; i++) {
            if (w[i*2] < 0 || w[i*2+1] > 24 || w[i*2] >= w[i*2+1]) return false;
            if (i>0 && w[i*2] < w[i*2-1]) return false;
        }
        return true;
    }
    public static String dayKey(long timestamp, TimeZone zone) {
        SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd", Locale.ROOT);
        f.setTimeZone(zone);
        return f.format(timestamp);
    }
    public static String when(long timestamp, long now, TimeZone zone) {
        if (timestamp <= 0) return "Belum tercatat";
        SimpleDateFormat clock = new SimpleDateFormat("HH.mm", Locale.ROOT);
        clock.setTimeZone(zone);
        String prefix;
        if (dayKey(timestamp,zone).equals(dayKey(now,zone))) prefix="Hari ini";
        else {
            Calendar yesterday=Calendar.getInstance(zone);
            yesterday.setTimeInMillis(now);
            yesterday.add(Calendar.DATE,-1);
            if (dayKey(timestamp,zone).equals(dayKey(yesterday.getTimeInMillis(),zone))) prefix="Kemarin";
            else {
                SimpleDateFormat date=new SimpleDateFormat("d MMM",new Locale("id"));
                date.setTimeZone(zone);
                prefix=date.format(timestamp);
            }
        }
        return prefix+" · "+clock.format(timestamp);
    }
    public static boolean stale(long timestamp,long now) { return timestamp>0 && now-timestamp>=6L*60*60*1000; }
    /** Display in the viewer's zone. This never changes stored timestamps or meal dates. */
    public static String localWhen(long timestamp,long now,TimeZone zone) {
        return timestamp<=0?"Belum tercatat":when(timestamp,now,zone)+" "+shortZone(zone,timestamp)+" - "+country(zone);
    }
    public static String clock(long at,TimeZone zone) {
        SimpleDateFormat f=new SimpleDateFormat("HH.mm",Locale.ROOT);f.setTimeZone(zone);
        return f.format(at)+" "+shortZone(zone,at)+" - "+country(zone);
    }
    public static String country(TimeZone zone){String code=ZoneCountries.ALL.get(zone.getID());return code==null?"Zona waktu HP":new Locale("",code).getDisplayCountry(new Locale("id"));}
    public static String shortZone(TimeZone zone,long at){
        if("ID".equals(ZoneCountries.ALL.get(zone.getID()))){int offset=zone.getOffset(at)/3600000;if(offset==7)return "WIB";if(offset==8)return "WITA";if(offset==9)return "WIT";}
        return zone.getDisplayName(zone.inDaylightTime(new java.util.Date(at)),TimeZone.SHORT,Locale.US);
    }
    public static int phase(long at,TimeZone zone){Calendar c=Calendar.getInstance(zone);c.setTimeInMillis(at);int h=c.get(Calendar.HOUR_OF_DAY);return h>=5&&h<11?0:h>=11&&h<15?1:h>=15&&h<18?2:3;}
    public static String phaseName(long at,TimeZone zone){return new String[]{"Pagi","Siang","Sore","Malam"}[phase(at,zone)];}
    public static String zoneLabel(TimeZone zone,long at){int minutes=zone.getOffset(at)/60000;return String.format(Locale.ROOT,"UTC%s%02d:%02d · %s",minutes<0?"−":"+",Math.abs(minutes)/60,Math.abs(minutes)%60,zone.getID());}
}
