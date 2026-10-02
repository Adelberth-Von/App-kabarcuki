# Push bridge Apple — belum dideploy

Program Node.js 22+ ini menghubungkan relay ntfy dengan APNs untuk aplikasi Kabar iOS. Tidak perlu login keluarga. Penyiapan dilakukan satu kali oleh pengelola aplikasi.

Bridge menyimpan public signing key, hash capability, topic terenkripsi, token perangkat, cursor serta deduplikasi. **Kunci AES dan signing private key pengirim tidak diterima server.** Status terenkripsi diverifikasi dengan P-256. Petunjuk notifikasi `KB1.<DER-signature>` pada metadata Title ditandatangani atas `kabar-alert-v1:<envelope>`; hanya ketukan dengan petunjuk valid menghasilkan APNs. Metadata ini menunjukkan ada kabar yang meminta notifikasi, tanpa mengungkap nama/status.

## Jalankan

1. Buat APNs authentication key dari akun Apple Developer untuk aplikasi yang telah diprovisioning. Simpan `.p8` di direktori rahasia di luar Git; gunakan izin file terbatas.
2. Salin `.env.example` menjadi `.env`, isi Team ID, Key ID, lokasi kunci dan Bundle ID aplikasi. `APNS_ENV=development` untuk build development; `production` untuk TestFlight/App Store. File contoh tidak berisi credential.
3. Pasang Node.js 22+, lalu:

   ```sh
   cd server
   npm test
   node --env-file=.env bridge.mjs
   ```

4. Pasang reverse proxy HTTPS pada URL `PUBLIC_URL`, diteruskan ke `127.0.0.1:8787`. Atur batas request body 4 KB, timeout, pembatasan koneksi dan pengawasan proses. Endpoint `/health` menyediakan status proses, bukan validasi koneksi APNs.
5. Masukkan URL HTTPS itu di Pengaturan Kabar pada iPhone/iPad penerima, lalu izinkan notifikasi. Di aplikasi keluarga yang siap distribusi, URL bisa diprakonfigurasi saat build agar orang tua tidak perlu mengaturnya sendiri.

Tidak ada dependensi npm runtime. Server membaca environment saat start; `npm start` tidak otomatis membaca `.env`. Jangan menyalin kunci APNs ke aplikasi mobile. Jangan commit `.env`, private key, database token, atau provisioning.

## Batas dan pengoperasian

- Listener hanya localhost; HTTPS dikelola reverse proxy. Secara default maksimal 20 keluarga, 10 token per keluarga, body pendaftaran 4096 byte, dan 30 request/menit per IP listener. Bila memakai reverse proxy, alamat yang terlihat adalah proxy; sesuaikan rate limiting di proxy untuk penggunaan lebih luas.
- Pendaftaran pertama menggunakan topic/capability panjang yang tidak dapat ditebak secara praktis. Pendaftaran berikutnya harus memakai capability dan public key yang sama. Capability perlu diperlakukan sebagai rahasia; jangan log header Authorization/body pendaftaran. Tidak ada katalog keluarga publik.
- Perangkat harus membuka Kabar setidaknya sekali setiap 14 hari untuk memperbarui pendaftaran. Token APNs yang dinyatakan tidak valid dihapus. Cursor dan token disimpan pada `KABAR_DATA_DIR`; batasi akses database dan lindungi backup.
- Pesan yang muat <=4096 byte dibawa langsung oleh APNs. Pesan lebih besar menggunakan referensi acak, diambil ekstensi dengan capability. Cache referensi terenkripsi hanya di memori selama 1 jam; jika proses restart atau fetch gagal, notifikasi umum ditampilkan, lalu aplikasi memulihkan dari ntfy.
- APNs memakai collapse ID per keluarga: update yang menumpuk dapat digabung oleh Apple. Relay/cache, APNs, jaringan dan OS dapat menunda atau melewatkan notifikasi. Antrean ntfy bukan arsip permanen.
- Bridge harus berjalan terus agar menerima klik Android ketika aplikasi iPhone tertutup. Ini bukan server production yang sudah dioperasikan atau hasil uji APNs pada iPhone fisik.
- Tes mencakup validasi pendaftaran, capability, tanda tangan DER, penolakan manipulasi pesan, hint silent/alert, ukuran payload, dan JWT ES256. Pengiriman APNs nyata memerlukan credential dan perangkat Apple; belum diuji.

Referensi: [APNs server](https://developer.apple.com/documentation/usernotifications/setting-up-a-remote-notification-server), [request APNs](https://developer.apple.com/documentation/usernotifications/sending-notification-requests-to-apns), [Notification Service Extension](https://developer.apple.com/documentation/usernotifications/modifying-content-in-newly-delivered-notifications).
