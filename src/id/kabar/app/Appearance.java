package id.kabar.app;

import android.content.*;
import android.graphics.Color;

/** Local preferences: never sent in a family status packet. */
final class Appearance {
    final boolean relationship,dark;
    final int bg,ink,muted,surface,tint,accent,peach,meal;
    static SharedPreferences prefs(Context c){return c.getSharedPreferences("appearance",Context.MODE_PRIVATE);}
    Appearance(Context c){this(prefs(c).getBoolean("relationship",false),prefs(c).getBoolean("dark",false));}
    Appearance(boolean relationship,boolean dark){
        this.relationship=relationship;this.dark=dark;
        bg=color(dark?(relationship?"211A24":"161B26"):(relationship?"FFF5F7":"F7F7FC"));
        ink=color(dark?"F6F3FC":(relationship?"4C3044":"292D45"));
        muted=color(dark?"C1BCCD":(relationship?"795C71":"666B84"));
        surface=color(dark?(relationship?"312532":"232A3B"):"FFFFFF");
        tint=color(dark?(relationship?"4C3347":"383455"):(relationship?"F8DFE9":"EBE7FC"));
        accent=color(dark?(relationship?"F5B1CA":"C2B8FF"):(relationship?"AF4B76":"6552BC"));
        peach=color(dark?(relationship?"553B48":"594534"):(relationship?"E9DDF8":"F9D2BC"));
        meal=color(dark?(relationship?"423046":"3C392C"):(relationship?"F3E7F7":"F0E8D7"));
    }
    private static int color(String hex){return Color.parseColor("#"+hex);}
}
