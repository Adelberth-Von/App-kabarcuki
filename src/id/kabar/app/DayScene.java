package id.kabar.app;

import android.content.Context;
import android.graphics.*;
import android.view.View;
import java.util.TimeZone;

/** The sky follows local time; the app's light/dark palette is independent. */
final class DayScene extends View {
    private final boolean together;
    private final long at;
    private final TimeZone zone;
    private final Paint paint=new Paint();
    private final String action;private final int frame;
    DayScene(Context c,boolean together,long at,TimeZone zone){this(c,together,at,zone,"idle",0);}
    DayScene(Context c,boolean together,long at,TimeZone zone,String action,int frame){super(c);this.together=together;this.at=at;this.zone=zone;this.action=action;this.frame=frame;setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);}
    private void r(Canvas c,int x,int y,int w,int h,String color){paint.setColor(Color.parseColor("#"+color));c.drawRect(x,y,x+w,y+h,paint);}
    @Override protected void onDraw(Canvas c){
        int phase=StatusLogic.phase(at,zone);String sky=new String[]{"DCEBE3","D4E9F3","F6CEB3","293653"}[phase];
        c.drawColor(Color.parseColor("#"+sky));float scale=Math.min(getWidth()/112f,getHeight()/38f);c.save();c.translate((getWidth()-112*scale)/2,(getHeight()-38*scale)/2);c.scale(scale,scale);
        if(phase==3){r(c,84,5,7,7,"FFE5AA");r(c,87,4,5,6,sky);for(int x:new int[]{9,25,47,67,102}){r(c,x,4+x%9,1,3,"E2D7BB");r(c,x-1,5+x%9,3,1,"E2D7BB");}}
        else{r(c,83,phase==2?16:6,8,8,"EBA669");r(c,85,phase==2?14:4,4,12,"F6C97E");r(c,13,9,16,2,"FFFAE9");r(c,16,7,8,2,"FFFAE9");r(c,61,12,12,2,"FFFAE9");}
        String land=phase==3?"40584E":together?"B6BEA0":"AAC4A8";
        r(c,0,31,112,7,land);r(c,0,30,112,1,phase==3?"6D8670":"8DA98E");
        r(c,16,19,21,12,"E6CCAC");r(c,13,17,27,3,together?"A16B83":"657D76");r(c,17,14,19,3,together?"A16B83":"657D76");r(c,21,11,11,3,together?"A16B83":"657D76");
        r(c,20,22,5,5,"FFE7A0");r(c,29,23,4,8,"58665A");r(c,91,24,2,8,"817462");r(c,87,17,10,8,phase==3?"657B70":"7D9D7C");r(c,89,14,6,4,phase==3?"657B70":"7D9D7C");
        String shirt=together?"A76B8B":"7980A5";
        if(action.equals("outside")){person(c,51+frame*3,shirt);r(c,48+frame*3,26,3,5,"BC967C");r(c,51+frame*3,33,frame==0?2:4,1,"4E4550");if(together){person(c,38,"9683AD");r(c,35,23-frame,2,5,"EDC8AE");}}
        else if(action.equals("meal")){person(c,50,shirt);if(together)person(c,68,"9683AD");r(c,46,31,together?30:20,2,"B78C76");r(c,48,33,2,3,"886C67");r(c,together?72:62,33,2,3,"886C67");r(c,57,29,5,2,"E6D7B5");r(c,59+frame,25,1,2,"FFFAE9");r(c,56,26+frame*2,3,1,"EDC8AE");if(together){r(c,67,29,5,2,"E6D7B5");r(c,69-frame,25,1,2,"FFFAE9");}}
        else if(action.equals("home")){r(c,47,29,together?30:16,6,together?"BD91AA":"98A0BF");person(c,52,shirt);r(c,51,28,4,3,"F4DCB6");r(c,55,28,3,3,"D1B3D7");r(c,29,23,4,8,"F8DEA5");if(together){person(c,68,"9683AD");r(c,65,23-frame,2,5,"EDC8AE");}}
        else{person(c,53,shirt);if(together)person(c,67,"9683AD");}
        if(together)heart(c,61,14-frame);
        if(phase==0){r(c,43+frame*3,7,2,1,"7C8C91");r(c,46+frame*3,7,2,1,"7C8C91");r(c,45+frame*3,8-frame,1,1,"7C8C91");}
        else if(phase==1){r(c,79+frame,24-frame,2,2,"AF7399");r(c,77+frame,24-frame,2,2,"E9B879");}
        else if(phase==2)r(c,95-frame*3,25+frame*2,2,1,"D89D73");
        else{r(c,43+frame*3,25-frame,1,1,"F9E9A4");r(c,82-frame,27-frame,1,1,"F9E9A4");}
        r(c,45,34,32,1,phase==3?"68756B":"DADEC2");
        for(int x:new int[]{7,42,81,103}){r(c,x,30,1,3,"698E71");r(c,x-1,28,3,2,together?"ECAAC0":"F5DC96");}
        c.restore();
    }
    private void person(Canvas c,int x,String shirt){r(c,x,21,5,2,"4E4550");r(c,x,23,5,4,"EDC8AE");r(c,x-1,27,7,4,shirt);r(c,x,31,2,3,"4E4550");r(c,x+3,31,2,3,"4E4550");}
    private void heart(Canvas c,int x,int y){r(c,x,y,2,2,"CA779A");r(c,x+3,y,2,2,"CA779A");r(c,x,y+2,5,1,"CA779A");r(c,x+1,y+3,3,1,"CA779A");r(c,x+2,y+4,1,1,"CA779A");}
}
