package id.kabar.app;

import android.app.*;
import android.appwidget.*;
import android.content.*;
import android.os.Build;
import android.view.View;
import android.widget.RemoteViews;
import java.util.TimeZone;

public class KabarWidget extends AppWidgetProvider {
    @Override public void onUpdate(Context c,AppWidgetManager manager,int[] ids) {for(int id:ids)manager.updateAppWidget(id,views(c));}
    public static void updateAll(Context c) {
        AppWidgetManager m=AppWidgetManager.getInstance(c);
        int[] ids=m.getAppWidgetIds(new ComponentName(c,KabarWidget.class));
        if(ids.length>0)new KabarWidget().onUpdate(c,m,ids);
    }
    public static RemoteViews views(Context c) {
        KabarState s=Store.state(c);long now=System.currentTimeMillis();TimeZone zone=TimeZone.getDefault();
        RemoteViews v=new RemoteViews(c.getPackageName(),R.layout.widget);Appearance a=new Appearance(c);
        v.setInt(R.id.widget_root,"setBackgroundColor",a.bg);
        for(int id:new int[]{R.id.widget_title,R.id.widget_location,R.id.widget_home,R.id.widget_meal,R.id.widget_connection,R.id.widget_outside,R.id.widget_home_action,R.id.widget_meal_action})v.setTextColor(id,a.ink);
        for(int id:new int[]{R.id.widget_outside,R.id.widget_home_action,R.id.widget_meal_action})v.setInt(id,"setBackgroundColor",a.tint);
        android.graphics.Bitmap art=android.graphics.Bitmap.createBitmap(80,64,android.graphics.Bitmap.Config.ARGB_8888);
        View illustration=a.relationship?new DayScene(c,true,now,zone):new PixelArt(c,s.location.equals("outside")?"outside":"home");illustration.layout(0,0,80,64);illustration.draw(new android.graphics.Canvas(art));
        v.setImageViewBitmap(R.id.widget_art,art);
        v.setTextViewText(R.id.widget_title,Store.role(c).isEmpty()?"abc":"abc · "+s.name);
        v.setTextViewText(R.id.widget_location,LocalProfile.label(c,s.locationText())+ (s.locationAt>0?" · "+LocalProfile.stamp(c,s.locationAt):""));
        v.setTextViewText(R.id.widget_home,LocalProfile.label(c,s.home)+": "+LocalProfile.stamp(c,s.homeAt));
        v.setTextViewText(R.id.widget_meal,s.mealAt==0?LocalProfile.text(c,"Makan belum tercatat","Meal not recorded","Essen nicht erfasst"):LocalProfile.label(c,s.mealCategory)+" · "+LocalProfile.stamp(c,s.mealAt));
        String connection=Store.prefs(c).getString("connection","Buka aplikasi untuk menghubungkan");
        if(StatusLogic.stale(s.locationAt,now))connection="Lokasi sudah lama · "+connection;
        if(Store.pending(c)>0)connection=Store.pending(c)+" kabar menunggu dikirim";
        v.setTextViewText(R.id.widget_connection,connection);
        boolean sender=Store.role(c).equals("sender");
        v.setViewVisibility(R.id.widget_actions,sender?View.VISIBLE:View.GONE);
        v.setTextViewText(R.id.widget_outside,s.outside);v.setTextViewText(R.id.widget_home_action,s.home);v.setTextViewText(R.id.widget_meal_action,s.meal);
        v.setOnClickPendingIntent(R.id.widget_root,open(c,"",10));
        v.setOnClickPendingIntent(R.id.widget_outside,open(c,"outside",11));
        v.setOnClickPendingIntent(R.id.widget_home_action,open(c,"home",12));
        v.setOnClickPendingIntent(R.id.widget_meal_action,open(c,"meal",13));
        return v;
    }
    private static PendingIntent open(Context c,String action,int request) {
        Intent i=AppEntry.open(c).putExtra("quickAction",action).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP);
        return PendingIntent.getActivity(c,request,i,PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);
    }
}
