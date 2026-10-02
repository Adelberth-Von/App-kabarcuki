package id.kabar.app;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;

public final class Relay {
    public static final String BASE="https://ntfy.sh";
    private Relay() {}
    public static HttpURLConnection open(String path) throws IOException {
        HttpURLConnection c=(HttpURLConnection)new URL(BASE+path).openConnection();
        c.setConnectTimeout(15000); c.setReadTimeout(75000);
        c.setRequestProperty("User-Agent","Kabar-Android/0.1");
        return c;
    }
    public static void publish(String topic,String payload) throws IOException {
        HttpURLConnection c=open("/"+topic);
        try {
            c.setRequestMethod("POST");c.setDoOutput(true);
            c.setRequestProperty("Content-Type","text/plain; charset=utf-8");
            byte[] b=payload.getBytes(StandardCharsets.UTF_8);
            c.setFixedLengthStreamingMode(b.length);
            try(OutputStream o=c.getOutputStream()){o.write(b);}
            int status=c.getResponseCode();
            if(status!=200)throw new IOException("Relay HTTP "+status);
            try(InputStream in=c.getInputStream()){while(in.read()!=-1){}}
        }finally{c.disconnect();}
    }
}
