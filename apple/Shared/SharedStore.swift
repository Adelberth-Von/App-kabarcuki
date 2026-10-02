import Foundation
import Security
import KabarCore

enum SharedStore {
    static let group = "group.id.kabar.shared"
    static let defaults = UserDefaults(suiteName: group)!
    static var accessGroup: String {
        #if targetEnvironment(simulator)
        // Simulator QA has no Apple provisioning profile; use the simulator's default keychain.
        return ""
        #else
        return Bundle.main.object(forInfoDictionaryKey: "KabarKeychainGroup") as? String ?? ""
        #endif
    }
    static func key(_ name: String) -> [String: Any] {
        var q: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "id.kabar.shared", kSecAttrAccount as String: name]
        if !accessGroup.isEmpty { q[kSecAttrAccessGroup as String] = accessGroup }
        return q
    }
    static func secret(_ name: String) -> Data? {
        var q = key(name); q[kSecReturnData as String] = true; q[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?; guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess else { return nil }; return result as? Data
    }
    static func saveSecret(_ data: Data, name: String) throws {
        let q = key(name)
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(q as CFDictionary, update as CFDictionary)
        #if DEBUG
        if status != errSecSuccess && status != errSecItemNotFound { print("Kabar Keychain update status: \(status)") }
        #endif
        if status == errSecItemNotFound {
            var add = q; add[kSecValueData as String] = data; add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(add as CFDictionary, nil) == errSecSuccess else { throw KabarError.invalid("Kunci pasangan tidak dapat disimpan. Periksa penandatanganan aplikasi.") }
        } else if status != errSecSuccess { throw KabarError.invalid("Kunci pasangan tidak dapat diperbarui") }
    }
    static func pairing() -> Pairing? {
        guard let data = secret("code"), let code = String(data: data, encoding: .utf8) else { return nil }
        return try? Pairing(code: code, privateRaw: defaults.string(forKey: "role") == "sender" ? secret("private") : nil)
    }
    static func state() -> KabarState {
        guard let data = defaults.data(forKey: "state"), let state = try? JSONDecoder().decode(KabarState.self, from: data), (try? state.validate()) != nil else { return KabarState() }
        return state
    }
    static func save(_ state: KabarState) throws { try state.validate(); defaults.set(try JSONEncoder().encode(state), forKey: "state") }
    static func reset() {
        for key in ["code", "private"] { SecItemDelete(self.key(key) as CFDictionary) }
        defaults.removePersistentDomain(forName: group)
    }
    static func receive(_ packet: Packet, topic: String) throws -> Bool {
        guard pairing()?.topic == topic, packet.state.revision > state().revision else { return false }
        try save(packet.state); return true
    }
}
struct RelayMessage: Decodable { let id: String?; let event: String; let message: String?; let time: Int64? }
enum RelayClient {
    static func publish(topic: String, envelope: String, proof: String? = nil) async throws {
        var r = URLRequest(url: URL(string: "https://ntfy.sh/" + topic)!); r.httpMethod = "POST"; r.timeoutInterval = 25
        r.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type"); r.httpBody = Data(envelope.utf8)
        if let proof { r.setValue(proof, forHTTPHeaderField: "Title") }
        let (_, response) = try await URLSession.shared.data(for: r)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw KabarError.invalid("Relay belum menerima kabar. Akan dicoba lagi.") }
    }
    static func latest(_ pairing: Pairing) async throws -> Packet? {
        let url = URL(string: "https://ntfy.sh/\(pairing.topic)/json?poll=1&since=latest")!
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url, timeoutInterval: 15))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw KabarError.invalid("Relay belum terhubung") }
        var latest: Packet?
        for line in String(decoding: data, as: UTF8.self).split(separator: "\n") {
            if let m = try? JSONDecoder().decode(RelayMessage.self, from: Data(line.utf8)), m.event == "message", let text = m.message,
               let p = try? Packet.decode(text, pairing: pairing), p.state.revision > (latest?.state.revision ?? -1) { latest = p }
        }
        return latest
    }
}
