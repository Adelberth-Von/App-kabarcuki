package id.kabar.app;
import android.content.*;
import android.app.NotificationManager;
import java.io.*;

public final class AppDataCleaner {
    public static void clear(Context c)throws IOException {
        synchronized(Store.LOCK) {
            Store.prefs(c).edit().putBoolean("enabled",false).commit();
            c.stopService(new Intent(c,SyncService.class));
            Store.wakeSync();
            File[] preferences=new File(c.getDataDir(),"shared_prefs").listFiles();
            if(preferences!=null)for(File file:preferences) {
                String name=file.getName();
                if(name.endsWith(".xml")&&!c.getSharedPreferences(name.substring(0,name.length()-4),Context.MODE_PRIVATE).edit().clear().commit())throw new IOException("Cannot clear application preferences");
            }
            // Clear known stores even if no XML file had been persisted yet.
            if(!Store.prefs(c).edit().clear().commit()||!LocalProfile.prefs(c).edit().clear().commit())throw new IOException("Cannot clear application preferences");
            // Deleting a database also removes its journal/WAL companions. A later
            // inventory entry may therefore already be gone; that is success.
            for(String db:c.databaseList())if(!c.deleteDatabase(db)&&c.getDatabasePath(db).exists())throw new IOException("Cannot clear application database");
            for(File dir:new File[]{c.getFilesDir(),c.getCacheDir(),c.getCodeCacheDir(),c.getNoBackupFilesDir(),c.getDir("flutter",Context.MODE_PRIVATE)})ScopedFiles.clear(dir);
            for(File dir:c.getExternalFilesDirs(null))ScopedFiles.clear(dir);
            for(File dir:c.getExternalCacheDirs())ScopedFiles.clear(dir);
            for(File dir:c.getExternalMediaDirs())ScopedFiles.clear(dir);
            c.getSystemService(NotificationManager.class).cancelAll();
        }
        Store.changed(c);
    }
}
