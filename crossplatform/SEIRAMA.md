# Seirama: API, persetujuan dan QA

Seirama adalah mode saling berbagi kabar. Pilihan terang/gelap tetap terpisah. Preferensi tampilan Seirama dari versi lama hanya menampilkan ajakan migrasi; preferensi tersebut tidak membuat sambungan atau kunci pengirim baru tanpa konfirmasi.

## Menghubungkan kedua HP

1. Pengguna mengonfirmasi `enableSeirama` pada masing-masing HP.
2. `pairCode` memberikan undangan `KB2` milik HP tersebut. Undangan memuat akses membaca, tanpa kunci tanda tangan pribadi.
3. Pada sambungan baru, kedua orang bertukar undangan dan mengonfirmasi `joinSeirama` dengan undangan dari HP pasangannya. Saat memigrasikan penerima satu arah, sumber yang sebelumnya disetujui dipertahankan; konfirmasi `enableSeirama` menyetujui berbagi balik kepada sumber tersebut. HP pengirim lamanya tetap perlu memasang undangan baru dari HP penerima itu.
4. Mode menjadi `active` setelah masing-masing HP menerima pesan bertanda tangan dari pasangannya yang mengikat topik penerima miliknya. Satu konfirmasi lokal tidak dianggap sebagai persetujuan kedua pihak.

Kode pasangan merupakan akses privat. Orang yang memperoleh kode bisa membaca stream terkait; bagikan hanya kepada penerima yang dimaksud.

## API bridge

Semua perintah mutasi memberikan `snapshot` terbaru. `confirmed` harus berupa boolean `true`; membatalkan dialog tidak memanggil perintah mutasi.

| Perintah | Argumen | Perilaku |
| --- | --- | --- |
| `enableSeirama` | `confirmed: true` | Mengaktifkan mode lokal. Pengirim lama mempertahankan kunci, status, label dan riwayat. Penerima lama mendapat stream milik sendiri dengan nama panggilan lokal; stream yang sebelumnya dibaca menjadi stream pasangan. |
| `pairCode` | — | `KB1` pada pengirim satu arah; `KB2` pada Seirama. |
| `joinSeirama` | `code`, `confirmed: true` | Memasang stream pasangan yang dapat dibaca. Kode milik sendiri ditolak, termasuk kode dengan kunci publik sendiri yang dibungkus ulang dengan secret lain. |
| `record`, `edit`, `clearGps`, `clearHistory` | Sesuai API yang sudah ada | Mengubah milik sendiri. Tidak mengubah status atau riwayat pasangan. |
| `disableSeirama` | `confirmed: true` | Menghentikan mode lokal dan memulihkan peran satu arah sebelumnya. Mengantrekan pemberitahuan penghentian bertanda tangan tanpa suara. |
| `toggleConnection` | — | Menjeda atau melanjutkan koneksi; data dan antrean tetap disimpan. |
| `disconnect` | — | Menghapus sambungan dan antrean lokal; tidak menghapus profil penampilan. |
| `prepareUninstall` | — | Menghapus data, kunci, antrean, notifikasi dan berkas dalam lingkup aplikasi. |

`own_code` dipetakan ke pesan `ownCodeError` dalam bahasa pengguna. `invalid_code` digunakan untuk undangan yang tidak valid. Kode `KB1` tetap berlaku untuk penyambungan satu arah, tetapi tidak otomatis menyetujui mode Seirama.

## Snapshot untuk UI dan widget

| Field | Makna |
| --- | --- |
| `role` | `sender`, `receiver`, `duplex`, atau kosong sebelum tersambung. |
| `mode` | `oneWay` atau `seirama`. |
| `modeUpgradeSuggested` | Preferensi tampilan lama mengusulkan migrasi yang memerlukan konfirmasi. |
| `state` | Status milik sendiri pada Seirama; status yang dibaca pada penerima satu arah. |
| `peerState` | Status pasangan pada Seirama, terpisah dari `state`; tidak ada sebelum stream pasangan dipasang. |
| `peerZone` | Zona waktu sumber dari status pasangan terakhir. |
| `peerLocalTimes` | Waktu setiap timestamp pasangan dengan preferensi zona waktu HP yang sedang menampilkan. |
| `peerMealsToday` | Checklist makan berdasarkan jadwal dan zona waktu sumber pasangan. |
| `quickPeer` | Satu kali membuka detail pasangan dari widget/notifikasi. |
| `quickAction` | Satu kali membuka konfirmasi tindakan milik sendiri; tautan tidak langsung mengirim status. |

