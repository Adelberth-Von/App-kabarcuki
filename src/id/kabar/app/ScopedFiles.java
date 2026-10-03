package id.kabar.app;
import java.io.*;
import java.nio.file.Files;

/** Clear only children of an explicitly supplied app-owned directory. Never follow links. */
public final class ScopedFiles {
    public static void clear(File directory)throws IOException {
        if(directory==null||!directory.exists())return;
        File root=directory.getCanonicalFile();
        File[] children=directory.listFiles();
        if(children==null)throw new IOException("Cannot read application directory");
        for(File child:children)remove(root,child);
    }
    private static void remove(File root,File file)throws IOException {
        if(Files.isSymbolicLink(file.toPath())) {Files.delete(file.toPath());return;}
        String allowed=root.getCanonicalPath()+File.separator;
        if(!file.getCanonicalPath().startsWith(allowed))throw new IOException("Path outside application directory");
        if(file.isDirectory()) {
            File[] children=file.listFiles();
            if(children==null)throw new IOException("Cannot read application directory");
            for(File child:children)remove(root,child);
        }
        if(!file.delete()&&file.exists())throw new IOException("Cannot clear application file");
    }
}
