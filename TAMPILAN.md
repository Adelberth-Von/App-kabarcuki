# abc 0.7.0 — pixel art yang mengikuti kabar

[Unduh APK Android 10 ke atas](https://raw.githubusercontent.com/Adelberth-Von/App-kabarcuki/refs/heads/main/abc.apk?v=0.7.0) · [Panduan](README.md) · [Hasil QA](QA.md)

Gambar Android berasal dari APK release yang berjalan pada dua emulator khusus uji. Nama, jam dan titik GPS merupakan data simulasi; tidak menunjukkan lokasi pengguna nyata. Gambar iPhone berasal dari rangkaian QA simulator yang lulus.

## Lihat gerakannya

[Putar rekaman 30 detik dari APK release](screenshots/abc07-motion.mp4): Keluar berjalan membawa tas, Kost beristirahat/membaca, dan Makan memakai mangkuk, sendok serta uap. Tema hubungan kini bernama **Seirama**: pasangan melambaikan tangan, menyambut pulang atau makan bersama. Konfirmasi juga menampilkan adegan tindakan yang dipilih.

| Beranda Seirama, malam | Konfirmasi tindakan |
|---|---|
| <img src="screenshots/abc07-home.png" width="280" alt="Beranda abc 0.7 dengan adegan makan Seirama pada malam hari"> | <img src="screenshots/abc07-confirm.png" width="280" alt="Konfirmasi Keluar dengan adegan pixel dan pilihan lokasi"> |

## Widget yang lebih jelas

Nama, fase hari, status dan waktunya dipisahkan agar mudah dibaca. Ilustrasi menjaga proporsi karakter, lalu informasi makan, kost dan kota tampil di bawahnya. Tombol berikon membuka konfirmasi di aplikasi. Ukuran kecil merangkum informasi; ukuran besar menampilkan lebih banyak detail.

| Widget Seirama | Widget Default |
|---|---|
| <img src="screenshots/abc07-widget.png" width="280" alt="Widget Seirama dengan dua karakter, status, waktu dan tiga tombol berikon"> | <img src="screenshots/abc07-widget-default.png" width="280" alt="Widget Default dengan satu karakter dan informasi kabar"> |

Android menggunakan dua frame ringan setiap 1,5 detik saat widget terlihat. Animasi berhenti pada hemat daya, pengurangan animasi atau saat sakelar Animasi pixel dimatikan. Widget iPhone menggunakan transisi saat data diperbarui, mengikuti batas WidgetKit. Widget Android mengikuti fase waktu pembaca melalui pembaruan sistem berkala; perubahan fase tidak selalu seketika di layar utama.

## Notifikasi dan suara khusus

Notifikasi Android menampilkan ilustrasi pixel, tindakan, waktu lokal, kota jika tersedia dan tombol **Lihat kabar**. Nada asli **abc pixel chime** terdiri dari tiga nada pendek dengan durasi 1,08 detik. Dengarkan [contoh suara](res/raw/abc_chime.wav). Suara mengikuti volume notifikasi, mode senyap, Jangan Ganggu dan pilihan pada pengaturan notifikasi HP. Pembaruan format jam tidak membunyikan ulang notifikasi.

<img src="screenshots/abc07-notification.png" width="280" alt="Notifikasi abc diperluas dengan ilustrasi pixel, waktu dan tombol Lihat kabar">

Nada yang sama sudah dibundel pada proyek iPhone. Instalasi pada iPhone fisik dan notifikasi APNs masih memerlukan signing Apple/TestFlight serta deployment server.

## Pagi, siang, sore dan malam

Burung pada pagi hari, kupu-kupu pada siang hari, daun pada sore hari, serta bintang/kunang-kunang pada malam hari mengikuti jam lokal HP. Mode **Terang/Gelap** tetap merupakan pilihan terpisah. Contoh berikut adalah frame yang dirender oleh tes canvas aplikasi, bukan mockup.

| Tema dan tindakan | Pagi · 08.00 | Siang · 12.00 | Sore · 16.00 | Malam · 20.00 |
|---|---|---|---|---|
| Default · Keluar | <img src="screenshots/abc07-scene-default-outside-8-motion.png" width="144" alt="Default Keluar pukul 8.00"> | <img src="screenshots/abc07-scene-default-outside-12-motion.png" width="144" alt="Default Keluar pukul 12.00"> | <img src="screenshots/abc07-scene-default-outside-16-motion.png" width="144" alt="Default Keluar pukul 16.00"> | <img src="screenshots/abc07-scene-default-outside-20-motion.png" width="144" alt="Default Keluar pukul 20.00"> |
| Default · Kost | <img src="screenshots/abc07-scene-default-home-8-motion.png" width="144" alt="Default Kost pukul 8.00"> | <img src="screenshots/abc07-scene-default-home-12-motion.png" width="144" alt="Default Kost pukul 12.00"> | <img src="screenshots/abc07-scene-default-home-16-motion.png" width="144" alt="Default Kost pukul 16.00"> | <img src="screenshots/abc07-scene-default-home-20-motion.png" width="144" alt="Default Kost pukul 20.00"> |
| Default · Makan | <img src="screenshots/abc07-scene-default-meal-8-motion.png" width="144" alt="Default Makan pukul 8.00"> | <img src="screenshots/abc07-scene-default-meal-12-motion.png" width="144" alt="Default Makan pukul 12.00"> | <img src="screenshots/abc07-scene-default-meal-16-motion.png" width="144" alt="Default Makan pukul 16.00"> | <img src="screenshots/abc07-scene-default-meal-20-motion.png" width="144" alt="Default Makan pukul 20.00"> |
| Seirama · Keluar | <img src="screenshots/abc07-scene-seirama-outside-8-motion.png" width="144" alt="Seirama Keluar pukul 8.00"> | <img src="screenshots/abc07-scene-seirama-outside-12-motion.png" width="144" alt="Seirama Keluar pukul 12.00"> | <img src="screenshots/abc07-scene-seirama-outside-16-motion.png" width="144" alt="Seirama Keluar pukul 16.00"> | <img src="screenshots/abc07-scene-seirama-outside-20-motion.png" width="144" alt="Seirama Keluar pukul 20.00"> |
| Seirama · Kost | <img src="screenshots/abc07-scene-seirama-home-8-motion.png" width="144" alt="Seirama Kost pukul 8.00"> | <img src="screenshots/abc07-scene-seirama-home-12-motion.png" width="144" alt="Seirama Kost pukul 12.00"> | <img src="screenshots/abc07-scene-seirama-home-16-motion.png" width="144" alt="Seirama Kost pukul 16.00"> | <img src="screenshots/abc07-scene-seirama-home-20-motion.png" width="144" alt="Seirama Kost pukul 20.00"> |
| Seirama · Makan | <img src="screenshots/abc07-scene-seirama-meal-8-motion.png" width="144" alt="Seirama Makan pukul 8.00"> | <img src="screenshots/abc07-scene-seirama-meal-12-motion.png" width="144" alt="Seirama Makan pukul 12.00"> | <img src="screenshots/abc07-scene-seirama-meal-16-motion.png" width="144" alt="Seirama Makan pukul 16.00"> | <img src="screenshots/abc07-scene-seirama-meal-20-motion.png" width="144" alt="Seirama Makan pukul 20.00"> |

Animasi di aplikasi memakai empat frame per detik pada canvas kecil, berhenti ketika tidak terlihat atau aplikasi tidak aktif. Format 24 jam/AM-PM berlaku serentak pada status, rentang makan, riwayat, Detail, widget dan notifikasi. Setiap HP tetap memakai zona serta preferensinya sendiri.

## Lokasi dan kategori makan

| Detail lokasi | Aktivasi lokasi | Kategori mengikuti jam |
|---|---|---|
| <img src="screenshots/abc07-detail-location.png" width="250" alt="Detail lokasi berisi daerah, kota, waktu, zona dan tombol peta tanpa angka koordinat"> | <img src="screenshots/abc07-location-enable.png" width="250" alt="Konfirmasi membuka pengaturan sistem untuk mengaktifkan layanan lokasi"> | <img src="screenshots/abc07-meal-routing.png" width="250" alt="Konfirmasi kategori makan otomatis saat Sarapan diketuk di luar rentang jadwal"> |

Lokasi menampilkan daerah, kota, waktu pengambilan dan zona waktu; **Lihat di peta** tetap memakai koordinat tepat. Pada emulator, layanan pencarian nama tidak tersedia sehingga contoh menampilkan keterangan belum diketahui. GPS diambil sekali setelah persetujuan. Jika layanan lokasi mati, pengguna diarahkan ke pengaturan sistem lalu pengambilan dilanjutkan setelah kembali.

Jika Sarapan diketuk pukul 18.00 dan jadwal makan malam 17.00–22.00, kategori yang dicatat adalah **Makan malam**. Contoh screenshot pukul 22.34 berada di luar jadwal awal, sehingga dicatat sebagai **Makan** tanpa mencentang kategori lain. Kategori ditentukan dari jam lokal pengirim ketika catatan disimpan.

## Tampilan iPhone

| Seirama pada iPhone | Pengaturan iPhone |
|---|---|
| <img src="screenshots/abc07-iphone-seirama-home.png" width="280" alt="Seirama pada simulator iPhone dengan jam AM-PM"> | <img src="screenshots/abc07-iphone-settings.png" width="280" alt="Pengaturan bahasa, waktu, tema dan animasi pada iPhone"> |

Seluruh alur integrasi selesai dan menghasilkan sembilan screenshot pada [QA Flutter Android/iPhone](https://github.com/Adelberth-Von/App-kabarcuki/actions/runs/37132886142). CI iPhone menggunakan GMT/UTC; zona tersebut adalah pengaturan simulator, bukan lokasi pengguna.

## Ikon aplikasi

<img src="screenshots/abc-icon.png" width="128" alt="Ikon abc berupa gelembung pesan pixel ungu">

Bahasa tersedia dalam Indonesia, English dan Deutsch. Panggilan dipilih sebelum masuk, kemudian dipakai untuk sapaan pada HP tersebut.