`reciprocity` bernilai `unlinked` sebelum memasang pasangan, `waiting` ketika menunggu bukti timbal balik, `active` setelah bukti valid, atau `inactive` setelah penghentian terbaru yang ditandatangani pasangan. Pada mode satu arah nilainya `none`.

## Penghentian dan batasnya

Setiap orang memiliki stream terenkripsi, kunci tanda tangan dan penghitung revisi sendiri. Pesan pasangan hanya boleh menulis slot pasangan. Pesan lama tidak dapat menurunkan revisi atau mengaktifkan kembali bukti yang sudah dicabut oleh revisi terbaru.

Pada penerima yang telah dimigrasikan, penghentian ditandatangani sebelum kunci pengirim barunya dihapus. Antrean penghentian hanya menyimpan topik dan ciphertext; tidak menyimpan private key atau kode akses membaca. Antrean dibatasi empat pesan dan dikirim sebelum melanjutkan pembacaan stream lama saat internet tersedia. Pada pengirim lama, penghentian dikirim melalui stream miliknya yang tetap dipertahankan.

Penerima lama yang sudah memiliki akses stream pengirim tetap dapat membaca stream itu setelah pengirim kembali ke mode satu arah. Untuk membatalkan akses tersebut, gunakan penggantian kode satu arah atau putuskan dan buat sambungan baru. Salinan kabar yang telah diterima HP lain tidak ikut terhapus.

Putuskan sambungan atau hapus data aplikasi membatalkan antrean lokal, termasuk penghentian yang belum terkirim. HP lain mungkin masih menampilkan kabar/bukti terakhir yang tersimpan; tidak akan ada kabar baru dari stream yang kuncinya sudah dihapus. Notifikasi Apple yang datang dari sambungan lama dibuat tanpa suara dan pasif; iOS masih dapat menyimpannya di pusat notifikasi.

## Pemeriksaan QA yang relevan

- Konfirmasi batal tidak mengubah peran, kunci, riwayat, lokasi atau antrean.
- Migrasi pengirim mempertahankan kode/label/riwayat; migrasi penerima membuat riwayat sendiri tanpa menimpa riwayat stream yang sebelumnya dibaca.
- Undangan `KB2` tidak dapat dipakai menandatangani kabar pasangan; stream milik sendiri ditolak berdasarkan identitas kunci publik.
- Revisi pasangan yang lebih kecil daripada revisi milik sendiri tetap diterima pada slot pasangan. Replay atau revisi yang lebih kecil pada stream yang sama ditolak.
- Bukti timbal balik mengharuskan tanda tangan stream pasangan dan pengikatan topik penerima yang benar.
- Penghentian terbaru bersifat senyap, mengubah bukti menjadi `inactive`, dan tidak dapat dibatalkan oleh replay kabar aktif yang lebih lama.
- Antrean penghentian dapat dikirim setelah private key stream yang dihentikan dihapus. Pause/logout/cleanup membatalkan pekerjaan dan mencegah antrean lama dipakai kembali.
- Payload dengan nama/lokasi multibyte dan pengikatan pasangan tetap di bawah batas relay 4096 byte; lokasi terbaru dipertahankan ketika riwayat lama dipadatkan.
- GPS hanya diperbarui saat pengguna memilihnya dan mengonfirmasi tindakan. Widget/notifikasi tidak memulai pengambilan GPS.
- Cleanup menghapus `code`, `private`, `peerCode`, `oneWayCode`, status pasangan dan kedua antrean. Item Keychain aplikasi lain tetap utuh.
- Pemeriksa release melarang definisi `QaProbe`, `SeiramaProbe`, `DeviceQA` dan kelas turunannya di seluruh DEX. Probe penyimpanan tersedia hanya di build debug.

`qaSeiramaProbe` pada Android menguji penyimpanan, tanda tangan, revisi independen, replay, penghentian dan cleanup dalam file preferensi fixture terpisah. Pengujian migrasi/konfirmasi UI dan pengiriman dua arah tetap dijalankan lewat alur aplikasi pada dua perangkat uji.
