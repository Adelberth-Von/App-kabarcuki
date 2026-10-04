# Laporan QA — abc 0.9.0 Cozy Pixel Art

Tanggal: **4 Oktober 2026**. APK terbaru dibangun dari perombakan Flutter dengan Shadcn, Pixelify dan pixelarticons.

- Build release berhasil; versionName **0.9.0**, versionCode **9**, paket `id.kabar.app`.
- Minimum Android **10/API 29**, target **36**, ABI ARM32, ARM64 dan x86_64.
- Ukuran **54,314,470 byte**; SHA-256 `bf1e524f2a8e96c60c8e72e76cea3f1a490cfee1b1c966bf22696074bf5804f8`.
- Signature v2 valid; sertifikat sama dengan 0.8.0 sehingga APK dapat dipasang sebagai pembaruan. ZIP alignment 16 KB lulus.
- Guard release lulus: ZIP utuh, nada notifikasi asli 1,08 detik, kelas debug QA tidak dibundel.
- Pada tahap perombakan UI, analyzer bersih dan **43 tes unit/widget lulus**. Pratinjau 14 gambar memakai renderer Flutter lokal.
- APK 0.9.0 belum diuji di emulator atau HP fisik. Hasil perangkat di bawah merupakan arsip versi 0.8.0.

---

# Laporan QA — abc 0.8.0

Tanggal: **4 Oktober 2026**. Fokus: UI dan adegan pixel baru, widget adaptif, Seirama sebagai mode dua arah dengan konfirmasi, serta kredit **develop by terrence**. Nama dan lokasi pada [preview](TAMPILAN.md) merupakan data simulasi pengujian.

## APK yang dibagikan

- Paket `id.kabar.app`, versionName **0.8.0**, versionCode **8**, minimum Android **10/API 29**, target/compile **36**. APK universal ARM32, ARM64, x86_64.
- Ukuran **51.466.926 byte**; SHA-256 `54b14634beae277bc1a418a691e19b85bc48a2e7237919f91fef40d2dc916e88`.
- Signature v2 dan alignment ZIP 16 KB diverifikasi. Sertifikat SHA-256 `ae0b8561a0364415fb9c13292fbae8903fe55e97714a4595f2cf0249323d3065` sama dengan rilis sebelumnya: pemasangan sebagai update mempertahankan pasangan dan data.
- Guard release memeriksa nada asli, kelas debug yang tidak ikut dibundel, dan fixture kode pasangan. Paket sumber mengecualikan kunci pribadi, kredensial, fixture privat, SDK serta hasil build. Segmen LOAD keenam library ELF diperiksa untuk alignment 16 KB.

## Hasil aktual

| Pemeriksaan | Hasil |
|---|---|
| Flutter analyze | Lulus tanpa issue |
| Unit/widget Flutter | **33 kasus lulus**, termasuk konfirmasi/migrasi Seirama, riwayat sendiri/pasangan, waktu pasangan, tiga bahasa, tulisan 200%, kredit pengembang, tombol Hubungkan saat keyboard terbuka, penolakan dialog ganda dari widget, 24 variasi adegan, lifecycle dan pengurangan gerakan |
| Domain Java | **146 assertions lulus**: dua stream independen, kode baca saja, penolakan kode sendiri termasuk kode yang dibungkus ulang, tanda tangan, revisi/cursor per sumber, replay, bukti hubungan timbal balik, penghentian dan penyambungan ulang |
| Widget native Android | **327 assertions lulus** pada 24 kombinasi mode/ukuran/font; kartu dan tombol berada di dalam layout. Delapan bitmap opaque RGB565 320×128 memakai **655.360 byte** dan parcel berada di bawah **950.000 byte** |
| Flutter Android/iPhone | Lulus pada **API 29/30/35/36 dan simulator iPhone**; alur UI, preferensi, bahasa, format waktu, mode warna, detail dan cleanup. Driver mewajibkan marker native dan sembilan screenshot per perangkat |
| Android native API 29–36 | Semua job lulus; smoke UI arsip dan komponen native. Pada API 35, widget juga diuji dengan **font sistem 1,5×**. UI MainActivity arsip tidak masuk APK Flutter; UI aplikasi saat ini diuji melalui Flutter |
| Apple core/native/widget | **9 kasus XCTest core lulus**, interoperabilitas Java/CryptoKit dua arah, build aplikasi/widget/ekstensi dan satu tes UI native simulator lulus |
| APK release di dua emulator | Seirama dikonfirmasi pada kedua HP, kode KB2 ditukar secara privat. Keluar dari Cuki dan Makan dari Mama masuk ke kartu pasangan masing-masing tanpa menimpa kabar sendiri. Asia/Jakarta dan Europe/Berlin tetap memakai zona yang berbeda |
| Migrasi dan persetujuan | Membatalkan migrasi Seirama lama mempertahankan peran dan status. Pengirim mempertahankan riwayat; penerima membuat stream sendiri dengan panggilan lokal. Membatalkan konfirmasi tindakan tidak mengirim status |
| Widget release di launcher | **Empat sampel frame berbeda** ketika aktif, statis pada Battery Saver, lalu kembali bergerak setelah Battery Saver dimatikan. Tombol Keluar membuka konfirmasi kabar sendiri; Batal tidak mengubah data |
| Animasi aplikasi | Adegan berubah per tindakan/mode/fase hari; frame bergerak saat aktif, berhenti saat hemat daya dan berlanjut setelahnya. Render 12 fps hanya memperbarui canvas ilustrasi |
| Notifikasi dan suara | Pembaruan pasangan diterima saat aplikasi berada di latar belakang. Nada asli mono PCM 22.050 Hz, **1,08 detik**, muncul satu kali dalam APK teroptimasi dan bytes-nya sama dengan nada di build iPhone. Channel suara khusus dipertahankan |
| Cleanup | Lulus lokal serta matrix Flutter Android/iPhone. File, cache, database, preferensi, kode/kunci, antrean, riwayat dan data mode dua arah dibersihkan. Notifikasi foreground Android ikut hilang; pembersihan dibatasi data abc |
| Pemeriksaan visual | Beranda kedua mode, kabar sendiri/pasangan, Settings dengan kredit, konfirmasi, detail, mode terang/gelap, widget renderer/launcher dan sembilan screenshot iPhone diperiksa. Video 30 detik memperlihatkan tiga tindakan dan konfirmasi, tanpa kode pasangan privat |

