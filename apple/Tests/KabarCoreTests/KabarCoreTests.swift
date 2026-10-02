import XCTest
@testable import KabarCore
final class KabarCoreTests: XCTestCase {
    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Int64 {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Asia/Jakarta")!
        return Int64(c.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!.timeIntervalSince1970*1000)
    }
    func testMealBoundaries() throws {
        var s = KabarState(); s.zone = "Asia/Jakarta"
        let cases: [(Int, Int, String)] = [(4,59,"Makan"),(5,0,"Sarapan"),(9,59,"Sarapan"),(10,0,"Makan siang"),(14,59,"Makan siang"),(15,0,"Makan"),(16,59,"Makan"),(17,0,"Makan malam"),(21,59,"Makan malam"),(22,0,"Makan")]
        for (h,m,label) in cases { XCTAssertEqual(s.category(at: at(2,h,m)), label) }
        XCTAssertFalse(KabarState.validWindows([5,10,9,15,17,22])); XCTAssertFalse(KabarState.validWindows([5,5,10,15,17,22]))
        XCTAssertFalse(KabarState.validWindows([-1,5,10,15,17,22])); XCTAssertFalse(KabarState.validWindows([5,10,10,15,17,25]))
        XCTAssertTrue(KabarState.validWindows([0,8,8,16,16,24]))
        XCTAssertEqual(s.when(at(1,23,59), now: at(2,0,1)), "Kemarin · 23.59")
    }
    func testIndependentStatusAndHistory() throws {
        var s = KabarState(); s.zone = "Asia/Jakarta"
        try s.record("home", at: at(2,8)); try s.record("meal", at: at(2,8,30)); try s.record("outside", at: at(2,9))
        XCTAssertEqual(s.location, "outside"); XCTAssertEqual(s.homeAt, at(2,8)); XCTAssertEqual(s.mealAt, at(2,8,30)); XCTAssertEqual(s.revision, 3)
        for i in 0..<50 { try s.record("meal", at: at(2,13)+Int64(i)) }
        XCTAssertEqual(s.events.count, 12); XCTAssertTrue(s.hasMealToday("Sarapan", now: at(2,14))); XCTAssertFalse(s.hasMealToday("Sarapan", now: at(3,0)))
        XCTAssertEqual(try JSONDecoder().decode(KabarState.self, from: JSONEncoder().encode(s)), s)
        XCTAssertThrowsError(try s.record("campus")); s.home = "Rumah"; try s.record("home"); XCTAssertEqual(s.locationText, "Di rumah")
        s.name = ""; XCTAssertThrowsError(try s.validate())
    }
    func testAuthenticationAndEncryption() throws {
        let sender = Pairing(); let receiver = try Pairing(code: " \n"+sender.code+"\n")
        XCTAssertEqual(sender.topic, receiver.topic); XCTAssertNil(receiver.privateKey)
        let data = Data("Kabar rahasia".utf8); let a = try sender.encrypt(data)
        XCTAssertEqual(try receiver.decrypt(a), data); XCTAssertNotEqual(a, try sender.encrypt(data)); XCTAssertFalse(a.contains("rahasia"))
        XCTAssertThrowsError(try receiver.encrypt(data)); XCTAssertThrowsError(try Pairing(code: "KB1.bad.bad"))
        var parts = a.split(separator: ".").map(String.init); var cipher = try Encoding.data(parts[2]); cipher[0] ^= 1; parts[2] = Encoding.b64(cipher)
        XCTAssertThrowsError(try receiver.decrypt(parts.joined(separator: "."))); XCTAssertThrowsError(try Pairing().decrypt(a))
        let restored = try Pairing(code: sender.code, privateRaw: sender.privateKey!.rawRepresentation)
        XCTAssertEqual(try receiver.decrypt(restored.encrypt(data)), data)
        XCTAssertThrowsError(try Pairing(code: sender.code, privateRaw: Pairing().privateKey!.rawRepresentation))
    }
    func testJavaSwiftInteroperability() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let fixture = root.appendingPathComponent("Fixtures/java.json")
        guard FileManager.default.fileExists(atPath: fixture.path) else { throw XCTSkip("Run scripts/test-apple.sh to generate Java fixture") }
        struct JavaFixture: Decodable { let code: String; let topic: String; let envelope: String; let state: KabarState }
        let f = try JSONDecoder().decode(JavaFixture.self, from: Data(contentsOf: fixture))
        let receiver = try Pairing(code: f.code); XCTAssertEqual(receiver.topic, f.topic)
        let packet = try Packet.decode(f.envelope, pairing: receiver); XCTAssertEqual(packet.state, f.state); XCTAssertTrue(packet.notify)
        let sender = Pairing(); var s = KabarState(); s.zone = "Asia/Jakarta"
        try s.record("home", at: at(2,8)); try s.record("meal", at: at(2,8,30)); try s.record("outside", at: at(2,9))
        s.gps = try GpsPoint(lat:-6.2,lon:106.816666,accuracy:20,at:at(2,9),zone:"Asia/Jakarta");s.events[0].gps = s.gps
        let json: [String: String] = ["code": sender.code, "topic": sender.topic, "envelope": try Packet(state: s, notify: true).envelope(pairing: sender)]
        try JSONSerialization.data(withJSONObject: json).write(to: root.appendingPathComponent("Fixtures/swift.json"))
    }
    func testManualMealsAndOptionalLocation() throws {
        var s = KabarState(); s.zone = "Asia/Jakarta"
        let point = try GpsPoint(lat:-6.2,lon:106.816666,accuracy:12.3,at:at(2,23),zone:s.zone)
        try s.record("home",at:at(2,7));try s.record("meal",at:at(2,23),meal:"Sarapan",point:point)
        XCTAssertTrue(s.hasMealToday("Sarapan",now:at(2,23)));XCTAssertEqual(s.location,"home");XCTAssertEqual(s.homeAt,at(2,7));XCTAssertEqual(s.gps,point)
        XCTAssertEqual(point.accuracy,13);XCTAssertThrowsError(try GpsPoint(lat:91,lon:0,accuracy:10,at:1,zone:"UTC"))
        XCTAssertThrowsError(try s.record("meal",meal:"Snack"));try s.record("meal",at:at(2,23,1),meal:"Makan malam")
        XCTAssertTrue(s.hasMealToday("Makan malam",now:at(2,23,2)));XCTAssertEqual(s.gps,point)
        s.zone = "Asia/Makassar";try s.record("outside",at:at(2,23,3));XCTAssertEqual(s.events[0].zone,"Asia/Makassar");XCTAssertEqual(s.events[1].zone,"Asia/Jakarta")
        for i in 0..<12 { try s.record("meal",at:at(2,23,4)+Int64(i),meal:"Makan",point:point) }
        XCTAssertEqual(s.events.filter({ $0.gps != nil }).count,3)
        XCTAssertEqual(try JSONDecoder().decode(KabarState.self,from:JSONEncoder().encode(s)),s)
        let sender = Pairing();XCTAssertLessThanOrEqual(try Packet(state:s,notify:true).envelope(pairing:sender).utf8.count,4096)
        var object = try JSONSerialization.jsonObject(with:JSONEncoder().encode(s)) as! [String:Any];object.removeValue(forKey:"gps")
        var events = object["events"] as! [[String:Any]];for i in events.indices { events[i].removeValue(forKey:"gps");events[i].removeValue(forKey:"zone") };object["events"] = events
        let legacy = try JSONDecoder().decode(KabarState.self,from:JSONSerialization.data(withJSONObject:object));XCTAssertNil(legacy.gps);try legacy.validate()
    }
}
