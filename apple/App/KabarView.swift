import SwiftUI
import KabarCore

private let cream = Color(red:0.97,green:0.96,blue:0.92)
private let sage = Color(red:0.29,green:0.42,blue:0.32)
struct KabarView: View {
    @EnvironmentObject var model: KabarModel
    @State private var joinCode = ""
    @State private var tab = 0
    @State private var editing = false
    @State private var confirm = ""
    var body: some View {
        TimelineView(.periodic(from:.now,by:60)) { _ in
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
            Button(confirm, role: .destructive) { if confirm == "Hapus riwayat" { model.clearHistory() } else if confirm == "Ganti kode pasangan" { model.beginSender() } else { model.disconnect() }; confirm = "" }
        }
        .sheet(isPresented: $editing) { EditView(state:model.state) { n,o,h,m,w in model.edit(name:n,outside:o,home:h,meal:m,windows:w) } }
    }
    private func page<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ScrollView { VStack(alignment:.leading,spacing:20) { content() }.padding(24).frame(maxWidth:600).frame(maxWidth:.infinity) }.background(cream)
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
            VStack(alignment:.leading,spacing:14) {
                PixelScene(outside:model.state.location == "outside").frame(height:150)
                Text(model.state.locationText).font(.title.bold())
                Text(model.state.when(model.state.locationAt)).foregroundStyle(.secondary)
                if model.state.stale { Text("Lokasi belum diperbarui lebih dari 6 jam").font(.caption).foregroundStyle(.orange) }
                Divider()
                Label("Terakhir \(model.state.meal.lowercased())",systemImage:"fork.knife").font(.headline)
                Text(model.state.when(model.state.mealAt)).foregroundStyle(.secondary)
                Label("Terakhir di \(model.state.home.lowercased())",systemImage:"house").font(.headline)
                Text(model.state.when(model.state.homeAt)).foregroundStyle(.secondary)
            }.padding(20).background(.white,in:RoundedRectangle(cornerRadius:24))
            if model.role == "sender" {
                Text("Update status").font(.headline)
                ViewThatFits(in:.horizontal) { actionRow; VStack(spacing:12) { actions } }
            }
            Text("Makan hari ini").font(.headline)
            ForEach(["Sarapan","Makan siang","Makan malam"],id:\.self) { category in
                Label(category + (model.state.hasMealToday(category) ? " · tercatat" : " · belum tercatat"),systemImage:model.state.hasMealToday(category) ? "checkmark.circle.fill" : "circle").foregroundStyle(sage)
            }
            Text(model.connection + (model.pending > 0 ? " · \(model.pending) antrean" : "")).font(.caption).foregroundStyle(.secondary)
        }
    }
    private var actionRow: some View { HStack(alignment:.top,spacing:10) { actions }.fixedSize(horizontal:true,vertical:false) }
    @ViewBuilder private var actions: some View {
        action(model.state.outside,"outside","figure.walk"); action(model.state.home,"home","house.fill"); action(model.state.meal,"meal","fork.knife")
    }
    private func action(_ label: String,_ kind: String,_ icon: String) -> some View {
        Button { model.record(kind) } label: { VStack(spacing:10) { Image(systemName:icon).font(.title2); Text(label).font(.headline).multilineTextAlignment(.center) }.frame(minWidth:68,minHeight:80).padding(12).frame(maxWidth:.infinity).background(Color(red:0.88,green:0.91,blue:0.83),in:RoundedRectangle(cornerRadius:18)) }.foregroundStyle(sage).accessibilityIdentifier(kind)
    }
    private var history: some View {
        page {
            Text("Riwayat kabar").font(.largeTitle.bold())
            if model.state.events.isEmpty { Text("Belum ada kabar. Status baru akan muncul di sini.").foregroundStyle(.secondary) }
            ForEach(Array(model.state.events.enumerated()),id:\.offset) { _, event in
                VStack(alignment:.leading,spacing:8) { Text(event.label).font(.headline); Text(model.state.when(event.at)).font(.subheadline).foregroundStyle(.secondary) }.padding(18).frame(maxWidth:.infinity,alignment:.leading).background(.white,in:RoundedRectangle(cornerRadius:18))
            }
        }
    }
    private var settings: some View {
        page {
            Text("Pengaturan").font(.largeTitle.bold())
            if model.role == "sender" {
                Button("Edit nama, tombol & jam makan") { editing = true }.buttonStyle(.bordered)
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
            Text("Kabar 0.2.0 · status manual").font(.caption).foregroundStyle(.secondary)
        }
    }
}
private struct EditView: View {
    @Environment(\.dismiss) var dismiss
    @State var state: KabarState
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
                ToolbarItem(placement:.confirmationAction) { Button("Simpan") { if save(state.name,state.outside,state.home,state.meal,state.windows) { dismiss() } }.disabled(!KabarState.validWindows(state.windows)) }
            }
        }
    }
}