Jumlah assertions dan kasus yang tumpang tindih tidak dijumlahkan sebagai jumlah kasus unik. Preview animasi direkam dari build release 0.8 sebelum penambahan footer kredit dan koreksi keyboard; tampilan utama/adegan pada APK akhir memakai implementasi yang sama. Screenshot kredit dan widget launcher berasal dari APK akhir.

### Bukti CI

- [Flutter Android 10/11/15/16 dan iPhone — seluruh job lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37191042614), sumber `1fce1d5`.
- [Komponen Android API 29–36 dan widget dengan font besar — seluruh job lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37192262414), sumber `f83e2b3`.
- [Apple core/native/widget/ekstensi — lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37176378964), sumber `a1f068a`.
- [Guard asset release teroptimasi — lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37176378992), sumber `a1f068a`; guard juga dijalankan pada APK akhir setelah perubahan kredit/cleanup.

Kode aplikasi APK akhir berasal dari `1fce1d5`; commit berikutnya hanya memperbaiki runner QA native dan dokumentasi. Bagian Swift tidak berubah sejak run Apple yang ditautkan. UI Flutter iPhone terbaru diuji pada run `1fce1d5`.

### Temuan dan perbaikan

Cleanup Android awalnya meninggalkan notifikasi koneksi meski layanan telah berhenti. Pembaruan foreground yang masih mengantre dapat memunculkan notifikasi itu lagi. Penghentian sekarang melepas keterikatan foreground sebelum membatalkan notifikasi; tes cleanup lokal dan API 29/30/35/36 kembali lulus.

Sheet kode pasangan kini menyesuaikan ruang keyboard sehingga tombol Hubungkan tetap dapat dijangkau. Penyambungan ulang ke pasangan yang sama mempertahankan bukti persetujuan dan cursor. Undangan yang memakai kunci publik sendiri ditolak meskipun dikemas ulang. Tidak ada kode pasangan privat atau kelas probe QA dalam APK release.

Percobaan QA UI native arsip dengan font sistem besar mengalami kegagalan pemulihan Activity pada API 35. Hasil tersebut tidak dipakai sebagai bukti UI APK Flutter. Pemeriksaan font sistem besar sekarang ditujukan pada widget native yang memang dibundel; UI aplikasi yang digunakan diuji lewat Flutter dengan teks 200%. Semua job pada run terakhir di atas lulus.

## Batas pengujian

QA menggunakan emulator/simulator, belum seluruh merek Android, launcher, atau perangkat page-size 16 KB fisik. Belum mengukur persentase konsumsi baterai maupun suara secara akustik pada HP fisik. Berhentinya frame membuktikan penghentian animasi, bukan angka penghematan keseluruhan. Koneksi foreground Android tetap bergantung pada jaringan, Doze dan kebijakan baterai HP.

Widget iPhone dibangun tetapi belum diuji pada layar utama iPhone fisik. WidgetKit mengatur timeline dan transisi pembaruan, tanpa loop animasi berkelanjutan. Instalasi iPhone fisik memerlukan signing/provisioning/TestFlight; notifikasi saat tertutup memerlukan deployment APNs. Keberhasilan simulator bukan bukti pengiriman APNs fisik.

Seirama tidak otomatis mencabut akses pemilik kode satu arah lama: ganti kode jika ingin mencabutnya. Penghentian hubungan diterima pasangan setelah paket bertanda tangan terkirim. Penghapusan lokal/uninstall tidak menghapus salinan pada HP pasangan atau riwayat yang sudah diterima relay. [Rincian mode dan cleanup](crossplatform/SEIRAMA.md).

GPS diambil sekali setelah pilihan dan persetujuan pemilik HP, tanpa pelacakan latar belakang. Sistem tidak mengizinkan aplikasi menyalakan GPS diam-diam; nama kota bergantung layanan geocoder. QA ini bukan audit keamanan independen atau pengesahan Play Protect. Sertifikat APK masih kunci pengembangan.

---

Laporan berikut merupakan arsip versi sebelumnya; ukuran, hash dan hasilnya berlaku untuk versi yang disebutkan.


# Arsip QA — abc 0.7.0

Tanggal: **3 Oktober 2026**. Fokus: animasi per tindakan/tema/fase hari, widget, nada notifikasi, lokasi dengan nama dan kategori makan sesuai jam lokal. [Pratinjau dan video release](TAMPILAN.md).

## APK yang dibagikan

- Paket `id.kabar.app`, versionName **0.7.0**, versionCode **7**, minimum Android **10/API 29**, target/compile **36**. APK universal ARM32, ARM64 dan x86_64.
- Ukuran **51.060.606 byte**; SHA-256 `39f21fcc11068a3f06a0ba7fd2eac51f275de5cec44f36b6ae40949743ade50f`.
- Signature v2 diverifikasi. Sertifikat SHA-256 `ae0b8561a0364415fb9c13292fbae8903fe55e97714a4595f2cf0249323d3065`, sama dengan rilis sebelumnya; update mempertahankan pasangan/data pada kedua emulator.
- Alignment ZIP 16 KB serta segmen LOAD keenam library ELF diverifikasi. Tidak ditemukan fixture kode pasangan release, `PAIRING_CODE`, `DeviceQA` atau `QaProbe` dalam lokasi binary yang diperiksa. Paket sumber mengecualikan SDK/build/cache/fixture pasangan/kredensial/kunci pribadi.

## Hasil aktual

