import SwiftUI
import KabarCore
import WidgetKit

private struct StatusDraft: Identifiable { let id = UUID(); var kind: String; var category: String? = nil }
struct KabarView: View {
    @EnvironmentObject var model: KabarModel
    @AppStorage("appearanceRelationship",store:SharedStore.defaults) private var together = false
    @AppStorage("appearanceDark",store:SharedStore.defaults) private var dark = false
    private var palette: KabarPalette { KabarPalette(together:together,dark:dark) }
    private var cream: Color { palette.background }
    private var sage: Color { palette.accent }
    @State private var joinCode = ""
    @State private var tab = 0
    @State private var editing = false
    @State private var confirm = ""
    @State private var draft: StatusDraft?
    var body: some View {
        TimelineView(.periodic(from:Date(timeIntervalSince1970:floor(Date().timeIntervalSince1970/60)*60),by:60)) { _ in
        Group {
            if model.role.isEmpty { welcome }
            else {
                TabView(selection: $tab) {
                    home.tabItem { Label("Beranda", systemImage:"house") }.tag(0)
                    history.tabItem { Label("Riwayat", systemImage:"clock") }.tag(1)
                    settings.tabItem { Label("Pengaturan", systemImage:"slider.horizontal.3") }.tag(2)
                }.tint(sage)
            }
        }
        }
        .alert("Kabar", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) { Button("Mengerti") { model.error = nil } } message: { Text(model.error ?? "") }
        .confirmationDialog(confirm, isPresented: Binding(get: { !confirm.isEmpty }, set: { if !$0 { confirm = "" } }), titleVisibility: .visible) {
            Button(confirm, role: confirm == "Bagikan lokasi HP" ? nil : .destructive) { if confirm == "Hapus riwayat" { model.clearHistory() } else if confirm == "Ganti kode pasangan" { model.beginSender() } else if confirm == "Bagikan lokasi HP" { model.refreshLocation() } else if confirm == "Hapus lokasi HP" { model.clearGps() } else { model.disconnect() }; confirm = "" }
        }
        .sheet(isPresented: $editing) { EditView(state:model.state) { n,o,h,m,w in model.edit(name:n,outside:o,home:h,meal:m,windows:w) } }
        .sheet(item:$draft) { value in StatusConfirmView(draft:value,state:model.state) { category,share in SharedStore.defaults.set(share,forKey:"shareLocation"); model.record(value.kind,meal:category,share:share) } }
    }
    private func page<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ScrollView { VStack(alignment:.leading,spacing:20) { content() }.padding(24).frame(maxWidth:600).frame(maxWidth:.infinity) }.background(cream).foregroundStyle(palette.ink)
    }
    private var welcome: some View {
        page {
            Text("kabar.").font(.system(size:44,weight:.bold,design:.rounded)).foregroundStyle(sage)
            PixelScene().frame(height:180)
            Text("Kabar kecil.\nTenang untuk keluarga.").font(.largeTitle.bold())
            Text("Bagikan status makan dan tempat tinggal dengan satu ketukan. Hubungkan HP memakai kode pasangan.").foregroundStyle(.secondary)
            Button("Aku membagikan kabar") { model.beginSender() }.buttonStyle(.borderedProminent).tint(sage).controlSize(.large).accessibilityIdentifier("sender-setup")
            Text("Menerima kabar").font(.headline)
            TextField("Tempel kode pasangan",text:$joinCode,axis:.vertical).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
            Button("Hubungkan HP ini") { model.join(joinCode) }.buttonStyle(.bordered).controlSize(.large)
            Text("iPhone & iPad · iOS 16 ke atas").font(.caption).foregroundStyle(.secondary)
        }
    }
    private var home: some View {
        page {
            HStack { Text("kabar.").font(.largeTitle.bold()).foregroundStyle(sage); Spacer(); Text(model.role == "sender" ? "PENGIRIM" : "PENERIMA").font(.caption.monospaced()).foregroundStyle(sage) }
            Text("Kabar \(model.state.name)").font(.title2.bold())
            dayCard
            if model.state.zone != TimeZone.current.identifier { Text("Di HP pengirim · "+LocalClock.clock(zone:model.state.timeZone)+"\nZona terakhir saat mengirim kabar.").font(.caption).foregroundStyle(.secondary) }
            VStack(alignment:.leading,spacing:14) {
                PixelScene(outside:model.state.location == "outside").frame(height:86)
                Text(model.state.locationText).font(.title.bold())
                Text(LocalClock.when(model.state.locationAt)).foregroundStyle(.secondary)
                if model.state.stale { Text("Lokasi belum diperbarui lebih dari 6 jam").font(.caption).foregroundStyle(.orange) }
                Divider()
                Label("Terakhir \(model.state.meal.lowercased())",systemImage:"fork.knife").font(.headline)
                Text(LocalClock.when(model.state.mealAt)).foregroundStyle(.secondary)
                Label("Terakhir di \(model.state.home.lowercased())",systemImage:"house").font(.headline)
                Text(LocalClock.when(model.state.homeAt)).foregroundStyle(.secondary)
            }.padding(20).background(palette.surface,in:RoundedRectangle(cornerRadius:24))
            if model.role == "sender" {
                Text("Update status").font(.headline)
                ViewThatFits(in:.horizontal) { actionRow; VStack(spacing:12) { actions } }
            }
            Text("Makan hari ini").font(.headline)
            Text("Tanggal & jadwal mengikuti HP pengirim · "+LocalClock.shortZone(model.state.timeZone,at:KabarState.now)).font(.caption).foregroundStyle(.secondary)
            Text(model.role == "sender" ? "Ketuk kategori untuk mencatat atau memperbarui waktu makan." : "Mengikuti catatan HP pengirim.").font(.caption).foregroundStyle(.secondary)
            ForEach(["Sarapan","Makan siang","Makan malam"],id:\.self) { category in
                let at = category == "Sarapan" ? model.state.breakfastAt : category == "Makan siang" ? model.state.lunchAt : model.state.dinnerAt
                Button { if model.role == "sender" { draft = StatusDraft(kind:"meal",category:category) } } label: {
                    HStack { Image(systemName:model.state.hasMealToday(category) ? "checkmark.circle.fill" : "plus.circle"); VStack(alignment:.leading,spacing:5) { Text(category).font(.headline); Text(model.state.hasMealToday(category) ? LocalClock.when(at) : "Belum tercatat").font(.caption) }; Spacer(); if model.role == "sender" { Image(systemName:"chevron.right").font(.caption) } }.padding(16).background(palette.surface,in:RoundedRectangle(cornerRadius:16))
                }.foregroundStyle(sage).disabled(model.role != "sender" || model.locating).accessibilityIdentifier("meal-"+category)
            }
            if model.state.mealCategory == "Makan", model.state.day(model.state.mealAt) == model.state.day(KabarState.now) { Text("Makan lainnya · "+LocalClock.when(model.state.mealAt)).font(.caption).foregroundStyle(.secondary) }
            gpsCard
            if !model.locationNote.isEmpty { Text(model.locationNote).font(.caption).foregroundStyle(.secondary) }
            Text(model.connection + (model.pending > 0 ? " · \(model.pending) antrean" : "")).font(.caption).foregroundStyle(.secondary)
        }
    }
    private var dayCard: some View {
        VStack(alignment:.leading,spacing:0) {
            DayScene(together:together).id("hero-\(together)-\(dark)-\(LocalClock.phase())").frame(height:108)
            VStack(alignment:.leading,spacing:5) {
                Text("Selamat "+LocalClock.phaseName().lowercased()+(together ? " ♥":"")).font(.subheadline.bold()).foregroundStyle(sage)
                Text(LocalClock.clock()).font(.headline).accessibilityIdentifier("local-clock")
                Text(together ? "Dekat dalam setiap kabar." : "Kabar kecil, bikin tenang.").font(.caption).foregroundStyle(.secondary)
            }.padding(16)
        }.frame(maxWidth:.infinity,alignment:.leading).background(palette.surface).clipShape(RoundedRectangle(cornerRadius:20))
    }
    private var appearanceSettings: some View {
        VStack(alignment:.leading,spacing:14) {
            Text("Appearance").font(.title2.bold())
            Text("Tema dan mode hanya berlaku di HP ini.").font(.caption).foregroundStyle(.secondary)
            themeChoice(false,"Default","Rumah hangat · sage & krem")
            themeChoice(true,"In Relationship","Dua karakter · hati · rose & lilac")
            Picker("Mode tampilan",selection:$dark) { Text("Terang").tag(false); Text("Gelap").tag(true) }.pickerStyle(.segmented).accessibilityIdentifier("appearance-mode")
            Text("Suasana pixel otomatis: pagi 05–11, siang 11–15, sore 15–18, malam 18–05. Mode terang/gelap tetap pilihanmu.").font(.caption).foregroundStyle(.secondary)
            Text("Jam & negara mengikuti zona waktu HP. Aktifkan zona waktu otomatis saat bepergian; tidak membutuhkan izin GPS.").font(.caption).foregroundStyle(.secondary)
        }.onChange(of:together) { _ in WidgetCenter.shared.reloadAllTimelines() }.onChange(of:dark) { _ in WidgetCenter.shared.reloadAllTimelines() }
    }
    private func themeChoice(_ value: Bool,_ name: String,_ detail: String) -> some View {
        Button { together = value } label: {
            VStack(alignment:.leading,spacing:8) {
                DayScene(together:value).id("preview-\(value)-\(dark)-\(LocalClock.phase())").frame(height:72)
                Text((together == value ? "✓  ":"")+name).font(.headline)
                Text(detail).font(.caption)
            }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(together == value ? palette.tint:palette.surface,in:RoundedRectangle(cornerRadius:18))
        }.buttonStyle(.plain).accessibilityIdentifier(value ? "theme-relationship":"theme-default").accessibilityAddTraits(together == value ? .isSelected:[])
    }
    private var actionRow: some View { HStack(alignment:.top,spacing:10) { actions }.fixedSize(horizontal:true,vertical:false) }
    @ViewBuilder private var actions: some View {
        action(model.state.outside,"outside","figure.walk"); action(model.state.home,"home","house.fill"); action(model.state.meal,"meal","fork.knife")
    }
    private func action(_ label: String,_ kind: String,_ icon: String) -> some View {
        Button { draft = StatusDraft(kind:kind) } label: { VStack(spacing:10) { Image(systemName:icon).font(.title2); Text(label).font(.headline).multilineTextAlignment(.center) }.frame(minWidth:68,minHeight:80).padding(12).frame(maxWidth:.infinity).background(palette.tint,in:RoundedRectangle(cornerRadius:18)) }.foregroundStyle(sage).disabled(model.locating).accessibilityIdentifier(kind)
    }
    private func pointTime(_ point: GpsPoint) -> String { LocalClock.when(point.at) }
    private func eventTime(_ event: KabarEvent) -> String { LocalClock.when(event.at) }
    private func mapLink(_ point: GpsPoint) -> some View { Link("Lihat di peta",destination:URL(string:"https://maps.apple.com/?ll=\(point.lat),\(point.lon)&q=Kabar")!).buttonStyle(.bordered).tint(sage) }
    private var gpsCard: some View {
        VStack(alignment:.leading,spacing:12) {
            Text("Lokasi HP").font(.headline)
            if let point = model.state.gps {
                Text(point.coordinates+" · perkiraan akurasi ±\(Int(point.accuracy)) m").font(.subheadline)
                Text("Diambil "+pointTime(point)).font(.caption).foregroundStyle(.secondary)
                if point.old { Text("Lokasi terakhir sudah lebih dari 15 menit. Posisi sekarang bisa berbeda.").font(.caption).foregroundStyle(.orange) }
                mapLink(point)
            } else { Text("Pengirim belum membagikan lokasi HP.").font(.subheadline).foregroundStyle(.secondary) }
            if model.role == "sender" { Button(model.locating ? "Mengambil lokasi…" : "Perbarui lokasi") { confirm = "Bagikan lokasi HP" }.buttonStyle(.bordered).disabled(model.locating) }
            Text("Lokasi diambil saat memberi kabar. Bukan pelacakan otomatis.").font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(maxWidth:.infinity,alignment:.leading).background(palette.surface,in:RoundedRectangle(cornerRadius:20))
    }
    private var history: some View {
        page {
            Text("Riwayat kabar").font(.largeTitle.bold())
            if model.state.events.isEmpty { Text("Belum ada kabar. Status baru akan muncul di sini.").foregroundStyle(.secondary) }
            ForEach(Array(model.state.events.enumerated()),id:\.offset) { _, event in
                VStack(alignment:.leading,spacing:8) { Text(event.label).font(.headline); Text(eventTime(event)).font(.subheadline).foregroundStyle(.secondary); if let point = event.gps { Text("Diambil "+pointTime(point)).font(.caption).foregroundStyle(.secondary); mapLink(point) } }.padding(18).frame(maxWidth:.infinity,alignment:.leading).background(palette.surface,in:RoundedRectangle(cornerRadius:18))
            }
        }
    }
    private var settings: some View {
        page {
            Text("Pengaturan").font(.largeTitle.bold())
            appearanceSettings
            if model.role == "sender" {
                Button("Edit nama, tombol & jam makan") { editing = true }.buttonStyle(.bordered)
                Button("Hapus lokasi yang dibagikan",role:.destructive) { confirm = "Hapus lokasi HP" }
                Text("Nonaktifkan Sertakan lokasi HP pada konfirmasi untuk menghentikan pengambilan berikutnya. Hapus lokasi mengosongkan koordinat pada kabar terbaru; salinan lama tidak dapat ditarik kembali.").font(.caption).foregroundStyle(.secondary)
                ShareLink(item:model.code) { Label("Bagikan kode pasangan",systemImage:"square.and.arrow.up") }.buttonStyle(.bordered)
                Text("Kode ini memberi akses membaca kabar. Bagikan kepada keluarga yang dipercaya.").font(.caption).foregroundStyle(.secondary)
                Button("Ganti kode pasangan",role:.destructive) { confirm = "Ganti kode pasangan" }
                Button("Hapus riwayat",role:.destructive) { confirm = "Hapus riwayat" }
                Text("Saat aplikasi berada di latar belakang, kabar baru dalam antrean dikirim setelah aplikasi dibuka lagi.").font(.caption).foregroundStyle(.secondary)
            }
            Button(model.enabled ? "Jeda koneksi" : "Aktifkan koneksi") { model.pause() }.buttonStyle(.bordered)
            Button("Izinkan notifikasi") { model.requestNotifications() }.buttonStyle(.bordered)
            Button("Buka pengaturan iPhone") { if let url = URL(string:UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
            Text("Widget").font(.headline)
            Text("Tahan layar utama > Tambah Widget > Kabar. Ketuk widget untuk membuka aplikasi. Waktu pembaruan widget ditentukan iOS.").font(.subheadline).foregroundStyle(.secondary)
            if model.role == "receiver" {
                Text("Notifikasi saat aplikasi tertutup").font(.headline)
                Text("\(model.pushEndpoint.isEmpty ? "Belum disiapkan." : "Server tersimpan.") Memerlukan server notifikasi Apple dari pengelola aplikasi.").font(.subheadline).foregroundStyle(.secondary)
                TextField("https://server-kabar.example",text:$model.pushEndpoint).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).textFieldStyle(.roundedBorder)
                Button("Simpan server notifikasi") { model.savePushEndpoint(); model.requestNotifications() }.buttonStyle(.bordered)
            }
            Divider()
            Button("Putuskan hubungan HP ini",role:.destructive) { confirm = "Putuskan hubungan HP ini" }
            Text("Menghapus data lokal dan kode pasangan. Untuk menghapus aplikasi, tahan ikon Kabar > Hapus App. iOS mengatur penghapusan aplikasi.").font(.caption).foregroundStyle(.secondary)
            Text("Kabar 0.4.0 · lokasi opsional · maksimal 3 titik pada riwayat terbaru").font(.caption).foregroundStyle(.secondary)
        }
    }
}
private struct EditView: View {
    @Environment(\.dismiss) var dismiss
    @State var state: KabarState
    @State private var confirmSave = false
    let save: (String,String,String,String,[Int]) -> Bool
    var body: some View {
        NavigationStack {
            Form {
                Section("Nama dan tombol · 1–24 karakter") {
                    TextField("Nama",text:$state.name);TextField("Keluar",text:$state.outside);TextField("Kost",text:$state.home);TextField("Makan",text:$state.meal)
                }
                Section("Jam makan · jam akhir tidak termasuk") {
                    ForEach(0..<3) { i in
                        Text(["Sarapan","Makan siang","Makan malam"][i]).font(.headline)
                        Stepper("Mulai \(state.windows[i*2]):00",value:$state.windows[i*2],in:0...23)
                        Stepper("Sampai \(state.windows[i*2+1]):00",value:$state.windows[i*2+1],in:1...24)
                    }
                    if !KabarState.validWindows(state.windows) { Text("Jam makan tidak boleh saling tumpang tindih.").foregroundStyle(.red) }
                }
            }.navigationTitle("Personalisasi").toolbar {
                ToolbarItem(placement:.cancellationAction) { Button("Batal") { dismiss() } }
                ToolbarItem(placement:.confirmationAction) { Button("Simpan") { confirmSave = true }.disabled(!KabarState.validWindows(state.windows)) }
            }
            .confirmationDialog("Konfirmasi perubahan",isPresented:$confirmSave,titleVisibility:.visible) { Button("Ya, simpan") { if save(state.name,state.outside,state.home,state.meal,state.windows) { dismiss() } } } message: { Text("Nama: \(state.name)\nTombol: \(state.outside), \(state.home), \(state.meal)\nPerubahan dikirim ke penerima.") }
        }
    }
}
private struct StatusConfirmView: View {
    @Environment(\.dismiss) private var dismiss
    let draft: StatusDraft
    @State var state: KabarState
    let save: (String?,Bool) -> Void
    @State private var selected = "Otomatis"
    @State private var share = SharedStore.defaults.bool(forKey:"shareLocation")
    var body: some View {
        NavigationStack {
            Form {
                Section("Kabar yang akan dikirim") {
                    Text(draft.kind == "home" ? "Di "+state.home.lowercased() : draft.kind == "outside" ? state.outside : draft.category ?? state.meal).font(.title2.bold())
                    Text(LocalClock.clock()).font(.subheadline)
                    if draft.kind == "meal", draft.category == nil { Picker("Waktu makan",selection:$selected) { ForEach(["Otomatis","Sarapan","Makan siang","Makan malam","Makan lainnya"],id:\.self) { Text($0) } } }
                    if draft.kind == "meal" { Text("Kategori terpilih diperbarui dengan waktu sekarang. Status tempat tinggal tetap.").font(.caption) }
                }
                Section("Lokasi opsional") { Toggle("Sertakan lokasi HP",isOn:$share); Text("Lokasi diambil saat memberi kabar dan dibagikan kepada pemilik kode pasangan. Izin lokasi diminta ketika dipakai.").font(.caption) }
                Button("Kirim status") { let category = draft.category ?? (selected == "Otomatis" ? nil : selected == "Makan lainnya" ? "Makan" : selected); save(category,share); dismiss() }.accessibilityIdentifier("confirm-status")
            }.navigationTitle("Konfirmasi status").toolbar { ToolbarItem(placement:.cancellationAction) { Button("Batal") { dismiss() } } }
        }
    }
}
