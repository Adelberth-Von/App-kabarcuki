package id.kabar.app;

import android.app.*;
import android.appwidget.AppWidgetManager;
import android.content.*;
import android.content.pm.PackageManager;
import android.graphics.*;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.*;
import android.provider.Settings;
import android.text.InputType;
import android.view.*;
import android.widget.*;
import org.json.*;
import java.util.*;

public class MainActivity extends Activity {
    private static final int BG=Color.rgb(248,246,240), INK=Color.rgb(36,53,46), MUTED=Color.rgb(101,114,101), SAGE=Color.rgb(222,230,216), PEACH=Color.rgb(249,210,188), GREEN=Color.rgb(73,102,81);
    private LinearLayout root,body;
    private int page=0;
    private int renderedPage=-1;
    private String renderedRole="";
    private boolean registered=false,busy=false;
    private final Handler handler=new Handler(Looper.getMainLooper());
    private final BroadcastReceiver updates=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent i){render();}};
    private final Runnable clockRefresh=new Runnable(){public void run(){render();handler.postDelayed(this,60000);}};
    private int dp(float n){return Math.round(n*getResources().getDisplayMetrics().density);}
    private GradientDrawable background(int color,int radius){GradientDrawable d=new GradientDrawable();d.setColor(color);d.setCornerRadius(dp(radius));return d;}
    private TextView text(String value,int size,int color,boolean bold) {
        TextView v=new TextView(this);v.setText(value);v.setTextSize(size);v.setTextColor(color);
        if(bold)v.setTypeface(Typeface.create("sans-serif",Typeface.BOLD));
        v.setLineSpacing(dp(2),1);return v;
    }
    private LinearLayout column(){LinearLayout l=new LinearLayout(this);l.setOrientation(LinearLayout.VERTICAL);return l;}
    private void gap(LinearLayout p,int size){View v=new View(this);p.addView(v,new LinearLayout.LayoutParams(1,dp(size)));}
    private void para(LinearLayout p,String value){p.addView(text(value,14,MUTED,false));}
    private Button button(String label,int color,Runnable click) {
        Button b=new Button(this);b.setText(label);b.setTextSize(15);b.setTextColor(INK);b.setAllCaps(false);
        b.setBackground(background(color,16));b.setMinHeight(dp(52));b.setPadding(dp(12),dp(8),dp(12),dp(8));
        b.setOnClickListener(v->click.run());return b;
    }
    private void wideButton(LinearLayout p,String label,int color,Runnable click){Button b=button(label,color,click);p.addView(b,new LinearLayout.LayoutParams(-1,-2));gap(p,10);}
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);if(state!=null)page=state.getInt("page",0);
        root=column();root.setBackgroundColor(BG);setContentView(root);
        root.setOnApplyWindowInsetsListener((v,insets)->{
            if(Build.VERSION.SDK_INT>=30) {android.graphics.Insets sys=insets.getInsets(WindowInsets.Type.systemBars()|WindowInsets.Type.ime());root.setPadding(sys.left,sys.top,sys.right,sys.bottom);}
            else root.setPadding(insets.getSystemWindowInsetLeft(),insets.getSystemWindowInsetTop(),insets.getSystemWindowInsetRight(),insets.getSystemWindowInsetBottom());
            return insets;
        });
        render();quickAction(getIntent());
    }
    @Override protected void onSaveInstanceState(Bundle out){out.putInt("page",page);super.onSaveInstanceState(out);}
    @Override protected void onNewIntent(Intent i){super.onNewIntent(i);setIntent(i);quickAction(i);}
    private void quickAction(Intent i) {
        String action=i.getStringExtra("quickAction");i.removeExtra("quickAction");
        if(action!=null&&!action.isEmpty()&&Store.role(this).equals("sender"))record(action);
    }
    @Override protected void onResume() {
        super.onResume();
        if(Build.VERSION.SDK_INT>=33)registerReceiver(updates,new IntentFilter("id.kabar.app.CHANGED"),Context.RECEIVER_NOT_EXPORTED);
        else registerReceiver(updates,new IntentFilter("id.kabar.app.CHANGED"));registered=true;
        if(!Store.role(this).isEmpty()) {SyncService.start(this);requestNotifications();}
        handler.postDelayed(clockRefresh,60000);render();
    }
    @Override protected void onPause(){if(registered){unregisterReceiver(updates);registered=false;}handler.removeCallbacks(clockRefresh);super.onPause();}
    private void requestNotifications(){
        SyncService.channels(this);
        if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED&&!Store.prefs(this).getBoolean("askedNotifications",false)){
            Store.prefs(this).edit().putBoolean("askedNotifications",true).apply();requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS},33);
        }
    }
    @Override public void onRequestPermissionsResult(int request,String[] permissions,int[] results){super.onRequestPermissionsResult(request,permissions,results);render();}
    private void render() {
        if(root==null)return;
        String role=Store.role(this);
        int previousScroll=(renderedPage==page&&renderedRole.equals(role)&&root.getChildCount()>0&&root.getChildAt(0) instanceof ScrollView)?((ScrollView)root.getChildAt(0)).getScrollY():0;
        renderedPage=page;renderedRole=role;
        root.removeAllViews();
        ScrollView scroll=new ScrollView(this);scroll.setFillViewport(true);
        body=column();body.setPadding(dp(22),dp(20),dp(22),dp(16));scroll.addView(body);
        root.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        if(previousScroll>0){final int restore=previousScroll;scroll.getViewTreeObserver().addOnGlobalLayoutListener(new android.view.ViewTreeObserver.OnGlobalLayoutListener(){public void onGlobalLayout(){scroll.getViewTreeObserver().removeOnGlobalLayoutListener(this);scroll.scrollTo(0,restore);}});}
        if(role.isEmpty()){welcome();return;}
        if(page==1)history();else if(page==2)settings();else home();
        LinearLayout nav=new LinearLayout(this);nav.setPadding(dp(12),dp(8),dp(12),dp(10));
        String[] tabs={"Beranda","Riwayat","Pengaturan"};
        for(int i=0;i<3;i++){
            final int tab=i;Button b=button(tabs[i],page==i?SAGE:BG,()->{page=tab;render();});b.setTextSize(12);
            LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(0,dp(48),1);lp.setMargins(dp(3),0,dp(3),0);nav.addView(b,lp);
        }
        root.addView(nav);
    }
    private void welcome() {
        gap(body,24);body.addView(text("Kabar",42,INK,true));para(body,"Kabar kecil, bikin tenang.");gap(body,28);
        PixelArt art=new PixelArt(this,"home");body.addView(art,new LinearLayout.LayoutParams(-1,dp(150)));gap(body,28);
        body.addView(text("Saling tahu, tanpa ribet.",24,INK,true));gap(body,10);
        para(body,"Pilih peran HP ini. Hubungkan dua HP dengan kode pasangan, tanpa email atau password.");gap(body,24);
        wideButton(body,busy?"Menyiapkan…":"Aku membagikan kabar",SAGE,()->{if(!busy)createSender();});
        wideButton(body,"Aku menerima kabar",PEACH,()->{if(!busy)join();});gap(body,12);
        para(body,"Versi uji · Android 8 atau lebih baru\nMemerlukan internet. Status dienkripsi melalui ntfy.sh. Koneksi aktif menampilkan notifikasi tetap dan bisa dijeda kapan saja.");
    }
    private void createSender() {
        busy=true;render();
        new Thread(()->{
            try {
                Pairing p=Pairing.create();KabarState s=new KabarState();s.revision=1;
                synchronized(Store.LOCK){Store.prefs(this).edit().putString("role","sender").putString("code",p.code()).putString("private",Pairing.encode(p.privateKey.getEncoded())).putBoolean("enabled",true).commit();Store.saveAndQueue(this,s,false);}
                runOnUiThread(()->{busy=false;page=0;SyncService.start(this);requestNotifications();render();});
            }catch(Exception e){runOnUiThread(()->{busy=false;error("Belum bisa menyiapkan aplikasi",e);render();});}
        },"CreateFamily").start();
    }
    private EditText field(String value,String hint) {
        EditText e=new EditText(this);e.setSingleLine(true);e.setText(value);e.setHint(hint);e.setTextSize(15);e.setTextColor(INK);e.setPadding(dp(12),dp(8),dp(12),dp(8));e.setBackground(background(Color.WHITE,12));
        e.setInputType(InputType.TYPE_CLASS_TEXT|InputType.TYPE_TEXT_FLAG_CAP_SENTENCES);return e;
    }
    private LinearLayout form(){LinearLayout f=column();f.setPadding(dp(20),dp(10),dp(20),dp(4));return f;}
    private void join() {
        LinearLayout f=form();para(f,"Salin kode dari Pengaturan di HP pengirim, lalu tempel di sini. Siapa pun yang memiliki kode dapat membaca kabar.");gap(f,12);
        EditText code=field("","KB1.…");code.setSingleLine(false);code.setMaxLines(5);code.setInputType(InputType.TYPE_CLASS_TEXT|InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS);f.addView(code);
        AlertDialog dialog=new AlertDialog.Builder(this).setTitle("Hubungkan HP").setView(f).setPositiveButton("Hubungkan",null).setNegativeButton("Batal",null).create();
        dialog.setOnShowListener(d->dialog.getButton(-1).setOnClickListener(v->{
            try {
                Pairing p=Pairing.parse(code.getText().toString());
                synchronized(Store.LOCK){Store.prefs(this).edit().clear().putString("role","receiver").putString("code",p.code()).putBoolean("enabled",true).commit();}
                dialog.dismiss();page=0;SyncService.start(this);requestNotifications();render();
                toast("Terhubung. Tekan salah satu tombol di HP pengirim.");
            }catch(Exception e){code.setError("Kode tidak valid. Salin kode lengkap dari HP pengirim.");}
        }));dialog.show();
    }
    private void title(String heading,String subtitle){body.addView(text(heading,30,INK,true));gap(body,3);para(body,subtitle);gap(body,22);}
    private void home() {
        KabarState s=Store.state(this);boolean sender=Store.role(this).equals("sender");long now=System.currentTimeMillis();TimeZone zone=TimeZone.getTimeZone(s.zone);
        title(sender?"Hai, "+s.name:"Kabar "+s.name,sender?"Kasih kabar hari ini.":"Kabar kecil dari orang tersayang.");
        TextView role=text(sender?"PENGIRIM":"PENERIMA",11,GREEN,true);body.addView(role);gap(body,12);
        statusCard(s.locationText(),s.locationAt==0?"Pilih lokasi untuk memberi kabar.":"Diperbarui "+StatusLogic.when(s.locationAt,now,zone),s.location.equals("outside")?"outside":"home",SAGE);
        if(StatusLogic.stale(s.locationAt,now)){para(body,"Lokasi ini sudah lebih dari 6 jam. Belum ada pembaruan baru.");gap(body,12);}
        statusCard(s.mealAt==0?"Makan belum tercatat":s.mealCategory,s.mealAt==0?"Beri kabar setelah makan.":"Terakhir makan · "+StatusLogic.when(s.mealAt,now,zone),"meal",Color.rgb(240,232,215));
        para(body,"Terakhir di "+s.home.toLowerCase(new Locale("id"))+" · "+StatusLogic.when(s.homeAt,now,zone));gap(body,20);
        if(sender) {
            body.addView(text("Update status",18,INK,true));gap(body,12);
            LinearLayout row=new LinearLayout(this);
            actionTile(row,s.outside,"outside",s.location.equals("outside")?SAGE:Color.WHITE);
            actionTile(row,s.home,"home",s.location.equals("home")?SAGE:Color.WHITE);
            body.addView(row,new LinearLayout.LayoutParams(-1,dp(116)));gap(body,10);
            wideButton(body,s.meal,PEACH,()->record("meal"));
            para(body,"Sekali ketuk untuk mencatat. Makan tidak mengubah lokasi.");gap(body,20);
        }
        body.addView(text("Makan hari ini",18,INK,true));gap(body,10);
        String[] categories={"Sarapan","Makan siang","Makan malam"};
        for(int i=0;i<3;i++) {
            boolean done=s.hasMealToday(categories[i],now);
            body.addView(text((done?"✓ ":"· ")+categories[i]+" — "+(done?"Tercatat":"Belum tercatat"),14,done?GREEN:MUTED,false));gap(body,6);
        }
        gap(body,14);
        String connection=Store.prefs(this).getString("connection","Menyiapkan koneksi…");
        if(Store.pending(this)>0)connection=Store.pending(this)+" kabar menunggu dikirim · otomatis saat online";
        TextView connectionView=text(connection,12,MUTED,false);body.addView(connectionView);gap(body,8);
        if(!Store.prefs(this).getBoolean("enabled",true))wideButton(body,"Aktifkan koneksi",SAGE,()->enable());
        if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)wideButton(body,"Izinkan notifikasi",SAGE,()->notificationSettings());
        if(!sender&&s.revision==0){gap(body,8);para(body,"Menunggu kabar pertama. Tekan Keluar, Kost, atau Makan di HP pengirim setelah kedua HP terhubung.");}
    }
    private void statusCard(String heading,String sub,String artKind,int color) {
        LinearLayout card=new LinearLayout(this);card.setGravity(Gravity.CENTER_VERTICAL);card.setPadding(dp(18),dp(18),dp(8),dp(18));card.setBackground(background(color,22));
        LinearLayout copy=column();copy.addView(text(heading,21,INK,true));gap(copy,7);copy.addView(text(sub,12,MUTED,false));
        card.addView(copy,new LinearLayout.LayoutParams(0,-2,1));PixelArt art=new PixelArt(this,artKind);card.addView(art,new LinearLayout.LayoutParams(dp(94),dp(82)));
        body.addView(card,new LinearLayout.LayoutParams(-1,-2));gap(body,12);
    }
    private void actionTile(LinearLayout row,String label,String kind,int color) {
        LinearLayout tile=column();tile.setGravity(Gravity.CENTER);tile.setPadding(dp(8),dp(8),dp(8),dp(8));tile.setBackground(background(color,18));
        PixelArt art=new PixelArt(this,kind);tile.addView(art,new LinearLayout.LayoutParams(dp(68),dp(62)));
        TextView caption=text(label,15,INK,true);caption.setGravity(Gravity.CENTER);tile.addView(caption);
        tile.setContentDescription(label);tile.setFocusable(true);tile.setOnClickListener(v->record(kind));
        LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(0,-1,1);lp.setMargins(0,0,row.getChildCount()==0?dp(10):0,0);row.addView(tile,lp);
    }
    private void record(String action) {
        if(!Store.role(this).equals("sender"))return;
        try {
            synchronized(Store.LOCK){KabarState s=Store.state(this);s.record(action,System.currentTimeMillis());Store.saveAndQueue(this,s,true);}
            SyncService.start(this);render();toast("Kabar dicatat");
        }catch(Exception e){error("Kabar belum tersimpan",e);}
    }
    private void history() {
        title("Riwayat kabar","12 kabar terbaru tersimpan di kedua HP.");
        KabarState s=Store.state(this);TimeZone zone=TimeZone.getTimeZone(s.zone);
        if(s.events.length()==0)para(body,"Belum ada riwayat. Kabar pertama akan muncul di sini.");
        for(int i=0;i<s.events.length();i++){
            JSONObject event=s.events.optJSONObject(i);if(event==null)continue;
            LinearLayout card=column();card.setPadding(dp(16),dp(14),dp(16),dp(14));card.setBackground(background(Color.WHITE,16));
            card.addView(text(event.optString("label"),17,INK,true));gap(card,5);card.addView(text(StatusLogic.when(event.optLong("at"),System.currentTimeMillis(),zone),13,MUTED,false));
            body.addView(card,new LinearLayout.LayoutParams(-1,-2));gap(body,10);
        }
    }
    private void settings() {
        boolean sender=Store.role(this).equals("sender");KabarState s=Store.state(this);
        title("Pengaturan","Bikin Kabar sesuai kebutuhanmu.");
        if(sender){
            wideButton(body,"Edit nama & tombol",SAGE,()->editLabels());
            wideButton(body,"Atur jam makan",Color.WHITE,()->editSchedule());
            para(body,"Nama tombol bebas diubah. Keluar dan Kost tetap mencatat lokasi; Makan tetap mencatat waktu makan.");gap(body,18);
            body.addView(text("Hubungkan HP lain",19,INK,true));gap(body,8);
            para(body,"Di HP kedua pilih “Aku menerima kabar”, lalu tempel kode pasangan ini. Tidak perlu akun atau aplikasi ntfy.");gap(body,12);
            wideButton(body,"Salin kode pasangan",SAGE,()->copyCode());
            wideButton(body,"Bagikan kode pasangan",Color.WHITE,()->shareCode());
            para(body,"Kode bersifat rahasia. Penerima bisa membaca status, tetapi tidak bisa mengirim status atas namamu.");gap(body,18);
        }else{para(body,"HP ini menerima kabar dari "+s.name+". Perubahan nama tombol dan jadwal mengikuti HP pengirim.");gap(body,18);}
        wideButton(body,"Tambahkan widget",SAGE,()->pinWidget());
        wideButton(body,"Pengaturan notifikasi",Color.WHITE,()->notificationSettings());
        boolean enabled=Store.prefs(this).getBoolean("enabled",true);
        wideButton(body,enabled?"Jeda koneksi":"Aktifkan koneksi",Color.WHITE,()->{
            if(enabled){Store.prefs(this).edit().putBoolean("enabled",false).apply();stopService(new Intent(this,SyncService.class));render();}else enable();
        });
        wideButton(body,"Pengaturan baterai aplikasi",Color.WHITE,()->startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:"+getPackageName()))));
        para(body,"Jika kabar terlambat saat layar mati, izinkan aktivitas latar belakang Kabar di pengaturan baterai HP. Setelah restart atau Paksa berhenti, buka Kabar kembali.");gap(body,18);
        if(sender){
            wideButton(body,"Hapus riwayat",PEACH,()->new AlertDialog.Builder(this).setTitle("Hapus riwayat keluarga?").setMessage("Lokasi dan makan akan kembali belum tercatat. Pembaruan dikirim ke HP penerima yang terhubung. Salinan pesan terenkripsi di relay mengikuti masa simpan layanan.").setPositiveButton("Hapus",(d,w)->clearHistory()).setNegativeButton("Batal",null).show());
            wideButton(body,"Ganti kode pasangan",PEACH,()->new AlertDialog.Builder(this).setTitle("Putuskan semua penerima?").setMessage("Kode lama tidak dapat menerima kabar baru. Bagikan kode baru untuk menghubungkan ulang.").setPositiveButton("Ganti kode",(d,w)->rotate()).setNegativeButton("Batal",null).show());
        }
        wideButton(body,"Putuskan hubungan HP ini",PEACH,()->disconnect());
        wideButton(body,"Uninstall Kabar",Color.WHITE,()->new AlertDialog.Builder(this).setTitle("Uninstall Kabar?").setMessage("Android akan meminta konfirmasi. Menghapus aplikasi tidak menghapus salinan kabar di HP lain.").setPositiveButton("Lanjutkan",(d,w)->uninstall()).setNegativeButton("Batal",null).show());
        gap(body,12);para(body,"Kabar 0.1.0 · versi uji\nTidak memakai GPS. Semua lokasi berasal dari tombol yang kamu tekan. Pesan dienkripsi dan ditandatangani di perangkat; relay ntfy.sh menerima ciphertext. Layanan publik memiliki batas dan cache sementara (umumnya 12 jam). Jika penerima lama offline, tekan status kembali pada pengirim. Riwayat lokal dibatasi 12 kabar.");
    }
    private void editLabels() {
        KabarState s=Store.state(this);LinearLayout f=form();
        EditText name=field(s.name,"Nama kamu"),outside=field(s.outside,"Keluar"),home=field(s.home,"Kost"),meal=field(s.meal,"Makan");
        String[] labels={"Nama pengirim","Tombol lokasi di luar","Tombol lokasi tempat tinggal","Tombol makan"};EditText[] fields={name,outside,home,meal};
        for(int i=0;i<4;i++){para(f,labels[i]);gap(f,5);f.addView(fields[i],new LinearLayout.LayoutParams(-1,dp(48)));gap(f,12);}
        AlertDialog d=new AlertDialog.Builder(this).setTitle("Edit nama & tombol").setView(f).setPositiveButton("Simpan",null).setNegativeButton("Batal",null).create();
        d.setOnShowListener(x->d.getButton(-1).setOnClickListener(v->{
            for(EditText e:fields)if(e.getText().toString().trim().isEmpty()||e.getText().toString().trim().length()>24){e.setError("Isi 1–24 karakter");return;}
            try{s.name=name.getText().toString().trim();s.outside=outside.getText().toString().trim();s.home=home.getText().toString().trim();s.meal=meal.getText().toString().trim();
                synchronized(Store.LOCK){KabarState current=Store.state(this);current.name=s.name;current.outside=s.outside;current.home=s.home;current.meal=s.meal;current.revision++;Store.saveAndQueue(this,current,false);}
                SyncService.start(this);d.dismiss();render();
            }catch(Exception e){error("Perubahan belum tersimpan",e);}
        }));d.show();
    }
    private void editSchedule() {
        KabarState s=Store.state(this);LinearLayout f=form();para(f,"Jam mulai termasuk; jam akhir tidak termasuk. Gunakan 0–24, berurutan tanpa tumpang tindih. Di luar jadwal dicatat sebagai “Makan”.");gap(f,14);
        EditText[] fields=new EditText[6];String[] labels={"Sarapan","Makan siang","Makan malam"};
        for(int i=0;i<3;i++){
            para(f,labels[i]);gap(f,5);LinearLayout row=new LinearLayout(this);row.setGravity(Gravity.CENTER_VERTICAL);
            for(int j=0;j<2;j++) {int index=i*2+j;fields[index]=field(""+s.windows[index],j==0?"Mulai":"Akhir");fields[index].setInputType(InputType.TYPE_CLASS_NUMBER);row.addView(fields[index],new LinearLayout.LayoutParams(0,dp(48),1));if(j==0){TextView dash=text("  —  ",18,MUTED,false);row.addView(dash);}}
            f.addView(row);gap(f,12);
        }
        AlertDialog d=new AlertDialog.Builder(this).setTitle("Atur jam makan").setView(f).setPositiveButton("Simpan",null).setNegativeButton("Batal",null).create();
        d.setOnShowListener(x->d.getButton(-1).setOnClickListener(v->{
            try{int[] windows=new int[6];for(int i=0;i<6;i++)windows[i]=Integer.parseInt(fields[i].getText().toString());
                if(!StatusLogic.validWindows(windows))throw new IllegalArgumentException("Jadwal harus berurutan, 0–24, dan tidak tumpang tindih.");
                synchronized(Store.LOCK){KabarState current=Store.state(this);current.windows=windows;current.revision++;Store.saveAndQueue(this,current,false);}
                SyncService.start(this);d.dismiss();render();
            }catch(Exception e){error("Jadwal belum tersimpan",e);}
        }));d.show();
    }
    private void clearHistory(){try{synchronized(Store.LOCK){KabarState current=Store.state(this);current.location="";current.locationAt=0;current.homeAt=0;current.mealAt=0;current.breakfastAt=0;current.lunchAt=0;current.dinnerAt=0;current.mealCategory="";current.events=new JSONArray();current.revision++;Store.saveAndQueue(this,current,false);}SyncService.start(this);render();}catch(Exception e){error("Belum bisa menghapus",e);}}
    private void rotate(){stopService(new Intent(this,SyncService.class));try{synchronized(Store.LOCK){Pairing p=Pairing.create();Store.prefs(this).edit().putString("code",p.code()).putString("private",Pairing.encode(p.privateKey.getEncoded())).putString("queue","[]").remove("cursor").remove("publishedAt").commit();KabarState s=Store.state(this);s.revision++;Store.saveAndQueue(this,s,false);}SyncService.start(this);render();toast("Kode diganti. Hubungkan ulang HP penerima.");}catch(Exception e){error("Kode belum diganti",e);}}
    private void disconnect(){new AlertDialog.Builder(this).setTitle("Putuskan hubungan?").setMessage("Data lokal dan kode pasangan di HP ini dihapus. HP lain tetap menyimpan kabar terakhir. Jika HP pengirim diputuskan, buat kode baru untuk menghubungkan ulang.").setPositiveButton("Putuskan",(d,w)->{stopService(new Intent(this,SyncService.class));synchronized(Store.LOCK){Store.prefs(this).edit().clear().commit();}page=0;Store.changed(this);render();}).setNegativeButton("Batal",null).show();}
    private void copyCode(){android.content.ClipboardManager cm=(android.content.ClipboardManager)getSystemService(CLIPBOARD_SERVICE);ClipData clip=ClipData.newPlainText("Kode pasangan Kabar",Store.prefs(this).getString("code",""));if(Build.VERSION.SDK_INT>=33){PersistableBundle extra=new PersistableBundle();extra.putBoolean("android.content.extra.IS_SENSITIVE",true);clip.getDescription().setExtras(extra);}cm.setPrimaryClip(clip);toast("Kode disalin");}
    private void shareCode(){Intent i=new Intent(Intent.ACTION_SEND);i.setType("text/plain");i.putExtra(Intent.EXTRA_TEXT,Store.prefs(this).getString("code",""));startActivity(Intent.createChooser(i,"Bagikan kode pasangan"));}
    private void pinWidget(){AppWidgetManager m=AppWidgetManager.getInstance(this);if(m.isRequestPinAppWidgetSupported())m.requestPinAppWidget(new ComponentName(this,KabarWidget.class),null,null);else new AlertDialog.Builder(this).setTitle("Pasang widget Kabar").setMessage("Tekan lama area kosong layar utama HP, pilih Widget, lalu pilih Kabar.").setPositiveButton("Mengerti",null).show();}
    private void enable(){Store.prefs(this).edit().putBoolean("enabled",true).apply();SyncService.start(this);render();}
    private void notificationSettings(){Intent i=new Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE,getPackageName());startActivity(i);}
    private void uninstall(){try{startActivity(new Intent(Intent.ACTION_DELETE,Uri.parse("package:"+getPackageName())));}catch(ActivityNotFoundException e){startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,Uri.parse("package:"+getPackageName())));}}
    private void toast(String msg){Toast.makeText(this,msg,Toast.LENGTH_SHORT).show();}
    private void error(String heading,Exception e){new AlertDialog.Builder(this).setTitle(heading).setMessage(e.getMessage()==null?"Coba lagi.":e.getMessage()).setPositiveButton("Mengerti",null).show();}
}
