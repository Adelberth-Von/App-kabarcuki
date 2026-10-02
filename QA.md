# Laporan QA — Kabar 0.1.0

Tanggal: **2 Oktober 2026** (Asia/Bangkok). Hasil: **127 assertions otomatis lulus**, ditambah pemeriksaan visual dan alur Android yang dijelaskan di bawah.

## Artefak yang diuji

- Paket: `id.kabar.app`, versi `0.1.0` / versionCode `1`.
- APK: `Kabar-0.1.0.apk`, **45.894 byte**.
- SHA-256: `848af00842e38c3b4dc242534e0c9f29eb39ecec3983451412c978800fc38865`.
- Minimum Android 8.0 / API 26; target dan compile API 35.
- Build langsung memakai JDK 17, aapt2, javac, D8, zipalign, dan apksigner.
- Verifikasi tanda tangan APK **v2 dan v3 lulus**. APK tidak memerlukan signature v1 karena minimum API 26.
- Package metadata, launcher activity, permissions, foreground service, dan widget provider diperiksa dari APK hasil build.

## Lingkungan dan hasil otomatis

Pengujian aplikasi dijalankan pada **satu emulator Android 11 / API 30, AOSP x86_64, layar 412 × 892**, dengan akselerasi WHPX. Pengujian antarperangkat memakai emulator dan klien Java terpisah melalui relay internet ntfy.sh. **Dua HP fisik belum diuji.**

| Rangkaian pengujian | Assertions | Hasil |
|---|---:|---|
| Aturan makan, tanggal, status, JSON, pairing, enkripsi dan tanda tangan | 58 | Lulus |
| Pengiriman nyata melalui relay, cursor/replay, dan stream subscription | 19 | Lulus |
| UI Android, antrean offline, pengeditan nama/tombol, persistensi, scroll, dan widget pixel art | 33 | Lulus |
| Android menerima update dari pengirim Java, mempertahankan riwayat lokasi/makan, dan menampilkan notifikasi saat Activity di latar belakang | 6 | Lulus |
| Android mengirim Kost → Makan → Keluar, antrean terkirim, dan relay mengakui pengiriman | 6 | Lulus |
| Penerima Java memverifikasi tanda tangan dan mendekripsi status yang dibuat APK Android | 5 | Lulus |
| **Total checks dalam rangkaian tes** | **127** | **Lulus** |

Angka di atas menghitung assertions dalam rangkaian akhir, bukan menjumlahkan semua pengulangan selama perbaikan. Tes diulang ketika ada perubahan yang memengaruhinya.

### Kasus yang tercakup

- Batas jam makan awal/akhir, sela 15.00–17.00, jadwal khusus, dan penolakan rentang kosong/tumpang tindih/jam di luar 0–24.
- Catatan **Makan** mempertahankan lokasi dan waktu terakhir di kost; **Keluar** mempertahankan waktu kost dan makan.
- Pergantian hari mempertahankan waktu terakhir makan, menampilkan **Kemarin**, dan mengosongkan checklist makan hari ini secara logis.
- Catatan sarapan tetap tersedia setelah riwayat 12 kabar bergeser.
- Revisi dan serialisasi/deserialisasi state; penolakan jenis tombol, label, waktu, dan format yang tidak valid.
- Pairing yang benar, kode rusak, spasi saat menempel kode, pemulihan kunci pengirim, serta pemisahan kunci tanda tangan pengirim dari penerima.
- AES-GCM memakai nonce baru, pesan berubah ditolak, keluarga berbeda tidak dapat mendekripsi, dan penerima tidak dapat membuat tanda tangan pengirim.
- Ukuran snapshot terenkripsi sesuai batas body relay 4096 byte untuk fixture nama panjang.
- Kabar offline tersimpan dalam antrean. Antrean penuh dibatasi 25; kabar berikutnya ditolak tanpa mengubah state yang sudah tersimpan.
- Label default dapat diganti menjadi **Pergi**, **Rumah**, dan **Sudah makan**, serta digunakan pada tombol dan widget.
- Nama/tombol bertahan setelah Activity dibuat ulang.
- Pembaruan status mempertahankan posisi gulir halaman Pengaturan.
- Widget dapat di-inflate Android sebagai RemoteViews, menampilkan nama/tombol baru, dan merender ilustrasi pixel art. Widget penerima menyembunyikan tombol pengirim.
- Replay memakai cursor sehingga tidak mengambil ulang kabar yang sudah diproses. Koneksi stream nyata yang sama dengan layanan Android diuji.
- Arah Java → Android dan Android → Java diuji lewat relay sebenarnya, dengan payload terenkripsi dan tanda tangan, bukan relay mock.
- Android receiver benar-benar mem-post notification ID 2 saat Activity berada di latar belakang. Ini belum menguji Doze atau penghentian aplikasi oleh produsen HP.

## Pemeriksaan manual pada emulator

