package id.kabar.app;

import android.app.*;
import android.content.*;
import android.view.View;
import android.widget.TextView;
import java.io.*;
import java.util.*;
import org.json.*;

/** Disposable emulator fixtures. This source is excluded from release APKs. */
public final class QaProbe {
    private static List<File> roots(Context c) {
        List<File> dirs=new ArrayList<>(Arrays.asList(c.getFilesDir(),c.getCacheDir(),c.getCodeCacheDir(),c.getNoBackupFilesDir(),c.getDir("flutter",0)));
        dirs.addAll(Arrays.asList(c.getExternalFilesDirs(null)));dirs.addAll(Arrays.asList(c.getExternalCacheDirs()));return dirs;
    }
    public static JSONObject cleanup(Context c,boolean seed)throws Exception {
        if(seed) {
            if(Store.role(c).isEmpty())throw new IllegalStateException("Seed only after fresh QA pairing");
            c.getSharedPreferences("abc_qa_extra",0).edit().putString("personal","fixture").commit();
            c.openOrCreateDatabase("abc_qa.db",0,null).close();
            for(File root:roots(c))if(root!=null){root.mkdirs();try(FileOutputStream out=new FileOutputStream(new File(root,"abc-qa-cleanup.txt"))){out.write(1);}}
        }
        boolean filesClear=true;for(File root:roots(c))if(root!=null&&new File(root,"abc-qa-cleanup.txt").exists())filesClear=false;
        return new JSONObject().put("filesClear",filesClear).put("databaseClear",!c.getDatabasePath("abc_qa.db").exists())
            .put("extraPreferencesClear",c.getSharedPreferences("abc_qa_extra",0).getAll().isEmpty())
            .put("secretsClear",!Store.prefs(c).contains("code")&&!Store.prefs(c).contains("private"))
            .put("notificationsClear",c.getSystemService(NotificationManager.class).getActiveNotifications().length==0);
    }
    public static JSONObject surfaces(Context c,boolean seed)throws Exception {
        if(seed) {
            long at=System.currentTimeMillis();SyncService.channels(c);
            android.os.Bundle metadata=new android.os.Bundle();metadata.putString("abcName","QA");metadata.putString("abcLabel","Makan");metadata.putLong("abcAt",at);
            c.getSystemService(NotificationManager.class).notify(2,new Notification.Builder(c,"updates").setSmallIcon(R.drawable.notification_icon)
                .setContentTitle("QA").setContentText(LocalProfile.stamp(c,at)).addExtras(metadata).build());
        }
        View widget=KabarWidget.views(c).apply(c,null);
        JSONObject result=new JSONObject();
        result.put("widgetAnimated",((android.widget.ViewFlipper)widget.findViewById(R.id.widget_frames)).isAutoStart());
        for(int id:new int[]{R.id.widget_location,R.id.widget_home,R.id.widget_meal})result.put("widget"+id,((TextView)widget.findViewById(id)).getText().toString());
        for(android.service.notification.StatusBarNotification n:c.getSystemService(NotificationManager.class).getActiveNotifications())if(n.getId()==2) {
            result.put("notification",n.getNotification().extras.getCharSequence(Notification.EXTRA_TEXT));
            result.put("notificationExpanded",n.getNotification().extras.getCharSequence(Notification.EXTRA_BIG_TEXT));
            result.put("onlyAlertOnce",(n.getNotification().flags&Notification.FLAG_ONLY_ALERT_ONCE)!=0);
        }
        for(Thread thread:Thread.getAllStackTraces().keySet())if(thread.getName().equals("KabarSync"))result.put("senderThread",thread.getState().name());
        return result;
    }
}
