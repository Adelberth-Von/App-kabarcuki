import Foundation
import KabarCore
enum PhoneText {
    static var language:String {SharedStore.defaults.dictionary(forKey:"abcProfile")?["language"] as? String ?? "id"}
    static func text(_ id:String,_ en:String,_ de:String)->String {language == "en" ? en : language == "de" ? de : id}
    static func label(_ raw:String)->String {
        switch raw {case "Keluar":return text("Keluar","Out","Unterwegs");case "Kost":return text("Kost","Home","Zuhause");case "Di kost":return text("Di kost","At home","Zuhause");case "Makan":return text("Makan","Meal","Essen");case "Sarapan":return text("Sarapan","Breakfast","Frühstück");case "Makan siang":return text("Makan siang","Lunch","Mittagessen");case "Makan malam":return text("Makan malam","Dinner","Abendessen");default:return raw}
    }
    static func stamp(_ at:Int64)->String {
        guard at>0 else {return text("Belum tercatat","Not recorded","Nicht erfasst")}
        let f=DateFormatter();f.locale=Locale(identifier:"en_US_POSIX");f.timeZone = .current
        let twelve=SharedStore.defaults.dictionary(forKey:"abcProfile")?["clock12"] as? Bool ?? false
        f.dateFormat=twelve ? "dd.MM.yyyy · h.mm a":"dd.MM.yyyy · HH.mm"
        return f.string(from:Date(timeIntervalSince1970:Double(at)/1000))+" "+LocalClock.shortZone(.current,at:at)
    }
    static func notification(_ packet:Packet)->String {label(packet.state.events.first?.label ?? packet.state.locationText)+" · "+stamp(packet.state.events.first?.at ?? packet.state.locationAt)}
    static func notificationData(_ packet:Packet)->[String:Any] {
        ["abcAt":packet.state.events.first?.at ?? packet.state.locationAt,
         "abcLabel":packet.state.events.first?.label ?? packet.state.locationText]
    }
}
