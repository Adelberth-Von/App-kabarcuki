package id.kabar.app;

import android.app.*;
import android.appwidget.*;
import android.content.*;
import android.os.*;
import android.view.View;
import android.widget.RemoteViews;
import android.graphics.*;
import android.util.TypedValue;
import java.util.TimeZone;

/** Responsive home-screen cards. The launcher, rather than a service timer, runs visible frames. */
public class KabarWidget extends AppWidgetProvider {
    private static final int[] FRAMES={R.id.widget_art,R.id.widget_art_next,R.id.widget_art_2,R.id.widget_art_3,R.id.widget_art_4,R.id.widget_art_5,R.id.widget_art_6,R.id.widget_art_7};
    @Override public void onUpdate(Context c,AppWidgetManager manager,int[] ids){for(int id:ids)update(c,manager,id,manager.getAppWidgetOptions(id));}
    @Override public void onAppWidgetOptionsChanged(Context c,AppWidgetManager manager,int id,Bundle options){update(c,manager,id,options);}
    private static void update(Context c,AppWidgetManager manager,int id,Bundle options){
        boolean portrait=c.getResources().getConfiguration().orientation!=android.content.res.Configuration.ORIENTATION_LANDSCAPE;
        int height=options.getInt(portrait?AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT:AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,280);
        int width=options.getInt(portrait?AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH:AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH,320);
        manager.updateAppWidget(id,views(c,width,height));
    }
    public static void updateAll(Context c){AppWidgetManager m=AppWidgetManager.getInstance(c);int[] ids=m.getAppWidgetIds(new ComponentName(c,KabarWidget.class));if(ids.length>0)new KabarWidget().onUpdate(c,m,ids);}
    public static String action(KabarState s){org.json.JSONObject e=s.events.optJSONObject(0);return e==null?"idle":e.optString("kind","idle");}
    private static String status(Context c,KabarState s){
        if(action(s).equals("meal")&&s.mealAt>0)return LocalProfile.label(c,s.mealCategory);
        if(s.location.equals("home"))return LocalProfile.text(c,"Di ","At ","In ")+LocalProfile.label(c,s.home);
        if(s.location.equals("outside"))return LocalProfile.label(c,s.outside);
        return LocalProfile.text(c,"Belum ada kabar","No update yet","Noch kein Update");
    }
    private static long statusAt(KabarState s){return action(s).equals("meal")&&s.mealAt>0?s.mealAt:s.locationAt;}
    public static Bitmap art(Context c,KabarState s,int frame){return art(c,s,frame,Store.isTwoWay(c));}
    private static Bitmap art(Context c,KabarState s,int frame,boolean together){
        // Opaque scenes need no alpha. An exact 2x pixel grid improves definition
        // while eight RGB565 frames total only 655,360 bytes in RemoteViews.
        Bitmap bitmap=Bitmap.createBitmap(320,128,Bitmap.Config.RGB_565);bitmap.setHasAlpha(false);
        DayScene scene=new DayScene(c,together,System.currentTimeMillis(),TimeZone.getDefault(),action(s),frame);
        scene.layout(0,0,320,128);scene.draw(new Canvas(bitmap));return bitmap;
    }
    public static RemoteViews views(Context c){return views(c,320,280);}
    public static RemoteViews views(Context c,int width,int height){
        TimeZone.setDefault(null);
        KabarState s=Store.state(c),peer=Store.peerState(c);long now=System.currentTimeMillis();TimeZone zone=TimeZone.getDefault();
        if(peer!=null&&peer.revision==0&&peer.locationAt==0&&peer.mealAt==0)peer=null;
        boolean together=Store.isTwoWay(c),paired=!Store.role(c).isEmpty(),canSend=Store.canSend(c),enabled=Store.prefs(c).getBoolean("enabled",true);
        Appearance a=new Appearance(together,new Appearance(c).dark);
        float font=Math.max(1,c.getResources().getConfiguration().fontScale);
        boolean compact=height<(together?300:245)*font||width<240,full=!compact&&height>=340*font;
        boolean tiny=compact&&height<190*font;
        boolean motion=paired&&enabled&&LocalProfile.prefs(c).getBoolean("animations",true)&&!c.getSystemService(PowerManager.class).isPowerSaveMode()&&android.provider.Settings.Global.getFloat(c.getContentResolver(),android.provider.Settings.Global.ANIMATOR_DURATION_SCALE,1)>0;
        int layout=compact?(motion?R.layout.widget_compact:R.layout.widget_compact_still):full?(motion?R.layout.widget:R.layout.widget_still):(motion?R.layout.widget_medium:R.layout.widget_medium_still);
        RemoteViews v=new RemoteViews(c.getPackageName(),layout);
        int background=together?(a.dark?R.drawable.widget_seirama_dark:R.drawable.widget_seirama_light):(a.dark?R.drawable.widget_default_dark:R.drawable.widget_default_light);
        int button=together?(a.dark?R.drawable.widget_button_seirama_dark:R.drawable.widget_button_seirama_light):(a.dark?R.drawable.widget_button_default_dark:R.drawable.widget_button_default_light);
        int card=together?(a.dark?R.drawable.widget_card_seirama_dark:R.drawable.widget_card_seirama_light):(a.dark?R.drawable.widget_card_default_dark:R.drawable.widget_card_default_light);
        v.setInt(R.id.widget_root,"setBackgroundResource",background);
        for(int id:new int[]{R.id.widget_own_card,R.id.widget_peer_card})v.setInt(id,"setBackgroundResource",card);
        for(int id:new int[]{R.id.widget_title,R.id.widget_location,R.id.widget_meal,R.id.widget_outside,R.id.widget_home_action,R.id.widget_meal_action,R.id.widget_peer_status})v.setTextColor(id,a.ink);
        for(int id:new int[]{R.id.widget_time,R.id.widget_home,R.id.widget_city,R.id.widget_connection,R.id.widget_own_name,R.id.widget_peer_time,R.id.widget_peer_name})v.setTextColor(id,a.muted);
        v.setTextColor(R.id.widget_phase,a.accent);
        for(int id:new int[]{R.id.widget_outside,R.id.widget_home_action,R.id.widget_meal_action,R.id.widget_phase})v.setInt(id,"setBackgroundResource",button);
        int[] icons=together?(a.dark?new int[]{R.drawable.widget_icon_outside_seirama_dark,R.drawable.widget_icon_home_seirama_dark,R.drawable.widget_icon_meal_seirama_dark}:new int[]{R.drawable.widget_icon_outside_seirama_light,R.drawable.widget_icon_home_seirama_light,R.drawable.widget_icon_meal_seirama_light}):(a.dark?new int[]{R.drawable.widget_icon_outside_default_dark,R.drawable.widget_icon_home_default_dark,R.drawable.widget_icon_meal_default_dark}:new int[]{R.drawable.widget_icon_outside_default_light,R.drawable.widget_icon_home_default_light,R.drawable.widget_icon_meal_default_light});
        int i=0;for(int id:new int[]{R.id.widget_outside,R.id.widget_home_action,R.id.widget_meal_action})v.setTextViewCompoundDrawables(id,icons[i++],0,0,0);
        for(i=0;i<(motion?FRAMES.length:1);i++)v.setImageViewBitmap(FRAMES[i],art(c,s,i*15,together));
        String[][] phases={{"Pagi","Morning","Morgen"},{"Siang","Daytime","Tag"},{"Sore","Evening","Abend"},{"Malam","Night","Nacht"}};
        int phase=StatusLogic.phase(now,zone);
        v.setTextViewText(R.id.widget_phase,LocalProfile.text(c,phases[phase][0],phases[phase][1],phases[phase][2]));
        v.setTextViewText(R.id.widget_title,!paired?"abc":together?"♥ Seirama":s.name+" · abc");
        v.setTextViewText(R.id.widget_own_name,LocalProfile.text(c,"Kamu · ","You · ","Du · ")+s.name);
        v.setViewVisibility(R.id.widget_own_name,together&&!tiny?View.VISIBLE:View.GONE);
        v.setTextViewText(R.id.widget_location,paired?(together&&tiny?LocalProfile.text(c,"Kamu · ","You · ","Du · "):"")+status(c,s):LocalProfile.text(c,"Bagikan kabarmu","Share your day","Teile deinen Tag"));
        v.setTextViewText(R.id.widget_time,paired?LocalProfile.stamp(c,statusAt(s)):LocalProfile.text(c,"Ketuk untuk menghubungkan","Tap to connect","Zum Verbinden tippen"));
        v.setViewVisibility(R.id.widget_time,together&&tiny&&font>1.15f?View.GONE:View.VISIBLE);
        v.setTextViewText(R.id.widget_home,LocalProfile.label(c,s.home)+" · "+LocalProfile.stamp(c,s.homeAt));
        v.setTextViewText(R.id.widget_meal,s.mealAt==0?LocalProfile.text(c,"Makan belum tercatat","Meal not recorded","Essen nicht erfasst"):"✓ "+LocalProfile.label(c,s.mealCategory)+" · "+LocalProfile.stamp(c,s.mealAt));
        v.setTextViewText(R.id.widget_city,s.gps==null?"":(s.gps.city.isEmpty()?LocalProfile.text(c,"Kota belum diketahui","City unavailable","Stadt unbekannt"):s.gps.city)+" · "+LocalProfile.stamp(c,s.gps.at));
        String waiting=LocalProfile.text(c,"Menunggu kabar pasangan","Waiting for partner's update","Warte auf ein Partner-Update");
        v.setTextViewText(R.id.widget_peer_name,peer==null?LocalProfile.text(c,"Pasangan","Partner","Partner"):peer.name);
        v.setTextViewText(R.id.widget_peer_status,peer==null?waiting:status(c,peer));
        v.setTextViewText(R.id.widget_peer_time,peer==null?LocalProfile.text(c,"Hubungkan dari kedua HP","Link from both phones","Auf beiden Telefonen verbinden"):LocalProfile.stamp(c,statusAt(peer)));
        v.setViewVisibility(R.id.widget_peer_card,together?View.VISIBLE:View.GONE);
        v.setViewVisibility(R.id.widget_peer_time,tiny?View.GONE:View.VISIBLE);
        if(tiny){
            int padding=Math.round(5*c.getResources().getDisplayMetrics().density);
            for(int id:new int[]{R.id.widget_own_card,R.id.widget_peer_card})v.setViewPadding(id,padding,padding,padding,padding);
            v.setTextViewTextSize(R.id.widget_location,TypedValue.COMPLEX_UNIT_SP,14);
            v.setTextViewTextSize(R.id.widget_peer_status,TypedValue.COMPLEX_UNIT_SP,13);
        }
        String connection=!paired?LocalProfile.text(c,"Mulai di aplikasi ↗","Get started in the app ↗","In der App beginnen ↗"):!enabled?"Ⅱ "+LocalProfile.text(c,"Dijeda","Paused","Pausiert"):Store.pending(c)>0?"↥ "+Store.pending(c)+LocalProfile.text(c," kabar menunggu"," pending updates"," ausstehende Updates"):together&&!Store.reciprocity(c).equals("active")?LocalProfile.text(c,"Hubungkan kedua HP untuk saling berkabar","Link both phones to share both ways","Beide Telefone für gegenseitige Updates verbinden"):LocalProfile.text(c,"Buka kabar ↗","Open update ↗","Update öffnen ↗");
        v.setTextViewText(R.id.widget_connection,connection);
        v.setViewVisibility(R.id.widget_meal,paired&&!compact&&(!together||full)?View.VISIBLE:View.GONE);
        v.setViewVisibility(R.id.widget_home,paired&&full&&!together?View.VISIBLE:View.GONE);
        v.setViewVisibility(R.id.widget_city,paired&&full&&s.gps!=null?View.VISIBLE:View.GONE);
        v.setViewVisibility(R.id.widget_connection,compact?View.GONE:View.VISIBLE);
        v.setViewVisibility(R.id.widget_actions,canSend&&height>=((together?235:195)*font)&&width>=225?View.VISIBLE:View.GONE);
        v.setTextViewText(R.id.widget_outside,LocalProfile.label(c,s.outside));v.setTextViewText(R.id.widget_home_action,LocalProfile.label(c,s.home));v.setTextViewText(R.id.widget_meal_action,LocalProfile.label(c,s.meal));
        if(width<300)for(int id:new int[]{R.id.widget_outside,R.id.widget_home_action,R.id.widget_meal_action})v.setTextViewTextSize(id,TypedValue.COMPLEX_UNIT_SP,11);
        String description=!paired?LocalProfile.text(c,"abc. Ketuk untuk menghubungkan perangkat.","abc. Tap to connect devices.","abc. Zum Verbinden tippen."):s.name+", "+status(c,s)+", "+LocalProfile.stamp(c,statusAt(s));
        v.setContentDescription(R.id.widget_own_card,description);
        v.setContentDescription(R.id.widget_peer_card,peer==null?waiting:peer.name+", "+status(c,peer)+", "+LocalProfile.stamp(c,statusAt(peer)));
        v.setOnClickPendingIntent(R.id.widget_root,open(c,"",10,false));v.setOnClickPendingIntent(R.id.widget_own_card,open(c,"",14,false));v.setOnClickPendingIntent(R.id.widget_peer_card,open(c,"",15,true));
        v.setOnClickPendingIntent(R.id.widget_outside,open(c,"outside",11,false));v.setOnClickPendingIntent(R.id.widget_home_action,open(c,"home",12,false));v.setOnClickPendingIntent(R.id.widget_meal_action,open(c,"meal",13,false));
        return v;
    }
    private static PendingIntent open(Context c,String action,int request,boolean peer){return PendingIntent.getActivity(c,request,AppEntry.open(c).putExtra("quickAction",action).putExtra("showPeer",peer).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP),PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);}
}
