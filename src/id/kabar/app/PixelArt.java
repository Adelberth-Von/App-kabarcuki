package id.kabar.app;

import android.content.Context;
import android.graphics.*;
import android.view.View;

/** Integer-grid pixel illustrations drawn natively; no downloaded assets. */
public class PixelArt extends View {
    private final String kind;
    private final Paint paint=new Paint();
    public PixelArt(Context c,String kind){super(c);this.kind=kind;setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);}
    private void rect(Canvas c,int x,int y,int w,int h,String color) {
        paint.setColor(Color.parseColor(color));c.drawRect(x,y,x+w,y+h,paint);
    }
    @Override protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);float scale=Math.min(getWidth()/40f,getHeight()/32f);
        canvas.save();canvas.translate((getWidth()-40*scale)/2,(getHeight()-32*scale)/2);canvas.scale(scale,scale);
        if(kind.equals("meal"))bowl(canvas);else if(kind.equals("outside"))person(canvas);else house(canvas);
        canvas.restore();
    }
    private void house(Canvas c) {
        rect(c,2,28,36,2,"#AEBCA6");rect(c,31,16,2,12,"#7D775D");
        rect(c,27,8,10,10,"#678D63");rect(c,25,11,14,6,"#678D63");rect(c,29,6,6,3,"#8FA97A");
        rect(c,8,14,20,14,"#31493F");rect(c,10,15,16,12,"#E4D1AE");
        rect(c,6,12,24,3,"#374C51");rect(c,8,10,20,2,"#374C51");rect(c,10,8,16,2,"#374C51");rect(c,12,6,12,2,"#374C51");
        rect(c,22,4,3,6,"#69766B");rect(c,12,17,4,4,"#EAA375");rect(c,20,17,4,4,"#EAA375");
        rect(c,13,17,1,4,"#FFF0C2");rect(c,21,17,1,4,"#FFF0C2");rect(c,17,22,4,6,"#657561");
        rect(c,5,24,3,4,"#BC8C68");rect(c,4,21,5,3,"#789569");rect(c,28,25,2,3,"#BC8C68");
    }
    private void bowl(Canvas c) {
        rect(c,6,17,28,3,"#3D473A");rect(c,8,20,24,4,"#6A5546");rect(c,11,24,18,3,"#6A5546");rect(c,15,27,10,2,"#3D473A");
        rect(c,9,13,22,4,"#FBF0CF");rect(c,12,10,16,4,"#FBF0CF");rect(c,15,8,10,3,"#FBF0CF");
        rect(c,10,15,5,2,"#E8DAB1");rect(c,20,13,6,4,"#E5A066");rect(c,22,12,3,2,"#F0BD7D");
        rect(c,26,10,5,6,"#678B54");rect(c,28,9,4,4,"#88A562");rect(c,16,5,2,3,"#B7BCAF");rect(c,18,2,2,3,"#B7BCAF");
    }
    private void person(Canvas c) {
        rect(c,8,28,24,2,"#AEBCA6");rect(c,17,6,9,3,"#273D38");rect(c,15,9,12,6,"#273D38");
        rect(c,18,10,7,7,"#EBC198");rect(c,23,12,3,2,"#EBC198");rect(c,23,11,1,2,"#273D38");
        rect(c,14,17,10,9,"#F9EDD6");rect(c,10,18,4,8,"#526E5D");rect(c,12,16,4,2,"#526E5D");
        rect(c,23,19,3,6,"#EBC198");rect(c,16,25,4,4,"#40565E");rect(c,21,25,4,4,"#40565E");
        rect(c,14,28,6,2,"#273D38");rect(c,21,28,7,2,"#273D38");
    }
}
