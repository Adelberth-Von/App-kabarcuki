import SwiftUI
import WidgetKit
import KabarCore

struct KabarEntry: TimelineEntry {
    let date: Date
    let state: KabarState
    let peer: KabarState?
    let paired: Bool
    let twoWay: Bool
    let reciprocal: Bool
}
struct KabarProvider: TimelineProvider {
    private func entry() -> KabarEntry {
        let peer=SharedStore.peerState()
        return KabarEntry(date:Date(),state:SharedStore.state(),peer:peer?.revision == 0 && peer?.locationAt == 0 && peer?.mealAt == 0 ? nil:peer,paired:SharedStore.pairing() != nil,twoWay:SharedStore.isTwoWay,reciprocal:SharedStore.reciprocity == "active")
    }
    func placeholder(in context: Context) -> KabarEntry {
        var s=KabarState();s.name="Cuki";s.location="home";s.locationAt=KabarState.now
        return KabarEntry(date:Date(),state:s,peer:nil,paired:true,twoWay:false,reciprocal:false)
    }
    func getSnapshot(in context: Context, completion: @escaping (KabarEntry) -> Void) { completion(entry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<KabarEntry>) -> Void) {
        Task {
            if (SharedStore.defaults.object(forKey:"enabled") as? Bool ?? true),let pair=SharedStore.incomingPairing(),let packet=try? await RelayClient.latest(pair) {
                _=try? SharedStore.receive(packet,topic:pair.topic)
            }
            let first=entry()
            let boundaries=[5,11,15,18].compactMap{Calendar.current.nextDate(after:first.date,matching:DateComponents(hour:$0),matchingPolicy:.nextTime)}.sorted()
            let entries=[first]+boundaries.map{KabarEntry(date:$0,state:first.state,peer:first.peer,paired:first.paired,twoWay:first.twoWay,reciprocal:first.reciprocal)}
            completion(Timeline(entries:entries,policy:.after(Date().addingTimeInterval(15*60))))
        }
    }
}

