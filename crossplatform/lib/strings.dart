// UI language is a local preference. User-entered names remain verbatim.
const languages = {'id': 'Indonesia', 'en': 'English', 'de': 'Deutsch'};

class Copy {
  final String language;
  const Copy(this.language);
  String operator [](String key) =>
      (messages[key] ?? [key, key, key])[language == 'en'
          ? 1
          : language == 'de'
              ? 2
              : 0];
  String fill(String key, String value) => this[key].replaceAll('{x}', value);
  String label(String value) => switch (value) {
        'Keluar' => this['outside'],
        'Kost' => this['homeStatus'],
        'Makan' => this['meal'],
        'Sarapan' => this['breakfast'],
        'Makan siang' => this['lunch'],
        'Makan malam' => this['dinner'],
        'Di kost' => this['atHome'],
        _ => value,
      };
}

const messages = <String, List<String>>{
  'hello': ['Hai, {x}', 'Hi, {x}', 'Hallo, {x}'],
  'morning': ['Selamat pagi', 'Good morning', 'Guten Morgen'],
  'afternoon': ['Selamat siang', 'Good afternoon', 'Guten Tag'],
  'evening': ['Selamat sore', 'Good evening', 'Guten Abend'],
  'night': ['Selamat malam', 'Good night', 'Gute Nacht'],
  'tagline': [
    'Kabar kecil, bikin tenang.',
    'Little updates, peace of mind.',
    'Kleine Updates, ein gutes Gefühl.'
  ],
  'togetherLine': [
    'Dekat dalam setiap kabar.',
    'A little closer with every update.',
    'Mit jedem Update ein Stück näher.'
  ],
  'welcome': [
    'Mulai dengan panggilanmu',
    'What should we call you?',
    'Wie sollen wir dich nennen?'
  ],
  'welcomeBody': [
    'Panggilan ini digunakan untuk sapaan di HP ini.',
    'We use this name to greet you on this phone.',
    'Dieser Name wird für die Begrüßung auf diesem Handy verwendet.'
  ],
  'nickname': ['Panggilanmu', 'Your nickname', 'Dein Rufname'],
  'nameHint': ['Contoh: Adel', 'For example: Alex', 'Zum Beispiel: Alex'],
  'nameError': [
    'Isi 1–24 karakter, tanpa baris baru.',
    'Enter 1–24 characters, without line breaks.',
    'Bitte 1–24 Zeichen ohne Zeilenumbruch eingeben.'
  ],
  'continue': ['Lanjutkan', 'Continue', 'Weiter'],
  'language': ['Bahasa', 'Language', 'Sprache'],
  'setupTitle': ['Saling terhubung', 'Stay connected', 'In Verbindung bleiben'],
  'setupBody': [
    'Pilih peran HP ini. Tidak perlu email atau password.',
    'Choose this phone’s role. No email or password needed.',
    'Wähle die Rolle dieses Handys. Ohne E-Mail oder Passwort.'
  ],
  'sender': [
    'Aku membagikan kabar',
    'I share my updates',
    'Ich teile meine Updates'
  ],
  'senderBody': [
    'Kirim kabar makan, tempat tinggal, dan lokasi opsional.',
    'Share meals, whereabouts, and optional location.',
    'Teile Mahlzeiten, Aufenthaltsstatus und optional deinen Standort.'
  ],
  'receiver': [
    'Aku menerima kabar',
    'I receive updates',
    'Ich empfange Updates'
  ],
  'receiverBody': [
    'Pantau kabar orang tersayang dengan kode pasangan.',
    'Follow a loved one’s updates with a pairing code.',
    'Verfolge die Updates einer vertrauten Person mit einem Kopplungscode.'
  ],
  'pairCode': ['Kode pasangan', 'Pairing code', 'Kopplungscode'],
  'pairHint': [
    'Tempel kode lengkap dari HP pengirim.',
    'Paste the full code from the sender’s phone.',
    'Füge den vollständigen Code vom sendenden Handy ein.'
  ],
  'connect': ['Hubungkan', 'Connect', 'Verbinden'],
  'invalidCode': [
    'Kode tidak valid. Periksa kode lengkapnya.',
    'Invalid code. Check that you pasted the full code.',
    'Ungültiger Code. Bitte den vollständigen Code prüfen.'
  ],
  'home': ['Beranda', 'Home', 'Start'],
  'history': ['Riwayat', 'History', 'Verlauf'],
  'settings': ['Pengaturan', 'Settings', 'Einstellungen'],
  'outside': ['Keluar', 'Out', 'Unterwegs'],
  'homeStatus': ['Kost', 'Home', 'Zuhause'],
  'meal': ['Makan', 'Meal', 'Mahlzeit'],
  'atHome': ['Di kost', 'At home', 'Zuhause'],
  'atPlace': ['Di {x}', 'At {x}', 'Bei {x}'],
  'unknown': ['Belum ada kabar', 'No update yet', 'Noch kein Update'],
  'actions': ['Beri kabar', 'Send an update', 'Update senden'],
  'source': ['Kabar dari {x}', 'Updates from {x}', 'Updates von {x}'],
  'latest': ['Kabar terakhir', 'Latest update', 'Letztes Update'],
  'lastMeal': ['Terakhir makan', 'Last meal', 'Letzte Mahlzeit'],
  'lastHome': ['Terakhir di {x}', 'Last at {x}', 'Zuletzt bei {x}'],
  'today': ['Hari ini', 'Today', 'Heute'],
  'yesterday': ['Kemarin', 'Yesterday', 'Gestern'],
  'unrecorded': ['Belum tercatat', 'Not recorded', 'Noch nicht erfasst'],
  'dailyMeals': ['Makan hari ini', 'Today’s meals', 'Heutige Mahlzeiten'],
  'mealCount': [
    '{x} dari 3 tercatat',
    '{x} of 3 recorded',
    '{x} von 3 erfasst'
  ],
  'senderDay': [
    'Tanggal & jadwal mengikuti HP pengirim.',
    'The date and meal schedule follow the sender’s phone.',
    'Datum und Essenszeiten richten sich nach dem sendenden Handy.'
  ],
  'breakfast': ['Sarapan', 'Breakfast', 'Frühstück'],
  'lunch': ['Makan siang', 'Lunch', 'Mittagessen'],
  'dinner': ['Makan malam', 'Dinner', 'Abendessen'],
  'otherMeal': ['Makan lainnya', 'Other meal', 'Andere Mahlzeit'],
  'confirmStatus': [
    'Periksa sebelum mengirim',
    'Review your update',
    'Update überprüfen'
  ],
  'send': ['Kirim status', 'Send update', 'Update senden'],
  'cancel': ['Batal', 'Cancel', 'Abbrechen'],
  'close': ['Tutup', 'Close', 'Schließen'],
  'auto': [
    'Otomatis sesuai jam',
    'Automatic by time',
    'Automatisch nach Uhrzeit'
  ],
  'chooseMeal': ['Waktu makan', 'Meal category', 'Mahlzeit wählen'],
  'mealKeepsPlace': [
    'Mencatat makan tidak mengubah status tempat tinggal.',
    'Recording a meal keeps your whereabouts unchanged.',
    'Eine Mahlzeit ändert deinen Aufenthaltsstatus nicht.'
  ],
  'shareLocation': [
    'Sertakan lokasi HP',
    'Include phone location',
    'Handystandort hinzufügen'
  ],
  'locationConsent': [
    'Lokasi diambil sekali saat mengirim dan dibagikan kepada pemilik kode pasangan.',
    'Location is sampled once when sending and shared with holders of your pairing code.',
    'Der Standort wird beim Senden einmal erfasst und mit Personen geteilt, die deinen Kopplungscode haben.'
  ],
  'locationTitle': [
    'Lokasi terakhir',
    'Last shared location',
    'Letzter geteilter Standort'
  ],
  'noLocation': [
    'Belum ada lokasi yang dibagikan.',
    'No location has been shared.',
    'Noch kein Standort geteilt.'
  ],
  'refreshLocation': [
    'Perbarui lokasi',
    'Update location',
    'Standort aktualisieren'
  ],
  'locationOld': [
    'Titik ini lebih dari 15 menit lalu; posisi sekarang bisa berbeda.',
    'This point is over 15 minutes old; the current position may differ.',
    'Dieser Punkt ist über 15 Minuten alt; der aktuelle Standort kann abweichen.'
  ],
  'placeOld': [
    'Status tempat ini lebih dari 6 jam lalu.',
    'This whereabouts update is over 6 hours old.',
    'Dieser Aufenthaltsstatus ist über 6 Stunden alt.'
  ],
  'detail': ['Detail', 'Details', 'Details'],
  'detailTitle': ['Detail kabar', 'Update details', 'Update-Details'],
  'localTime': [
    'Waktu di HP ini',
    'Time on this phone',
    'Zeit auf diesem Handy'
  ],
  'senderTime': [
    'Waktu di HP pengirim',
    'Time on the sender’s phone',
    'Zeit auf dem sendenden Handy'
  ],
  'timeZone': ['Zona waktu', 'Time zone', 'Zeitzone'],
  'recorded': ['Waktu kejadian', 'Event time', 'Zeitpunkt'],
  'gpsTime': [
    'Waktu pengambilan lokasi',
    'Location sampled at',
    'Standort erfasst um'
  ],
  'coordinates': ['Koordinat', 'Coordinates', 'Koordinaten'],
  'accuracy': [
    'Perkiraan akurasi',
    'Estimated accuracy',
    'Geschätzte Genauigkeit'
  ],
  'map': ['Lihat di peta', 'Open map', 'Karte öffnen'],
  'eventNoGps': [
    'Lokasi tidak disertakan pada catatan ini.',
    'No location was included with this update.',
    'Für dieses Update wurde kein Standort erfasst.'
  ],
  'eventGpsExpired': [
    'Koordinat catatan ini sudah tidak disimpan; hanya tiga titik riwayat terbaru disimpan.',
    'This update’s coordinates are no longer retained; only the three newest history points are kept.',
    'Die Koordinaten dieses Updates werden nicht mehr gespeichert; nur die drei neuesten Verlaufspunkte bleiben erhalten.'
  ],
  'gpsNote': [
    'Lokasi merupakan titik saat diambil, bukan pelacakan terus-menerus.',
    'This is the position when sampled, not continuous tracking.',
    'Dies ist der Standort zum Erfassungszeitpunkt, keine laufende Ortung.'
  ],
  'historyBody': [
    '12 kabar terbaru, lengkap dengan detailnya.',
    'Your 12 latest updates, with their details.',
    'Die 12 neuesten Updates mit ihren Details.'
  ],
  'emptyHistory': [
    'Cerita hari ini belum dimulai',
    'No updates yet',
    'Noch keine Updates'
  ],
  'emptyHistoryBody': [
    'Kabar yang dikonfirmasi akan muncul di sini.',
    'Confirmed updates will appear here.',
    'Bestätigte Updates werden hier angezeigt.'
  ],
  'profile': [
    'Profil di HP ini',
    'Profile on this phone',
    'Profil auf diesem Handy'
  ],
  'editName': ['Ubah panggilan', 'Change nickname', 'Rufnamen ändern'],
  'save': ['Simpan', 'Save', 'Speichern'],
  'appearance': ['Tampilan', 'Appearance', 'Darstellung'],
  'defaultTheme': ['Default', 'Default', 'Standard'],
  'relationshipTheme': [
    'In Relationship',
    'In Relationship',
    'In einer Beziehung'
  ],
  'defaultDescription': [
    'Tenang, hangat, dan sederhana.',
    'Calm, warm, and simple.',
    'Ruhig, warm und schlicht.'
  ],
  'relationshipDescription': [
    'Dua karakter, satu kabar kecil.',
    'Two characters, one little update.',
    'Zwei Figuren, ein kleines Update.'
  ],
  'light': ['Terang', 'Light', 'Hell'],
  'dark': ['Gelap', 'Dark', 'Dunkel'],
  'timeFormat': ['Format jam', 'Time format', 'Zeitformat'],
  'clock24': ['24 jam', '24-hour', '24 Stunden'],
  'clock12': ['12 jam · AM/PM', '12-hour · AM/PM', '12 Stunden · AM/PM'],
  'appearanceNote': [
    'Tema, bahasa, dan format jam hanya berlaku di HP ini.',
    'Theme, language, and time format apply only to this phone.',
    'Design, Sprache und Zeitformat gelten nur auf diesem Handy.'
  ],
  'daySceneNote': [
    'Langit pixel mengikuti pagi, siang, sore, dan malam. Mode terang/gelap tetap pilihanmu.',
    'The pixel sky follows morning, afternoon, evening, and night. Light/dark mode stays your choice.',
    'Der Pixelhimmel folgt Morgen, Tag, Abend und Nacht. Hell/dunkel bleibt deine Wahl.'
  ],
  'zoneNote': [
    'Jam mengikuti zona HP. Aktifkan zona waktu otomatis saat bepergian.',
    'Time follows your phone’s zone. Enable automatic time zones when travelling.',
    'Die Uhrzeit folgt der Handy-Zeitzone. Aktiviere auf Reisen die automatische Zeitzone.'
  ],
  'family': [
    'Hubungan & status',
    'Connection & updates',
    'Verbindung & Updates'
  ],
  'editLabels': [
    'Nama & tombol status',
    'Name & status buttons',
    'Name & Status-Tasten'
  ],
  'senderName': [
    'Nama yang dibagikan',
    'Shared sender name',
    'Geteilter Absendername'
  ],
  'schedule': ['Jadwal makan', 'Meal schedule', 'Essenszeiten'],
  'scheduleInvalid': [
    'Gunakan jam 0–24, berurutan tanpa tumpang tindih.',
    'Use hours 0–24, in order and without overlap.',
    'Verwende Stunden von 0–24, aufsteigend und ohne Überschneidung.'
  ],
  'confirmChange': [
    'Simpan perubahan ini?',
    'Save these changes?',
    'Änderungen speichern?'
  ],
  'sharedChange': [
    'Perubahan ini juga dikirim ke HP penerima.',
    'These changes are also sent to receiving phones.',
    'Diese Änderungen werden auch an empfangende Handys gesendet.'
  ],
  'shareCode': ['Kode pasangan', 'Pairing code', 'Kopplungscode'],
  'secretCode': [
    'Siapa pun yang memiliki kode ini dapat membaca kabar dan lokasi yang dibagikan.',
    'Anyone with this code can read your updates and shared locations.',
    'Jede Person mit diesem Code kann Updates und geteilte Standorte lesen.'
  ],
  'copy': ['Salin kode', 'Copy code', 'Code kopieren'],
  'share': ['Bagikan', 'Share', 'Teilen'],
  'copied': ['Kode disalin', 'Code copied', 'Code kopiert'],
  'connection': ['Koneksi', 'Connection', 'Verbindung'],
  'online': ['Terhubung', 'Connected', 'Verbunden'],
  'sending': ['Mengirim…', 'Sending…', 'Wird gesendet…'],
  'sent': ['Kabar terkirim', 'Update sent', 'Update gesendet'],
  'offline': [
    'Menunggu internet',
    'Waiting for internet',
    'Warten auf Internet'
  ],
  'paused': ['Koneksi dijeda', 'Connection paused', 'Verbindung pausiert'],
  'connecting': [
    'Menghubungkan…',
    'Connecting…',
    'Verbindung wird hergestellt…'
  ],
  'queued': [
    '{x} kabar menunggu dikirim',
    '{x} updates waiting to send',
    '{x} Updates warten auf das Senden'
  ],
  'pause': ['Jeda koneksi', 'Pause connection', 'Verbindung pausieren'],
  'resume': ['Aktifkan koneksi', 'Resume connection', 'Verbindung fortsetzen'],
  'notifications': [
    'Pengaturan notifikasi',
    'Notification settings',
    'Benachrichtigungen'
  ],
  'widget': ['Tambahkan widget', 'Add widget', 'Widget hinzufügen'],
  'battery': [
    'Pengaturan baterai aplikasi',
    'App battery settings',
    'Akku-Einstellungen der App'
  ],
  'batteryNote': [
    'Pembatasan baterai HP dapat menunda kabar. Setelah paksa berhenti atau restart, buka abc lagi.',
    'Phone battery limits can delay updates. After a force-stop or restart, open abc again.',
    'Akku-Beschränkungen können Updates verzögern. Öffne abc nach einem Neustart oder erzwungenen Stopp erneut.'
  ],
  'privacy': ['Privasi & data', 'Privacy & data', 'Datenschutz & Daten'],
  'privacyBody': [
    'Kabar dan lokasi opsional dienkripsi. Kode pasangan memberikan akses membaca.',
    'Updates and optional locations are encrypted. The pairing code grants read access.',
    'Updates und optionale Standorte sind verschlüsselt. Der Kopplungscode gewährt Lesezugriff.'
  ],
  'clearGps': [
    'Hapus lokasi yang dibagikan',
    'Remove shared locations',
    'Geteilte Standorte entfernen'
  ],
  'clearGpsBody': [
    'Koordinat dihapus dari kabar terbaru. Salinan lama di perangkat lain atau relay tidak dapat ditarik kembali.',
    'Coordinates are removed from the latest update. Old copies on other devices or the relay cannot be recalled.',
    'Koordinaten werden aus dem aktuellen Update entfernt. Alte Kopien auf anderen Geräten oder im Relay können nicht zurückgerufen werden.'
  ],
  'clearHistory': ['Hapus riwayat', 'Clear history', 'Verlauf löschen'],
  'clearHistoryBody': [
    'Status dan riwayat dikosongkan lalu dikirim ke penerima. Salinan lama dapat tetap ada.',
    'Clear your status and history and send the reset to receivers. Old copies may remain.',
    'Status und Verlauf werden geleert und der Reset an Empfänger gesendet. Alte Kopien können bestehen bleiben.'
  ],
  'rotate': [
    'Ganti kode pasangan',
    'Replace pairing code',
    'Kopplungscode erneuern'
  ],
  'rotateBody': [
    'Kode lama berhenti menerima kabar baru. Hubungkan ulang HP dengan kode yang baru.',
    'The old code stops receiving new updates. Reconnect phones using the new code.',
    'Der alte Code empfängt keine neuen Updates mehr. Verbinde Handys mit dem neuen Code erneut.'
  ],
  'disconnect': [
    'Putuskan HP ini',
    'Disconnect this phone',
    'Dieses Handy trennen'
  ],
  'disconnectBody': [
    'Kode dan kabar di HP ini dihapus. HP lain tetap menyimpan kabar terakhir.',
    'The code and updates on this phone are removed. Other phones keep their last update.',
    'Code und Updates auf diesem Handy werden entfernt. Andere Handys behalten ihr letztes Update.'
  ],
  'uninstall': ['Uninstall abc', 'Uninstall abc', 'abc deinstallieren'],
  'uninstallBody': [
    'Sistem akan meminta konfirmasi penghapusan aplikasi.',
    'The system will ask you to confirm removing the app.',
    'Das System fragt nach einer Bestätigung zum Entfernen der App.'
  ],
  'queueFull': [
    'Antrean 25 kabar penuh. Hubungkan internet sebelum menambah kabar.',
    'The 25-update queue is full. Connect to the internet before adding more.',
    'Die Warteschlange mit 25 Updates ist voll. Verbinde dich zuerst mit dem Internet.'
  ],
  'error': [
    'Belum berhasil. Coba lagi.',
    'That didn’t work. Please try again.',
    'Das hat nicht geklappt. Bitte erneut versuchen.'
  ],
  'retry': ['Coba lagi', 'Try again', 'Erneut versuchen'],
  'locationDenied': [
    'Izin lokasi belum diberikan; status tetap dicatat tanpa titik baru.',
    'Location permission was not granted; the status was saved without a new point.',
    'Die Standortberechtigung wurde nicht erteilt; der Status wurde ohne neuen Punkt gespeichert.'
  ],
  'locationUnavailable': [
    'Lokasi belum didapat; status tetap dicatat tanpa titik baru.',
    'Location was unavailable; the status was saved without a new point.',
    'Der Standort war nicht verfügbar; der Status wurde ohne neuen Punkt gespeichert.'
  ],
  'locationFailed': [
    'Lokasi belum bisa dibagikan. Aktifkan lokasi dan izinnya, lalu coba lagi.',
    'Location could not be shared. Enable location and its permission, then retry.',
    'Der Standort konnte nicht geteilt werden. Aktiviere Ortung und Berechtigung und versuche es erneut.'
  ],
  'saved': ['Perubahan disimpan', 'Changes saved', 'Änderungen gespeichert'],
  'version': [
    'abc 0.5.0 · versi uji',
    'abc 0.5.0 · test version',
    'abc 0.5.0 · Testversion'
  ],
  'iosWidget': [
    'Tahan layar utama → Tambah Widget → abc. Pembaruan mengikuti iOS.',
    'Hold the Home Screen → Add Widget → abc. Refresh timing is managed by iOS.',
    'Startbildschirm gedrückt halten → Widget hinzufügen → abc. iOS steuert die Aktualisierung.'
  ],
  'iosUninstall': [
    'Tahan ikon abc di layar utama → Hapus App → Hapus App.',
    'Hold the abc icon on the Home Screen → Remove App → Delete App.',
    'Halte das abc-Symbol auf dem Startbildschirm gedrückt → App entfernen → App löschen.'
  ],
  'pushServer': [
    'Notifikasi iPhone saat tertutup',
    'iPhone notifications while closed',
    'iPhone-Benachrichtigungen bei geschlossener App'
  ],
  'pushNote': [
    'Memerlukan server notifikasi Apple dari pengelola aplikasi.',
    'Requires an Apple notification server set up by the app owner.',
    'Erfordert einen Apple-Benachrichtigungsserver des App-Betreibers.'
  ],
};
