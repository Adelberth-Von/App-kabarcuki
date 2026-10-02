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
        KabarState s=Store.state(c);long now=System.currentTimeMillis();TimeZone zone=TimeZone.getTimeZone(s.zone);
        RemoteViews v=new RemoteViews(c.getPackageName(),R.layout.widget);
        android.graphics.Bitmap art=android.graphics.Bitmap.createBitmap(80,64,android.graphics.Bitmap.Config.ARGB_8888);
        PixelArt illustration=new PixelArt(c,s.location.equals("outside")?"outside":"home");illustration.layout(0,0,80,64);illustration.draw(new android.graphics.Canvas(art));
        v.setImageViewBitmap(R.id.widget_art,art);
        v.setTextViewText(R.id.widget_title,Store.role(c).isEmpty()?"Kabar":"Kabar "+s.name);
        v.setTextViewText(R.id.widget_location,s.locationText()+ (s.locationAt>0?" · "+StatusLogic.when(s.locationAt,now,zone):""));
        v.setTextViewText(R.id.widget_home,"Terakhir di "+s.home.toLowerCase(new java.util.Locale("id"))+": "+StatusLogic.when(s.homeAt,now,zone));
        v.setTextViewText(R.id.widget_meal,s.mealAt==0?"Makan belum tercatat":s.mealCategory+" · "+StatusLogic.when(s.mealAt,now,zone));
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
        Intent i=new Intent(c,MainActivity.class).putExtra("quickAction",action).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP|Intent.FLAG_ACTIVITY_SINGLE_TOP);
        return PendingIntent.getActivity(c,request,i,PendingIntent.FLAG_IMMUTABLE|PendingIntent.FLAG_UPDATE_CURRENT);
    }
}
