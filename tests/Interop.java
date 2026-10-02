package id.kabar.app;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import org.json.*;
/** CI-only bidirectional Java/CryptoKit interoperability fixture. No production key. */
public class Interop {
 public static void main(String[] args)throws Exception {
  Path dir=Paths.get(args[1]);Files.createDirectories(dir);
  if(args[0].equals("generate")) {
   Pairing p=Pairing.create();KabarState s=new KabarState();s.zone="Asia/Jakarta";
   s.record("home",1790902800000L);s.record("meal",1790904600000L);s.record("outside",1790906400000L);
   s.gps=new GpsPoint(-6.2,106.816666,20,1790906400000L,"Asia/Jakarta");s.events.getJSONObject(0).put("gps",s.gps.json());
   JSONObject f=new JSONObject().put("code",p.code()).put("topic",p.topic()).put("state",s.json()).put("envelope",p.encrypt(new JSONObject().put("state",s.json()).put("notify",true).toString()));
   Files.write(dir.resolve("java.json"),f.toString().getBytes(StandardCharsets.UTF_8));
   Files.write(dir.resolve("java-private.txt"),Pairing.encode(p.privateKey.getEncoded()).getBytes(StandardCharsets.UTF_8));
  } else {
   JSONObject f=new JSONObject(new String(Files.readAllBytes(dir.resolve("swift.json")),StandardCharsets.UTF_8));
   Pairing p=Pairing.parse(f.getString("code"));
   if(!p.topic().equals(f.getString("topic")))throw new AssertionError("Topic mismatch");
   JSONObject packet=new JSONObject(p.decrypt(f.getString("envelope")));KabarState s=KabarState.parse(packet.getJSONObject("state").toString());
   if(s.revision!=3||!s.location.equals("outside")||s.homeAt<=0||s.mealAt<=0)throw new AssertionError("State mismatch");
   if(s.gps==null||Math.abs(s.gps.lat+6.2)>0.000001)throw new AssertionError("GPS mismatch");
   System.out.println("PASS Swift sender -> Java receiver AES-GCM and P-256 DER interoperability");
  }
 }
}