- APK terpasang dan aplikasi terbuka tanpa crash.
- Dialog Android untuk **Tambahkan widget** muncul; widget ditambahkan ke launcher melalui **Add automatically**.
- Layout aplikasi pengirim dan penerima, pixel art, navigasi, serta widget diperiksa melalui screenshot.
- Menekan tombol widget membuka aplikasi dan menjalankan aksinya. Saat antrean penuh, muncul pesan batas antrean yang sesuai.
- **Uninstall Kabar → Lanjutkan** membuka dialog uninstall milik Android. Dialog dibatalkan agar aplikasi tetap tersedia untuk QA.
- **Putuskan hubungan HP ini → Putuskan** mengembalikan aplikasi ke layar pemilihan peran.
- Log `AndroidRuntime:E` tidak menampilkan crash pada pemeriksaan akhir.

Screenshot berada di `screenshots/`. Data pada screenshot adalah fixture QA, bukan kabar pengguna.

## Temuan dan perbaikan selama QA

- Pembacaan cache relay tepat setelah publish kadang belum berisi pesan. Penguji replay sekarang menunggu penyimpanan cache, sedangkan jalur live memakai stream subscription yang sudah diuji.
- Checklist makan yang hanya memakai riwayat terbatas dapat kehilangan sarapan setelah banyak klik. Catatan tiap kategori makan kini disimpan terpisah.
- Pergantian kode membutuhkan pemisahan worker/koneksi lama dan baru. Pemeriksaan sesi dan penutupan koneksi memakai objek koneksi yang tepat.
- Widget semula mengisi seluruh slot launcher dan meninggalkan ruang kosong besar. Background kartu kini mengikuti tinggi kontennya.
- Refresh status semula mengembalikan posisi gulir ke atas. Posisi kini dipulihkan setelah layout pada halaman yang sama; ada regression assertion untuk kasus ini.
- Penguji dialog pernah membaca jendela sebelum form tersedia. Penguji kini menunggu jendela dialog yang memiliki empat field; ini perbaikan penguji.

## Belum terverifikasi pada HP fisik

Android 8, Android 13–16, prompt izin notifikasi Android 13+, aturan foreground service Android 14+, edge-to-edge Android 15+, launcher tiap merek, Doze, layar mati dalam waktu lama, pembatasan baterai vendor, restart, dan jaringan seluler yang berpindah-pindah belum diuji pada perangkat nyata. Manifest dan kode memiliki cabang versi yang diperlukan, tetapi kompilasi bukan bukti pengujian runtime untuk semua versi.

Versi ini memakai foreground service dengan notifikasi tetap, bukan FCM. Notifikasi dapat tertunda atau berhenti jika internet mati, layanan dijeda, aplikasi dipaksa berhenti, atau Android membatasi aplikasi. Setelah restart atau Paksa berhenti, buka Kabar lagi. Relay memiliki cache sementara dan batas layanan; bukan arsip permanen atau jaminan pengiriman instan.

Persetujuan pasangan per perangkat, pengingat makan otomatis, pemulihan kunci, GPS, penghapusan cache relay, dan push FCM belum tersedia. Kode pasangan dapat digunakan beberapa penerima; mengganti kode mencabut akses kabar baru untuk semua penerima lama.

## Checklist uji dua HP

1. Pasang APK yang sama di kedua HP. HP A: **Aku membagikan kabar**; HP B: **Aku menerima kabar** dengan kode dari HP A.
2. Izinkan notifikasi pada kedua HP, khususnya HP B. Pastikan layanan **Kabar aktif** tampil.
3. Tekan **Kost** di A. B harus menampilkan lokasi kost dan waktu yang sesuai.
4. Tekan **Makan** di A. B harus mempertahankan lokasi kost dan menambahkan waktu/kategori makan.
5. Tekan **Keluar** di A. B harus menampilkan Keluar, sambil mempertahankan waktu terakhir di kost dan makan.
6. Tekan Home di B; ulangi perubahan dari A. Periksa notifikasi di B. Coba juga layar mati beberapa menit untuk mengetahui batas baterai perangkat.
7. Edit nama tombol di A. Periksa label di A, B, dan widget. Edit jadwal makan dan periksa kategori pada catatan makan berikutnya.
8. Pasang widget di B. Pastikan perubahan status muncul; waktu pembaruan dapat mengikuti koneksi dan pembatasan perangkat.
9. Matikan internet A, catat satu status, lalu nyalakan lagi. Antrean harus berkurang setelah relay menerima pesan dan B mendapat status.
10. Coba jeda/aktifkan koneksi B. Setelah aplikasi dipaksa berhenti atau HP restart, buka Kabar lagi sebelum mengharapkan notifikasi.
11. Uji ganti kode di A. B dengan kode lama tidak boleh menerima kabar baru; hubungkan ulang menggunakan kode baru.
12. Jika selesai, gunakan Putuskan hubungan atau Uninstall Kabar. Uninstall tetap meminta konfirmasi Android.

## Menjalankan ulang tes

Tes logika/live: `tests/run-tests.ps1` (tambahkan `-Live` untuk relay). Penguji Android: `tests/build-device-qa.ps1` menghasilkan APK instrumentation terpisah di `work/device-qa`, bukan dalam APK pengguna. Mode `ui`, `sender`, dan `receiver` dijalankan melalui instrumentation `id.kabar.qa/id.kabar.app.DeviceQA` pada target `id.kabar.app`.

Tes memakai state dan kode baru khusus QA, serta mereset data target di emulator. Jangan menjalankan instrumentation pada HP yang berisi kabar asli. File `DeviceQA.java` tidak dimasukkan ke APK Kabar pengguna.
