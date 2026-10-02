# Kabar 0.1.0 — APK uji dua HP

Kabar adalah aplikasi Android native dengan tema sage, krem, peach, dan ilustrasi pixel art. Tidak ada layar login. Satu APK yang sama digunakan untuk pengirim dan penerima.

## Pasang dan hubungkan

1. Kirim **Kabar-0.1.0.apk** ke kedua HP Android. Minimal Android 8.0 (API 26). APK tidak dapat dipasang di iPhone.
2. Buka file APK. Jika Android meminta, izinkan instalasi dari aplikasi yang dipakai membuka file, kemudian tekan **Install**. Jika aplikasi pemindai keamanan menampilkan hasil, ikuti informasi yang ditampilkan; jangan menonaktifkan perlindungan perangkat.
3. Di HP pertama, buka Kabar dan pilih **Aku membagikan kabar**. Izinkan notifikasi bila diminta.
4. Buka **Pengaturan → Salin kode pasangan**. Pindahkan kode lengkap ke HP kedua, misalnya melalui pesan pribadi. Kode bukan PIN pendek; salin/tempel agar tidak salah.
5. Di HP kedua pilih **Aku menerima kabar**, tempel kode, lalu tekan **Hubungkan**. Izinkan notifikasi.
6. Tekan **Kost** di HP pertama. Status di HP kedua akan berubah. Coba **Makan**, lalu **Keluar**. Kedua HP dapat memakai jaringan internet yang berbeda.
7. Di setiap HP buka **Pengaturan → Tambahkan widget**, lalu konfirmasi melalui launcher. Jika launcher tidak mendukung penambahan otomatis, tekan lama area kosong layar utama → Widget → Kabar.

Kode pasangan bersifat rahasia. Siapa pun yang memiliki kode dapat membaca status. Hanya HP pengirim memiliki kunci untuk menandatangani status baru. Versi ini memakai undangan berupa kode bersama; belum ada persetujuan per perangkat atau daftar penerima individual. Untuk mencabut akses, gunakan **Ganti kode pasangan**, lalu hubungkan kembali penerima yang diinginkan.

## Tombol dan catatan waktu

- **Keluar:** memperbarui lokasi di luar, mempertahankan waktu terakhir di tempat tinggal dan makan.
- **Kost:** memperbarui lokasi tempat tinggal dan waktu terakhir berada di sana.
- **Makan:** mencatat waktu serta kategori makan; lokasi tidak berubah.
- **Edit nama & tombol:** mengganti nama pengirim dan label ketiga tombol. Fungsi lokasi/makan tetap mengikuti jenis tombolnya. Contoh: Keluar → Pergi, Kost → Rumah, Makan → Sudah makan.
- **Atur jam makan:** mengubah tiga rentang jam. Batas awal termasuk, batas akhir tidak termasuk. Rentang harus berurutan tanpa tumpang tindih.
- Jadwal awal: sarapan 05.00–10.00; siang 10.00–15.00; malam 17.00–22.00. Di luar rentang dicatat sebagai **Makan**.
- Status memakai zona waktu HP pengirim. Catatan melewati tengah malam tetap tersimpan dengan label **Kemarin**, sementara daftar makan hari ini mengikuti tanggal baru.
- **Belum tercatat** berarti belum ada tombol ditekan; aplikasi tidak menyimpulkan bahwa pengguna belum makan.
- Lokasi yang berumur minimal 6 jam diberi keterangan sudah lama. Tidak ada GPS atau pelacakan lokasi otomatis.
- Riwayat menampilkan 12 kabar terbaru. Catatan sarapan/siang/malam disimpan terpisah agar tidak hilang hanya karena riwayat bergeser.

## Internet, notifikasi, dan baterai

Versi uji memakai relay publik **https://ntfy.sh**, sehingga tidak perlu membuat akun Firebase atau menyiapkan server sendiri. Status dienkripsi AES-256-GCM dan ditandatangani ECDSA P-256 sebelum dikirim melalui HTTPS. Relay menerima ciphertext, waktu pengiriman, dan metadata jaringan. Tidak ada nama atau lokasi dalam teks pesan relay.

Layanan koneksi aktif menampilkan notifikasi tetap **Kabar aktif**. Ini memakai foreground service Android, bukan Firebase push. Menutup layar aplikasi dengan tombol Home tetap memungkinkan layanan berjalan, tetapi penghematan baterai, Doze, jaringan, pengaturan notifikasi, dan kebijakan produsen HP dapat menunda atau menghentikannya. Untuk uji latar belakang, izinkan aktivitas latar belakang Kabar pada pengaturan baterai. Setelah restart, Paksa berhenti, atau penghentian layanan oleh Android, buka Kabar kembali. Jangan mengharapkan aplikasi berjalan diam-diam atau notifikasi instan yang dijamin.

