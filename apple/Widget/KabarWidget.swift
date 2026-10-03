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
            let boundaries=[5,11,15,18].compactMap{Calendar.current.nextDate(after:entry.date,matching:DateComponents(hour:$0),matchingPolicy:.nextTime)}.sorted()
            let entries=[entry]+boundaries.map{KabarEntry(date:$0,state:entry.state,paired:entry.paired)}
            completion(Timeline(entries:entries,policy:.after(Date().addingTimeInterval(15*60))))
        }
    }
}
struct KabarWidgetView: View {
    var entry: KabarEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var together: Bool { SharedStore.defaults.bool(forKey:"appearanceRelationship") }
    private var dark: Bool { SharedStore.defaults.bool(forKey:"appearanceDark") }
    private var palette: KabarPalette { KabarPalette(together:together,dark:dark) }
    private var animate:Bool { !reduceMotion && !ProcessInfo.processInfo.isLowPowerModeEnabled && (SharedStore.defaults.dictionary(forKey:"abcProfile")?["animations"] as? Bool ?? true) }
    private var phase:String {
        let names=[PhoneText.text("Pagi","Morning","Morgen"),PhoneText.text("Siang","Daytime","Tag"),PhoneText.text("Sore","Evening","Abend"),PhoneText.text("Malam","Night","Nacht")]
        return names[LocalClock.phase(Int64(entry.date.timeIntervalSince1970*1000),zone:.current)]
    }
    var content: some View {
        VStack(alignment:.leading,spacing:8) {
            HStack {Text(entry.paired ? entry.state.name : "abc").font(.headline).lineLimit(1);Spacer();Text(together ? "Seirama":"abc").font(.caption2).foregroundStyle(palette.accent)}
            HStack(spacing:12) {
                DayScene(together:together,at:Int64(entry.date.timeIntervalSince1970*1000),action:entry.state.events.first?.kind ?? "idle")
                    .frame(width:family == .systemSmall ? 52:104,height:70).clipShape(RoundedRectangle(cornerRadius:12))
                    .id(entry.state.revision).transition(.opacity.combined(with:.scale(scale:0.94)))
                    .animation(animate ? .easeInOut(duration:0.5):nil,value:entry.state.revision)
                VStack(alignment:.leading,spacing:4) {
                    Text(phase).font(.caption2).foregroundStyle(palette.accent)
                if entry.paired {
                    Text(PhoneText.label(entry.state.locationText)).font(.subheadline.bold()).lineLimit(2)
                    Text(PhoneText.stamp(entry.state.locationAt)).font(.caption2).lineLimit(2)
                } else {Text(PhoneText.text("Ketuk untuk terhubung","Tap to connect","Zum Verbinden tippen")).font(.caption)}
                }.minimumScaleFactor(0.8)
            }
            if entry.paired && family != .systemSmall {
                HStack(alignment:.top,spacing:8) {Image(systemName:"fork.knife").foregroundStyle(palette.accent);Text(PhoneText.label(entry.state.mealCategory.isEmpty ? entry.state.meal:entry.state.mealCategory)+" · "+PhoneText.stamp(entry.state.mealAt)).lineLimit(2)}.font(.caption2)
                if family == .systemLarge {
                    Divider()
                    if let point=entry.state.gps {Label(point.city ?? PhoneText.text("Kota belum diketahui","City unavailable","Stadt unbekannt"),systemImage:"mappin.and.ellipse").font(.subheadline);Text(PhoneText.stamp(point.at)+" · "+point.zone).font(.caption2)}
                    Text(PhoneText.label(entry.state.home)+" · "+PhoneText.stamp(entry.state.homeAt)).font(.caption2)
                }
            }
        }.padding(4).foregroundStyle(palette.ink).environment(\.colorScheme,dark ? .dark:.light).widgetURL(URL(string:"kabar://home"))
    }
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) { content.containerBackground(palette.background,for:.widget) }
        else { content.background(palette.background) }
    }
}
@main struct KabarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:"KabarWidget",provider:KabarProvider()) { KabarWidgetView(entry:$0) }
            .configurationDisplayName("abc").description(PhoneText.text("Kabar, makan, dan suasana harimu.","Updates, meals, and your day.","Updates, Mahlzeiten und dein Tag.")).supportedFamilies([.systemSmall,.systemMedium,.systemLarge])
    }
}