| Pemeriksaan | Hasil |
|---|---|
| Flutter analyze | Lulus tanpa issue |
| Flutter unit/widget | **23 kasus lulus**; 24 kombinasi tindakan × tema × fase menghasilkan gambar berbeda, frame bergerak mengubah piksel; lifecycle, visibility, Reduce Motion/hemat daya, format waktu dua arah, Detail terbuka, tiga bahasa dan teks 200% |
| Domain Java | **120 assertions lulus**, termasuk kategori makan mengikuti jam sebenarnya, lokasi bernama dan paket terenkripsi ≤4.096 byte dengan label multibyte maksimal |
| Apple core | **8 kasus Swift lulus**, interoperabilitas Java/CryptoKit dua arah, build aplikasi/widget/ekstensi dan UI native simulator lulus |
| Server APNs | **7 kasus lulus**, termasuk validasi otorisasi/tanda tangan, batas payload dan nama suara `abc_chime.wav` |
| Integrasi Flutter Android/iPhone | **Lulus API 29/30/35/36 dan simulator iPhone**: seluruh alur selesai, marker native terverifikasi dan sembilan screenshot wajib per perangkat; preferensi, bahasa/tema/format, detail dan cleanup |
| Komponen/UI native Android arsip | **Lulus API 29–36**, termasuk font 1,5× pada API 35. UI MainActivity arsip tidak masuk APK Flutter |
| Dua APK release | Lulus pada APK akhir setelah perbaikan resource: pengirim Asia/Jakarta dan penerima Europe/Berlin; kabar terenkripsi tersinkron, notifikasi diterima saat penerima di latar belakang |
| Widget Android release | Lulus: tiga sampel frame berbeda ketika aktif, satu frame statis pada Battery Saver, dua frame berbeda setelah Battery Saver dimatikan. Proporsi portrait dan tombol/info diperiksa pada launcher emulator |
| Suara/notifikasi | WAV mono PCM 22.050 Hz, 1,08 detik, dibundel Android/iPhone; Android memeriksa channel `updates_pixel_v1`, resource URI nama stabil, format waktu normal/diperluas dan pembaruan senyap. Pada APK release akhir, lookup URI resource berhasil, durasi 1.080 ms dan callback pemutaran selesai diverifikasi melalui fixture terpisah pada emulator penerima. Playback akustik pada HP fisik belum diukur |
| Guard APK release | Build release teroptimasi di CI lulus; file nada identik dengan WAV sumber dan kelas debug tidak dibundel. Uji negatif memastikan APK tanpa nada ditolak |
| Persetujuan GPS | Membatalkan aktivasi tidak mengubah revisi. Setelah pengaturan lokasi diaktifkan dan kembali ke aplikasi, sampel baru tertangkap dan tersinkron |
| Detail dan peta | Sampel simulasi Yogyakarta `-7.7956, 110.3695`, akurasi 5 m; detail tidak menampilkan angka koordinat, intent peta memakai titik yang sama. Geocoder emulator tidak tersedia: fallback kota belum diketahui tampil tanpa mengarang nama |
| Makan berdasarkan waktu | Tes domain memverifikasi Sarapan pada 18.00 masuk Makan malam untuk jadwal 17.00–22.00. Uji GUI release pada 22.34 masuk Makan karena di luar seluruh rentang awal; konfirmasi menjelaskan kategori otomatis |
| Retensi/paket | Data lokasi bernama tetap di bawah batas relay dengan mengurangi GPS riwayat lama lalu kejadian tertua; titik terbaru dan waktu makan independen dipertahankan |
| Cleanup native | CI memeriksa file/cache/database/preferensi, kode/kunci, antrean/riwayat dan notifikasi; item Keychain fixture dengan service lain tetap ada. Penghapusan dibatasi data abc |
| Pemeriksaan visual | Beranda, konfirmasi, lokasi/Detail/peta, notifikasi, widget kedua tema dan screenshot iPhone diperiksa; video 30 detik merekam tiga tindakan dari APK release |

### Bukti CI

- [Flutter Android 10/11/15/16 dan iPhone — seluruh job lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37132886142), sumber `f0eca53`.
- [Komponen Android API 29–36 — seluruh job lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37133402259), sumber `99dcd98`.
- [Apple core/native/widget/ekstensi — lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37131749866), sumber `5c2c3ac`.
- [Server notifikasi Apple — lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37131749865), sumber `5c2c3ac`.
- [Build dan guard paket release — lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37134844124), sumber `2cfee63`.

Kode aplikasi release memuat fitur pada `5c2c3ac` dan koreksi ukuran portrait widget pada `706a58b`. Commit sesudahnya memperbaiki penguji/driver dan dokumentasi; tidak mengubah perilaku aplikasi release. Angka kasus yang tumpang tindih tidak dijumlahkan sebagai kasus unik.