Status **Kabar terkirim ke relay** berarti server menerima pesan, bukan tanda HP penerima sudah membacanya. **Terhubung ke relay** menunjukkan koneksi penerima ke layanan, bukan keberadaan pengirim secara langsung.

Saat offline, pengirim menyimpan antrean maksimal 25 kabar dan mencoba kembali dengan jeda yang bertambah sampai 60 detik. Setelah penuh, aplikasi menolak kabar tambahan dengan penjelasan; kabar tersimpan sebelumnya tetap ada. Penerima memulihkan kabar yang masih tersedia di cache menggunakan cursor. Revisi yang sama atau lebih lama tidak mengubah status dan tidak menghasilkan notifikasi ulang.

Relay memiliki batas penggunaan, tanpa jaminan layanan. Cache sementara umumnya 12 jam; jangan mengandalkannya sebagai arsip permanen. Jika pengirim tetap aktif, snapshot diperbarui setiap 4 jam tanpa notifikasi. Jika kedua aplikasi lama tidak aktif atau penerima belum pernah menerima status, buka pengirim dan tekan status lagi. Notifikasi kabar lama saat pemasangan pertama disenyapkan; pembaruan baru dan kabar yang tertunda setelah pernah terhubung dapat menghasilkan notifikasi.

## Hapus dan putuskan

- **Jeda koneksi:** menghentikan layanan. Lanjutkan dengan Aktifkan koneksi.
- **Hapus riwayat:** pengirim mengosongkan status serta catatan makan/lokasi, lalu mengirim snapshot kosong ke penerima. Cache relay terenkripsi lama mengikuti masa simpan layanan dan tidak dihapus oleh tombol ini.
- **Ganti kode pasangan:** mencabut penerimaan kabar baru melalui kode lama. Catatan yang sudah disimpan di HP lama tetap ada.
- **Putuskan hubungan HP ini:** menghapus data dan kode pasangan lokal. Tidak menghapus data di HP lain.
- **Uninstall Kabar:** membuka konfirmasi uninstall Android. Menghapus APK di Download hanya menghapus file installer, bukan aplikasi terpasang.
- Tidak ada skrip terpisah yang dipasang di HP. Aplikasi dan data lokal dikelola Android.

## Batas versi uji

Belum tersedia notifikasi push FCM yang hemat baterai, persetujuan penerima per perangkat, pengingat makan otomatis, GPS, pemulihan kunci pengirim, atau distribusi Play Store. Menghapus data atau memasang ulang HP pengirim dapat menghilangkan kunci pengirim; kode penerima tidak dapat memulihkannya. Buat pasangan baru jika ini terjadi. Menambah penerima dapat dilakukan dengan kode yang sama.

APK ini ditandatangani dengan kunci pengembangan lokal untuk sideload dan uji pribadi. Kunci build disimpan di folder kerja komputer, tidak dimasukkan ke APK atau paket sumber. Aplikasi tidak memiliki akses khusus, root, Accessibility Service, kontak, SMS, mikrofon, atau GPS.

## Sumber dan build

Kode Java, resources XML, manifest, skrip build, dan tes tersedia dalam folder ini. Tidak ada dependensi runtime eksternal di APK.

Build memakai JDK 17, Android platform API 35, dan Build Tools 35.0.0. Skrip `build.ps1` memakai alat yang disiapkan di `work/tools` pada workspace asal. Ini bukan proyek Gradle; pipeline langsung: aapt2 → javac → D8 → zipalign → apksigner.

```powershell
./build.ps1 -ToolRoot "C:\path\to\tools"
./tests/run-tests.ps1 -ToolRoot "C:\path\to\tools"
./tests/run-tests.ps1 -ToolRoot "C:\path\to\tools" -Live
```

`ToolRoot` berisi direktori JDK (`bin/java.exe` dan `bin/javac.exe`), `android-35/android.jar`, Build Tools pada `android-15/` (nama direktori dalam ZIP resmi; revisinya 35.0.0), dan `json.jar` untuk tes JVM. Pustaka JSON hanya dipakai di tes desktop; aplikasi menggunakan JSON bawaan Android.

Lihat **QA.md** untuk hasil pengujian dan daftar uji dua HP.

Referensi: [API ntfy](https://docs.ntfy.sh/subscribe/api/), [pengiriman dan cache ntfy](https://docs.ntfy.sh/publish/), [foreground service Android](https://developer.android.com/about/versions/14/changes/fgs-types-required).
