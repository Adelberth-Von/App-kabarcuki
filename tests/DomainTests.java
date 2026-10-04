package id.kabar.app;

import org.json.*;
import java.util.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;

public class DomainTests {
    private static int checks=0;
    private static final TimeZone TZ=TimeZone.getTimeZone("Asia/Jakarta");
    private static void ok(boolean b,String msg){checks++;if(!b)throw new AssertionError(msg);}
    private static void eq(Object a,Object b,String msg){ok(Objects.equals(a,b),msg+" expected="+b+" actual="+a);}
    private static long at(int day,int hour,int minute){Calendar c=Calendar.getInstance(TZ);c.clear();c.set(2026,Calendar.OCTOBER,day,hour,minute);return c.getTimeInMillis();}
    private interface Checked {void run()throws Exception;}
    private static void rejects(Checked f,String msg){boolean rejected=false;try{f.run();}catch(Exception e){rejected=true;}ok(rejected,msg);}
    public static void main(String[] args)throws Exception{
        if(args.length>0&&args[0].equals("device-publisher")){devicePublisher(args[1]);return;}
        if(args.length>0&&args[0].equals("device-subscriber")){deviceSubscriber(args[1]);System.out.println("PASS device sender interoperability: "+checks+" assertions");return;}
        mealRules();clockRules();stateRules();locationAndManualMealRules();namedLocationBudget();cryptoRules();seiramaRules();cleanupScopeRules();
        if(args.length>0&&args[0].equals("live")){liveRelay();liveStream();}
        System.out.println("PASS "+checks+" assertions");
    }
    private static void cleanupScopeRules()throws Exception {
        java.nio.file.Path sandbox=java.nio.file.Files.createTempDirectory("abc-cleanup-qa-").toRealPath();
        java.nio.file.Path app=sandbox.resolve("abc"),other=sandbox.resolve("other-app");
        java.nio.file.Files.createDirectories(app.resolve("cache/nested"));java.nio.file.Files.createDirectories(other);
        java.nio.file.Files.write(app.resolve("cache/nested/private.txt"),new byte[]{1,2,3});
        java.nio.file.Path sentinel=other.resolve("keep.txt");java.nio.file.Files.write(sentinel,new byte[]{9,8,7});
        boolean linked=false;
        try {
            try{java.nio.file.Files.createSymbolicLink(app.resolve("external-link"),other);linked=true;}catch(UnsupportedOperationException|IOException denied){}
            ScopedFiles.clear(app.toFile());
            ok(app.toFile().isDirectory(),"cleanup retains the named app directory");
            eq(app.toFile().list().length,0,"cleanup erases only app contents");
            ok(java.util.Arrays.equals(java.nio.file.Files.readAllBytes(sentinel),new byte[]{9,8,7}),"unrelated application file untouched");
            if(linked)ok(java.nio.file.Files.isDirectory(other),"cleanup does not follow a directory link outside app scope");
        } finally {
            // This directory is created by this test, with a checked absolute temp root.
            ok(sandbox.isAbsolute()&&sandbox.getFileName().toString().startsWith("abc-cleanup-qa-"),"QA cleanup remains in its own temporary sandbox");
            ScopedFiles.clear(sandbox.toFile());java.nio.file.Files.delete(sandbox);
        }
    }
    private static void namedLocationBudget()throws Exception {
        KabarState s=new KabarState();s.zone=TZ.getID();String label=String.join("",Collections.nCopies(24,"界"));String area=String.join("",Collections.nCopies(32,"界"));s.name=label;s.home=label;s.outside=label;s.meal=label;
        for(int i=0;i<12;i++)s.record("home",at(2,18,0)+i,null,new GpsPoint(-7.7956,110.3695,12,at(2,18,0)+i,s.zone,area,area));
        s.fitRelay();Pairing sender=Pairing.create();String body=new JSONObject().put("state",s.json()).put("notify",true).toString();String encrypted=sender.encrypt(body);
        ok(encrypted.getBytes(StandardCharsets.UTF_8).length<=4096,"named multibyte places fit encrypted relay budget");eq(s.gps.city,area,"latest city retained under payload pressure");eq(s.events.getJSONObject(0).getJSONObject("gps").getDouble("lat"),-7.7956,"latest precise map point retained");eq(KabarState.parse(s.json().toString()).revision,s.revision,"compacted history remains compatible");
    }
    private static void clockRules(){
        eq(StatusLogic.clock(at(2,12,0),TZ),"12.00 WIB - Indonesia","local WIB clock");
        eq(StatusLogic.clock(at(2,12,0),TimeZone.getTimeZone("Asia/Makassar")),"13.00 WITA - Indonesia","WITA clock");
        eq(StatusLogic.clock(at(2,12,0),TimeZone.getTimeZone("Asia/Jayapura")),"14.00 WIT - Indonesia","WIT clock");
        eq(StatusLogic.country(TimeZone.getTimeZone("Asia/Tokyo")),"Jepang","Japan label");
        eq(StatusLogic.country(TimeZone.getTimeZone("Europe/Brussels")),"Belgia","same clock rules do not merge countries");
        eq(StatusLogic.country(TimeZone.getTimeZone("US/Eastern")),"Amerika Serikat","legacy zone alias");
        eq(StatusLogic.country(TimeZone.getTimeZone("GMT+07:00")),"Zona waktu HP","fixed offset does not guess country");
        TimeZone ny=TimeZone.getTimeZone("America/New_York");
        eq(StatusLogic.shortZone(ny,java.time.Instant.parse("2026-01-02T12:00:00Z").toEpochMilli()),"EST","winter abbreviation");
        eq(StatusLogic.shortZone(ny,java.time.Instant.parse("2026-07-02T12:00:00Z").toEpochMilli()),"EDT","summer abbreviation");
        int[][] edges={{4,59,3},{5,0,0},{10,59,0},{11,0,1},{14,59,1},{15,0,2},{17,59,2},{18,0,3},{23,59,3},{0,0,3}};
        for(int[] edge:edges)eq(StatusLogic.phase(at(2,edge[0],edge[1]),TZ),edge[2],"day scene phase boundary");
        eq(StatusLogic.phase(at(2,12,0),ny),3,"viewer time drives scene");
        eq(StatusLogic.localWhen(at(2,0,30),at(2,12,0),ny),"Kemarin · 13.30 EDT - Amerika Serikat","date conversion across midnight");
    }
    private static void mealRules(){
        int[] w=StatusLogic.DEFAULT_WINDOWS;
        eq(StatusLogic.mealAt(at(2,4,59),w,TZ),"Makan","before breakfast");
        eq(StatusLogic.mealAt(at(2,5,0),w,TZ),"Sarapan","breakfast start");
        eq(StatusLogic.mealAt(at(2,9,59),w,TZ),"Sarapan","breakfast end exclusive");
        eq(StatusLogic.mealAt(at(2,10,0),w,TZ),"Makan siang","lunch start boundary");
        eq(StatusLogic.mealAt(at(2,14,59),w,TZ),"Makan siang","lunch last minute");
        eq(StatusLogic.mealAt(at(2,15,0),w,TZ),"Makan","gap start");
        eq(StatusLogic.mealAt(at(2,16,59),w,TZ),"Makan","gap end");
        eq(StatusLogic.mealAt(at(2,17,0),w,TZ),"Makan malam","dinner start");
        eq(StatusLogic.mealAt(at(2,21,59),w,TZ),"Makan malam","dinner last minute");
        eq(StatusLogic.mealAt(at(2,22,0),w,TZ),"Makan","dinner end");
        ok(StatusLogic.validWindows(w),"default windows valid");
        ok(!StatusLogic.validWindows(new int[]{5,10,9,15,17,22}),"reject overlapping windows");
        ok(!StatusLogic.validWindows(new int[]{5,5,10,15,17,22}),"reject empty window");
        ok(!StatusLogic.validWindows(new int[]{-1,5,10,15,17,22}),"reject negative hour");
        ok(!StatusLogic.validWindows(new int[]{5,10,10,15,17,25}),"reject over 24");
        ok(StatusLogic.validWindows(new int[]{0,8,8,16,16,24}),"full day valid");
        eq(StatusLogic.when(at(1,23,59),at(2,0,1),TZ),"Kemarin · 23.59","midnight formatting");
        eq(StatusLogic.when(at(2,8,0),at(2,12,0),TZ),"Hari ini · 08.00","today formatting");
        eq(StatusLogic.when(0,at(2,12,0),TZ),"Belum tercatat","missing status wording");
        ok(StatusLogic.stale(at(2,6,0),at(2,12,0)),"6h old is stale");
        ok(!StatusLogic.stale(at(2,6,1),at(2,12,0)),"under 6h fresh");
        ok(!StatusLogic.stale(0,at(2,12,0)),"missing location not stale");
        eq(StatusLogic.mealAt(at(2,5,0),new int[]{6,11,11,16,18,23},TZ),"Makan","custom schedule applied");
    }
    private static void stateRules()throws Exception{
        KabarState s=new KabarState();s.zone=TZ.getID();
        eq(s.locationText(),"Lokasi belum tercatat","empty state");
        s.record("home",at(2,8,0));s.record("meal",at(2,8,30));
        eq(s.location,"home","meal does not change location");
        eq(s.homeAt,at(2,8,0),"meal does not change home timestamp");
        eq(s.mealCategory,"Sarapan","meal automatically classified");
        s.record("outside",at(2,9,0));
        eq(s.location,"outside","outside changes current location");
        eq(s.homeAt,at(2,8,0),"last home retained");
        eq(s.mealAt,at(2,8,30),"last meal retained");
        ok(s.hasMealToday("Sarapan",at(2,10,0)),"today breakfast registered");
        ok(!s.hasMealToday("Sarapan",at(3,0,0)),"next day checklist resets");
        eq(StatusLogic.when(s.mealAt,at(3,0,0),TZ),"Kemarin · 08.30","last meal persists overnight");
        eq(s.revision,3L,"revision increments per action");
        String raw=s.json().toString();KabarState copy=KabarState.parse(raw);
        eq(copy.json().toString(),raw,"serialization roundtrip");
        copy.home="Rumah";copy.outside="Pergi";copy.meal="Sudah makan";
        copy.record("home",at(2,12,0));eq(copy.locationText(),"Di rumah","editable home label");
        copy.record("outside",at(2,12,1));eq(copy.locationText(),"Pergi","editable outside label");
        for(int i=0;i<50;i++)copy.record("meal",at(2,13,0)+i);
        eq(copy.events.length(),12,"history bounded");
        ok(copy.hasMealToday("Sarapan",at(2,14,0)),"breakfast survives history eviction");
        eq(copy.events.getJSONObject(0).getLong("at"),at(2,13,0)+49,"newest history first");
        rejects(()->copy.record("campus",at(2,12,0)),"reject unknown action");
        rejects(()->copy.record("meal",0),"reject invalid timestamp");
        JSONObject bad=s.json().put("windows",new JSONArray(new int[]{5,10,9,15,17,22}));
        rejects(()->KabarState.parse(bad.toString()),"reject malicious schedule");
        rejects(()->KabarState.parse(s.json().put("name","").toString()),"reject empty name");
        rejects(()->KabarState.parse(s.json().put("location","gps").toString()),"reject unknown location");
    }
    private static void locationAndManualMealRules()throws Exception{
        KabarState s=new KabarState();s.zone=TZ.getID();
        s.record("home",at(2,7,0));long home=s.homeAt;
        GpsPoint point=new GpsPoint(-6.200001,106.816666,12.3,at(2,23,0),"Asia/Jakarta");
        s.record("meal",at(2,23,0),"Sarapan",point);
        ok(!s.hasMealToday("Sarapan",at(2,23,1)),"late breakfast does not check morning");
        eq(s.mealCategory,"Makan","outside all windows becomes other meal");eq(s.homeAt,home,"manual meal preserves home");
        eq(s.gps.coordinates(),"-6.20000, 106.81667","coordinates formatted consistently");
        eq(s.gps.accuracy,13.0,"accuracy rounded conservatively");
        eq(KabarState.parse(s.json().toString()).gps.lat,point.lat,"GPS state survives roundtrip");
        ok(!point.old(at(2,23,14)),"point younger than 15 minutes");ok(point.old(at(2,23,15)),"old point marked at 15 minutes");
        rejects(()->new GpsPoint(91,0,10,1,"UTC"),"reject out-of-range latitude");
        rejects(()->new GpsPoint(0,-181,10,1,"UTC"),"reject out-of-range longitude");
        rejects(()->new GpsPoint(Double.NaN,0,10,1,"UTC"),"reject NaN coordinate");
        rejects(()->new GpsPoint(0,0,0,1,"UTC"),"reject missing accuracy");
        rejects(()->new GpsPoint(0,0,1,1,"not/a/zone"),"reject invalid GPS timezone");
        rejects(()->s.record("meal",at(2,23,1),"Snack",null),"reject unknown manual category");
        s.record("meal",at(2,23,2),"Makan malam",null);ok(!s.hasMealToday("Makan malam",at(2,23,3)),"outside dinner window does not check dinner");
        KabarState evening=new KabarState();evening.zone=TZ.getID();evening.record("meal",at(2,18,0),"Sarapan",null);eq(evening.mealCategory,"Makan malam","breakfast tap at 18 routes to dinner");ok(evening.hasMealToday("Makan malam",at(2,18,1)),"dinner checked");ok(!evening.hasMealToday("Sarapan",at(2,18,1)),"breakfast not checked");
        GpsPoint named=new GpsPoint(-7.7956,110.3695,12,at(2,18,0),"Asia/Jakarta","Yogyakarta","Gondomanan");eq(GpsPoint.parse(named.json()).city,"Yogyakarta","city survives protocol round trip");eq(GpsPoint.parse(named.json()).place,"Gondomanan","area survives protocol round trip");
        eq(s.gps.at,point.at,"action without GPS preserves explicitly dated last point");
        s.zone="Asia/Makassar";s.record("outside",at(2,23,4));
        eq(s.events.getJSONObject(0).getString("zone"),"Asia/Makassar","new event uses current sender zone");
        eq(s.events.getJSONObject(1).getString("zone"),"Asia/Jakarta","previous event retains its original zone");
        JSONObject legacy=s.json();legacy.remove("gps");for(int i=0;i<legacy.getJSONArray("events").length();i++){legacy.getJSONArray("events").getJSONObject(i).remove("zone");legacy.getJSONArray("events").getJSONObject(i).remove("gps");}
        eq(KabarState.parse(legacy.toString()).gps,null,"old APK snapshot remains compatible");
        for(int i=0;i<12;i++)s.record("meal",at(2,23,5)+i,"Makan",point);
        int points=0;for(int i=0;i<s.events.length();i++)if(s.events.getJSONObject(i).has("gps"))points++;
        eq(points,3,"only three historical GPS points retained");
        ok(s.events.getJSONObject(3).optBoolean("gpsCaptured"),"pruned event remembers that a point was once included");
        ok(!s.events.getJSONObject(3).has("gps"),"pruned event does not borrow the current GPS point");
        String encrypted=Pairing.create().encrypt(new JSONObject().put("state",s.json()).put("notify",true).toString());
        ok(encrypted.getBytes(StandardCharsets.UTF_8).length<=4096,"GPS history and timezone fit relay");
        ok(StatusLogic.zoneLabel(TimeZone.getTimeZone("Asia/Makassar"),at(2,12,0)).startsWith("UTC+08:00"),"sender timezone offset shown");
    }
    private static void cryptoRules()throws Exception{
        Pairing sender=Pairing.create(),receiver=Pairing.parse(sender.code());
        eq(sender.topic(),receiver.topic(),"paired topic equality");
        eq(receiver.privateKey,null,"receiver has no sender signing key");
        Pairing restored=receiver.withPrivate(Pairing.encode(sender.privateKey.getEncoded()));
        String secret="{\"name\":\"Aku\",\"status\":\"Di kost\"}";
        String message=restored.encrypt(secret);
        String proof=restored.alertProof(message);
        ok(receiver.verifyAlert(message,proof),"public alert hint authenticated");
        ok(!receiver.verifyAlert(message+"x",proof),"alert hint bound to ciphertext");
        ok(!receiver.verifyAlert(message,""),"silent snapshot has no alert proof");
        rejects(()->receiver.alertProof(message),"receiver cannot forge push hint");
        eq(receiver.decrypt(message),secret,"encrypted signed roundtrip");
        ok(!message.contains("kost")&&!message.contains("Aku"),"plaintext hidden from relay");
        ok(!message.equals(restored.encrypt(secret)),"fresh nonce per encryption");
        rejects(()->receiver.encrypt(secret),"receiver cannot forge sender status");
        rejects(()->Pairing.parse("KB1.bad.bad"),"invalid pairing code rejected");
        rejects(()->Pairing.parse(sender.code()+".extra"),"extra pairing data rejected");
        String[] parts=message.split("\\.");byte[] cipher=Pairing.decode(parts[2]);cipher[0]^=1;
        String tampered=parts[0]+"."+parts[1]+"."+Pairing.encode(cipher)+"."+parts[3];
        rejects(()->receiver.decrypt(tampered),"ciphertext tampering rejected");
        Pairing stranger=Pairing.create();rejects(()->stranger.decrypt(message),"wrong family rejected");
        eq(Pairing.parse("  "+sender.code()+"\n").topic(),sender.topic(),"pasted whitespace tolerated");
        KabarState s=new KabarState();s.zone=TZ.getID();
        s.name="Nama panjang keluarga";s.home="Tempat tinggal bersama";s.outside="Sedang berada di luar";
        for(int i=0;i<12;i++)s.record(i%2==0?"home":"meal",at(2,18,i));
        String payload=sender.encrypt(new JSONObject().put("state",s.json()).put("notify",true).toString());
        ok(payload.getBytes(StandardCharsets.UTF_8).length<=4096,"snapshot within relay size limit");
        KabarState received=KabarState.parse(new JSONObject(receiver.decrypt(payload)).getJSONObject("state").toString());
        eq(received.revision,s.revision,"full state encryption roundtrip");
    }
    private static void seiramaRules()throws Exception {
        Pairing alice=Pairing.create(),bob=Pairing.create();
        Pairing aliceRead=Seirama.parseInvite(Seirama.invite(alice)),bobRead=Seirama.parseInvite(Seirama.invite(bob));
        eq(aliceRead.topic(),alice.topic(),"Seirama invitation points to independent Alice stream");
        eq(bobRead.privateKey,null,"Seirama invitation never includes writer private key");
        rejects(()->bobRead.encrypt("{}"),"peer cannot write partner stream");
        rejects(()->Seirama.requireDifferent(alice,aliceRead),"cannot pair own stream to itself");
        Pairing rewrappedOwn=new Pairing(new byte[32],alice.publicKey,null);
        ok(!rewrappedOwn.topic().equals(alice.topic()),"altered invitation secret produces different relay topic");
        rejects(()->Seirama.requireDifferent(alice,rewrappedOwn),"matching own writer key rejected even with different invitation secret/topic");
        rejects(()->Seirama.parseInvite(alice.code()),"legacy one-way code does not silently consent to Seirama");
        rejects(()->Seirama.parseInvite("KB2.bad"),"malformed reciprocal invite rejected");
        rejects(()->aliceRead.withPrivate(Pairing.encode(bob.privateKey.getEncoded())),"foreign signing key rejected on restore");
        KabarState a=new KabarState(),b=new KabarState();a.zone=TZ.getID();b.zone="Europe/Berlin";a.name="Alice";b.name="Bob";
        for(int i=0;i<25;i++)a.record("home",at(2,8,0)+i);
        b.record("outside",at(2,18,0));
        String before=a.json().toString();
        JSONObject alicePacket=Seirama.packet(a,false,bobRead),bobPacket=Seirama.packet(b,true,aliceRead);
        String bobEnvelope=bob.encrypt(bobPacket.toString());
        JSONObject verifiedBob=new JSONObject(bobRead.decrypt(bobEnvelope));
        KabarState peer=Seirama.next(verifiedBob,new KabarState());
        eq(peer.name,"Bob","low revision peer accepted independently from high revision own state");
        eq(a.json().toString(),before,"partner reception does not overwrite own status/history");
        ok(Seirama.reciprocates(verifiedBob,alice),"partner signed recipient binding proves reciprocal consent");
        ok(!Seirama.reciprocates(alicePacket,alice),"own outgoing consent cannot stand in for partner consent");
        eq(Seirama.next(verifiedBob,peer),null,"replayed peer revision ignored");
        rejects(()->aliceRead.decrypt(bobEnvelope),"wrong stream signature and secret rejected");
        JSONObject legacy=Seirama.packet(b,false,null);ok(!Seirama.reciprocates(legacy,alice),"one-way packets remain compatible without reciprocal consent");
        b.record("meal",at(2,18,1));
        KabarState newest=Seirama.next(new JSONObject(bobRead.decrypt(bob.encrypt(Seirama.packet(b,true,aliceRead).toString()))),peer);
        eq(newest.mealCategory,"Makan siang","partner local timezone governs own meal classification");
        eq(Seirama.next(verifiedBob,newest),null,"older peer snapshot cannot roll back history");
        String label=String.join("",Collections.nCopies(24,"界")),place=String.join("",Collections.nCopies(32,"界"));
        a.name=a.home=a.meal=a.outside=label;
        for(int i=0;i<12;i++)a.record("home",at(2,18,0)+i,null,new GpsPoint(-7.7956,110.3695,12,at(2,18,0)+i,a.zone,place,place));
        String full=alice.encrypt(Seirama.packet(a,true,bobRead).toString());
        ok(full.getBytes(StandardCharsets.UTF_8).length<=4096,"reciprocal signature/recipient hint with multibyte GPS fits relay budget");
        eq(new JSONObject(aliceRead.decrypt(full)).getJSONObject("state").getJSONObject("gps").getString("city"),place,"reciprocal budget keeps latest exact GPS and city");
        rejects(()->Seirama.next(Seirama.packet(a,false,bobRead).put("peerTopic","invalid"),new KabarState()),"malformed signed recipient topic rejected");
        KabarState stopped=KabarState.parse(b.json().toString());stopped.revision++;
        String shutdown=bob.encrypt(Seirama.revocation(stopped).toString());JSONObject verifiedShutdown=new JSONObject(bobRead.decrypt(shutdown));
        KabarState retired=Seirama.next(verifiedShutdown,newest);ok(retired!=null,"signed newer revocation accepted on peer stream");
        ok(!Seirama.reciprocates(verifiedShutdown,alice),"revocation removes reciprocal consent");
        eq(Seirama.next(verifiedBob,retired),null,"old active proof cannot reactivate after revocation");
        ok(!verifiedShutdown.optBoolean("notify",true),"mode revocation is silent");
        ok(!Seirama.reciprocates(verifiedShutdown.put("peerTopic",alice.topic()),alice),"explicit revocation wins over contradictory recipient binding");
    }
    private static void liveRelay()throws Exception{
        Pairing sender=Pairing.create(),receiver=Pairing.parse(sender.code());
        KabarState state=new KabarState();state.zone=TZ.getID();
        String cursor="";
        for(String action:new String[]{"home","meal","outside"}) {
            state.record(action,System.currentTimeMillis());
            String payload=sender.encrypt(new JSONObject().put("state",state.json()).put("notify",true).toString());
            Relay.publish(sender.topic(),payload);
            String path="/"+receiver.topic()+"/json?poll=1&since="+(cursor.isEmpty()?"all":cursor);
            int count=0;KabarState received=null;
            for(int attempt=0;attempt<12&&count==0;attempt++) {
                HttpURLConnection c=Relay.open(path);
                try(BufferedReader reader=new BufferedReader(new InputStreamReader(c.getInputStream(),StandardCharsets.UTF_8))){
                    String line;
                    while((line=reader.readLine())!=null){JSONObject m=new JSONObject(line);if(!m.optString("event").equals("message"))continue;
                        received=KabarState.parse(new JSONObject(receiver.decrypt(m.getString("message"))).getJSONObject("state").toString());cursor=m.getString("id");count++;
                    }
                }finally{c.disconnect();}
                if(count==0)Thread.sleep(1000);
            }
            eq(count,1,"relay delivers new action once: "+action);ok(received!=null,"relay data received");
            eq(received.revision,state.revision,"relay revision matches");eq(received.location,state.location,"relay location matches");eq(received.mealAt,state.mealAt,"relay meal matches");
        }
        System.out.println("PASS live encrypted relay: home, meal, outside; cursor prevents repeats");
    }
    private static void devicePublisher(String path)throws Exception{
        Pairing sender=Pairing.create();
        java.nio.file.Files.write(java.nio.file.Paths.get(path),sender.code().getBytes(StandardCharsets.UTF_8));
        KabarState state=new KabarState();state.name="QA";
        System.out.println("Device publisher prepared; waiting 20 seconds for receiver");
        Thread.sleep(20000);
        for(String action:new String[]{"home","meal","outside"}){
            state.record(action,System.currentTimeMillis());
            Relay.publish(sender.topic(),sender.encrypt(new JSONObject().put("state",state.json()).put("notify",true).toString()));
            System.out.println("Published QA "+action+" revision "+state.revision);
            Thread.sleep(1800);
        }
    }
    private static void liveStream()throws Exception{
        Pairing sender=Pairing.create(),receiver=Pairing.parse(sender.code());
        java.util.concurrent.CountDownLatch opened=new java.util.concurrent.CountDownLatch(1),arrived=new java.util.concurrent.CountDownLatch(1);
        java.util.concurrent.atomic.AtomicReference<KabarState> received=new java.util.concurrent.atomic.AtomicReference<>();
        java.util.concurrent.atomic.AtomicReference<Throwable> failure=new java.util.concurrent.atomic.AtomicReference<>();
        HttpURLConnection c=Relay.open("/"+receiver.topic()+"/json?since=latest");
        Thread listener=new Thread(()->{
            try(BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream(),StandardCharsets.UTF_8))){
                String line;while((line=r.readLine())!=null){JSONObject packet=new JSONObject(line);
                    if(packet.optString("event").equals("open"))opened.countDown();
                    if(packet.optString("event").equals("message")){received.set(KabarState.parse(new JSONObject(receiver.decrypt(packet.getString("message"))).getJSONObject("state").toString()));arrived.countDown();return;}
                }
            }catch(Throwable e){failure.set(e);opened.countDown();arrived.countDown();}
        },"QA-Stream");listener.setDaemon(true);listener.start();
        try{
            ok(opened.await(20,java.util.concurrent.TimeUnit.SECONDS),"live stream opens");
            if(failure.get()!=null)throw new RuntimeException(failure.get());
            KabarState s=new KabarState();s.record("home",System.currentTimeMillis());
            Relay.publish(sender.topic(),sender.encrypt(new JSONObject().put("state",s.json()).put("notify",true).toString()));
            ok(arrived.await(20,java.util.concurrent.TimeUnit.SECONDS),"live stream delivers update");
            if(failure.get()!=null)throw new RuntimeException(failure.get());
            eq(received.get().location,"home","stream snapshot location");
            eq(received.get().revision,s.revision,"stream snapshot revision");
            System.out.println("PASS live stream subscription, same endpoint used by Android service");
        }finally{c.disconnect();listener.interrupt();}
    }
    private static void deviceSubscriber(String path)throws Exception{
        String code=new String(java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(path)),StandardCharsets.UTF_8);
        Pairing receiver=Pairing.parse(code);KabarState state=null;
        for(int attempt=0;attempt<12&&state==null;attempt++){
            HttpURLConnection c=Relay.open("/"+receiver.topic()+"/json?poll=1&since=latest");
            try(BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream(),StandardCharsets.UTF_8))){String line;
                while((line=r.readLine())!=null){JSONObject m=new JSONObject(line);if(!m.optString("event").equals("message"))continue;state=KabarState.parse(new JSONObject(receiver.decrypt(m.getString("message"))).getJSONObject("state").toString());}
            }finally{c.disconnect();}
            if(state==null)Thread.sleep(1000);
        }
        ok(state!=null,"native sender message decrypts and signature verifies on independent receiver");
        eq(state.revision,3L,"native sender latest revision");eq(state.location,"outside","native sender outside status");ok(state.homeAt>0,"native sender last home retained");ok(state.mealAt>0,"native sender last meal retained");
    }
}
