# abc 0.8.0 — dua cerita, satu dunia pixel

Antarmuka **Flutter** yang sama dipakai untuk Android dan iPhone. Beranda memiliki dunia pixel berlapis, tiga tombol tindakan, serta kartu kabar dengan nama dan waktu yang jelas. **Seirama sekarang menjadi mode berbagi dua arah**: masing-masing orang dapat mengirim kabar sendiri dan melihat kabar pasangan. Sinkronisasi, enkripsi, lokasi, notifikasi, dan widget menggunakan kemampuan native masing-masing perangkat.

**Unduh Android:** [abc.apk](https://raw.githubusercontent.com/Adelberth-Von/App-kabarcuki/refs/heads/main/abc.apk?v=0.8.0). Minimal Android 10. APK lama Kabar disimpan sebagai arsip. **APK tidak dapat dipasang di iPhone**; proyek iOS tersedia, tetapi instalasi pada iPhone fisik memerlukan penandatanganan Apple/TestFlight. Lihat [QA](QA.md) dan [pratinjau](TAMPILAN.md).

## Cara memasang dan mencoba mode satu arah

1. Buka tautan **abc.apk** di atas melalui browser HP dan unduh file tersebut.
2. Buka folder Download, ketuk **abc.apk**, lalu pilih **Install/Update**. Jika diminta, izinkan pemasangan dari browser atau pengelola file yang digunakan. Pertahankan Play Protect aktif; peringatan pengembang belum dikenal tidak berarti aplikasi sudah dinyatakan aman oleh Google.
3. Buka **abc** dan masukkan panggilan, misalnya **Cuki**. Sapaan pada HP itu akan menjadi **Hai, Cuki**. Pada pembaruan dari Kabar, pasangan dan riwayat tetap dipertahankan.
4. Untuk satu arah, pada HP pengirim baru pilih **Aku membagikan kabar**. Buka **Pengaturan → Kode pasangan**, salin seluruh kode, lalu kirim secara pribadi ke HP kedua.
5. Pada HP kedua, masukkan panggilan pemilik HP itu dan pilih **Aku menerima kabar**. Tempel kode lengkap lalu tekan **Hubungkan**.
6. Pada pengirim, ketuk **Kost**, periksa konfirmasi, lalu **Kirim status**. Coba juga **Keluar** dan **Makan**. Kedua HP memerlukan internet, tetapi boleh menggunakan jaringan berbeda.
7. Buka **Pengaturan → Pengaturan notifikasi** pada masing-masing HP. Aktifkan notifikasi abc. Untuk mencoba latar belakang, cek pengaturan baterai aplikasi sesuai merek HP.
8. Buka **Pengaturan → Tambahkan widget** atau tahan area kosong layar utama → Widget → abc. Tombol pada widget pengirim membuka aplikasi untuk meminta konfirmasi.

APK ini memakai identitas `id.kabar.app` dan kunci pengembangan yang sama dengan rilis Kabar/abc sebelumnya. Pembaruan tidak perlu uninstall. Build sendiri dengan kunci debug berbeda tidak dapat menggantikan APK ini. Kunci pribadi build tidak disertakan dalam repositori/paket sumber.

## Seirama: saling berkabar dari dua HP

Pasang **abc 0.8.0 di kedua HP**. Seirama dipilih melalui **Mode berbagi**, lalu meminta konfirmasi sebelum mengaktifkan kemampuan mengirim sekaligus menerima. Saat memperbarui tampilan Seirama versi lama, aplikasi menawarkan perpindahan ini; membatalkan konfirmasi mempertahankan peran satu arah.

1. Pada HP A dan HP B, masukkan panggilan masing-masing. Untuk pemasangan baru, pilih **Aktifkan Seirama**. Untuk perangkat yang sudah terhubung, buka **Pengaturan → Mode berbagi → Seirama**.
2. Baca konfirmasi lalu tekan **Aktifkan Seirama** pada masing-masing HP.
3. Pada layar **Tukar kode Seirama**, salin **Kode milikmu** dari HP A ke HP B, serta kode HP B ke HP A. Kirim kode secara pribadi.
4. Pada HP A, tempel kode HP B di **Kode dari pasangan**, tekan **Hubungkan**, lalu konfirmasi. Pada HP B, lakukan hal yang sama dengan kode HP A.
5. Gunakan kode Seirama yang diawali **KB2.**, bukan kode satu arah **KB1.**. Memasukkan kode milik HP sendiri akan ditolak.
6. Setelah kedua HP tersambung ke internet dan menerima konfirmasi pasangan, muncul **Kalian terhubung dua arah**. Jika baru satu HP selesai, aplikasi masih menampilkan keterangan menunggu.
7. Coba **Keluar/Kost/Makan** dari masing-masing HP. Kartu **Kabarku** dan **Kabar pasangan** menampilkan nama, tindakan terakhir dan waktu secara terpisah. Tombol tindakan selalu mencatat pemilik HP yang sedang digunakan.

Status dan riwayat pasangan hanya dapat dilihat dari HP ini. **Riwayat** menyediakan pilihan Kabarku/Kabar pasangan; **Lihat kabarnya** membuka detail lokasi serta peta pasangan jika mereka menyertakannya. Jadwal makan milikmu digunakan untuk catatanmu, begitu juga jadwal pasangan untuk catatan mereka. Lokasi tetap memerlukan pilihan dan izin pada HP pemilik lokasi.

**Kembali ke satu arah** meminta konfirmasi, menghentikan sambungan Seirama dan memulihkan peran sebelumnya. Pasangan diberi keterangan bahwa mode dua arah telah dihentikan setelah perubahan berhasil dikirim; salinan kabar yang sudah diterima tetap ada. Jika HP ini semula pengirim, pemilik kode satu arah lama tetap dapat membaca kabarnya. Ganti kode jika ingin mencabut akses melalui kode tersebut.

Teks **develop by terrence** ditampilkan pada bagian bawah Pengaturan.

## Panggilan, bahasa, jam dan tampilan

Di **Pengaturan**, setiap HP dapat memilih **Indonesia, English, atau Deutsch**. Panggilan, bahasa, format jam dan mode warna adalah pengaturan lokal. Warna serta karakter mengikuti mode berbagi yang sudah dikonfirmasi. Label buatan pengguna tetap ditampilkan sesuai tulisan aslinya.

**Format waktu** menyediakan **24 jam** (`12.00 WIB - Indonesia`) dan **12 jam AM/PM** (`12.00 PM WIB - Indonesia`). Jam pada beranda/riwayat mengikuti zona waktu sistem HP pembaca. Detail juga menunjukkan waktu di zona pengirim, identifier zona, serta waktu kejadian UTC. Jam musim panas dihitung untuk tanggal masing-masing kejadian. Nama negara menjelaskan zona waktu, bukan bukti lokasi GPS. Aktifkan zona waktu otomatis di pengaturan HP ketika bepergian.

Mode **Satu arah** memakai warna periwinkle dan satu karakter. Mode **Seirama** memakai warna rose/lilac dan dua karakter dengan hati. Pada **Tampilan**, pilih **Terang** atau **Gelap** secara terpisah. Ilustrasi dan sapaan mengikuti pagi 05.00–10.59, siang 11.00–14.59, sore 15.00–17.59, dan malam 18.00–04.59. Suasana diperbarui setiap menit saat aplikasi aktif; mode terang pada malam hari tetap menampilkan langit malam dengan kartu terang.

## Animasi dan baterai

Setiap tindakan punya adegan berbeda: **Keluar** berada di jalur taman dengan tas dan langkah kaki; **Kost** memperlihatkan ruang rumah dengan sofa, buku, tanaman dan lampu; **Makan** memperlihatkan meja, mangkuk, sendok serta uap. Latar memiliki bukit, rumah, pohon, cahaya jendela dan detail kecil. Seirama menambah karakter pasangan yang melambaikan tangan, menyambut pulang atau makan bersama. Burung pagi, kupu-kupu siang, daun sore dan bintang/kunang-kunang malam mengikuti waktu lokal. Konfirmasi status menampilkan adegan tindakan yang dipilih.

Animasi aplikasi memakai **12 frame per detik**, dengan siklus 120 frame dan transisi pergantian adegan. Hanya canvas ilustrasi yang digambar ulang. Widget Android menggunakan **delapan frame** dengan jeda **240 ms** dan transisi **90 ms**, dikelola launcher tanpa timer animasi pada layanan sinkronisasi. Delapan gambar berukuran 320×128 memakai total sekitar 640 KiB agar pembaruan widget tetap ringan.

Widget menyesuaikan ukuran, orientasi dan ukuran tulisan. Tampilan ringkas memakai thumbnail dan kartu status; tampilan sedang/besar memperluas ilustrasi. Pada Seirama, kabar sendiri dan pasangan memiliki kartu serta waktu yang berbeda. Tombol widget membuka konfirmasi untuk kabar sendiri. Pada ukuran sangat kecil dengan tulisan besar, sebagian informasi tambahan diringkas; ketuk kartu untuk membuka detail lengkap.

Widget Android beralih ke tampilan statis ketika koneksi dijeda, perangkat belum dihubungkan, hemat daya/pengurangan animasi aktif, atau Animasi pixel dimatikan. Perilaku widget di luar layar mengikuti launcher. Fase pagi–malam pada layar utama mengikuti pembaruan widget sistem berkala, sehingga perubahan fase tidak selalu seketika. Widget iPhone memakai transisi saat data/timeline berubah sesuai batas WidgetKit; sistem mengatur waktu pembaruannya dan tidak menyediakan animasi loop terus-menerus seperti halaman aplikasi.

Animasi aplikasi berhenti saat ilustrasi keluar layar, tertutup dialog, aplikasi tidak aktif, sistem meminta pengurangan animasi, atau mode hemat daya HP aktif. Pilihan **Pengaturan → Tampilan → Animasi pixel** dapat dimatikan dan disimpan. Mode terang/gelap tetap terpisah dari fase langit.

UI menerima pemberitahuan perubahan dari native tanpa pemeriksaan status setiap lima detik. Pengirim menunggu kabar baru; jam UI diperbarui sekali per menit saat aktif. GPS hanya diambil sekali setelah persetujuan. Penerima Android dan mode Seirama mempertahankan sambungan penerimaan untuk notifikasi; konsumsi baterai tetap bergantung pada jaringan/HP. Tidak meminta pengecualian optimasi baterai secara otomatis. Besarnya penghematan belum diukur pada HP fisik.

Mengganti 24 jam/AM-PM memperbarui waktu status, makan harian, rentang jadwal di beranda, riwayat, Detail termasuk UTC/GPS, widget, dan notifikasi abc yang masih tampil. Detail yang terbuka ikut berubah. Preferensi lokal tiap HP tetap terpisah dan waktu kejadian yang tersimpan tidak berubah. Pembaruan notifikasi Android tidak membunyikan ulang kabar.

## Tombol, makan hari ini dan riwayat

- **Keluar:** memperbarui status di luar. Waktu terakhir di kost dan makan tetap tersimpan.
- **Kost:** memperbarui status tempat tinggal dan waktu terakhir berada di sana.
- **Makan:** mencatat waktu makan tanpa mengubah status tempat tinggal. Kategori selalu mengikuti jadwal dan jam lokal pengirim saat disimpan, termasuk ketika baris Sarapan/Siang/Malam yang diketuk berbeda.
- **Sarapan / Makan siang / Makan malam** di kartu Makan hari ini dapat diketuk. Pengirim mendapat konfirmasi sebelum catatan dikirim; penerima dapat membuka detail catatan yang masih tersedia.
- **Edit nama & tombol** serta **Jadwal makan** meminta konfirmasi sebelum mengirim perubahan ke penerima. Label awal Keluar/Kost/Makan dapat diganti, misalnya Pergi/Rumah/Sudah makan.

Jadwal awal: sarapan 05.00–10.00, siang 10.00–15.00, malam 17.00–22.00; di luar rentang dicatat sebagai Makan. Batas awal termasuk dan batas akhir tidak termasuk. Rentang harus berurutan tanpa tumpang tindih. Makan hari ini mengikuti tanggal/zona pengirim agar tidak bergeser ketika keluarga berada di negara berbeda. **Belum tercatat** berarti belum ada catatan, bukan kesimpulan bahwa orang itu belum makan.

**Riwayat → Detail** menampilkan status, waktu lokal pembaca, waktu pengirim, zona, serta nama daerah/kota, akurasi, waktu pengambilan dan tombol peta jika lokasi disertakan pada kejadian itu. Catatan tanpa GPS tidak meminjam koordinat dari kejadian lain. Terdapat maksimal 12 kejadian terbaru; waktu sarapan/siang/malam tetap tersimpan terpisah.

Kartu kabar dan widget menampilkan tindakan terbaru. Jika terakhir mengetuk Makan, kategori makan serta waktunya menjadi informasi utama; status tempat tinggal yang sebelumnya dicatat tetap tersimpan sebagai informasi terpisah.

## Lokasi opsional dan privasi

Aktifkan **Sertakan lokasi HP** pada konfirmasi status atau pilih **Perbarui lokasi**. Lokasi diambil sekali saat aplikasi terbuka. Tidak ada pelacakan latar belakang, izin Always, maupun geofence. Jika GPS mati, abc meminta persetujuan untuk membuka pengaturan sistem. Setelah layanan lokasi dinyalakan dan kembali ke abc, pengambilan dilanjutkan. Membatalkan langkah aktivasi membatalkan status. Android/iPhone tidak mengizinkan abc menyalakan GPS diam-diam. Jika izin ditolak atau sampel belum tersedia setelah aktivasi, status tetap dapat disimpan tanpa titik baru. Refresh lokasi saja tidak membuat koordinat palsu.

Titik menyertakan waktu dan perkiraan akurasi. Titik berumur 15 menit diberi penjelasan lama. Tampilan lokasi menunjukkan daerah terakhir, kota, waktu pengambilan dan zona waktu, tanpa angka koordinat. Nama dicari sekali dengan batas 2,5 detik; jika layanan tidak tersedia, muncul keterangan belum diketahui. Peta tetap memakai koordinat yang tepat. Snapshot menyimpan titik terakhir serta GPS pada maksimal tiga posisi riwayat terbaru. GPS riwayat lama lalu kejadian tertua dapat diringkas lebih awal jika nama multibyte membuat paket terlalu besar; lokasi terbaru dan waktu makan tetap dipertahankan. Detail menjelaskan jika koordinat suatu kejadian sudah tidak disimpan. Tautan peta membagikan koordinat ke layanan peta hanya setelah dipilih.

Kode pasangan adalah rahasia: pemilik kode dapat membaca status/lokasi dari sumber kode itu. Pada Seirama, setiap HP memiliki kunci pengirim sendiri; kode yang dibagikan tidak membawa kunci untuk menulis status pemiliknya. Konfirmasi dua arah menghubungkan dua sumber kabar secara terpisah. Seirama tidak membatasi akses menjadi eksklusif untuk satu pembaca: pemilik kode lama dapat tetap menerima kabar sampai kode diganti. Belum ada daftar penerima individual. **Ganti kode pasangan** mencabut akses menerima kabar baru melalui kode lama; tukar kode baru dan hubungkan ulang perangkat yang diinginkan. Salinan lama di HP lain/cache relay tidak dapat ditarik kembali.

Jika Sarapan diketuk pukul 18.00 pada jadwal sarapan 05.00–10.00 dan malam 17.00–22.00, yang tercatat adalah **Makan malam**. Di luar seluruh rentang, dicatat **Makan** tanpa mencentang kategori lain. Konfirmasi menjelaskan kategori otomatis ini.

## Internet, notifikasi dan batas versi uji

Relay uji adalah [ntfy.sh](https://ntfy.sh). Status dan lokasi dienkripsi AES-256-GCM dan ditandatangani ECDSA P-256 sebelum dikirim melalui HTTPS. Relay menerima ciphertext dan metadata jaringan/waktu pengiriman. Kunci dan data lokal tetap harus dilindungi melalui keamanan HP.

Notifikasi kabar baru menampilkan tindakan, waktu lokal, nama kota jika tersedia, ilustrasi pixel Android dan tombol Lihat kabar. Nada asli **abc pixel chime** berdurasi **1,08 detik**, dibundel untuk Android/iPhone, mengikuti volume notifikasi, mode senyap dan Jangan Ganggu. Notifikasi yang sebelumnya dimatikan tetap dimatikan. Android 11 ke atas juga mempertahankan suara yang dipilih pengguna pada saluran lama; pembaruan format waktu tidak memutar ulang nada. [Dengarkan nada abc](res/raw/abc_chime.wav). Notifikasi koneksi tetap senyap.

Android menggunakan foreground service dengan notifikasi **abc aktif**. Baterai, Doze, jaringan dan pengaturan merek HP dapat menunda kabar. Setelah restart atau Paksa berhenti, buka abc lagi. Status **Kabar terkirim** berarti diterima relay, bukan sudah dibaca penerima. Tidak ada jaminan notifikasi seketika.

Saat offline, pengirim menyimpan maksimal 25 kabar dan mencoba ulang. Antrean penuh menolak kabar tambahan dengan penjelasan. Revisi duplikat/lama tidak memperbarui status atau memberi notifikasi ulang. Relay publik memiliki batas layanan dan cache sementara; ini bukan arsip permanen. Pengirim aktif memperbarui snapshot setiap empat jam tanpa notifikasi. Jika lama tidak aktif, buka pengirim dan kirim status lagi.

iPhone menggunakan APNs untuk notifikasi saat aplikasi tertutup dan WidgetKit untuk widget. [Server notifikasi](server/README.md) tersedia sebagai sumber; akun Apple, sertifikat, penandatanganan dan deployment APNs belum disiapkan. Tanpa itu, jangan mengharapkan notifikasi iPhone saat tertutup. Apple Watch/TV/macOS belum menjadi target aplikasi ini.

## Hapus data dan aplikasi

- **Hapus lokasi yang dibagikan:** menghapus koordinat snapshot milikmu dan mematikan pilihan lokasi berikutnya.
- **Hapus riwayat:** mengosongkan status/catatan milikmu dan mengirim snapshot kosong kepada penerima. Riwayat pasangan tidak diubah oleh tombol ini.
- **Putuskan HP ini:** menghapus kode dan data keluarga lokal. Preferensi tampilan/panggilan tetap ada.
- **Uninstall abc:** meminta konfirmasi, lalu menghapus semua data abc lokal: kode/kunci pengirim dan pasangan, riwayat sendiri/pasangan, antrean, panggilan, bahasa/tampilan/format jam, database, file dan cache milik aplikasi, serta notifikasi. Android kemudian membuka dialog uninstall sistem. **Membatalkan dialog sistem tidak mengembalikan data yang sudah dibersihkan.** Pada iPhone, data abc dan akun Keychain miliknya dibersihkan lebih dulu, kemudian ikuti petunjuk **Delete App/Hapus App**, bukan Offload.

Pembersihan dibatasi ke penyimpanan abc dan App Group/akun Keychain abc. Foto, folder Download, installer APK yang Anda unduh, file pribadi di luar abc, dan data aplikasi lain tidak disentuh. Android menonaktifkan backup aplikasi dan pilihan mempertahankan data setelah uninstall. Salinan kabar di HP lain atau cache relay tidak ikut terhapus melalui tombol lokal ini.

Menghapus file APK di Download hanya menghapus installer. Tidak ada skrip terpisah yang dipasang di HP. Menghapus data pengirim dapat menghilangkan kunci; kode penerima tidak bisa memulihkannya. Tidak ada akses kontak, SMS, mikrofon, root, atau Accessibility Service. Versi uji belum memiliki distribusi Play Store/App Store, FCM, pemulihan kunci, atau audit keamanan independen.

## Sumber, build dan QA

Antarmuka aktif ada di [crossplatform](crossplatform/README.md), memakai Flutter stable **3.47.6**, Dart **3.13.5**, JDK 17, Android SDK 36/NDK 28.2 dan minimum Android API 29. APK universal berisi ARM32, ARM64 dan x86_64 serta engine Flutter. Proyek iOS menargetkan iOS 16 ke atas dan menggunakan native App Groups/Keychain, widget serta ekstensi notifikasi.

Folder `src`, `apple/Sources/KabarCore`, dan `apple/Shared` berisi enkripsi, aturan status, penyimpanan serta integrasi native. UI native Kabar lama dan skrip `build.ps1` tetap ada sebagai arsip pengembangan; skrip itu membangun Kabar 0.4, bukan abc. Untuk abc, gunakan panduan crossplatform.

QA membedakan pemeriksaan kode, tes UI Flutter, integrasi pada emulator/simulator, interoperabilitas enkripsi dan pengujian perangkat fisik. Hasil aktual serta keterbatasannya dicatat pada [QA.md](QA.md). Lulus emulator tidak menjamin setiap merek HP atau seluruh OS masa depan.
