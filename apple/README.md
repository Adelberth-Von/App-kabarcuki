# Kabar untuk iPhone dan iPad

## Pembaruan 0.4.0

Tema Default/In Relationship dan mode Terang/Gelap tersedia di Pengaturan → Appearance. Ilustrasi pagi/siang/sore/malam mengikuti jam lokal dan terpisah dari mode warna. Status/riwayat menggunakan jam pembaca dengan label zona/negara; jadwal makan tetap memakai zona pengirim. Tema disimpan per perangkat dan juga dipakai widget.

Konfirmasi diperlukan sebelum mencatat status atau menyimpan personalisasi. Daftar Makan hari ini bisa dipakai mencatat kategori. Lokasi GPS opsional diambil satu kali dengan izin When In Use; kartu menampilkan akurasi, umur titik dan tautan peta. Tidak ada pelacakan latar belakang.

Distribusi perangkat fisik tetap memerlukan penandatanganan Apple dan TestFlight/IPA yang sesuai. APK Android tidak bisa dipasang pada iPhone.

Aplikasi native SwiftUI, minimum **iOS/iPadOS 16**. UI sage/krem/pixel art, pengirim/penerima tanpa login, kode pasangan lintas Android–Apple, tombol Keluar/Kost/Makan yang dapat diganti, jadwal makan, riwayat, antrean offline, widget layar utama, serta Notification Service Extension tersedia dalam sumber ini.

**Status distribusi:** sumber dan build simulator tersedia. Belum ada IPA bertanda tangan atau undangan TestFlight. APK Android tidak dapat dipasang di iPhone. Pengujian simulator tidak menggantikan pengujian iPhone/iPad fisik, APNs, dan seluruh versi iOS.

## Buka proyek di Mac

1. Clone repositori, pasang Xcode yang mendukung SDK iOS 18.5 atau lebih baru dan XcodeGen (`brew install xcodegen`).
2. Jalankan `cd apple && xcodegen generate`, lalu buka `Kabar.xcodeproj`. Proyek berisi aplikasi, widget, ekstensi notifikasi, dan tes UI.
3. Pilih simulator iPhone/iPad dan Run untuk uji lokal. Untuk perangkat fisik, pilih Apple Developer Team pada ketiga target aplikasi/ekstensi.
4. Jika Bundle ID atau App Group sudah dimiliki developer lain, ganti `id.kabar.app`, ID kedua ekstensi, `group.id.kabar.shared`, dan grup Keychain pada `project.yml`. Ubah juga `Shared/SharedStore.swift` bila App Group berubah. Ketiga target harus memiliki App Group serta grup Keychain yang sama.
5. Aktifkan App Groups, Keychain Sharing, dan Push Notifications untuk identifier yang sesuai. Untuk TestFlight, gunakan provisioning distribusi dan lingkungan APNs `production`; build perangkat Development memakai `development`. Jangan memasukkan private key/certificate/provisioning ke Git.
6. Build/Run pada iPhone dengan penandatanganan yang sesuai, atau Archive → Distribute melalui Xcode untuk TestFlight. Akun Apple Developer dan provisioning diperlukan untuk distribusi ini.

Referensi: [distribusi aplikasi Apple](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases/).

## Hubungkan dengan Android

Pada salah satu HP, pilih **Aku membagikan kabar**, kemudian bagikan kode di Pengaturan. Pada HP penerima, tempel kode itu. Android dan Apple memakai format `KB1`, AES-256-GCM, kunci P-256 DER, topic SHA-256, dan state JSON yang sama. Tidak ada login pengguna.

Saat aplikasi Apple terbuka, status diterima melalui koneksi ntfy dan kabar pengirim terkirim otomatis. Antrean disimpan sampai 25 pesan; setelah penuh, ketukan tambahan ditolak tanpa mengganti status yang tersimpan. Aplikasi mencoba kembali sampai jeda 60 detik. iOS dapat menghentikan koneksi saat aplikasi berada di latar belakang; buka kembali aplikasi pengirim untuk mengirim antrean yang tertunda.

Widget bersifat **ringkasan baca**. Ketuk untuk membuka aplikasi. Provider meminta pembaruan berkala, tetapi iOS menentukan anggaran dan waktu refresh. Notifikasi APNs yang berhasil diproses juga meminta refresh widget. Widget tidak menjanjikan pembaruan setiap ketukan secara instan. [Aturan refresh WidgetKit](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

## Notifikasi saat aplikasi tertutup

Memerlukan Apple Developer/APNs serta backend HTTPS. Program backend sudah tersedia di [`../server`](../server/README.md), tetapi belum dideploy. Tanpa konfigurasi ini, uji menerima status dengan aplikasi Apple terbuka; jangan mengharapkan notifikasi latar belakang Apple sudah aktif.

1. Pengelola menjalankan push bridge menggunakan kunci APNs dan topic Bundle ID aplikasi.
2. Di HP penerima Apple, buka Pengaturan Kabar, simpan URL HTTPS bridge, lalu izinkan notifikasi.
3. Aplikasi mengirim device token, public signing key dan capability pasangan ke bridge. Kunci AES tidak dikirim ke backend.
4. Saat tombol ditekan, pengirim menambahkan petunjuk notifikasi bertanda tangan pada metadata relay. Snapshot rutin dan perubahan pengaturan tidak memiliki petunjuk itu.
5. Backend memverifikasi tanda tangan, lalu mengirim ciphertext melalui APNs. Ekstensi Apple memverifikasi dan mendekripsi di HP, memperbarui ringkasan, dan menampilkan nama/status.

Jika ekstensi melewati batas waktu, perangkat belum dibuka setelah restart, atau jaringan gagal, iOS dapat menampilkan pemberitahuan umum **Ada kabar baru**, bukan teks status. Buka Kabar untuk memulihkan status lewat relay. APNs tidak memberikan jaminan tiap ketukan selalu menjadi pemberitahuan yang terpisah.

**Putuskan hubungan HP ini** menghapus kode/data lokal dan mencoba mencabut token dari backend. Jika offline, token lama kedaluwarsa maksimal 14 hari sejak pendaftaran terakhir; ekstensi tidak lagi dapat membaca status setelah kode dihapus. Gunakan ganti kode pada pengirim untuk mencabut semua penerima dari kabar baru.

iOS tidak mengizinkan aplikasi menghapus dirinya sendiri. Hapus melalui ikon aplikasi → Hapus App. Hapus data melalui Putuskan sebelum uninstall; Keychain dapat bertahan setelah uninstall.

## QA

`bash scripts/test-apple.sh` dari root menjalankan tes Swift serta interoperability Java → CryptoKit → Java. GitHub Actions membangun aplikasi/dua ekstensi untuk simulator dan menjalankan tes UI iPhone. Artefak simulator `.app` bukan IPA untuk HP fisik. Simulator menggunakan Keychain default karena tidak memiliki provisioning; Keychain bersama antar ekstensi tetap perlu pengujian perangkat fisik bertanda tangan.

Build ini tidak mencakup Apple Watch, Apple TV, atau aplikasi macOS native.
