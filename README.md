# abc 0.5.0 — kabar kecil, bikin tenang

Antarmuka **Flutter** yang sama dipakai untuk Android dan iPhone. Desain baru memakai kartu yang ringkas, ikon pixel, tiga tombol status di bagian atas, serta tema Default dan In Relationship. Sinkronisasi, enkripsi, lokasi, notifikasi, dan widget menggunakan kemampuan native masing-masing perangkat.

**Unduh Android:** [abc.apk](https://raw.githubusercontent.com/Adelberth-Von/App-kabarcuki/refs/heads/main/abc.apk). Minimal Android 10. APK lama Kabar disimpan sebagai arsip. **APK tidak dapat dipasang di iPhone**; proyek iOS tersedia, tetapi instalasi pada iPhone fisik memerlukan penandatanganan Apple/TestFlight. Lihat [QA](QA.md) dan [pratinjau](TAMPILAN.md).

## Cara mencoba di dua HP Android

1. Buka tautan **abc.apk** di atas melalui browser HP dan unduh file tersebut.
2. Buka folder Download, ketuk **abc.apk**, lalu pilih **Install/Update**. Jika diminta, izinkan pemasangan dari browser atau pengelola file yang digunakan. Pertahankan Play Protect aktif; peringatan pengembang belum dikenal tidak berarti aplikasi sudah dinyatakan aman oleh Google.
3. Buka **abc** dan masukkan panggilan, misalnya **Cuki**. Sapaan pada HP itu akan menjadi **Hai, Cuki**. Pada pembaruan dari Kabar, pasangan dan riwayat tetap dipertahankan.
4. Pada HP pengirim baru, pilih **Aku membagikan kabar**. Buka **Pengaturan → Kode pasangan**, salin seluruh kode, lalu kirim secara pribadi ke HP kedua.
5. Pada HP kedua, masukkan panggilan pemilik HP itu dan pilih **Aku menerima kabar**. Tempel kode lengkap lalu tekan **Hubungkan**.
6. Pada pengirim, ketuk **Kost**, periksa konfirmasi, lalu **Kirim kabar**. Coba juga **Keluar** dan **Makan**. Kedua HP memerlukan internet, tetapi boleh menggunakan jaringan berbeda.
7. Buka **Pengaturan → Pengaturan notifikasi** pada masing-masing HP. Aktifkan notifikasi abc. Untuk mencoba latar belakang, cek pengaturan baterai aplikasi sesuai merek HP.
8. Buka **Pengaturan → Tambahkan widget** atau tahan area kosong layar utama → Widget → abc. Tombol pada widget pengirim membuka aplikasi untuk meminta konfirmasi.

APK ini memakai identitas `id.kabar.app` dan kunci pengembangan yang sama dengan Kabar 0.1–0.4. Pembaruan tidak perlu uninstall. Build sendiri dengan kunci debug berbeda tidak dapat menggantikan APK ini. Kunci pribadi build tidak disertakan dalam repositori/paket sumber.

## Panggilan, bahasa, jam dan appearance

Di **Pengaturan**, setiap HP dapat memilih **Indonesia, English, atau Deutsch**. Panggilan, bahasa, format jam, tema, dan mode warna adalah pengaturan lokal; tidak dikirim ke HP keluarga. Label buatan pengguna tetap ditampilkan sesuai tulisan aslinya.

**Format waktu** menyediakan **24 jam** (`12.00 WIB - Indonesia`) dan **12 jam AM/PM** (`12.00 PM WIB - Indonesia`). Jam pada beranda/riwayat mengikuti zona waktu sistem HP pembaca. Detail juga menunjukkan waktu di zona pengirim, identifier zona, serta waktu kejadian UTC. Jam musim panas dihitung untuk tanggal masing-masing kejadian. Nama negara menjelaskan zona waktu, bukan bukti lokasi GPS. Aktifkan zona waktu otomatis di pengaturan HP ketika bepergian.

Pilih tema **Default** (krem/periwinkle, satu karakter) atau **In Relationship** (rose/lilac, dua karakter dengan hati), lalu **Terang** atau **Gelap**. Ilustrasi dan sapaan mengikuti pagi 05.00–10.59, siang 11.00–14.59, sore 15.00–17.59, dan malam 18.00–04.59. Suasana diperbarui setiap menit saat aplikasi aktif. Mode warna tetap mengikuti pilihan Anda; mode terang pada malam hari menampilkan langit malam dengan kartu terang.

## Tombol, makan hari ini dan riwayat

- **Keluar:** memperbarui status di luar. Waktu terakhir di kost dan makan tetap tersimpan.
- **Kost:** memperbarui status tempat tinggal dan waktu terakhir berada di sana.
- **Makan:** mencatat waktu makan tanpa mengubah status tempat tinggal. Kategori dapat otomatis atau dipilih manual.
- **Sarapan / Makan siang / Makan malam** di kartu Makan hari ini dapat diketuk. Pengirim mendapat konfirmasi sebelum catatan dikirim; penerima dapat membuka detail catatan yang masih tersedia.
- **Edit nama & tombol** serta **Jadwal makan** meminta konfirmasi sebelum mengirim perubahan ke penerima. Label awal Keluar/Kost/Makan dapat diganti, misalnya Pergi/Rumah/Sudah makan.

Jadwal awal: sarapan 05.00–10.00, siang 10.00–15.00, malam 17.00–22.00; di luar rentang dicatat sebagai Makan. Batas awal termasuk dan batas akhir tidak termasuk. Rentang harus berurutan tanpa tumpang tindih. Makan hari ini mengikuti tanggal/zona pengirim agar tidak bergeser ketika keluarga berada di negara berbeda. **Belum tercatat** berarti belum ada catatan, bukan kesimpulan bahwa orang itu belum makan.

**Riwayat → Detail** menampilkan status, waktu lokal pembaca, waktu pengirim, zona, serta koordinat, akurasi, waktu pengambilan dan tombol peta jika lokasi disertakan pada kejadian itu. Catatan tanpa GPS tidak meminjam koordinat dari kejadian lain. Terdapat 12 kejadian terbaru; waktu sarapan/siang/malam tetap tersimpan terpisah.

## Lokasi opsional dan privasi

Aktifkan **Sertakan lokasi HP** pada konfirmasi status atau pilih **Perbarui lokasi**. Lokasi diambil sekali saat aplikasi terbuka. Tidak ada pelacakan latar belakang, izin Always, maupun geofence. Jika izin ditolak, GPS mati, atau sampel belum tersedia, status yang dikonfirmasi tetap disimpan tanpa titik baru. Refresh lokasi saja tidak membuat koordinat palsu.

Titik menyertakan waktu dan perkiraan akurasi. Titik berumur 15 menit diberi penjelasan lama. Snapshot menyimpan titik terakhir serta GPS pada maksimal tiga posisi riwayat terbaru agar muat dalam relay. Detail menjelaskan jika koordinat suatu kejadian sudah tidak disimpan. Tautan peta membagikan koordinat ke layanan peta hanya setelah dipilih.

Kode pasangan adalah rahasia: semua pemilik kode dapat membaca status/lokasi. Hanya pengirim memiliki kunci penandatanganan. Belum ada daftar penerima individual atau persetujuan per perangkat. **Ganti kode pasangan** mencabut akses menerima kabar baru melalui kode lama; hubungkan ulang penerima yang diinginkan. Salinan lama di HP lain/cache relay tidak dapat ditarik kembali.

## Internet, notifikasi dan batas versi uji

Relay uji adalah [ntfy.sh](https://ntfy.sh). Status dan lokasi dienkripsi AES-256-GCM dan ditandatangani ECDSA P-256 sebelum dikirim melalui HTTPS. Relay menerima ciphertext dan metadata jaringan/waktu pengiriman. Kunci dan data lokal tetap harus dilindungi melalui keamanan HP.

Android menggunakan foreground service dengan notifikasi **abc aktif**. Baterai, Doze, jaringan dan pengaturan merek HP dapat menunda kabar. Setelah restart atau Paksa berhenti, buka abc lagi. Status **Kabar terkirim** berarti diterima relay, bukan sudah dibaca penerima. Tidak ada jaminan notifikasi seketika.

Saat offline, pengirim menyimpan maksimal 25 kabar dan mencoba ulang. Antrean penuh menolak kabar tambahan dengan penjelasan. Revisi duplikat/lama tidak memperbarui status atau memberi notifikasi ulang. Relay publik memiliki batas layanan dan cache sementara; ini bukan arsip permanen. Pengirim aktif memperbarui snapshot setiap empat jam tanpa notifikasi. Jika lama tidak aktif, buka pengirim dan kirim status lagi.

iPhone menggunakan APNs untuk notifikasi saat aplikasi tertutup dan WidgetKit untuk widget. [Server notifikasi](server/README.md) tersedia sebagai sumber; akun Apple, sertifikat, penandatanganan dan deployment APNs belum disiapkan. Tanpa itu, jangan mengharapkan notifikasi iPhone saat tertutup. Apple Watch/TV/macOS belum menjadi target aplikasi ini.

## Hapus data dan aplikasi

- **Hapus lokasi yang dibagikan:** menghapus koordinat snapshot terbaru dan mematikan pilihan lokasi berikutnya.
- **Hapus riwayat:** mengosongkan status/catatan dan mengirim snapshot kosong kepada penerima.
- **Putuskan HP ini:** menghapus kode dan data keluarga lokal. Preferensi tampilan/panggilan tetap ada.
- **Uninstall abc:** membuka konfirmasi Android; iPhone mendapat petunjuk penghapusan melalui layar utama.

Menghapus file APK di Download hanya menghapus installer. Tidak ada skrip terpisah yang dipasang di HP. Menghapus data pengirim dapat menghilangkan kunci; kode penerima tidak bisa memulihkannya. Tidak ada akses kontak, SMS, mikrofon, root, atau Accessibility Service. Versi uji belum memiliki distribusi Play Store/App Store, FCM, pemulihan kunci, atau audit keamanan independen.

## Sumber, build dan QA

Antarmuka aktif ada di [crossplatform](crossplatform/README.md), memakai Flutter stable **3.47.6**, Dart **3.13.5**, JDK 17, Android SDK 36/NDK 28.2 dan minimum Android API 29. APK universal berisi ARM32, ARM64 dan x86_64 serta engine Flutter. Proyek iOS menargetkan iOS 16 ke atas dan menggunakan native App Groups/Keychain, widget serta ekstensi notifikasi.

Folder `src`, `apple/Sources/KabarCore`, dan `apple/Shared` berisi enkripsi, aturan status, penyimpanan serta integrasi native. UI native Kabar lama dan skrip `build.ps1` tetap ada sebagai arsip pengembangan; skrip itu membangun Kabar 0.4, bukan abc. Untuk abc, gunakan panduan crossplatform.

QA membedakan pemeriksaan kode, tes UI Flutter, integrasi pada emulator/simulator, interoperabilitas enkripsi dan pengujian perangkat fisik. Hasil aktual serta keterbatasannya dicatat pada [QA.md](QA.md). Lulus emulator tidak menjamin setiap merek HP atau seluruh OS masa depan.
