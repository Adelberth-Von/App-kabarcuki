package id.kabar.app;

import android.app.*;
import android.content.*;
import android.os.*;
import android.view.*;
import android.widget.*;
import org.json.*;

/** Separate instrumentation APK: never included in the user APK. */
public class DeviceQA extends Instrumentation {
    private Bundle args;
    private int assertions=0;
    private MainActivity activity;
    @Override public void onCreate(Bundle arguments){args=arguments;start();}
    private void ok(boolean value,String label){assertions++;if(!value)throw new AssertionError(label);}
    private void main(Runnable run){runOnMainSync(run);waitForIdleSync();}
    private View find(View view,String label) {
        if(view instanceof TextView && ((TextView)view).getText().toString().equals(label))return view;
        if(label.equals(view.getContentDescription()))return view;
        if(view instanceof ViewGroup){ViewGroup g=(ViewGroup)view;for(int i=0;i<g.getChildCount();i++){View found=find(g.getChildAt(i),label);if(found!=null)return found;}}
        return null;
    }
    private void click(String label) {
        main(()->{View v=find(activity.getWindow().getDecorView(),label);ok(v!=null,"UI control exists: "+label);v.performClick();});
    }
    private void await(String label,long millis) throws Exception {
        long end=System.currentTimeMillis()+millis;
        while(System.currentTimeMillis()<end){if(find(activity.getWindow().getDecorView(),label)!=null)return;Thread.sleep(200);}
        throw new AssertionError("UI missing: "+label);
    }
    @Override public void onStart() {
        Bundle result=new Bundle();
        try {
            Context c=getTargetContext();String mode=args.getString("mode","ui");
            if(mode.equals("ui")){
                c.stopService(new Intent(c,SyncService.class));Store.prefs(c).edit().clear().commit();
                Intent launch=new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                activity=(MainActivity)startActivitySync(launch);waitForIdleSync();
                await("Aku membagikan kabar",5000);click("Aku membagikan kabar");await("Update status",10000);
                ok(Store.role(c).equals("sender"),"sender setup");
                Pairing p=Store.pairing(c);ok(p.privateKey!=null,"private key stored only for sender");
                // Pause delivery before manipulating offline UI, preserving the queue for assertions.
                main(()->{Store.prefs(c).edit().putBoolean("enabled",false).commit();c.stopService(new Intent(c,SyncService.class));});
                Thread.sleep(500);
                click("Kost");long home=Store.state(c).homeAt;
                click("Makan");KabarState s=Store.state(c);ok(s.location.equals("home"),"meal preserves home location");ok(s.homeAt==home,"home time preserved");ok(s.mealAt>0,"meal timestamp recorded");
                click("Keluar");s=Store.state(c);ok(s.location.equals("outside"),"outside location recorded");ok(s.homeAt==home,"outside preserves last home");
                ok(Store.pending(c)>=3,"offline actions queued");
                click("Riwayat");await("Di kost",3000);ok(Store.state(c).events.length()==3,"history records every click");
                click("Pengaturan");await("Edit nama & tombol",3000);
                main(()->{scrollView().scrollTo(0,200);Store.changed(c);});Thread.sleep(150);waitForIdleSync();
                main(()->ok(scrollView().getScrollY()==200,"settings retain scroll after status refresh"));
                click("Edit nama & tombol");
                android.accessibilityservice.AccessibilityServiceInfo info=getUiAutomation().getServiceInfo();info.flags|=android.accessibilityservice.AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS;getUiAutomation().setServiceInfo(info);
                android.view.accessibility.AccessibilityNodeInfo dialogRoot=null;
                java.util.ArrayList<android.view.accessibility.AccessibilityNodeInfo> fields=new java.util.ArrayList<>();
                long dialogDeadline=System.currentTimeMillis()+8000;
                while(fields.size()!=4&&System.currentTimeMillis()<dialogDeadline){
                    for(android.view.accessibility.AccessibilityWindowInfo window:getUiAutomation().getWindows()){
                        android.view.accessibility.AccessibilityNodeInfo candidate=window.getRoot();java.util.ArrayList<android.view.accessibility.AccessibilityNodeInfo> candidateFields=new java.util.ArrayList<>();collectEditable(candidate,candidateFields);
                        if(candidateFields.size()==4){fields=candidateFields;dialogRoot=candidate;break;}
                    }
                    if(fields.size()!=4)Thread.sleep(200);
                }
                ok(fields.size()==4,"editable names form");String[] values={"QA","Pergi","Rumah","Sudah makan"};
                for(int index=0;index<4;index++){Bundle b=new Bundle();b.putCharSequence(android.view.accessibility.AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,values[index]);ok(fields.get(index).performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_SET_TEXT,b),"set edited label");}
                for(android.view.accessibility.AccessibilityNodeInfo node:dialogRoot.findAccessibilityNodeInfosByText("Simpan"))if(node.isClickable())node.performAction(android.view.accessibility.AccessibilityNodeInfo.ACTION_CLICK);
                Thread.sleep(500);waitForIdleSync();
                ok(Store.state(c).home.equals("Rumah"),"edited label saved");
                click("Beranda");await("Pergi",3000);click("Rumah");ok(Store.state(c).locationText().equals("Di rumah"),"edited button functional");
                main(()->{
                    RemoteViews rv=KabarWidget.views(c);View widget=rv.apply(c,new FrameLayout(c));
                    ok(find(widget,"Rumah")!=null,"sender widget labels updated");
                    ok(find(widget,"Kabar QA")!=null,"widget sender name updated");
                    ok(((ImageView)widget.findViewById(R.id.widget_art)).getDrawable()!=null,"widget renders native pixel art");
                });
                main(()->activity.recreate());Thread.sleep(1200);
                ok(Store.state(c).home.equals("Rumah"),"settings survive recreation");
                while(Store.pending(c)<25){KabarState pending=Store.state(c);pending.record("meal",System.currentTimeMillis());Store.saveAndQueue(c,pending,true);}
                long lastSaved=Store.state(c).revision;boolean rejected=false;
                try{KabarState extra=Store.state(c);extra.record("outside",System.currentTimeMillis());Store.saveAndQueue(c,extra,true);}catch(IllegalStateException full){rejected=true;}
                ok(rejected,"full offline queue rejects additional action");ok(Store.pending(c)==25,"offline queue stays bounded");ok(Store.state(c).revision==lastSaved,"rejected action does not overwrite saved state");
                result.putString("stream","PASS Device UI, offline queue, edited buttons, persistence, widget: "+assertions+" assertions");
            }else if(mode.equals("sender")){
                c.stopService(new Intent(c,SyncService.class));Pairing p=Pairing.create();
                Store.prefs(c).edit().clear().putString("role","sender").putString("code",p.code()).putString("private",Pairing.encode(p.privateKey.getEncoded())).putBoolean("enabled",true).commit();
                try(java.io.FileOutputStream out=new java.io.FileOutputStream("/sdcard/Download/kabar-qa-sender.txt")){out.write(p.code().getBytes(java.nio.charset.StandardCharsets.UTF_8));}
                activity=(MainActivity)startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitForIdleSync();
                click("Kost");click("Makan");click("Keluar");
                long end=System.currentTimeMillis()+30000;while(Store.pending(c)>0&&System.currentTimeMillis()<end)Thread.sleep(300);
                ok(Store.pending(c)==0,"native sender flushes queue to relay");ok(Store.state(c).revision==3,"all native sender actions recorded");ok(Store.prefs(c).getLong("publishedAt",0)>0,"relay acknowledges native sender");
                result.putString("stream","PASS Device native sender publishes three actions: "+assertions+" assertions");
            }else if(mode.equals("receiver")){
                String code=args.getString("code");Pairing p=Pairing.parse(code);
                c.stopService(new Intent(c,SyncService.class));
                Store.prefs(c).edit().clear().putString("role","receiver").putString("code",p.code()).putBoolean("enabled",true).commit();
                activity=(MainActivity)startActivitySync(new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));waitForIdleSync();
                main(()->activity.moveTaskToBack(true));
                long end=System.currentTimeMillis()+30000;while(Store.state(c).revision<3&&System.currentTimeMillis()<end)Thread.sleep(300);
                KabarState s=Store.state(c);ok(s.revision>=3,"receiver obtains live state");ok(s.location.equals("outside"),"remote latest location");ok(s.mealAt>0,"remote meal retained");ok(s.homeAt>0,"remote home retained");
                NotificationManager nm=c.getSystemService(NotificationManager.class);boolean notified=false;
                long notifyDeadline=System.currentTimeMillis()+3000;
                while(!notified&&System.currentTimeMillis()<notifyDeadline){for(android.service.notification.StatusBarNotification n:nm.getActiveNotifications())if(n.getId()==2)notified=true;if(!notified)Thread.sleep(100);}
                ok(notified,"actual status notification posted");
                main(()->{RemoteViews rv=KabarWidget.views(c);View widget=rv.apply(c,new FrameLayout(c));ok(widget.findViewById(R.id.widget_actions).getVisibility()==View.GONE,"receiver widget hides sender actions");});
                result.putString("stream","PASS Device live receiver and notification: "+assertions+" assertions");
            }
            finish(Activity.RESULT_OK,result);
        }catch(Throwable e){result.putString("stream","FAIL "+e.toString());android.util.Log.e("KabarQA","Failure",e);finish(Activity.RESULT_CANCELED,result);}
    }
    private void collectEditable(android.view.accessibility.AccessibilityNodeInfo n,java.util.ArrayList<android.view.accessibility.AccessibilityNodeInfo> out){
        if(n==null)return;if(n.isEditable())out.add(n);
        for(int i=0;i<n.getChildCount();i++)collectEditable(n.getChild(i),out);
    }
    private ScrollView scrollView(){ViewGroup content=activity.findViewById(android.R.id.content);LinearLayout root=(LinearLayout)content.getChildAt(0);return (ScrollView)root.getChildAt(0);}
}
