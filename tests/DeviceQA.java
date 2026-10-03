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
        android.util.Log.i("KabarQA","Click: "+label);
        main(()->{View v=findAction(activity.getWindow().getDecorView(),label);ok(v!=null,"UI control exists: "+label);v.performClick();});
    }
    private View findAction(View v,String label){
        if(v.isClickable()&&(label.equals(v.getContentDescription())||(v instanceof TextView&&label.equals(((TextView)v).getText().toString()))))return v;
        if(v instanceof ViewGroup){ViewGroup g=(ViewGroup)v;for(int i=0;i<g.getChildCount();i++){View found=findAction(g.getChildAt(i),label);if(found!=null)return found;}}return null;
    }
    private void acceptStatus(){main(()->{ok(activity.confirmationDialog!=null&&activity.confirmationDialog.isShowing(),"confirmation shown before status save");activity.confirmationDialog.getButton(AlertDialog.BUTTON_POSITIVE).performClick();});}
    private void status(String label){click(label);SystemClock.sleep(300);acceptStatus();}
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
                c.stopService(new Intent(c,SyncService.class));Store.prefs(c).edit().clear().commit();Appearance.prefs(c).edit().clear().commit();
                Intent launch=new Intent(c,MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                activity=(MainActivity)startActivitySync(launch);waitForIdleSync();
                await("Aku membagikan kabar",5000);click("Aku membagikan kabar");await("Update status",10000);
                ok(Store.role(c).equals("sender"),"sender setup");
                Pairing p=Store.pairing(c);ok(p.privateKey!=null,"private key stored only for sender");
                // Pause delivery before manipulating offline UI, preserving the queue for assertions.
                main(()->{Store.prefs(c).edit().putBoolean("enabled",false).commit();SyncService.stop(c);});
                Thread.sleep(500);
                long before=Store.state(c).revision;click("Kost");ok(Store.state(c).revision==before,"preview does not alter status");main(()->activity.confirmationDialog.getButton(AlertDialog.BUTTON_NEGATIVE).performClick());ok(Store.state(c).revision==before,"cancel leaves status unchanged");
                status("Kost");long home=Store.state(c).homeAt;
                status("Makan");KabarState s=Store.state(c);ok(s.location.equals("home"),"meal preserves home location");ok(s.homeAt==home,"home time preserved");ok(s.mealAt>0,"meal timestamp recorded");
                status("Keluar");s=Store.state(c);ok(s.location.equals("outside"),"outside location recorded");ok(s.homeAt==home,"outside preserves last home");
                ok(Store.pending(c)>=3,"offline actions queued");
                click("Riwayat");await("Di kost",3000);ok(Store.state(c).events.length()==3,"history records every click");
                click("Beranda");status("Sarapan");ok(Store.state(c).breakfastAt>0,"today breakfast row functional");ok(Store.state(c).mealCategory.equals("Sarapan"),"today row selects explicit meal category");ok(Store.state(c).location.equals("outside"),"today row preserves location");
                long breakfast=Store.state(c).breakfastAt;click("Sarapan");main(()->activity.confirmationDialog.getButton(AlertDialog.BUTTON_NEGATIVE).performClick());ok(Store.state(c).breakfastAt==breakfast,"cancel today meal preserves its original time");
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
                ok(Store.state(c).home.equals("Kost"),"edit labels await explicit confirmation");main(()->activity.confirmationDialog.getButton(AlertDialog.BUTTON_POSITIVE).performClick());
                ok(Store.state(c).home.equals("Rumah"),"edited label saved");
                click("Beranda");await("Pergi",3000);status("Rumah");ok(Store.state(c).locationText().equals("Di rumah"),"edited button functional");
                status("Makan malam");ok(Store.state(c).dinnerAt>0,"today dinner row functional");
                main(()->{
                    android.location.Location fresh=new android.location.Location("gps");fresh.setLatitude(-6.2);fresh.setLongitude(106.816666);fresh.setAccuracy(20);fresh.setTime(System.currentTimeMillis());fresh.setElapsedRealtimeNanos(SystemClock.elapsedRealtimeNanos());
                    ok(LocationCapture.fresh(fresh),"fresh device location accepted");fresh.setElapsedRealtimeNanos(SystemClock.elapsedRealtimeNanos()-180000000000L);ok(!LocationCapture.fresh(fresh),"stale cached device location rejected");
                });
                main(()->{
                    RemoteViews rv=KabarWidget.views(c);View widget=rv.apply(c,new FrameLayout(c));
                    ok(find(widget,"Rumah")!=null,"sender widget labels updated");
                    ok(find(widget,"Kabar QA")!=null,"widget sender name updated");
                    ok(((ImageView)widget.findViewById(R.id.widget_art)).getDrawable()!=null,"widget renders native pixel art");
                });
                testLocation(c);
                main(()->scrollView().scrollTo(0,0));Thread.sleep(200);
                saveScreenshot(c,"ui-home.png");
                click("Rumah");saveScreenshot(c,"ui-confirm.png");main(()->activity.confirmationDialog.getButton(AlertDialog.BUTTON_NEGATIVE).performClick());
                testAppearance(c);
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
                status("Kost");status("Makan");status("Keluar");
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
    private void appearanceClick(String control)throws Exception{
        ActivityMonitor monitor=addMonitor(MainActivity.class.getName(),null,false);
        click(control);Activity next=waitForMonitorWithTimeout(monitor,8000);removeMonitor(monitor);
        ok(next instanceof MainActivity,"appearance recreation completes");activity=(MainActivity)next;waitForIdleSync();
    }
    private void testAppearance(Context c)throws Exception{
        String code=Store.prefs(c).getString("code","");long revision=Store.state(c).revision;
        click("Pengaturan");appearanceClick("Tema In Relationship");
        ok(new Appearance(c).relationship&&!new Appearance(c).dark,"relationship chosen without dark mode");
        appearanceClick("Mode gelap");ok(new Appearance(c).relationship&&new Appearance(c).dark,"dark and relationship independent");
        click("Beranda");main(()->scrollView().scrollTo(0,0));saveScreenshot(c,"ui-relationship-dark.png");
        click("Pengaturan");main(()->scrollView().scrollTo(0,0));saveScreenshot(c,"ui-appearance-dark.png");
        appearanceClick("Mode terang");click("Beranda");main(()->scrollView().scrollTo(0,0));saveScreenshot(c,"ui-relationship-light.png");
        click("Pengaturan");appearanceClick("Tema Default");appearanceClick("Mode gelap");click("Beranda");main(()->scrollView().scrollTo(0,0));saveScreenshot(c,"ui-default-dark.png");
        ok(!new Appearance(c).relationship&&new Appearance(c).dark,"default theme keeps dark preference");
        main(()->{
            View widget=KabarWidget.views(c).apply(c,new FrameLayout(c));
            ok(((TextView)widget.findViewById(R.id.widget_title)).getCurrentTextColor()==new Appearance(c).ink,"widget respects dark palette");
        });
        click("Pengaturan");appearanceClick("Mode terang");click("Beranda");
        ok(code.equals(Store.prefs(c).getString("code","")),"appearance preserves pairing");ok(revision==Store.state(c).revision,"appearance does not publish status");
        java.util.TimeZone original=java.util.TimeZone.getDefault();
        try{
            main(()->{java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("Asia/Tokyo"));Store.changed(c);});
            // Modern Android may queue broadcasts; wait for the rendered result, not a fixed delay.
            long deadline=SystemClock.elapsedRealtime()+5000;boolean[] shown={false};
            while(!shown[0]&&SystemClock.elapsedRealtime()<deadline){main(()->shown[0]=find(activity.getWindow().getDecorView(),StatusLogic.clock(System.currentTimeMillis(),java.util.TimeZone.getTimeZone("Asia/Tokyo")))!=null);if(!shown[0])Thread.sleep(100);}
            ok(shown[0],"local clock follows device zone on refresh");
            ok(Store.state(c).revision==revision,"viewer zone leaves state untouched");
        }finally{main(()->{java.util.TimeZone.setDefault(original);Store.changed(c);});}
    }
    private void shell(String command)throws Exception {try(android.os.ParcelFileDescriptor fd=getUiAutomation().executeShellCommand(command);java.io.FileInputStream in=new java.io.FileInputStream(fd.getFileDescriptor())){while(in.read()!=-1){}}}
    private void testLocation(Context c)throws Exception {
        if(!LocationCapture.allowed(c)){
            java.util.concurrent.CountDownLatch denied=new java.util.concurrent.CountDownLatch(1);
            main(()->LocationCapture.start(c,(point,message)->{ok(point==null&&!message.isEmpty(),"capture without permission explains missing location");denied.countDown();}));
            ok(denied.await(5,java.util.concurrent.TimeUnit.SECONDS),"denied location request completes");
        }
        shell("pm grant id.kabar.app android.permission.ACCESS_COARSE_LOCATION");shell("pm grant id.kabar.app android.permission.ACCESS_FINE_LOCATION");
        shell("settings put secure location_mode 0");Thread.sleep(400);
        long before=Store.state(c).revision;click("Rumah");main(()->{View checkbox=find(activity.confirmationDialog.getWindow().getDecorView(),"Sertakan lokasi HP");ok(checkbox!=null,"location is explicit opt-in");checkbox.performClick();});acceptStatus();
        long end=System.currentTimeMillis()+5000;while(Store.state(c).revision==before&&System.currentTimeMillis()<end)Thread.sleep(100);
        ok(Store.state(c).revision==before+1,"GPS disabled still saves confirmed status");ok(Store.state(c).gps==null,"disabled GPS does not invent coordinates");
        shell("settings put secure location_mode 3");shell("appops set id.kabar.app android:mock_location allow");Thread.sleep(400);
        android.location.LocationManager manager=c.getSystemService(android.location.LocationManager.class);
        try{
            main(()->{
                manager.addTestProvider("gps",false,false,false,false,true,true,true,android.location.Criteria.POWER_LOW,android.location.Criteria.ACCURACY_FINE);manager.setTestProviderEnabled("gps",true);
                android.location.Location point=new android.location.Location("gps");point.setLatitude(-6.2);point.setLongitude(106.816666);point.setAccuracy(1);point.setTime(System.currentTimeMillis());point.setElapsedRealtimeNanos(SystemClock.elapsedRealtimeNanos());manager.setTestProviderLocation("gps",point);
            });Thread.sleep(500);
            before=Store.state(c).revision;status("Pergi");end=System.currentTimeMillis()+15000;while(Store.state(c).revision==before&&System.currentTimeMillis()<end)Thread.sleep(100);
            GpsPoint point=Store.state(c).gps;ok(point!=null,"confirmed status captures real LocationManager sample from emulator test provider");ok(Math.abs(point.lat+6.2)<0.00001,"shared coordinate matches sample");
            ok(Store.state(c).events.getJSONObject(0).optJSONObject("gps")!=null,"history retains dated location sample");ok(find(activity.getWindow().getDecorView(),"Lihat di peta")!=null,"map action visible for received coordinate");
            Pairing receiver=Pairing.parse(Store.prefs(c).getString("code",""));JSONArray queue=new JSONArray(Store.prefs(c).getString("queue","[]"));
            JSONObject packet=new JSONObject(receiver.decrypt(queue.getJSONObject(queue.length()-1).getString("body")));ok(packet.getJSONObject("state").getJSONObject("gps").getDouble("lat")==point.lat,"location included in authenticated encrypted packet");
        }finally{main(()->manager.removeTestProvider("gps"));shell("appops set id.kabar.app android:mock_location deny");}
    }
    private void saveScreenshot(Context c,String name)throws Exception {Thread.sleep(400);android.graphics.Bitmap bitmap=getUiAutomation().takeScreenshot();try(java.io.FileOutputStream out=new java.io.FileOutputStream(new java.io.File(c.getCacheDir(),name))){if(bitmap!=null)bitmap.compress(android.graphics.Bitmap.CompressFormat.PNG,100,out);}}
    private ScrollView scrollView(){ViewGroup content=activity.findViewById(android.R.id.content);LinearLayout root=(LinearLayout)content.getChildAt(0);return (ScrollView)root.getChildAt(0);}
}
