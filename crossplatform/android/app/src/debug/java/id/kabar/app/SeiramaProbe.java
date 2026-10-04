package id.kabar.app;

import android.content.*;
import java.util.Map;
import org.json.*;

/** Native storage/security QA in a separate preference file; never included in release APKs. */
public final class SeiramaProbe {
    private static void check(boolean condition,String what){if(!condition)throw new AssertionError(what);}
    public static JSONObject run(Context app,boolean ignored)throws Exception {
        synchronized(Store.LOCK) {
        Map<String,?> before=Store.prefs(app).getAll();
        String fixtureName="abc_qa_seirama";
        Context fixture=new ContextWrapper(app){@Override public SharedPreferences getSharedPreferences(String name,int mode){return super.getSharedPreferences(name.equals("kabar")?fixtureName:name,mode);}};
        SharedPreferences prefs=Store.prefs(fixture);prefs.edit().clear().commit();
        JSONObject result=new JSONObject();
        try {
            Pairing own=Pairing.create(),writer=Pairing.create(),incoming=Pairing.parse(writer.code());
            KabarState mine=new KabarState();mine.name="QA own";mine.zone="Asia/Jakarta";for(int i=0;i<20;i++)mine.record("home",1790931600000L+i);
            KabarState peer=new KabarState();peer.name="QA peer";peer.zone="Europe/Berlin";peer.record("outside",1790931600000L);
            prefs.edit().putString("role","duplex").putString("code",own.code()).putString("private",Pairing.encode(own.privateKey.getEncoded())).putString("state",mine.json().toString()).putString("peerCode",writer.code()).putString("peerState",new KabarState().json().toString()).commit();
            String ownBefore=Store.state(fixture).json().toString();
            JSONObject packet=new JSONObject(incoming.decrypt(writer.encrypt(Seirama.packet(peer,true,Pairing.parse(own.code())).toString())));
            check(Store.receive(fixture,packet,writer.topic(),"first"),"Peer revision independent of own revision");
            check(Store.state(fixture).json().toString().equals(ownBefore),"Peer cannot overwrite own history");
            check(Store.peerState(fixture).name.equals("QA peer"),"Peer saved in independent slot");
            check(Store.reciprocity(fixture).equals("active"),"Signed reciprocal binding activates mode");
            check(Store.linkPeer(fixture,incoming),"Same peer rejoin identified");
            check(Store.reciprocity(fixture).equals("active")&&prefs.getString("cursor","").equals("first"),"Same peer rejoin keeps proof and cursor");
            check(!Store.receive(fixture,packet,writer.topic(),"replay"),"Replay rejected");
            check(!Store.receive(fixture,packet,own.topic(),"wrong-source"),"Wrong source topic rejected");
            peer.revision++;
            JSONObject revoked=new JSONObject(incoming.decrypt(writer.encrypt(Seirama.revocation(peer).toString())));
            check(Store.receive(fixture,revoked,writer.topic(),"revoked"),"Authenticated revocation accepted");
            check(Store.reciprocity(fixture).equals("inactive"),"Authenticated revocation clears active state");
            check(Store.linkPeer(fixture,incoming)&&Store.reciprocity(fixture).equals("inactive"),"Same peer rejoin cannot erase a verified revocation");
            check(!Store.receive(fixture,packet,writer.topic(),"old-consent"),"Old consent cannot reactivate mode");
            check(Store.state(fixture).json().toString().equals(ownBefore),"Revocation preserves own state");
            Store.retire(fixture,own,Store.state(fixture));
            JSONObject retired=new JSONArray(prefs.getString("retiredQueue","[]")).getJSONObject(0);
            JSONObject shutdown=new JSONObject(Pairing.parse(own.code()).decrypt(retired.getString("body")));
            check(!shutdown.optBoolean("seirama",true)&&!shutdown.optBoolean("notify",true),"Retired outbox holds signed silent shutdown");
            check(!retired.has("private")&&!retired.has("code"),"Retired outbox retains no private key or read capability");
            check(!Store.linkPeer(fixture,Pairing.create()),"Different peer resets stream association");
            check(Store.peerState(fixture).revision==0&&Store.reciprocity(fixture).equals("waiting")&&!prefs.contains("cursor"),"Different peer clears only peer counter/proof/cursor");
            check(Store.state(fixture).json().toString().equals(ownBefore),"Changing peer preserves own history");
            prefs.edit().remove("private").commit();
            check(!prefs.contains("private")&&Pairing.parse(own.code()).decrypt(retired.getString("body")).equals(shutdown.toString()),"Queued shutdown survives writer key removal");
            result.put("independentStates",true).put("reciprocalSignature",true).put("replayRejected",true).put("revocationVerified",true).put("retiredNoKeys",true).put("samePeerRejoin",true);
        } finally {
            check(prefs.edit().clear().commit(),"Fixture cleanup committed");
            check(prefs.getAll().isEmpty(),"All fixture keys/status/outboxes removed");
            app.deleteSharedPreferences(fixtureName);
            Map<String,?> after=Store.prefs(app).getAll();
            for(String key:new String[]{"code","private","peerCode","role","state","peerState","queue","retiredQueue"})check(java.util.Objects.equals(before.get(key),after.get(key)),"Actual application pairing/status/outboxes untouched");
        }
        result.put("fixtureClean",true).put("originalUntouched",true);return result;
        }
    }
}