struct KabarWidgetView: View {
    let entry: KabarEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var dark: Bool { SharedStore.defaults.bool(forKey:"appearanceDark") }
    private var palette: KabarPalette { KabarPalette(together:entry.twoWay,dark:dark) }
    private var animate: Bool { !reduceMotion && !ProcessInfo.processInfo.isLowPowerModeEnabled && (SharedStore.defaults.dictionary(forKey:"abcProfile")?["animations"] as? Bool ?? true) }
    private var phase: String {
        [PhoneText.text("Pagi","Morning","Morgen"),PhoneText.text("Siang","Daytime","Tag"),PhoneText.text("Sore","Evening","Abend"),PhoneText.text("Malam","Night","Nacht")][LocalClock.phase(Int64(entry.date.timeIntervalSince1970*1000),zone:.current)]
    }
    private var phaseIcon: String { ["sunrise.fill","sun.max.fill","sunset.fill","moon.stars.fill"][LocalClock.phase(Int64(entry.date.timeIntervalSince1970*1000),zone:.current)] }
    private var canSend: Bool { SharedStore.canSend }
    private var enabled: Bool { SharedStore.defaults.object(forKey:"enabled") as? Bool ?? true }
    private func status(_ state:KabarState) -> String {
        if state.events.first?.kind == "meal",state.mealAt>0 {return PhoneText.label(state.mealCategory)}
        if state.location == "home" {return PhoneText.text("Di ","At ","In ")+PhoneText.label(state.home)}
        if state.location == "outside" {return PhoneText.label(state.outside)}
        return PhoneText.text("Belum ada kabar","No update yet","Noch kein Update")
    }
    private func statusAt(_ state:KabarState) -> Int64 {state.events.first?.kind == "meal" && state.mealAt>0 ? state.mealAt:state.locationAt}
    var body: some View {
        if #available(iOSApplicationExtension 17.0, *) { content.containerBackground(palette.background,for:.widget) }
        else { content.padding(12).background(palette.background) }
    }
    private var content: some View {
        GeometryReader { geometry in
            VStack(alignment:.leading,spacing:family == .systemSmall ? 6:8) {
                header
                if !entry.paired {
                    scene(height:max(38,geometry.size.height-78))
                    Text(PhoneText.text("Bagikan kabarmu","Share your day","Teile deinen Tag")).font(.headline).lineLimit(1)
                    Text(PhoneText.text("Ketuk untuk menghubungkan HP","Tap to connect phones","Tippen, um Telefone zu verbinden")).font(.caption2).foregroundStyle(palette.muted).lineLimit(2)
                } else if family == .systemSmall {
                    small(height:geometry.size.height)
                } else if family == .systemMedium {
                    medium(height:geometry.size.height)
                } else {
                    large(height:geometry.size.height)
                }
            }.foregroundStyle(palette.ink).environment(\.colorScheme,dark ? .dark:.light)
        }.widgetURL(URL(string:"kabar://home"))
    }
    private var header: some View {
        HStack(spacing:6) {
            Image(systemName:entry.twoWay ? "heart.fill":"sparkles").font(.caption2).foregroundStyle(palette.accent)
            Text(entry.twoWay ? "Seirama":entry.paired ? entry.state.name:"abc").font(.system(size:13,weight:.bold)).lineLimit(1)
            Spacer(minLength:2)
            Label(phase,systemImage:phaseIcon).font(.system(size:9,weight:.medium)).labelStyle(.titleAndIcon).lineLimit(1).padding(.horizontal,6).padding(.vertical,4).background(palette.tint,in:Capsule()).foregroundStyle(palette.accent)
        }
    }
    private func scene(height:CGFloat) -> some View {
        DayScene(together:entry.twoWay,at:Int64(entry.date.timeIntervalSince1970*1000),action:entry.state.events.first?.kind ?? "idle")
            .aspectRatio(2.5,contentMode:.fill).frame(height:height).clipped()
            .clipShape(RoundedRectangle(cornerRadius:family == .systemSmall ? 11:16))
            .id(entry.state.revision)
            .transition(.opacity.combined(with:.scale(scale:0.96)))
            .animation(animate ? .easeInOut(duration:0.6):nil,value:entry.state.revision)
    }
    @ViewBuilder private func small(height:CGFloat) -> some View {
        scene(height:max(30,height-(entry.twoWay ? 111:82)))
        if entry.twoWay {
            HStack(alignment:.top,spacing:7) {
                tinyPerson(entry.state,own:true)
                Rectangle().fill(palette.tint).frame(width:1)
                tinyPerson(entry.peer,own:false)
            }.frame(maxWidth:.infinity).padding(7).background(palette.surface,in:RoundedRectangle(cornerRadius:11))
            Text(entry.reciprocal ? PhoneText.text("Saling berkabar ↗","Share both ways ↗","Gegenseitig teilen ↗"):PhoneText.text("Hubungkan kedua HP ↗","Link both phones ↗","Beide Telefone verbinden ↗")).font(.system(size:9)).foregroundStyle(palette.accent).lineLimit(1)
        } else {
            Text(status(entry.state)).font(.system(size:16,weight:.bold)).lineLimit(1).minimumScaleFactor(0.85)
            Text(PhoneText.stamp(statusAt(entry.state))).font(.system(size:10)).foregroundStyle(palette.muted).lineLimit(2)
        }
    }
    private func tinyPerson(_ state:KabarState?,own:Bool) -> some View {
        VStack(alignment:.leading,spacing:3) {
            Text(own ? PhoneText.text("Kamu","You","Du"):state?.name ?? PhoneText.text("Pasangan","Partner","Partner")).font(.system(size:9,weight:.medium)).foregroundStyle(palette.muted).lineLimit(1)
            Text(state.map{status($0)} ?? "…").font(.system(size:12,weight:.bold)).lineLimit(1).minimumScaleFactor(0.75)
            Text(state.map{PhoneText.stamp(statusAt($0))} ?? PhoneText.text("Belum terhubung","Not linked yet","Noch nicht verbunden")).font(.system(size:8)).foregroundStyle(palette.muted).lineLimit(2)
        }.frame(maxWidth:.infinity,alignment:.leading)
    }
    private func medium(height:CGFloat) -> some View {
        HStack(alignment:.top,spacing:9) {
            VStack(alignment:.leading,spacing:7) {
                scene(height:max(52,height-62))
                Label(enabled ? PhoneText.text("Buka kabar","Open update","Update öffnen"):PhoneText.text("Dijeda","Paused","Pausiert"),systemImage:enabled ? "arrow.up.right":"pause.fill").font(.system(size:10,weight:.medium)).foregroundStyle(palette.accent).lineLimit(1)
            }.frame(maxWidth:.infinity)
            VStack(alignment:.leading,spacing:6) {
                person(entry.state,own:entry.twoWay,compact:true)
                if entry.twoWay { person(entry.peer,own:false,compact:true) }
                else { fact("fork.knife",mealText(entry.state),compact:true) }
            }.frame(maxWidth:.infinity)
        }
    }
    private func large(height:CGFloat) -> some View {
        VStack(alignment:.leading,spacing:7) {
            scene(height:max(82,height-(entry.twoWay ? 225:201)))
            if entry.twoWay {
                HStack(alignment:.top,spacing:7) {
                    person(entry.state,own:true,compact:false)
                    person(entry.peer,own:false,compact:false)
                }
            } else { person(entry.state,own:false,compact:false) }
            fact("fork.knife",mealText(entry.state),compact:false)
            if let point=entry.state.gps {
                fact("mappin.and.ellipse",point.city?.isEmpty == false ? point.city!:PhoneText.text("Kota belum diketahui","City unavailable","Stadt unbekannt"),compact:false)
            } else if !entry.twoWay {
                fact("house.fill",PhoneText.label(entry.state.home)+" · "+PhoneText.stamp(entry.state.homeAt),compact:false)
            }
            if canSend { actions }
            else { Label(PhoneText.text("Ketuk untuk detail","Tap for details","Für Details tippen"),systemImage:"arrow.up.right").font(.caption2).foregroundStyle(palette.accent) }
        }
    }
    private func person(_ state:KabarState?,own:Bool,compact:Bool) -> some View {
        Link(destination:URL(string:entry.twoWay && !own ? "kabar://home?peer=1":"kabar://home")!) {
        VStack(alignment:.leading,spacing:compact && entry.twoWay ? 2:4) {
            if entry.twoWay {Text(own ? PhoneText.text("Kamu · ","You · ","Du · ")+(state?.name ?? ""):state?.name ?? PhoneText.text("Pasangan","Partner","Partner")).font(.system(size:compact ? 8:9,weight:.medium)).foregroundStyle(palette.muted).lineLimit(1)}
            Text(state.map{status($0)} ?? PhoneText.text("Menunggu kabar","Waiting for update","Warte auf Update")).font(.system(size:compact ? 13:17,weight:.bold)).lineLimit(1).minimumScaleFactor(0.78)
            Text(state.map{PhoneText.stamp(statusAt($0))} ?? PhoneText.text("Hubungkan kedua HP","Link both phones","Beide Telefone verbinden")).font(.system(size:compact ? 9:10)).foregroundStyle(palette.muted).lineLimit(compact && entry.twoWay ? 1:2)
        }.frame(maxWidth:.infinity,alignment:.leading).padding(compact ? 6:10).background(palette.surface,in:RoundedRectangle(cornerRadius:13))
        }
    }
    private func mealText(_ state:KabarState) -> String { state.mealAt == 0 ? PhoneText.text("Makan belum tercatat","Meal not recorded","Essen nicht erfasst"):PhoneText.label(state.mealCategory)+" · "+PhoneText.stamp(state.mealAt) }
    private func fact(_ icon:String,_ text:String,compact:Bool) -> some View {
        HStack(spacing:6) {Image(systemName:icon).foregroundStyle(palette.accent);Text(text).lineLimit(compact ? 2:1);Spacer(minLength:0)}.font(.system(size:compact ? 10:11)).foregroundStyle(palette.muted).padding(.horizontal,compact ? 2:8).padding(.vertical,compact ? 2:5)
    }
    private var actions:some View {
        HStack(spacing:6) {
            action("outside","figure.walk",PhoneText.label(entry.state.outside))
            action("home","house.fill",PhoneText.label(entry.state.home))
            action("meal","fork.knife",PhoneText.label(entry.state.meal))
        }
    }
    private func action(_ kind:String,_ icon:String,_ label:String) -> some View {
        Link(destination:URL(string:"kabar://action?kind="+kind)!) {
            Label(label,systemImage:icon).font(.system(size:10,weight:.semibold)).lineLimit(1).minimumScaleFactor(0.8).frame(maxWidth:.infinity).padding(.vertical,9).foregroundStyle(palette.accent).background(palette.tint,in:RoundedRectangle(cornerRadius:10))
        }.accessibilityLabel(PhoneText.text("Konfirmasi ","Confirm ","Bestätigen: ")+label)
    }
}
@main struct KabarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind:"KabarWidget",provider:KabarProvider()) { KabarWidgetView(entry:$0) }
            .configurationDisplayName("abc").description(PhoneText.text("Dunia pixel, kabarmu, dan kabar pasangan.","Your pixel world, updates and your partner.","Deine Pixelwelt, Updates und dein Partner.")).supportedFamilies([.systemSmall,.systemMedium,.systemLarge])
    }
}
