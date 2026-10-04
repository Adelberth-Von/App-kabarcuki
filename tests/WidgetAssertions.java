package id.kabar.app;

import android.content.*;
import android.content.res.Configuration;
import android.os.Parcel;
import android.view.*;
import android.widget.*;
import java.util.Map;
import org.json.*;

/** UI-only emulator checks; call on the main thread after stopping the disposable QA sync service. */
public final class WidgetAssertions {
    private static int checks;
    private static void check(boolean condition,String message){checks++;if(!condition)throw new IllegalStateException("Widget QA: "+message);}
    @SuppressWarnings("unchecked") private static void restore(android.content.SharedPreferences p,Map<String,?> values){
        android.content.SharedPreferences.Editor e=p.edit().clear();
        for(Map.Entry<String,?> value:values.entrySet()){
            Object v=value.getValue();String k=value.getKey();
            if(v instanceof String)e.putString(k,(String)v);else if(v instanceof Boolean)e.putBoolean(k,(Boolean)v);else if(v instanceof Integer)e.putInt(k,(Integer)v);else if(v instanceof Long)e.putLong(k,(Long)v);else if(v instanceof Float)e.putFloat(k,(Float)v);else if(v instanceof java.util.Set)e.putStringSet(k,(java.util.Set<String>)v);
        }
        e.commit();
    }
    private static float dp(Context c,int value){return value*c.getResources().getDisplayMetrics().density;}
    private static void screenshot(Context c,View view,String name)throws java.io.IOException {
        android.graphics.Bitmap image=android.graphics.Bitmap.createBitmap(view.getWidth(),view.getHeight(),android.graphics.Bitmap.Config.ARGB_8888);
        try{view.draw(new android.graphics.Canvas(image));try(java.io.FileOutputStream out=new java.io.FileOutputStream(new java.io.File(c.getCacheDir(),name))){image.compress(android.graphics.Bitmap.CompressFormat.PNG,100,out);}}finally{image.recycle();}
    }
    private static int bottom(View child,View root){int y=child.getBottom();ViewParent parent=child.getParent();while(parent instanceof View&&parent!=root){y+=((View)parent).getTop();parent=parent.getParent();}return y;}
    private static void fits(View view,View root,String size){
        if(view.getVisibility()!=View.VISIBLE)return;
        check(bottom(view,root)<=root.getHeight()-root.getPaddingBottom()+1,size+" clips "+view.getClass().getSimpleName()+" below card");
        if(view instanceof ViewGroup)for(int i=0;i<((ViewGroup)view).getChildCount();i++)fits(((ViewGroup)view).getChildAt(i),root,size);
    }
    public static int run(Context original)throws Exception {
        checks=0;Map<String,?> saved=Store.prefs(original).getAll(),profile=LocalProfile.prefs(original).getAll();
        try {
            KabarState own=new KabarState();own.name="Alice";own.location="home";own.locationAt=1735720200000L;own.homeAt=own.locationAt;own.mealAt=own.locationAt+60000;own.mealCategory="Makan siang";own.revision=2;
            own.events=new JSONArray().put(new JSONObject().put("kind","meal").put("label","Makan siang").put("at",own.mealAt));
            KabarState peer=new KabarState();peer.name="Bob";peer.location="outside";peer.locationAt=own.locationAt+120000;peer.revision=3;
            LocalProfile.prefs(original).edit().putBoolean("animations",true).putString("language","id").putBoolean("clock12",false).commit();
            for(boolean duplex:new boolean[]{false,true}) {
                Store.prefs(original).edit().putString("role",duplex?"duplex":"sender").putString("state",own.json().toString()).putString("peerCode",duplex?"widget-qa-placeholder":"").putString("peerState",peer.json().toString()).putBoolean("enabled",true).putBoolean("peerConfirmed",true).commit();
                for(float font:new float[]{1f,1.5f}) {
                    Configuration config=new Configuration(original.getResources().getConfiguration());config.fontScale=font;Context c=original.createConfigurationContext(config);
                    for(int[] size:new int[][]{{180,150},{230,180},{320,235},{320,280},{320,360},{360,560}}) {
                        RemoteViews rv=KabarWidget.views(c,size[0],size[1]);View widget=rv.apply(c,new FrameLayout(c));
                        widget.measure(View.MeasureSpec.makeMeasureSpec(Math.round(dp(c,size[0])),View.MeasureSpec.EXACTLY),View.MeasureSpec.makeMeasureSpec(Math.round(dp(c,size[1])),View.MeasureSpec.EXACTLY));
                        widget.layout(0,0,widget.getMeasuredWidth(),widget.getMeasuredHeight());
                        String label=(duplex?"duplex":"one-way")+" "+size[0]+"x"+size[1]+" font "+font;
                        fits(widget.findViewById(R.id.widget_title),widget,label);fits(widget.findViewById(R.id.widget_own_card),widget,label);fits(widget.findViewById(R.id.widget_peer_card),widget,label);fits(widget.findViewById(R.id.widget_actions),widget,label);
                        check(widget.findViewById(R.id.widget_frames).getHeight()>0,label+" has no artwork height");
                        check(((ViewFlipper)widget.findViewById(R.id.widget_frames)).getChildCount()==8,label+" frame count");
                        check(((TextView)widget.findViewById(R.id.widget_location)).getText().toString().contains("Makan siang"),label+" latest meal missing");
                        check(widget.findViewById(R.id.widget_peer_card).getVisibility()==(duplex?View.VISIBLE:View.GONE),label+" incorrect peer visibility");
                        if(duplex)check(((TextView)widget.findViewById(R.id.widget_peer_status)).getText().toString().equals("Keluar"),label+" peer overwrote own status");
                        Parcel p=Parcel.obtain();try{rv.writeToParcel(p,0);check(p.dataSize()<950000,label+" oversized RemoteViews parcel");}finally{p.recycle();}
                        if(size[0]>=320&&size[1]!=280)screenshot(c,widget,"widget-"+(duplex?"duplex":"oneway")+"-"+size[1]+"-font"+(font==1f?"1":"15")+".png");
                    }
                }
            }
            LocalProfile.prefs(original).edit().putBoolean("animations",false).commit();
            View still=KabarWidget.views(original).apply(original,new FrameLayout(original));
            check(!((ViewFlipper)still.findViewById(R.id.widget_frames)).isAutoStart(),"animations off must use a static card");
            android.graphics.Bitmap bitmap=KabarWidget.art(original,own,0);try{
                check(bitmap.getWidth()==320&&bitmap.getHeight()==128,"scene must use the exact 2x pixel grid");
                check(bitmap.getConfig()==android.graphics.Bitmap.Config.RGB_565&&!bitmap.hasAlpha(),"opaque scenes must not allocate an alpha channel");
                check(bitmap.getAllocationByteCount()*8==655360,"eight scene bitmaps exceed the 655,360 byte budget");
                check(android.graphics.Color.alpha(bitmap.getPixel(0,0))==255&&android.graphics.Color.alpha(bitmap.getPixel(319,127))==255,"scene background must fill the opaque frame");
            }finally{bitmap.recycle();}
            return checks;
        }finally{restore(Store.prefs(original),saved);restore(LocalProfile.prefs(original),profile);}
    }
}
