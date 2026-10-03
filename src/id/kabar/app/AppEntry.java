package id.kabar.app;
import android.content.*;
/** Keep legacy builds usable while routing widgets and alerts to the shared UI. */
public final class AppEntry {
    public static Intent open(Context c) {
        String host="id.kabar.app.AbcActivity";
        try { Class.forName(host); } catch(ClassNotFoundException e) { host="id.kabar.app.MainActivity"; }
        return new Intent().setClassName(c,host);
    }
}
