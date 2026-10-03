package id.kabar.app;

import android.app.*;
import android.appwidget.*;
import android.content.*;
import android.os.*;
import android.view.View;
import android.widget.RemoteViews;
import android.graphics.*;
import java.util.TimeZone;

public class KabarWidget extends AppWidgetProvider {
    @Override public void onUpdate(Context c,AppWidgetManager manager,int[] ids){for(int id:ids)manager.updateAppWidget(id,views(c,manager.getAppWidgetOptions(id).getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,280)));}
    @Override public void onAppWidgetOptionsChanged(Context c,AppWidgetManager manager,int id,Bundle options){manager.updateAppWidget(id,views(c,options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,280)));}
    public static void updateAll(Context c){AppWidgetManager m=AppWidgetManager.getInstance(c);int[] ids=m.getAppWidgetIds(new ComponentName(c,KabarWidget.class));if(ids.length>0)new KabarWidget().onUpdate(c,m,ids);}
    public static String action(KabarState s){org.json.JSONObject e=s.events.optJSONObject(0);return e==null?"idle":e.optString("kind","idle");}
    public static Bitmap art(Context c,KabarState s,int frame){Bitmap bitmap=Bitmap.createBitmap(336,114,Bitmap.Config.ARGB_8888);DayScene scene=new DayScene(c,new Appearance(c).relationship,System.currentTimeMillis(),TimeZone.getDefault(),action(s),frame);scene.layout(0,0,336,114);scene.draw(new Canvas(bitmap));return bitmap;}
    public static RemoteViews views(Context c){return views(c,280);}
    private static RemoteViews views(Context c,int height){
        TimeZone.setDefault(null);
        KabarState s=Store.state(c);long now=System.currentTimeMillis();TimeZone zone=TimeZone.getDefault();Appearance a=new Appearance(c);
        boolean compact=height<340,paired=!Store.role(c).isEmpty();
        boolean motion=paired&&Store.prefs(c).getBoolean("enabled",true)&&LocalProfile.prefs(c).getBoolean("animations",true)&&!c.getSystemService(PowerManager.class).isPowerSaveMode()&&android.provider.Settings.Global.getFloat(c.getContentResolver(),android.provider.Settings.Global.ANIMATOR_DURATION_SCALE,1)>0;
        int layout=compact?(motion?R.layout.widget_compact:R.layout.widget_compact_still):(motion?R.layout.widget:R.layout.widget_still);
        RemoteViews v=new RemoteViews(c.getPackageName(),layout);
        v.setInt(R.id.widget_root,"setBackgroundResource",a.relationship?(a.dark?R.drawable.widget_seirama_dark:R.drawable.widget_seirama_light):(a.dark?R.drawable.widget_default_dark:R.drawable.widget_default_light));
        for(int id:new int[]{R.id.widget_title,R.id.widget_location,R.id.widget_home,R.id.widget_meal,R.id.widget_connection,R.id.widget_outside,R.id.widget_home_action,R.id.widget_meal_action,R.id.widget_city,R.id.widget_phase})v.setTextColor(id,a.ink);
        int button=a.relationship?(a.dark?R.drawable.widget_button_seirama_dark:R.drawable.widget_button_seirama_light):(a.dark?R.drawable.widget_button_default_dark:R.drawable.widget_button_default_light);
        for(int id:new int[]{R.id.widget_outside,R.id.widget_home_action,R.id.widget_meal_action,R.id.widget_phase})v.setInt(id,"setBackgroundResource",button);
        for(int id:new int[]{R.id.widget_time,R.id.widget_home,R.id.widget_city,R.id.widget_connection})v.setTextColor(id,a.muted);
        v.setTextColor(R.id.widget_phase,a.accent);
        v.setTextViewCompoundDrawables(R.id.widget_outside,0,R.drawable.widget_icon_outside,0,0);
        v.setTextViewCompoundDrawables(R.id.widget_home_action,0,R.drawable.widget_icon_home,0,0);
        v.setTextViewCompoundDrawables(R.id.widget_meal_action,0,R.drawable.widget_icon_meal,0,0);
        v.setImageViewBitmap(R.id.widget_art,art(c,s,0));v.setImageViewBitmap(R.id.widget_art_next,art(c,s,1));
        int phase=StatusLogic.phase(now,zone);
        String[][] phases={{"Pagi","Morning","Morgen"},{"Siang","Daytime","Tag"},{"Sore","Evening","Abend"},{"Malam","Night","Nacht"}};
        v.setTextViewText(R.id.widget_phase,(a.relationship?"Seirama · ":"")+LocalProfile.text(c,phases[phase][0],phases[phase][1],phases[phase][2]));
        v.setTextViewText(R.id.widget_title,paired?s.name+" · abc":"abc");
        v.setTextViewText(R.id.widget_location,paired?LocalProfile.label(c,s.locationText()):LocalProfile.text(c,"Ketuk untuk menghubungkan","Tap to connect","Zum Verbinden tippen"));
        v.setTextViewText(R.id.widget_time,paired?LocalProfile.stamp(c,s.locationAt):"");
        v.setTextViewText(R.id.widget_home,LocalProfile.label(c,s.home)+": "+LocalProfile.stamp(c,s.homeAt));
        v.setTextViewText(R.id.widget_meal,s.mealAt==0?LocalProfile.text(c,"Makan belum tercatat","Meal not recorded","Essen nicht erfasst"):"✓ "+LocalProfile.label(c,s.mealCategory)+" · "+LocalProfile.stamp(c,s.mealAt));
        v.setTextViewText(R.id.widget_city,s.gps==null?"":LocalProfile.text(c,"Lokasi terakhir · ","Last location · ","Letzter Standort · ")+(s.gps.city.isEmpty()?LocalProfile.text(c,"Nama kota belum tersedia","City unavailable","Stadt unbekannt"):s.gps.city));
        String connection=!paired?LocalProfile.text(c,"Hubungkan perangkat di aplikasi","Connect devices in the app","Geräte in der App verbinden"):!Store.prefs(c).getBoolean("enabled",true)?"Ⅱ "+LocalProfile.text(c,"Dijeda","Paused","Pausiert"):Store.pending(c)>0?"↥ "+Store.pending(c)+LocalProfile.text(c," kabar menunggu"," pending updates"," ausstehende Updates"):"↗ "+LocalProfile.text(c,"Ketuk untuk detail","Tap for details","Für Details tippen");
        v.setTextViewText(R.id.widget_connection,connection);
        v.setViewVisibility(R.id.widget_home,compact?View.GONE:View.VISIBLE);v.setViewVisibility(R.id.widget_city,compact||s.gps==null?View.GONE:View.VISIBLE);v.setViewVisibility(R.id.widget_connection,compact?View.GONE:View.VISIBLE);
        v.setViewVisibility(R.id.widget_actions,Store.role(c).equals("sender")&&height>=220?View.VISIBLE:View.GONE);
        v.setTextViewText(R.id.widget_outside,LocalProfile.label(c,s.outside));v.setTextViewText(R.id.widget_home_action,LocalProfile.label(c,s.home));v.setTextViewText(R.id.widget_meal_action,LocalProfile.label(c,s.meal));
        v.setOnClickPendingIntent(R.id.widget_root,open(c,"",10));v.setOnClickPendingIntent(R.id.widget_outside,open(c,"outside",11));v.setOnClickPendingIntent(R.id.widget_home_action,open(c,"home",12));v.setOnClickPendingIntent(R.id.widget_meal_action,open(c,"meal",13));
        return v;
    }
    private static PendingIntent open(Context c,String action,int request){return PendingIntent.getActivity(c,request,AppEntry.open(c).putExtra("quickAction",action).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);}
}
