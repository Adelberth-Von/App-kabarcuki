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
        bg=color(dark?(relationship?"211B28":"18231F"):(relationship?"FFF5F6":"F8F6F0"));
        ink=color(dark?"F5EEE6":(relationship?"492F42":"24352E"));
        muted=color(dark?"C1BCB5":(relationship?"795F73":"657265"));
        surface=color(dark?(relationship?"302736":"24342D"):"FFFFFF");
        tint=color(dark?(relationship?"493346":"334A3D"):(relationship?"F5DFE8":"DEE6D8"));
        accent=color(dark?(relationship?"F5B6CE":"B5D7AC"):(relationship?"954965":"496651"));
        peach=color(dark?(relationship?"553B48":"594534"):(relationship?"E9DDF8":"F9D2BC"));
        meal=color(dark?(relationship?"423046":"3C392C"):(relationship?"F3E7F7":"F0E8D7"));
    }
    private static int color(String hex){return Color.parseColor("#"+hex);}
}
