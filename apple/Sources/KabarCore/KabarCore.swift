import Foundation
import CryptoKit

public enum KabarError: Error, LocalizedError {
    case invalid(String)
    public var errorDescription: String? { if case .invalid(let text) = self { return text }; return nil }
}
public enum Encoding {
    public static func b64(_ data: Data) -> String { data.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "") }
    public static func data(_ text: String) throws -> Data {
        guard text.range(of: "^[A-Za-z0-9_-]+$", options: .regularExpression) != nil,
              let data = Data(base64Encoded: text.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/") + String(repeating: "=", count: (4-text.count%4)%4)) else { throw KabarError.invalid("Kode tidak valid") }
        return data
    }
    public static func hash(_ text: String) -> String { b64(Data(SHA256.hash(data: Data(text.utf8)))) }
}
public struct Pairing {
    public let secret: Data
    public let publicKey: P256.Signing.PublicKey
    public let privateKey: P256.Signing.PrivateKey?
    public init() {
        let key = P256.Signing.PrivateKey()
        privateKey = key; publicKey = key.publicKey
        secret = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    }
    public init(code: String, privateRaw: Data? = nil) throws {
        let clean = code.filter { !$0.isWhitespace }
        let parts = clean.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard clean.count <= 400, parts.count == 3, parts[0] == "KB1" else { throw KabarError.invalid("Kode pasangan tidak valid") }
        secret = try Encoding.data(parts[1])
        guard secret.count == 32 else { throw KabarError.invalid("Kunci pasangan tidak valid") }
        publicKey = try P256.Signing.PublicKey(derRepresentation: Encoding.data(parts[2]))
        if let raw = privateRaw {
            let key = try P256.Signing.PrivateKey(rawRepresentation: raw)
            guard key.publicKey.derRepresentation == publicKey.derRepresentation else { throw KabarError.invalid("Kunci pengirim tidak cocok") }
            privateKey = key
        } else { privateKey = nil }
    }
    public var code: String { "KB1.\(Encoding.b64(secret)).\(Encoding.b64(publicKey.derRepresentation))" }
    public var topic: String { "kabar-" + Encoding.hash("kabar-v1:" + code) }
    public var pushCapability: String { Encoding.hash("kabar-push-v1:" + code) }
    public func encrypt(_ data: Data) throws -> String {
        guard let key = privateKey else { throw KabarError.invalid("Hanya pengirim dapat mengirim kabar") }
        let box = try AES.GCM.seal(data, using: SymmetricKey(data: secret))
        let nonce = box.nonce.withUnsafeBytes { Data($0) }
        let signed = "K1.\(Encoding.b64(nonce)).\(Encoding.b64(box.ciphertext + box.tag))"
        return signed + "." + Encoding.b64(try key.signature(for: Data(signed.utf8)).derRepresentation)
    }
    public func decrypt(_ envelope: String) throws -> Data {
        let parts = envelope.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard envelope.utf8.count <= 8192, parts.count == 4, parts[0] == "K1" else { throw KabarError.invalid("Format pesan tidak valid") }
        let signed = parts.prefix(3).joined(separator: ".")
        let signature = try P256.Signing.ECDSASignature(derRepresentation: Encoding.data(parts[3]))
        guard publicKey.isValidSignature(signature, for: Data(signed.utf8)) else { throw KabarError.invalid("Tanda tangan kabar tidak valid") }
        let nonce = try Encoding.data(parts[1]); let encrypted = try Encoding.data(parts[2])
        guard nonce.count == 12, encrypted.count >= 16 else { throw KabarError.invalid("Pesan terenkripsi tidak valid") }
        let box = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonce), ciphertext: encrypted.dropLast(16), tag: encrypted.suffix(16))
        return try AES.GCM.open(box, using: SymmetricKey(data: secret))
    }
    public func alertProof(_ envelope: String) throws -> String {
        guard let key = privateKey else { throw KabarError.invalid("Hanya pengirim dapat menandai notifikasi") }
        return "KB1." + Encoding.b64(try key.signature(for: Data(("kabar-alert-v1:"+envelope).utf8)).derRepresentation)
    }
    public func verifyAlert(_ envelope: String, proof: String) -> Bool {
        guard proof.hasPrefix("KB1."), let bytes = try? Encoding.data(String(proof.dropFirst(4))), let signature = try? P256.Signing.ECDSASignature(derRepresentation: bytes) else { return false }
        return publicKey.isValidSignature(signature, for: Data(("kabar-alert-v1:"+envelope).utf8))
    }
}
public struct KabarEvent: Codable, Equatable, Identifiable {
    public var kind: String
    public var at: Int64
    public var label: String
    public var id: String { "\(at)-\(kind)" }
}
public struct KabarState: Codable, Equatable {
    public var v = 1
    public var revision: Int64 = 0
    public var name = "Aku", outside = "Keluar", home = "Kost", meal = "Makan"
    public var zone = TimeZone.current.identifier
    public var windows = [5,10,10,15,17,22]
    public var location = "", mealCategory = ""
    public var locationAt: Int64 = 0, homeAt: Int64 = 0, mealAt: Int64 = 0
    public var breakfastAt: Int64 = 0, lunchAt: Int64 = 0, dinnerAt: Int64 = 0
    public var events: [KabarEvent] = []
    public init() {}
    public var timeZone: TimeZone { TimeZone(identifier: zone) ?? .gmt }
    public var locationText: String { location == "home" ? "Di " + home.lowercased() : location == "outside" ? outside : "Lokasi belum tercatat" }
    public static var now: Int64 { Int64(Date().timeIntervalSince1970 * 1000) }
    public static func validWindows(_ w: [Int]) -> Bool {
        guard w.count == 6 else { return false }
        return (0..<3).allSatisfy { i in w[i*2] >= 0 && w[i*2+1] <= 24 && w[i*2] < w[i*2+1] && (i == 0 || w[i*2] >= w[i*2-1]) }
    }
    public func category(at: Int64) -> String {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: Date(timeIntervalSince1970: Double(at)/1000))
        for i in 0..<3 where hour >= windows[i*2] && hour < windows[i*2+1] { return ["Sarapan", "Makan siang", "Makan malam"][i] }
        return "Makan"
    }
    public func day(_ at: Int64) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.timeZone = timeZone; f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date(timeIntervalSince1970: Double(at)/1000))
    }
    public func hasMealToday(_ category: String, now: Int64 = Self.now) -> Bool {
        let at = category == "Sarapan" ? breakfastAt : category == "Makan siang" ? lunchAt : category == "Makan malam" ? dinnerAt : 0
        return at > 0 && day(at) == day(now)
    }
    public func when(_ at: Int64, now: Int64 = Self.now) -> String {
        guard at > 0 else { return "Belum tercatat" }
        let f = DateFormatter(); f.locale = Locale(identifier: "id_ID"); f.timeZone = timeZone; f.dateFormat = "HH.mm"
        let date = Date(timeIntervalSince1970: Double(at)/1000)
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = timeZone
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date(timeIntervalSince1970: Double(now)/1000))!
        let prefix: String
        if day(at) == day(now) { prefix = "Hari ini" }
        else if day(at) == day(Int64(yesterday.timeIntervalSince1970*1000)) { prefix = "Kemarin" }
        else { let d = DateFormatter(); d.locale = f.locale; d.timeZone = timeZone; d.dateFormat = "d MMM"; prefix = d.string(from: date) }
        return prefix + " · " + f.string(from: date)
    }
    public var stale: Bool { locationAt > 0 && Self.now - locationAt >= 6*60*60*1000 }
    public mutating func record(_ kind: String, at: Int64 = Self.now) throws {
        guard ["home","outside","meal"].contains(kind), at > 0 else { throw KabarError.invalid("Status tidak valid") }
        let label: String
        if kind == "meal" {
            mealAt = at; mealCategory = category(at: at); label = mealCategory
            if mealCategory == "Sarapan" { breakfastAt = at }
            if mealCategory == "Makan siang" { lunchAt = at }
            if mealCategory == "Makan malam" { dinnerAt = at }
        } else {
            location = kind; locationAt = at
            if kind == "home" { homeAt = at }
            label = locationText
        }
        revision += 1; events.insert(KabarEvent(kind: kind, at: at, label: label), at: 0); events = Array(events.prefix(12))
    }
    public func validate() throws {
        guard v == 1, revision >= 0, ["", "home", "outside"].contains(location), zone.utf16.count <= 80,
              Self.validWindows(windows), events.count <= 12, mealCategory.utf16.count <= 24,
              [locationAt,homeAt,mealAt,breakfastAt,lunchAt,dinnerAt].allSatisfy({ $0 >= 0 }) else { throw KabarError.invalid("Data kabar tidak valid") }
        for label in [name,outside,home,meal] {
            guard !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, label.utf16.count <= 24, !label.contains("\n") else { throw KabarError.invalid("Nama dan tombol harus 1–24 karakter") }
        }
        for e in events { guard ["home","outside","meal"].contains(e.kind), e.at > 0, e.label.utf16.count <= 40 else { throw KabarError.invalid("Riwayat tidak valid") } }
    }
}
public struct Packet: Codable {
    public var state: KabarState
    public var notify: Bool
    public init(state: KabarState, notify: Bool) { self.state = state; self.notify = notify }
    public static func decode(_ envelope: String, pairing: Pairing) throws -> Packet {
        let data = try pairing.decrypt(envelope)
        guard data.count <= 6000 else { throw KabarError.invalid("Data terlalu besar") }
        let packet = try JSONDecoder().decode(Packet.self, from: data); try packet.state.validate(); return packet
    }
    public func envelope(pairing: Pairing) throws -> String {
        try state.validate()
        let text = try pairing.encrypt(JSONEncoder().encode(self))
        guard text.utf8.count <= 4096 else { throw KabarError.invalid("Kabar terlalu panjang untuk dikirim") }
        return text
    }
    public var notificationBody: String { (state.events.first?.label ?? state.locationText) + " · " + state.when(state.events.first?.at ?? state.locationAt) }
}
