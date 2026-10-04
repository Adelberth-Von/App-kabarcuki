package id.kabar.app;

import android.content.Context;
import android.graphics.*;
import android.view.View;

/** Hand-drawn 24-pixel icons with consistent outlines and highlight colours. */
public class PixelArt extends View {
    private final String kind;
    public PixelArt(Context c,String kind){super(c);this.kind=kind;setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);}
    @Override protected void onDraw(Canvas canvas){
        super.onDraw(canvas);float scale=Math.min(getWidth()/24f,getHeight()/24f);
        canvas.save();canvas.translate((getWidth()-24*scale)/2,(getHeight()-24*scale)/2);canvas.scale(scale,scale);
        drawIcon(canvas,kind);canvas.restore();
    }
    public static void drawIcon(Canvas canvas,String kind){
        int[][] pixels;
        switch(kind){
            case "brand": pixels=new int[][]{{9,4,13,12,0x846379},{10,3,12,10,0xDCA4B6},{12,5,8,6,0xF8DFCF},{17,13,3,3,0xDCA4B6},{2,7,16,12,0x354F68},{1,9,18,8,0x354F68},{3,8,14,9,0x75A8AD},{4,9,12,7,0xFAEDCF},{4,18,5,2,0x354F68},{4,20,3,2,0x354F68},{5,18,3,2,0x75A8AD},{7,12,2,2,0x628796},{11,12,2,2,0xBE849B},{11,5,1,2,0xFFF1DA},{20,2,1,2,0xC399A4},{19,3,3,1,0xC399A4}};break;
            case "home": pixels=new int[][]{{3,13,18,9,0x62526A},{4,13,16,8,0xE5C5A3},{5,14,14,6,0xF2DEB7},{1,10,22,3,0x435D79},{3,8,18,2,0x435D79},{5,6,14,2,0x435D79},{7,4,10,2,0x435D79},{9,2,6,2,0x435D79},{4,9,16,1,0x77A5AE},{7,7,10,1,0x77A5AE},{10,5,4,1,0x77A5AE},{17,3,3,5,0xB58B8D},{16,2,5,1,0xDFBEA2},{6,14,5,5,0xA48283},{7,15,3,3,0xFAE7AA},{8,15,1,3,0xF6F2D5},{14,16,4,6,0x657F8A},{15,17,2,4,0x8DA6A3},{17,19,1,1,0xFFE2B0},{13,22,7,1,0xC1A18F},{2,20,4,3,0xB1868A},{2,18,3,2,0x8CAA85},{4,17,2,2,0xB4C78B}};break;
            case "meal": pixels=new int[][]{{2,13,20,3,0x4D6079},{3,16,18,3,0x4D6079},{5,19,14,2,0x4D6079},{8,21,8,2,0x4D6079},{3,14,18,2,0xF8ECC8},{5,17,14,2,0x8FAFB5},{8,20,8,1,0x75A0AD},{4,11,16,2,0xDDB99B},{6,9,12,2,0xF8E3B2},{8,8,8,1,0xFFF2CB},{6,11,3,1,0xF7D490},{13,10,3,3,0xD48B72},{14,10,1,1,0xECAA75},{17,8,4,4,0x6C927B},{18,7,3,2,0xA8BE89},{9,3,1,3,0x8DA6AD},{10,1,1,2,0xBBC9C5},{13,2,1,3,0x8DA6AD},{14,5,1,2,0xBBC9C5},{2,22,4,1,0xDEC7A7},{19,22,3,1,0xDEC7A7}};break;
            case "outside": pixels=new int[][]{{8,2,7,2,0x4F485D},{7,4,9,5,0x4F485D},{8,5,7,5,0xEDC3A1},{9,4,4,2,0x4F485D},{9,7,1,1,0x4F485D},{13,7,1,1,0x4F485D},{8,9,2,1,0xD69794},{13,9,2,1,0xD69794},{7,11,9,7,0x66939D},{8,11,7,1,0xC8DAD1},{11,13,1,4,0xA5BFC0},{4,11,3,6,0xAE8182},{5,10,2,2,0xE0C4A6},{16,12,2,5,0x66939D},{16,17,2,1,0xEDC3A1},{8,18,3,4,0x4F485D},{14,18,3,3,0x4F485D},{7,22,4,1,0xEBDAC0},{14,21,5,1,0xEBDAC0},{19,5,3,1,0xBA8D9F},{21,4,1,3,0xBA8D9F}};break;
            case "heart": pixels=new int[][]{{4,6,6,3,0x70566D},{14,6,6,3,0x70566D},{2,9,20,5,0x70566D},{4,14,16,3,0x70566D},{7,17,10,3,0x70566D},{10,20,4,2,0x70566D},{5,8,5,2,0xE9B3BD},{14,8,5,2,0xE9B3BD},{4,10,16,4,0xD995AD},{6,14,12,3,0xD995AD},{9,17,6,2,0xBE7C9B},{6,9,2,3,0xFADED2}};break;
            case "history": pixels=new int[][]{{5,3,14,19,0x536F83},{6,4,12,17,0xE8D4B5},{4,6,3,2,0xBD98A0},{4,11,3,2,0xBD98A0},{4,16,3,2,0xBD98A0},{9,6,6,1,0xB1A69B},{9,9,6,1,0xB1A69B},{9,12,6,1,0xB1A69B},{12,15,8,6,0x75A5A8},{14,14,4,8,0x75A5A8},{15,16,1,4,0xFCEAC8},{15,19,3,1,0xFCEAC8}};break;
            case "location": pixels=new int[][]{{7,2,10,2,0x59667F},{4,4,16,9,0x59667F},{6,13,12,4,0x59667F},{8,17,8,3,0x59667F},{10,20,4,3,0x59667F},{7,4,10,2,0xB588A4},{6,6,12,6,0xD5A1B1},{8,12,8,4,0xB588A4},{10,16,4,3,0xB588A4},{9,6,6,6,0xF9E5C6},{11,8,2,2,0x8DA6AF},{6,6,2,3,0xEBC5C9}};break;
            default:drawIcon(canvas,"outside");return;
        }
        Paint paint=new Paint();paint.setAntiAlias(false);
        for(int[] p:pixels){paint.setColor(0xff000000|p[4]);canvas.drawRect(p[0],p[1],p[0]+p[2],p[1]+p[3],paint);}
    }
}