Pemeriksaan paket akhir menemukan nada dipangkas pada build release karena hanya dipanggil melalui nama URI. Resource kini dipertahankan dengan aturan tools:keep sesuai [panduan Android](https://developer.android.com/topic/performance/app-optimization/customize-which-resources-to-keep). Guard release membandingkan bytes WAV asli, durasi/format serta daftar kelas debug. APK dibangun ulang dan nada benar-benar diputar dari resource APK tersebut.

### Perbaikan keandalan QA

Percobaan awal menemukan registrasi tes yang menunggu pekerjaan asinkron sebelum `testWidgets`, sehingga runner bisa berstatus berhasil tanpa menjalankan alur UI. Klaim awal dikoreksi. Registrasi kini sinkron, pemanasan accessibility ada di `setUpAll`, dan driver **menolak hasil tanpa marker penyelesaian native serta sembilan screenshot wajib**. Run awal `37131749814` tidak digunakan sebagai bukti integrasi. Run Flutter yang ditautkan di atas menjalankan tiga tes dan menampilkan **QA PASS** serta **All tests passed**.

Penguji waktu juga memisahkan teks notifikasi dari metadata channel suara; penguji GPS menunggu sampel siap dan render UI selesai. Tes zona waktu menunggu tampilan UTC sebelum mengganti ke Tokyo agar perubahan benar-benar diperiksa.

## Batas pengujian

Belum mengukur persentase konsumsi baterai, playback suara pada HP fisik, seluruh merek/launcher, atau perangkat page-size 16 KB nyata. Android penerima tetap menggunakan koneksi/foreground service; jaringan, Doze dan pengaturan baterai merek HP dapat menunda kabar. Pemeriksaan frame membuktikan animasi berhenti, bukan angka penghematan daya keseluruhan.

Widget iPhone dibangun tetapi belum diperiksa pada layar utama iPhone fisik; WidgetKit memakai transisi pembaruan data, bukan loop berkelanjutan. iPhone fisik tetap memerlukan signing/provisioning/TestFlight serta deployment APNs. Build/simulator bukan bukti pengiriman APNs fisik.

GPS diambil sekali setelah persetujuan; sistem tidak mengizinkan abc mengaktifkannya diam-diam. Nama kota tergantung layanan geocoder; peta tetap memakai titik tepat ketika nama tidak tersedia. Pengujian GPS simulasi bukan pengukuran akurasi perangkat nyata.

QA ini bukan audit keamanan independen atau pengesahan Play Protect. Sertifikat APK masih kunci pengembangan. Mute channel lama dipertahankan; pilihan suara non-null pengguna pada Android 11 ke atas dipertahankan melalui informasi sistem. Pada Android 10, migrasi channel tidak dapat membedakan pilihan suara tersebut dengan mekanisme yang digunakan; pengguna dapat mengatur suara kembali dari pengaturan notifikasi HP.

---

Arsip berikut merekam laporan versi terdahulu sebelum driver diberi penjagaan hasil kosong. Hasil integrasi terdahulu tidak dipakai sebagai bukti QA versi 0.7; bukti yang digunakan adalah run lengkap di atas.

# Arsip QA — abc 0.6.0

Tanggal: **3 Oktober 2026**. Fokus: animasi pixel yang mengikuti kondisi baterai/lifecycle, format waktu konsisten, dan pembersihan hanya data abc lokal sebelum uninstall.

## APK

- `id.kabar.app`, versionName **0.6.0**, versionCode **6**; minimum Android **10/API 29**, target/compile **36**; ARM32, ARM64, x86_64.
- **51,709,434 byte**, SHA-256 `66462a66c97347d6b53bd5aa618e58d919710f6a5a96c2dd998559ce9107b476`.
- Signature v2 dan sertifikat sama dengan rilis sebelumnya; pembaruan APK pada pasangan emulator berhasil. Alignment ZIP 16 KB dan keenam library ELF diverifikasi.
- APK release memakai `main.dart`, tanpa fixture kode pasangan, `PAIRING_CODE`, kelas debug QaProbe, atau marker file QA. Paket sumber mengecualikan SDK/build/cache/kredensial/kunci pribadi.

## Hasil

| Pemeriksaan | Hasil |
|---|---|
| Analisis Flutter | Lulus, tanpa issue |
| Flutter unit/widget | **21 test case lulus**: event tanpa polling idle, burst digabung, lifecycle/dispose, empat frame per detik, viewport/dialog/Reduce Motion/TickerMode/hemat daya, preferensi animasi, format dua arah termasuk Detail terbuka, konfirmasi hapus/batal, serta fungsi UI sebelumnya dan tiga bahasa/teks 200% |
| Domain Java lokal | **111 assertions lulus**; penghapusan anak direktori abc tidak menghapus sentinel direktori lain. CI Linux juga menguji symbolic link tanpa mengikuti tujuannya |
| Integrasi native Android 11 | Lulus: pasangan, konfirmasi status, makan, riwayat, preferensi/persistensi, format widget dan pembaruan notifikasi tanpa alert ulang |
| Dua emulator terenkripsi | Lulus: pengirim Asia/Jakarta, penerima Europe/Berlin, English/AM-PM; perubahan diterima melalui EventChannel tanpa refresh manual tiap detik |
| APK release dua perangkat | Lulus: klik status memperbarui penerima aktif, notifikasi diterima ketika penerima di latar belakang, format 24/AM-PM di status/Detail termasuk UTC |
| Animasi APK release dan sistem hemat daya | Lulus: piksel bergerak saat aktif, berhenti pada Battery Saver Android, bergerak lagi setelah dimatikan. Thread pengirim mencatat **0 tick CPU selama sampel idle 5 detik**; ini bukan pengukuran konsumsi baterai keseluruhan |
| Hapus data native | Lulus pada emulator khusus uji: file/cache/no-backup/Flutter, database beserta journal, preferensi tambahan, kode/kunci, riwayat/antrean, notifikasi bersih |
| Tombol hapus di APK release | Lulus: batal pada konfirmasi awal mempertahankan data; lanjut membersihkan data sebelum dialog sistem. Batal pada dialog sistem meninggalkan aplikasi kosong. Sentinel di Download serta salinan di pengirim tetap ada |
| Uninstall dan instal ulang Android | Lulus melalui pengelola paket OS pada emulator uji; instal ulang menampilkan input panggilan kosong, sentinel Download tetap ada |
| CI Flutter Android 10/11/15/16 | **Lulus API 29/30/35/36**, mencakup snapshot tanpa feedback loop, seluruh UI/persistensi, format widget/notifikasi jika izin tersedia, dan cleanup fixture |
| CI Flutter iPhone | **Lulus**, UI/persistensi/format/tema/bahasa, snapshot tanpa feedback loop, cleanup file/preferensi/kode/kunci/riwayat/antrean; item Keychain fixture dari service lain tetap ada |
| Apple core/native/widget/ekstensi | **Lulus**, termasuk enam kasus Swift dan interoperabilitas Java/CryptoKit |
| Komponen/UI native Android arsip | **Lulus API 29–36**, termasuk teks 1,5× pada API 35; posisi gulir dipertahankan ketika render lama saling menyusul. MainActivity arsip tidak masuk APK Flutter |

[Flutter Android — empat job lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37096450226), [Flutter iPhone — lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37098673868), [Apple core/native](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37095357870), [Android native arsip](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37097127174).

APK dan CI Android bersumber dari `fa13d76`; QA iPhone bersumber dari `6d0a208`, dengan tambahan diagnostik debug, koneksi VM langsung untuk CI, dan reset URLCache sebelum menghapus file cache. Antarmuka Dart sama. Perubahan UI native arsip (MainActivity) tidak dimasukkan ke abc Flutter. Angka kasus yang tumpang tindih tidak dijumlahkan. Screenshot dan penanda menggunakan perangkat serta data khusus uji.

Percobaan iPhone awal berhasil build tetapi Flutter tidak menemukan alamat VM dari log. Menentukan port loopback khusus simulator dan menghubungkan driver langsung menghasilkan **All tests passed** dan sembilan screenshot. Ini perbaikan alat QA, bukan perubahan jaringan aplikasi release. Log URLCache menyebut database yang sudah dihapus ketika proses cache asinkron menyusul cleanup; semua assertion pembersihan tetap lulus. Notifikasi APNs fisik belum diuji.

## Perbaikan yang diverifikasi

Polling UI lima detik dan wakeup pengirim 1,5 detik diganti pemberitahuan perubahan dan penantian antrean. Jam hanya memperbarui saat aktif pada batas menit. Snapshot iOS tidak lagi mengubah properti Published, untuk menghindari pembaruan yang saling memicu. Animasi hanya me-repaint canvas kecil empat kali/detik, berhenti jika tidak terlihat/inaktif, Reduce Motion atau hemat daya aktif, dan dapat dimatikan.

Format jam tetap per HP dan tidak mengubah timestamp/UTC kejadian. Rentang jadwal pada beranda, status, makan, riwayat, Detail UTC/GPS, widget dan notifikasi mengikuti pilihan yang sama. Metadata notifikasi Android disalin khusus field abc agar tidak menimpa teks baru dengan extras sistem lama; penguji menunggu pemrosesan NotificationManager yang asinkron.

Cleanup dibatasi direktori milik abc serta akun Keychain/App Group abc. Penghapusan database juga menghapus journal/WAL; entri yang sudah terhapus bukan kegagalan. Pengirim/penerima yang sedang berhenti tidak boleh menulis ulang data pribadi/notifikasi setelah cleanup. Membatalkan uninstall sistem setelah cleanup tidak memulihkan data. Download/foto/file di luar abc, aplikasi lain, dan salinan di HP lain tidak ikut dihapus.

## Batas pengujian

Belum mengukur persentase konsumsi baterai, menjalankan uji jangka panjang pada HP fisik, atau memverifikasi seluruh merek/launcher dan perangkat 16 KB nyata. Sampel CPU singkat bukan bukti angka penghematan baterai. Penerima Android masih memakai foreground service/koneksi jaringan; kualitas jaringan dan aturan baterai HP berpengaruh.

iPhone fisik tetap memerlukan signing/provisioning/TestFlight dan deployment APNs. Build/simulator bukan installer iPhone atau bukti notifikasi APNs fisik. QA ini bukan audit keamanan independen atau pengesahan Play Protect.

---

# Arsip QA — abc 0.5.0

Tanggal: **3 Oktober 2026**. Antarmuka aktif sekarang **Flutter**, dengan integrasi native Android/Apple untuk enkripsi, GPS, notifikasi dan widget. APK yang dibagikan adalah `abc.apk`.

## APK dan pemeriksaan lokal

- Paket `id.kabar.app`, versi **0.5.0 / 5**, minimum Android **10/API 29**, compile/target **36**. APK universal ARM32, ARM64, x86_64.
- **51.594.718 byte**, SHA-256 `bed0b50eaea70cdae5dd10c6f02ce39ccba3a3fa7cc5e2844fc4984a042102bf`.
- Signature **v2 diverifikasi**; sertifikat sama dengan Kabar 0.1–0.4: `ae0b8561a0364415fb9c13292fbae8903fe55e97714a4595f2cf0249323d3065`.
- Upgrade dari Kabar 0.4 ke abc berhasil pada emulator uji dan snapshot masih membaca pasangan/revisi lama. Upgrade APK debug uji ke release abc juga berhasil pada pengirim/penerima baru; nama, peran, riwayat dan koneksi tetap terbaca.
- `zipalign -c -P 16 4` lulus. Semua segmen LOAD enam library ELF memiliki alignment minimal 16 KB. Ini pemeriksaan binary, bukan uji perangkat fisik dengan page size 16 KB.
- Source ZIP tidak memuat SDK/cache/build, credential, fixture pasangan, atau private signing key. APK release tidak memuat kode pasangan QA, konstanta `PAIRING_CODE`, ataupun instrumentasi DeviceQA.

## Hasil fungsional

| Pemeriksaan | Hasil |
|---|---|
| Pemeriksaan Dart/Flutter | `flutter analyze`: **tanpa masalah** |
| Unit dan widget Flutter | **15 test case lulus**, termasuk tiga bahasa, nama wajib, konfirmasi/batal, makan harian, Detail GPS per kejadian, format jam dan teks 200% pada lebar 360 |
| Domain native Android | **107 assertions lulus**: status, serialisasi, kategori makan, enkripsi/tanda tangan, GPS, zona waktu dan fase langit |
| Integrasi Flutter → native Android 11 | **Lulus** pada emulator baru: membuat pasangan, konfirmasi/batal, makan mempertahankan status tempat tinggal, riwayat, tema/format/bahasa lokal, dan data setelah aplikasi dibuat ulang |
| Detail GPS | **Lulus** dengan sampel LocationManager simulasi `-7.7956, 110.3695`, akurasi 5 m; waktu/koordinat sesuai kejadian. Provider ini hanya fixture emulator, tidak masuk APK |
| Dua perangkat melalui internet | **Lulus**: pengirim Asia/Jakarta dan penerima Europe/Berlin menggunakan relay ntfy terenkripsi; penerima English/AM-PM menampilkan Germany dan tidak dapat melakukan aksi pengirim |
| APK release dan notifikasi | **Lulus**: konfirmasi Keluar pada pengirim memperbarui penerima; NotificationManager mem-post notifikasi update ID 2 ketika aplikasi penerima di latar belakang |
| Pergantian suasana real time | **Lulus pada APK release**: 17.59 → 18.00 WIB mengubah Selamat sore menjadi Selamat malam tanpa membuka ulang. Mode terang pada malam hari tetap terang; langit tetap malam |
| CI Flutter Android | **Lulus Android 10/11/15/16 (API 29/30/35/36)**: analisis, 15 test case dan integrasi native/UI |
| CI komponen Android native dan arsip UI | **Lulus API 29–36**, termasuk ulangan Android 15 pada font 1,5× |
| Apple native/core | **Lulus**: build aplikasi/widget/ekstensi, enam test case Swift, Java/CryptoKit dua arah dan UI native simulator |
| CI UI Flutter iPhone | **Lulus**: build host Flutter + widget/ekstensi dan integrasi pada simulator iPhone; pasangan, konfirmasi/batal, makan, Detail, Indonesia→Deutsch, AM-PM, tema/mode dan preferensi setelah root UI dibuat ulang |

[Workflow Flutter](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37091767248), [komponen Android native](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37092012906), dan [Apple core/interoperability](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37091507011). Pengujian native lama dipisahkan dari antarmuka Flutter aktif; hasilnya tidak menggantikan pengujian Flutter.

Workflow Flutter akhir bersumber pada commit `b39120f`; pembaruan sesudahnya hanya mengubah penguji native lama, dokumentasi, screenshot dan APK. Penguji native lama dahulu menyimpan referensi Activity yang sudah diganti setelah konfigurasi/font berubah; sekarang penguji mengikuti Activity yang benar-benar aktif. Seluruh API 29–36 dan font 1,5× kemudian lulus.

Rangkaian domain yang tumpang tindih tidak dijumlahkan sebagai kasus unik. Screenshot menggunakan nama/status uji. Uji GPS simulasi bukan bukti akurasi GPS di HP fisik. Integrasi Flutter membuat ulang root UI dan membaca ulang snapshot native; uji native tersendiri mencakup restart proses.

Screenshot iPhone beranda, Detail dan pengaturan diperiksa secara visual: teks, safe area, kartu dan navigasi terbaca. Simulator CI memakai GMT/UTC; itu zona pengujian, bukan lokasi pengguna.

Format **24 jam / 12 jam AM-PM**, panggilan, bahasa, Default/In Relationship dan Terang/Gelap disimpan per HP. Tema tidak mengirim status keluarga. Jam riwayat mengikuti pembaca, Detail juga menunjukkan zona/waktu pengirim. Negara mengikuti zona sistem HP, bukan GPS.

GPS diambil sekali setelah persetujuan saat aplikasi aktif. Sampel stale/future ditolak; status tetap dapat dicatat tanpa koordinat saat lokasi tidak tersedia. Riwayat tanpa GPS tidak meminjam titik terakhir. Koordinat lama dapat dibatasi retensinya atau dihapus, dan Detail menjelaskan perbedaan itu.

## Batas versi uji

Belum diuji pada dua HP fisik, semua merek Android/launcher, iPhone/iPad fisik, baterai jangka panjang, atau page size 16 KB pada perangkat nyata. Emulator tidak menjamin seluruh perangkat/OS mendatang. Apple masih memerlukan signing/provisioning, TestFlight dan backend APNs; build simulator bukan installer iPhone.

Ini QA fungsional, bukan audit keamanan independen atau pengesahan Play Protect. APK memakai kunci pengembangan untuk uji pribadi; penyimpanan kunci Android belum dipindahkan ke Android Keystore. Kode pasangan harus tetap rahasia. Jangan mematikan Play Protect untuk mengikuti panduan ini.

---

# Arsip QA — Kabar 0.4.0

Tanggal: **3 Oktober 2026**. Fokus: jam lokal per HP, tema Default/In Relationship, mode terang/gelap terpisah dari suasana waktu; termasuk perbaikan konfirmasi, makan harian dan lokasi opsional dari 0.3.0.

## Artefak

- APK `Kabar-0.4.0.apk`: **70,468 byte**; SHA-256 `f1f375af2b12fa0a8e235e7f3c5b73c0c29e72e331e183c7b18477d4803c4757`.
- `id.kabar.app`, versionCode **4**, minimum Android **10/API 29**, compile/target **35**. Tanda tangan APK v3 diverifikasi. Kunci sama dengan 0.1.0–0.3.0; upgrade lokal diuji tanpa konflik tanda tangan.
- APK akhir dipasang dan diuji pada emulator Android 11/API 30. Penguji terpisah, kunci build, credential, dan fixture rahasia tidak masuk APK/source ZIP.

## Hasil 0.4.0

| Pemeriksaan | Hasil |
|---|---|
| Logika, serialisasi, aturan makan, enkripsi/tanda tangan, GPS, zona waktu dan fase langit | **105 assertions lulus** |
| Rangkaian di atas + publish/subscribe nyata ntfy (terenkripsi, cursor, stream) | **124 assertions lulus** |
| Alur APK Android final: konfirmasi/batal, makan harian, edit label, lokasi, antrean, widget, 4 kombinasi tema/mode, persistensi, zona pembaca | **95 assertions lulus** pada emulator dengan izin lokasi telah diberikan |
| Sore → malam saat layar tetap terbuka, melalui perubahan jam pada emulator | **Lulus**; 17.59 → 18.00 WIB, sapaan dan pixel sky berubah tanpa membuka ulang |
| Mode terang pada malam hari | **Lulus**; kartu tetap terang, langit malam tetap tampil |
| Apple core + Java/CryptoKit dua arah | **6 test case Swift lulus**, termasuk WIB/WITA/WIT, DST, beda tanggal, titik GPS dan kategori makan manual |
| Apple aplikasi/widget/ekstensi dan UI simulator iPhone | **Lulus**; konfirmasi, edit tombol, tema relationship, mode gelap/terang dan persistensi setelah restart |
| Android 10–16 dan Android 15 font 1,5× | Lulus pada versi 0.4.0 |

[QA Apple 0.4.0](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37083913533).

[QA Android 0.4.0](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37084069528).

Angka logika/live tidak dijumlahkan karena sebagian besar kasusnya sama. Rangkaian UI awal dengan izin lokasi belum diberikan mencakup dua assertion tambahan. Pengujian server tidak diulang karena sumber server tidak berubah.

## Kasus penting

- Label `12.00 WIB - Indonesia`, WITA/WIT, Jepang, alias Amerika, negara dengan aturan jam yang sama tetap berbeda, serta offset tetap yang tidak ditebak negaranya. Tabel IANA memetakan 549 identifier/alias; aturan jam dan DST berasal dari OS.
- WIB → New York dapat mengubah tanggal tampilan menjadi kemarin, tanpa mengubah timestamp, revisi, kode pasangan, atau tanggal kategori makan pengirim.
- Batas 05.00/11.00/15.00/18.00 serta 00.00 diuji. Langit mengikuti waktu lokal, pilihan mode disimpan terpisah.
- Mengganti tema tidak mengirim status keluarga. Koneksi, catatan dan kode tetap ada setelah pergantian tema/mode dan Activity dibuat ulang. Warna widget mengikuti mode lokal.
- GPS ditolak/tidak aktif/stale diperiksa; titik uji hanya dari provider emulator, bukan bukti akurasi GPS di HP nyata.
- Screenshot pagi dan malam berasal dari aplikasi berjalan; screenshot malam memakai **jam emulator yang disimulasikan**. Seluruh nama/status merupakan fixture QA. Jam emulator dipulihkan setelah pengujian.

## Temuan yang diperbaiki

- Ilustrasi SwiftUI diberi identitas sesuai tema/mode/fase agar diperbarui setelah perubahan color scheme. Teks pendamping memakai warna dengan kontras lebih jelas.

- Penguji tombol Sarapan dahulu bisa mengambil judul status Sarapan. Pencarian sekarang memilih elemen yang dapat diklik.
- Perubahan jam sistem dahulu membuat timer menunggu batas menit lama. Penerima broadcast kini menjadwalkan ulang refresh menuju menit lokal berikutnya; uji pergantian 17.59 → 18.00 kemudian lulus.
- Penguji zona lokal kini mengubah zona Android yang sebenarnya dan menunggu hasil broadcast. Override zona JVM saja dapat direset oleh perubahan konfigurasi Android (misalnya font besar/recreation), sehingga tidak mewakili pengaturan HP.

## Batas pengujian

Belum ada pengujian dua HP fisik, akurasi GPS lapangan, seluruh merek/launcher, konsumsi baterai jangka panjang, atau seluruh versi iOS. Hasil emulator tidak menjamin semua perangkat atau versi OS mendatang. Widget dan pengiriman latar belakang tetap mengikuti pembatasan sistem.

GPS hanya sekali saat aksi foreground, bukan lokasi live terus-menerus. Label negara/jam mengikuti **zona HP**, bukan hasil geolokasi GPS. Batas pagi/siang/sore/malam adalah pembagian jam, bukan waktu matahari terbit/terbenam astronomis.

Apple masih memerlukan penandatanganan/provisioning, IPA/TestFlight dan backend APNs untuk notifikasi tertutup. Build simulator bukan installer iPhone.

QA fungsional ini bukan audit keamanan independen, pemindaian malware tersertifikasi, atau pengesahan Google Play Protect. APK masih memakai kunci pengembangan untuk uji pribadi; penyimpanan kunci Android belum dipindah ke Android Keystore. Kode pasangan harus tetap rahasia.

## Uji cepat di dua HP

1. Perbarui kedua HP memakai APK 0.4.0; buka pasangan yang sudah tersimpan.
2. Di Pengaturan → Appearance, pilih Relationship/Gelap di A dan Default/Terang di B. Pilihan masing-masing harus bertahan sendiri.
3. Aktifkan zona waktu otomatis di HP. Untuk simulasi, ubah zona B ke Tokyo; jam/negara di B berubah, A tetap lokal, catatan kejadian tetap sama. Kembalikan zona otomatis sesudah tes.
4. Tekan Kost lalu Batal: tidak ada catatan baru. Tekan Kost → Kirim status: B menerima kabar. Coba Makan serta tiap kategori Makan hari ini.
5. Coba Sertakan lokasi HP; uji izin diterima dan ditolak. Kartu harus menjelaskan waktu/akurasi atau belum ada lokasi baru. Jangan menganggap titik lama sebagai posisi saat ini.
6. Amati pergantian suasana pada batas jam dengan mode tetap. Riwayat, widget dan notifikasi harus tetap dapat dibaca dalam mode pilihan.

## Catatan 0.3.0 sebelum pembaruan tema

Android API 29–36 lulus [run 37040875684](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37040875684), Apple lulus [run 37039778312](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37039778312). Android final 0.3.0 juga diuji sebagai pengirim native (**9 assertions**) dan penerima native (**6 assertions**, termasuk notifikasi nyata) terhadap klien Java melalui ntfy; pengirim Java menyertakan titik uji dan zona Asia/Makassar.

---

# Laporan QA — Kabar 0.2.0

Tanggal: **2 Oktober 2026**. Perubahan kompatibilitas Android, aplikasi Apple dan backend Apple diperiksa sebelum penyerahan. Riwayat QA 0.1.0 dipertahankan di bawah sebagai catatan versi sebelumnya.

## APK final 0.2.0

- Paket `id.kabar.app`, versionCode `2`, minimum API `29` (**Android 10**), compile/target API `35`.
- `Kabar-0.2.0.apk`: **45.895 byte**; SHA-256 `38507107899cdd4c9e18565629a77b113ef171a701dc217cf814a7a2b358eaaa`.
- APK final ditandatangani dengan kunci lokal yang sama dengan 0.1.0; verifikasi signature **v3 lulus**. Minimum Android 10 mendukung skema ini. Metadata paket, manifest, permissions, classes.dex dan tidak adanya kelas instrumentasi pada APK produksi diperiksa.
- Tidak ada library native dalam APK. CPU ARM/x86 tidak memerlukan binary terpisah; perubahan alignment library 16 KB tidak berlaku untuk library aplikasi ini.
- Proyek Gradle/Android Studio dibangun terpisah di CI. Sertifikat debug CI berbeda dari APK sideload yang dibagikan.

## Matriks Android

[Workflow Android yang lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37027034586), sumber commit `5f780e7` (perubahan sumber Android terakhir pada rangkaian ini):

| OS | API | UI, edit tombol, persistensi, antrean offline dan widget |
|---|---:|---|
| Android 10 | 29 | Lulus · 33 assertions |
| Android 11 | 30 | Lulus · 33 assertions |
| Android 12 | 31 | Lulus · 33 assertions |
| Android 12L | 32 | Lulus · 33 assertions |
| Android 13 | 33 | Lulus · 33 assertions |
| Android 14 | 34 | Lulus · 33 assertions |
| Android 15 | 35 | Lulus · 33 assertions; diulang pada font scale 1.5 dan lulus |
| Android 16 | 36 | Lulus · 33 assertions |

Emulator x86_64 Google APIs dijalankan di GitHub Actions. Android 13+ diberikan permission POST_NOTIFICATIONS untuk tes; alur menolak permission secara manual dan kebijakan baterai berbagai produsen belum tercakup matriks ini. Tes UI menekan kontrol aplikasi melalui instrumentasi; tes edit field menggunakan UI Automation dan widget diuji sebagai RemoteViews. Angka assertions pada versi OS berbeda adalah pengulangan rangkaian yang sama, bukan kasus unik baru.

QA menemukan race saat layanan dijeda ketika startForegroundService masih menunggu. Penanganan diperbaiki dengan promosi foreground pada callback startup dan pengantrean permintaan STOP yang terikat sesi. Rotasi pasangan memperbarui sesi worker tanpa langsung menghentikan layanan yang sedang mulai. Rangkaian akhir di atas lulus. Salah satu kegagalan tes sebelumnya juga disertai ANR Pixel Launcher emulator; log dan screenshot digunakan untuk membedakannya dari crash Kabar.

## APK sideload dan jaringan nyata

Pada emulator lokal **Android 11/API 30**, APK final yang dibagikan di root benar-benar diinstal dan diuji:

- **81 assertions** aturan domain/crypto dan jaringan nyata: 62 aturan lokal (termasuk empat cek signed alert hint) serta 19 relay/cursor/live stream.
- **33 assertions** UI, perubahan nama/tombol, antrean 25 item, persistensi, scroll dan widget.
- **6 assertions** pengirim native: Kost → Makan → Keluar, antrean terkirim, revisi/waktu benar, server mengakui pengiriman.
- **6 assertions** penerima native: menerima tiga kabar dari klien Java terpisah, mempertahankan waktu makan/tempat tinggal, widget penerima menyembunyikan tombol, serta NotificationManager benar-benar mem-post notification ID 2 saat Activity dipindahkan ke latar belakang.
- Tambahan pemeriksaan independen memastikan ciphertext serta Title notifikasi dari APK diterima ntfy, public hint terikat ciphertext, dan kedua tanda tangan diverifikasi oleh kode Node push bridge. Backend tidak membutuhkan kunci AES untuk verifikasi.
- Screenshot APK final diperiksa pada `screenshots/android-0.2.0.png`; screenshot hasil CI API 36 juga diperiksa. Screenshot CI yang kembali ke launcher setelah instrumentasi tidak dianggap bukti visual layar aplikasi.

## Apple dan server

Aplikasi iPhone/iPad menargetkan **iOS/iPadOS 16+**, dengan SwiftUI, WidgetKit, Keychain/App Group serta Notification Service Extension. Build simulator aplikasi dan dua ekstensi berhasil di Xcode 16.4/SDK iOS 18.5. Tes Swift memiliki empat test case (jam makan, riwayat/status, crypto, interoperability); Java → CryptoKit dan CryptoKit → Java memverifikasi AES-GCM, tanda tangan P-256 DER, topic dan state.

[Workflow Apple akhir yang lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37030986763), sumber commit `4d6f5fd`: build aplikasi/widget/ekstensi, empat tes Swift dan interoperability dua arah, serta **satu tes UI iPhone simulator** (pilih pengirim, jeda koneksi, ketuk Kost/Makan/Keluar, riwayat, ganti Kost menjadi Rumah, lalu terminate/relaunch dan cek data bertahan). Build simulator memakai penandatanganan ad hoc lokal agar Keychain asli dapat berfungsi. Pengujian awal menemukan bahwa build tanpa tanda tangan ditolak oleh Keychain; konfigurasi QA diperbaiki. Waktu/tanggal/checklist Apple diperbarui setiap menit selama UI terbuka.

Screenshot hasil XCUITest diperiksa secara visual: [layar awal](screenshots/apple-welcome.png) dan [riwayat setelah edit tombol](screenshots/apple-history.png). Teks, kartu, safe area dan navigasi terbaca pada simulator iPhone 16 Pro.

[Tes server akhir yang lulus](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37033104126), sumber commit `4ac811d`: **tujuh test case lulus lokal dan CI**, mencakup validasi perangkat/capability, tanda tangan envelope, hint alert/silent, payload APNs 4096 byte, JWT ES256, serta DER valid dengan integer pendek. Vektor DER pendek diverifikasi oleh OpenSSL secara independen; byte tambahan tetap ditolak. Rangkaian ini tidak mengirim ke APNs nyata.

**Batas:** belum ada iPhone/iPad fisik, provisioning Apple, pengiriman APNs nyata, server HTTPS yang dideploy, IPA bertanda tangan, atau TestFlight. Simulator menggunakan Keychain default; akses grup Keychain/App Group antar ekstensi harus diuji pada perangkat fisik bertanda tangan. Widget iOS tidak menjanjikan refresh setiap klik. Mac, Watch dan Apple TV belum ditargetkan.

Hasil simulator Android tidak menjamin semua merek HP atau versi Android masa depan. Doze/OEM, force-stop, reboot, layar terkunci, jaringan berganti, izin notifikasi ditolak dan penggunaan baterai lama tetap perlu pengujian dua HP pengguna. Referensi instalasi ada pada README utama dan `apple/README.md`.

---

# Arsip QA — Kabar 0.1.0

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
