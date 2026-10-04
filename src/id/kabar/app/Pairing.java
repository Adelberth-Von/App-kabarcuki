package id.kabar.app;

import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.spec.*;
import java.util.Base64;
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

/** Shared AES key provides privacy; only the sender has the signing private key. */
public final class Pairing {
    private static final SecureRandom RANDOM=new SecureRandom();
    public final byte[] secret;
    public final PublicKey publicKey;
    public final PrivateKey privateKey;
    public Pairing(byte[] secret,PublicKey publicKey,PrivateKey privateKey) {
        this.secret=secret; this.publicKey=publicKey; this.privateKey=privateKey;
    }
    public static Pairing create() throws Exception {
        KeyPairGenerator g=KeyPairGenerator.getInstance("EC");
        g.initialize(new ECGenParameterSpec("secp256r1"));
        KeyPair p=g.generateKeyPair();
        byte[] secret=new byte[32]; RANDOM.nextBytes(secret);
        return new Pairing(secret,p.getPublic(),p.getPrivate());
    }
    public static String encode(byte[] bytes) { return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes); }
    public static byte[] decode(String text) { return Base64.getUrlDecoder().decode(text); }
    public String code() { return "KB1."+encode(secret)+"."+encode(publicKey.getEncoded()); }
    public static Pairing parse(String raw) throws Exception {
        String clean=raw.replaceAll("\\s+", "");
        String[] p=clean.split("\\.");
        if(p.length!=3 || !p[0].equals("KB1") || clean.length()>400) throw new IllegalArgumentException("Kode pasangan tidak valid");
        byte[] secret=decode(p[1]);
        if(secret.length!=32) throw new IllegalArgumentException("Kunci pasangan tidak valid");
        PublicKey pub=KeyFactory.getInstance("EC").generatePublic(new X509EncodedKeySpec(decode(p[2])));
        if (!(pub instanceof java.security.interfaces.ECPublicKey) || ((java.security.interfaces.ECPublicKey)pub).getParams().getCurve().getField().getFieldSize()!=256) throw new IllegalArgumentException("Kunci publik tidak valid");
        return new Pairing(secret,pub,null);
    }
    public Pairing withPrivate(String encoded) throws Exception {
        PrivateKey key=KeyFactory.getInstance("EC").generatePrivate(new PKCS8EncodedKeySpec(decode(encoded)));
        byte[] challenge="kabar-key-match-v1".getBytes(StandardCharsets.UTF_8);
        Signature check=Signature.getInstance("SHA256withECDSA");check.initSign(key);check.update(challenge);byte[] proof=check.sign();
        check.initVerify(publicKey);check.update(challenge);if(!check.verify(proof))throw new SecurityException("Kunci pengirim tidak cocok");
        return new Pairing(secret,publicKey,key);
    }
    public String topic() throws Exception {
        byte[] digest=MessageDigest.getInstance("SHA-256").digest(("kabar-v1:"+code()).getBytes(StandardCharsets.UTF_8));
        return "kabar-"+encode(digest);
    }
    public String encrypt(String json) throws Exception {
        if(privateKey==null) throw new SecurityException("Hanya pengirim dapat mengirim status");
        byte[] nonce=new byte[12]; RANDOM.nextBytes(nonce);
        Cipher cipher=Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE,new SecretKeySpec(secret,"AES"),new GCMParameterSpec(128,nonce));
        byte[] ciphertext=cipher.doFinal(json.getBytes(StandardCharsets.UTF_8));
        String signed="K1."+encode(nonce)+"."+encode(ciphertext);
        Signature signature=Signature.getInstance("SHA256withECDSA");
        signature.initSign(privateKey); signature.update(signed.getBytes(StandardCharsets.UTF_8));
        return signed+"."+encode(signature.sign());
    }
    /** Public signed hint lets an Apple push bridge distinguish clicks from silent snapshots. */
    public String alertProof(String envelope) throws Exception {
        if(privateKey==null)throw new SecurityException("Hanya pengirim dapat menandai notifikasi");
        Signature s=Signature.getInstance("SHA256withECDSA");s.initSign(privateKey);
        s.update(("kabar-alert-v1:"+envelope).getBytes(StandardCharsets.UTF_8));
        return "KB1."+encode(s.sign());
    }
    public boolean verifyAlert(String envelope,String proof) throws Exception {
        if(!proof.startsWith("KB1."))return false;
        Signature s=Signature.getInstance("SHA256withECDSA");s.initVerify(publicKey);
        s.update(("kabar-alert-v1:"+envelope).getBytes(StandardCharsets.UTF_8));
        return s.verify(decode(proof.substring(4)));
    }
    public String decrypt(String envelope) throws Exception {
        if(envelope.length()>8192) throw new SecurityException("Pesan terlalu besar");
        String[] p=envelope.split("\\.");
        if(p.length!=4 || !p[0].equals("K1")) throw new SecurityException("Format pesan salah");
        Signature signature=Signature.getInstance("SHA256withECDSA");
        signature.initVerify(publicKey);
        signature.update((p[0]+"."+p[1]+"."+p[2]).getBytes(StandardCharsets.UTF_8));
        if(!signature.verify(decode(p[3]))) throw new SecurityException("Tanda tangan tidak valid");
        byte[] nonce=decode(p[1]);
        if(nonce.length!=12) throw new SecurityException("Nonce tidak valid");
        Cipher cipher=Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.DECRYPT_MODE,new SecretKeySpec(secret,"AES"),new GCMParameterSpec(128,nonce));
        return new String(cipher.doFinal(decode(p[2])),StandardCharsets.UTF_8);
    }
}
