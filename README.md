# abc 0.7.0 — kabar kecil, bikin tenang

Antarmuka **Flutter** yang sama dipakai untuk Android dan iPhone. Desain baru memakai kartu yang ringkas, ikon pixel, tiga tombol status di bagian atas, serta tema Default dan Seirama. Sinkronisasi, enkripsi, lokasi, notifikasi, dan widget menggunakan kemampuan native masing-masing perangkat.

**Unduh Android:** [abc.apk](https://raw.githubusercontent.com/Adelberth-Von/App-kabarcuki/refs/heads/main/abc.apk?v=0.7.0). Minimal Android 10. APK lama Kabar disimpan sebagai arsip. **APK tidak dapat dipasang di iPhone**; proyek iOS tersedia, tetapi instalasi pada iPhone fisik memerlukan penandatanganan Apple/TestFlight. Lihat [QA](QA.md) dan [pratinjau](TAMPILAN.md).

## Cara mencoba di dua HP Android

1. Buka tautan **abc.apk** di atas melalui browser HP dan unduh file tersebut.
2. Buka folder Download, ketuk **abc.apk**, lalu pilih **Install/Update**. Jika diminta, izinkan pemasangan dari browser atau pengelola file yang digunakan. Pertahankan Play Protect aktif; peringatan pengembang belum dikenal tidak berarti aplikasi sudah dinyatakan aman oleh Google.
3. Buka **abc** dan masukkan panggilan, misalnya **Cuki**. Sapaan pada HP itu akan menjadi **Hai, Cuki**. Pada pembaruan dari Kabar, pasangan dan riwayat tetap dipertahankan.
4. Pada HP pengirim baru, pilih **Aku membagikan kabar**. Buka **Pengaturan → Kode pasangan**, salin seluruh kode, lalu kirim secara pribadi ke HP kedua.
5. Pada HP kedua, masukkan panggilan pemilik HP itu dan pilih **Aku menerima kabar**. Tempel kode lengkap lalu tekan **Hubungkan**.
6. Pada pengirim, ketuk **Kost**, periksa konfirmasi, lalu **Kirim status**. Coba juga **Keluar** dan **Makan**. Kedua HP memerlukan internet, tetapi boleh menggunakan jaringan berbeda.
7. Buka **Pengaturan → Pengaturan notifikasi** pada masing-masing HP. Aktifkan notifikasi abc. Untuk mencoba latar belakang, cek pengaturan baterai aplikasi sesuai merek HP.
8. Buka **Pengaturan → Tambahkan widget** atau tahan area kosong layar utama → Widget → abc. Tombol pada widget pengirim membuka aplikasi untuk meminta konfirmasi.

APK ini memakai identitas `id.kabar.app` dan kunci pengembangan yang sama dengan rilis Kabar/abc sebelumnya. Pembaruan tidak perlu uninstall. Build sendiri dengan kunci debug berbeda tidak dapat menggantikan APK ini. Kunci pribadi build tidak disertakan dalam repositori/paket sumber.

## Panggilan, bahasa, jam dan appearance

Di **Pengaturan**, setiap HP dapat memilih **Indonesia, English, atau Deutsch**. Panggilan, bahasa, format jam, tema, dan mode warna adalah pengaturan lokal; tidak dikirim ke HP keluarga. Label buatan pengguna tetap ditampilkan sesuai tulisan aslinya.

**Format waktu** menyediakan **24 jam** (`12.00 WIB - Indonesia`) dan **12 jam AM/PM** (`12.00 PM WIB - Indonesia`). Jam pada beranda/riwayat mengikuti zona waktu sistem HP pembaca. Detail juga menunjukkan waktu di zona pengirim, identifier zona, serta waktu kejadian UTC. Jam musim panas dihitung untuk tanggal masing-masing kejadian. Nama negara menjelaskan zona waktu, bukan bukti lokasi GPS. Aktifkan zona waktu otomatis di pengaturan HP ketika bepergian.

Pilih tema **Default** (krem/periwinkle, satu karakter) atau **Seirama** (rose/lilac, dua karakter dengan hati), lalu **Terang** atau **Gelap**. Ilustrasi dan sapaan mengikuti pagi 05.00–10.59, siang 11.00–14.59, sore 15.00–17.59, dan malam 18.00–04.59. Suasana diperbarui setiap menit saat aplikasi aktif. Mode warna tetap mengikuti pilihan Anda; mode terang pada malam hari menampilkan langit malam dengan kartu terang.

## Animasi dan baterai

Setiap tindakan punya adegan berbeda: Keluar berjalan membawa tas, Kost beristirahat/membaca, dan Makan duduk dengan mangkuk serta uap. Seirama menambah pasangan yang melambaikan tangan, menyambut pulang atau makan bersama. Burung pagi, kupu-kupu siang, daun sore, dan kunang-kunang/bintang malam mengikuti waktu lokal. Konfirmasi status juga menampilkan adegan tindakan yang dipilih. Animasi kecil ini memakai empat repaint canvas per detik; halaman tidak dibangun ulang untuk tiap frame. Widget Android menampilkan dua frame ringan tiap 1,5 detik ketika terlihat, dan beralih ke tampilan statis saat hemat daya/pengurangan animasi aktif atau animasi dimatikan. Widget iPhone memakai transisi saat data berubah sesuai batas WidgetKit. Ukuran kecil/besar, mode warna, tombol berikon dan informasi waktu mengikuti tampilan lokal.

Animasi berhenti saat ilustrasi keluar layar, tertutup dialog, aplikasi tidak aktif, sistem meminta pengurangan animasi, atau mode hemat daya HP aktif. Pilihan **Pengaturan → Appearance → Animasi pixel** dapat dimatikan dan disimpan. Mode terang/gelap tetap terpisah dari fase langit.

UI menerima pemberitahuan perubahan dari native; pemeriksaan status tiap lima detik dihapus. Pengirim menunggu kabar baru, menggantikan timer 1,5 detik. Jam UI diperbarui sekali per menit saat aktif. GPS hanya diambil sekali setelah persetujuan. Penerima Android mempertahankan koneksi untuk notifikasi; konsumsi baterai tetap bergantung pada jaringan/HP. Tidak meminta pengecualian optimasi baterai secara otomatis. Besarnya penghematan belum diukur pada HP fisik.

Mengganti 24 jam/AM-PM memperbarui waktu status, makan harian, rentang jadwal di beranda, riwayat, Detail termasuk UTC/GPS, widget, dan notifikasi abc yang masih tampil. Detail yang terbuka ikut berubah. Preferensi lokal tiap HP tetap terpisah dan waktu kejadian yang tersimpan tidak berubah. Pembaruan notifikasi Android tidak membunyikan ulang kabar.

## Tombol, makan hari ini dan riwayat

- **Keluar:** memperbarui status di luar. Waktu terakhir di kost dan makan tetap tersimpan.
- **Kost:** memperbarui status tempat tinggal dan waktu terakhir berada di sana.
- **Makan:** mencatat waktu makan tanpa mengubah status tempat tinggal. Kategori selalu mengikuti jadwal dan jam lokal pengirim saat disimpan, termasuk ketika baris Sarapan/Siang/Malam yang diketuk berbeda.
- **Sarapan / Makan siang / Makan malam** di kartu Makan hari ini dapat diketuk. Pengirim mendapat konfirmasi sebelum catatan dikirim; penerima dapat membuka detail catatan yang masih tersedia.
- **Edit nama & tombol** serta **Jadwal makan** meminta konfirmasi sebelum mengirim perubahan ke penerima. Label awal Keluar/Kost/Makan dapat diganti, misalnya Pergi/Rumah/Sudah makan.

Jadwal awal: sarapan 05.00–10.00, siang 10.00–15.00, malam 17.00–22.00; di luar rentang dicatat sebagai Makan. Batas awal termasuk dan batas akhir tidak termasuk. Rentang harus berurutan tanpa tumpang tindih. Makan hari ini mengikuti tanggal/zona pengirim agar tidak bergeser ketika keluarga berada di negara berbeda. **Belum tercatat** berarti belum ada catatan, bukan kesimpulan bahwa orang itu belum makan.

**Riwayat → Detail** menampilkan status, waktu lokal pembaca, waktu pengirim, zona, serta nama daerah/kota, akurasi, waktu pengambilan dan tombol peta jika lokasi disertakan pada kejadian itu. Catatan tanpa GPS tidak meminjam koordinat dari kejadian lain. Terdapat maksimal 12 kejadian terbaru; waktu sarapan/siang/malam tetap tersimpan terpisah.

## Lokasi opsional dan privasi

Aktifkan **Sertakan lokasi HP** pada konfirmasi status atau pilih **Perbarui lokasi**. Lokasi diambil sekali saat aplikasi terbuka. Tidak ada pelacakan latar belakang, izin Always, maupun geofence. Jika GPS mati, abc meminta persetujuan untuk membuka pengaturan sistem. Setelah layanan lokasi dinyalakan dan kembali ke abc, pengambilan dilanjutkan. Membatalkan langkah aktivasi membatalkan status. Android/iPhone tidak mengizinkan abc menyalakan GPS diam-diam. Jika izin ditolak atau sampel belum tersedia setelah aktivasi, status tetap dapat disimpan tanpa titik baru. Refresh lokasi saja tidak membuat koordinat palsu.

Titik menyertakan waktu dan perkiraan akurasi. Titik berumur 15 menit diberi penjelasan lama. Tampilan lokasi menunjukkan daerah terakhir, kota, waktu pengambilan dan zona waktu, tanpa angka koordinat. Nama dicari sekali dengan batas 2,5 detik; jika layanan tidak tersedia, muncul keterangan belum diketahui. Peta tetap memakai koordinat yang tepat. Snapshot menyimpan titik terakhir serta GPS pada maksimal tiga posisi riwayat terbaru. GPS riwayat lama lalu kejadian tertua dapat diringkas lebih awal jika nama multibyte membuat paket terlalu besar; lokasi terbaru dan waktu makan tetap dipertahankan. Detail menjelaskan jika koordinat suatu kejadian sudah tidak disimpan. Tautan peta membagikan koordinat ke layanan peta hanya setelah dipilih.

Kode pasangan adalah rahasia: semua pemilik kode dapat membaca status/lokasi. Hanya pengirim memiliki kunci penandatanganan. Belum ada daftar penerima individual atau persetujuan per perangkat. **Ganti kode pasangan** mencabut akses menerima kabar baru melalui kode lama; hubungkan ulang penerima yang diinginkan. Salinan lama di HP lain/cache relay tidak dapat ditarik kembali.

Jika Sarapan diketuk pukul 18.00 pada jadwal sarapan 05.00–10.00 dan malam 17.00–22.00, yang tercatat adalah **Makan malam**. Di luar seluruh rentang, dicatat **Makan** tanpa mencentang kategori lain. Konfirmasi menjelaskan kategori otomatis ini.

## Internet, notifikasi dan batas versi uji

Relay uji adalah [ntfy.sh](https://ntfy.sh). Status dan lokasi dienkripsi AES-256-GCM dan ditandatangani ECDSA P-256 sebelum dikirim melalui HTTPS. Relay menerima ciphertext dan metadata jaringan/waktu pengiriman. Kunci dan data lokal tetap harus dilindungi melalui keamanan HP.

Notifikasi kabar baru menampilkan tindakan, waktu lokal, nama kota jika tersedia, ilustrasi pixel Android dan tombol Lihat kabar. Nada asli **abc pixel chime** berdurasi **1,08 detik**, dibundel untuk Android/iPhone, mengikuti volume notifikasi, mode senyap dan Jangan Ganggu. Notifikasi yang sebelumnya dimatikan tetap dimatikan. Android 11 ke atas juga mempertahankan suara yang dipilih pengguna pada saluran lama; pembaruan format waktu tidak memutar ulang nada. [Dengarkan nada abc](res/raw/abc_chime.wav). Notifikasi koneksi tetap senyap.

Android menggunakan foreground service dengan notifikasi **abc aktif**. Baterai, Doze, jaringan dan pengaturan merek HP dapat menunda kabar. Setelah restart atau Paksa berhenti, buka abc lagi. Status **Kabar terkirim** berarti diterima relay, bukan sudah dibaca penerima. Tidak ada jaminan notifikasi seketika.

Saat offline, pengirim menyimpan maksimal 25 kabar dan mencoba ulang. Antrean penuh menolak kabar tambahan dengan penjelasan. Revisi duplikat/lama tidak memperbarui status atau memberi notifikasi ulang. Relay publik memiliki batas layanan dan cache sementara; ini bukan arsip permanen. Pengirim aktif memperbarui snapshot setiap empat jam tanpa notifikasi. Jika lama tidak aktif, buka pengirim dan kirim status lagi.

iPhone menggunakan APNs untuk notifikasi saat aplikasi tertutup dan WidgetKit untuk widget. [Server notifikasi](server/README.md) tersedia sebagai sumber; akun Apple, sertifikat, penandatanganan dan deployment APNs belum disiapkan. Tanpa itu, jangan mengharapkan notifikasi iPhone saat tertutup. Apple Watch/TV/macOS belum menjadi target aplikasi ini.

## Hapus data dan aplikasi

- **Hapus lokasi yang dibagikan:** menghapus koordinat snapshot terbaru dan mematikan pilihan lokasi berikutnya.
- **Hapus riwayat:** mengosongkan status/catatan dan mengirim snapshot kosong kepada penerima.
- **Putuskan HP ini:** menghapus kode dan data keluarga lokal. Preferensi tampilan/panggilan tetap ada.
- **Uninstall abc:** meminta konfirmasi, lalu menghapus semua data abc lokal: kode/kunci pasangan, riwayat, antrean, panggilan, bahasa/tema/format jam, database, file dan cache milik aplikasi, serta notifikasi. Android kemudian membuka dialog uninstall sistem. **Membatalkan dialog sistem tidak mengembalikan data yang sudah dibersihkan.** Pada iPhone, data abc dan dua akun Keychain miliknya dibersihkan lebih dulu, kemudian ikuti petunjuk **Delete App/Hapus App**, bukan Offload.

Pembersihan dibatasi ke penyimpanan abc dan App Group/akun Keychain abc. Foto, folder Download, installer APK yang Anda unduh, file pribadi di luar abc, dan data aplikasi lain tidak disentuh. Android menonaktifkan backup aplikasi dan pilihan mempertahankan data setelah uninstall. Salinan kabar di HP lain atau cache relay tidak ikut terhapus melalui tombol lokal ini.

Menghapus file APK di Download hanya menghapus installer. Tidak ada skrip terpisah yang dipasang di HP. Menghapus data pengirim dapat menghilangkan kunci; kode penerima tidak bisa memulihkannya. Tidak ada akses kontak, SMS, mikrofon, root, atau Accessibility Service. Versi uji belum memiliki distribusi Play Store/App Store, FCM, pemulihan kunci, atau audit keamanan independen.

## Sumber, build dan QA

Antarmuka aktif ada di [crossplatform](crossplatform/README.md), memakai Flutter stable **3.47.6**, Dart **3.13.5**, JDK 17, Android SDK 36/NDK 28.2 dan minimum Android API 29. APK universal berisi ARM32, ARM64 dan x86_64 serta engine Flutter. Proyek iOS menargetkan iOS 16 ke atas dan menggunakan native App Groups/Keychain, widget serta ekstensi notifikasi.

Folder `src`, `apple/Sources/KabarCore`, dan `apple/Shared` berisi enkripsi, aturan status, penyimpanan serta integrasi native. UI native Kabar lama dan skrip `build.ps1` tetap ada sebagai arsip pengembangan; skrip itu membangun Kabar 0.4, bukan abc. Untuk abc, gunakan panduan crossplatform.

QA membedakan pemeriksaan kode, tes UI Flutter, integrasi pada emulator/simulator, interoperabilitas enkripsi dan pengujian perangkat fisik. Hasil aktual serta keterbatasannya dicatat pada [QA.md](QA.md). Lulus emulator tidak menjamin setiap merek HP atau seluruh OS masa depan.
