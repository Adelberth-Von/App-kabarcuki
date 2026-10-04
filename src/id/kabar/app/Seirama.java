package id.kabar.app;

import java.nio.charset.StandardCharsets;
import org.json.JSONObject;

/** Reciprocal consent is signed on independent streams; invitations never contain private keys. */
public final class Seirama {
    private Seirama() {}
    public static String invite(Pairing own) {return "KB2."+Pairing.encode(own.code().getBytes(StandardCharsets.UTF_8));}
    public static Pairing parseInvite(String raw) throws Exception {
        String clean=raw==null?"":raw.replaceAll("\\s+","");
        if(!clean.startsWith("KB2.")||clean.length()>560)throw new IllegalArgumentException("Kode Seirama tidak valid");
        return Pairing.parse(new String(Pairing.decode(clean.substring(4)),StandardCharsets.UTF_8));
    }
    public static void requireDifferent(Pairing own,Pairing peer)throws Exception {
        if(isOwn(own,peer))throw new IllegalArgumentException("Gunakan kode dari perangkat pasangan");
    }
    public static boolean isOwn(Pairing own,Pairing peer){return java.util.Arrays.equals(own.publicKey.getEncoded(),peer.publicKey.getEncoded());}
    public static JSONObject packet(KabarState state,boolean notify,Pairing peer)throws Exception {
        state.fitRelay();
        JSONObject packet=new JSONObject().put("state",state.json()).put("notify",notify);
        if(peer!=null)packet.put("peerTopic",peer.topic());
        return packet;
    }
    public static JSONObject revocation(KabarState state)throws Exception {return packet(state,false,null).put("seirama",false);}
    /** Call only after verifying the packet signature using the paired incoming public key. */
    public static boolean reciprocates(JSONObject verified,Pairing own)throws Exception {
        return (!verified.has("seirama")||verified.optBoolean("seirama",true))&&own.topic().equals(verified.optString("peerTopic",""));
    }
    public static KabarState next(JSONObject verified,KabarState previous)throws Exception {
        KabarState state=KabarState.parse(verified.getJSONObject("state").toString());
        String peer=verified.optString("peerTopic","");
        if(!peer.isEmpty()&&!peer.matches("^kabar-[A-Za-z0-9_-]{43}$"))throw new IllegalArgumentException("Pasangan kabar tidak valid");
        return state.revision>previous.revision?state:null;
    }
}
