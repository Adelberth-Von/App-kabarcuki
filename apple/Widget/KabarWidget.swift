import SwiftUI
import WidgetKit
import KabarCore
struct KabarEntry: TimelineEntry { let date: Date; let state: KabarState; let paired: Bool }
struct KabarProvider: TimelineProvider {
    func placeholder(in context: Context) -> KabarEntry { var s = KabarState(); s.location = "home"; return KabarEntry(date:Date(),state:s,paired:true) }
    func getSnapshot(in context: Context, completion: @escaping (KabarEntry) -> Void) { completion(KabarEntry(date:Date(),state:SharedStore.state(),paired:SharedStore.pairing() != nil)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<KabarEntry>) -> Void) {
        Task {
            if SharedStore.defaults.string(forKey:"role") == "receiver", (SharedStore.defaults.object(forKey:"enabled") as? Bool ?? true), let pair = SharedStore.pairing(), let packet = try? await RelayClient.latest(pair) {
                _ = try? SharedStore.receive(packet, topic:pair.topic)
            }
            let entry = KabarEntry(date:Date(),state:SharedStore.state(),paired:SharedStore.pairing() != nil)
            completion(Timeline(entries:[entry],policy:.after(Date().addingTimeInterval(15*60))))
        }
    }
}
struct KabarWidgetView: View {
    var entry: KabarEntry
    private var together: Bool { SharedStore.defaults.bool(forKey:"appearanceRelationship") }
    private var dark: Bool { SharedStore.defaults.bool(forKey:"appearanceDark") }
    private var palette: KabarPalette { KabarPalette(together:together,dark:dark) }
    var content: some View {
        HStack(spacing:12) {
            VStack(alignment:.leading,spacing:6) {
                Text("abc · \(entry.state.name)").font(.headline).foregroundStyle(palette.accent)
                if entry.paired {
                    Text(PhoneText.label(entry.state.locationText)).font(.subheadline.bold())
                    Text(PhoneText.stamp(entry.state.locationAt)).font(.caption2)
                    Text("\(PhoneText.label(entry.state.meal)): \(PhoneText.stamp(entry.state.mealAt))").font(.caption2)
                    Text("\(PhoneText.label(entry.state.home)): \(PhoneText.stamp(entry.state.homeAt))").font(.caption2)
                } else { Text(PhoneText.text("Buka abc untuk menghubungkan HP","Open abc to connect your phone","Öffne abc, um dein Handy zu verbinden")).font(.caption) }
            }.minimumScaleFactor(0.8)
            Group { if together { DayScene(together:true,at:Int64(entry.date.timeIntervalSince1970*1000)) } else { PixelScene(outside:entry.state.location == "outside") } }.frame(width:70,height:70)
        }.padding(12).foregroundStyle(palette.ink).environment(\.colorScheme,dark ? .dark:.light).widgetURL(URL(string:"kabar://home"))
    }
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) { content.containerBackground(palette.background,for:.widget) }
        else { content.background(palette.background) }
    }
}
@main struct KabarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:"KabarWidget",provider:KabarProvider()) { KabarWidgetView(entry:$0) }
            .configurationDisplayName("abc").description(PhoneText.text("Lihat kabar terakhir.","See the latest update.","Das neueste Update ansehen.")).supportedFamilies([.systemMedium])
    }
}
