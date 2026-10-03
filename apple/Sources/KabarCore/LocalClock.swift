import Foundation

public enum LocalClock {
    public static func country(_ zone: TimeZone) -> String {
        guard let code = ZoneCountries.all[zone.identifier] else { return "Zona waktu HP" }
        return Locale(identifier:"id_ID").localizedString(forRegionCode:code) ?? code
    }
    public static func shortZone(_ zone: TimeZone, at: Int64) -> String {
        let date = Date(timeIntervalSince1970:Double(at)/1000)
        if ZoneCountries.all[zone.identifier] == "ID" {
            switch zone.secondsFromGMT(for:date)/3600 { case 7: return "WIB"; case 8: return "WITA"; case 9: return "WIT"; default: break }
        }
        return zone.abbreviation(for:date) ?? "UTC"
    }
    public static func clock(_ at: Int64 = KabarState.now, zone: TimeZone = .current) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier:"en_US_POSIX"); f.timeZone = zone; f.dateFormat = "HH.mm"
        return f.string(from:Date(timeIntervalSince1970:Double(at)/1000))+" "+shortZone(zone,at:at)+" - "+country(zone)
    }
    public static func when(_ at: Int64, now: Int64 = KabarState.now, zone: TimeZone = .current) -> String {
        guard at > 0 else { return "Belum tercatat" }
        var display = KabarState(); display.zone = zone.identifier
        return display.when(at,now:now)+" "+shortZone(zone,at:at)+" - "+country(zone)
    }
    public static func phase(_ at: Int64 = KabarState.now, zone: TimeZone = .current) -> Int {
        var c = Calendar(identifier:.gregorian); c.timeZone = zone
        let h = c.component(.hour,from:Date(timeIntervalSince1970:Double(at)/1000))
        return (5..<11).contains(h) ? 0 : (11..<15).contains(h) ? 1 : (15..<18).contains(h) ? 2 : 3
    }
    public static func phaseName(_ at: Int64 = KabarState.now, zone: TimeZone = .current) -> String { ["Pagi","Siang","Sore","Malam"][phase(at,zone:zone)] }
}
