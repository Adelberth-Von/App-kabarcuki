# abc: shared Flutter app

UI Android/iPhone ada pada `lib/`. Native capabilities dihubungkan melalui `abc/native` (Java pada Android, Swift pada iOS). Preferensi per HP tidak masuk paket keluarga terenkripsi.

## Android

Pasang Flutter stable 3.47.6, JDK 17 dan Android SDK 36/NDK 28.2.13676358, lalu dari direktori ini:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Hasil ada di `build/app/outputs/flutter-apk/app-release.apk`. Build pengembangan menggunakan kunci debug. Untuk tanda tangan Anda sendiri, isi lingkungan `ABC_KEYSTORE` (path absolut), `ABC_KEYSTORE_PASSWORD`, dan `ABC_KEY_ALIAS`. Jangan menyimpan kunci/password dalam repositori. Paket Android tetap `id.kabar.app`.

## iPhone/iPad (Mac + Xcode)

Pasang Flutter 3.47.6 dan XcodeGen, lalu:

```sh
flutter pub get
flutter build ios --simulator --debug --config-only --no-codesign
cd ios
xcodegen generate
cd ..
flutter build ios --simulator --debug
```

XcodeGen menggabungkan host Flutter, KabarCore, widget dan ekstensi notifikasi. Build simulator memakai penandatanganan ad hoc Xcode agar Keychain dapat menyimpan pasangan. Buka `ios/Runner.xcworkspace` untuk penandatanganan perangkat fisik. Isi Apple Team; aktifkan App Groups `group.id.kabar.shared`, shared Keychain `id.kabar.shared`, serta Push Notifications pada profil yang sesuai. iPhone fisik memerlukan signing Apple/TestFlight. Backend APNs belum dideploy.

## QA integrasi

Hanya gunakan emulator/simulator khusus uji. Tes membuat pasangan jika belum ada dan menambah dua catatan status; tidak menghapus pasangan yang sudah ada. Gunakan emulator baru jika antrean lama penuh.

```sh
flutter drive --keep-app-running --driver=test_driver/integration.dart --target=integration_test/native_test.dart -d DEVICE_ID
```

Gambar hasil tes disimpan pada `qa-screenshots/`. UI tests memeriksa bahasa, panggilan, konfirmasi, riwayat, GPS per kejadian, mode warna, dan teks besar 200%. Folder SDK, build, cache, dan rahasia tidak disertakan dalam paket sumber.

## QA 0.6 dan penghapusan

Animasi memakai empat repaint canvas per detik, mengikuti lifecycle/visibility/Reduce Motion/Low Power Mode. EventChannel `abc/updates` menggantikan polling UI. Pengirim native menunggu antrean melalui condition/continuation sampai kabar baru atau heartbeat empat jam.

Pada simulator kosong, tambahkan `--dart-define=QA_CLEANUP=true` ke perintah integrasi. Mode ini menolak pasangan yang sudah ada sebelum memulai; setelah uji UI/persistensi, ia menanam fixture di penyimpanan abc lalu memanggil pembersihan. Pemeriksaan mencakup preferensi tambahan, file/cache/database, kode/kunci, antrean, riwayat, dan notifikasi Android; iOS juga memeriksa satu fixture Keychain dengan service lain tetap ada. Probe Android hanya dikompilasi di source set debug dan probe iOS dibungkus `#if DEBUG`. Jangan jalankan mode pembersihan di HP berisi data pribadi.

Tombol Uninstall membersihkan data abc lokal sebelum dialog uninstall Android/petunjuk Delete App iOS. Jika dialog sistem dibatalkan, data tetap sudah dibersihkan. File di luar sandbox abc, Download dan salinan di HP lain tetap ada.
