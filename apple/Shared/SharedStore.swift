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
        return try? Pairing(code: code, privateRaw: canSend ? secret("private") : nil)
    }
    static var isTwoWay: Bool {defaults.string(forKey:"role") == "duplex"}
    static var isDuplex: Bool {isTwoWay}
    static var mode: String {isTwoWay ? "seirama":"oneWay"}
    static var canSend: Bool {["sender","duplex"].contains(defaults.string(forKey:"role") ?? "")}
    static var reciprocity: String {!isTwoWay ? "none":incomingPairing()==nil ? "unlinked":defaults.bool(forKey:"peerRevoked") ? "inactive":defaults.bool(forKey:"peerConfirmed") ? "active":"waiting"}
    static func incomingPairing() -> Pairing? {
        if isTwoWay {guard let data=secret("peerCode"),let code=String(data:data,encoding:.utf8) else {return nil};return try? Pairing(code:code)}
        return defaults.string(forKey:"role")=="receiver" ? pairing():nil
    }
    static func selfState() -> KabarState {state()}
    static func linkPeer(_ incoming: Pairing) throws -> Bool {
        guard isTwoWay,let own=pairing() else {throw KabarError.invalid("Enable Seirama first")};try Seirama.requireDifferent(own,incoming)
        let same=incomingPairing()?.code==incoming.code
        try saveSecret(Data(incoming.code.utf8),name:"peerCode")
        if !same {for key in ["peerState","cursor","peerConfirmed","peerRevoked"] {defaults.removeObject(forKey:key)};defaults.set(false,forKey:"pushRegistered")}
        return same
    }
    static func peerState() -> KabarState? {
        guard isTwoWay,incomingPairing() != nil else {return nil}
        guard let data=defaults.data(forKey:"peerState"),let state=try? JSONDecoder().decode(KabarState.self,from:data),(try? state.validate()) != nil else {return KabarState()};return state
    }
    static func state() -> KabarState {
        guard let data = defaults.data(forKey: "state"), let state = try? JSONDecoder().decode(KabarState.self, from: data), (try? state.validate()) != nil else { return KabarState() }
        return state
    }
    static func save(_ state: KabarState) throws { try state.validate(); defaults.set(try JSONEncoder().encode(state), forKey: "state") }
    static func reset() {
        for key in ["code", "private", "peerCode", "oneWayCode"] { SecItemDelete(self.key(key) as CFDictionary) }
        let dark = defaults.bool(forKey:"appearanceDark"), together = defaults.bool(forKey:"appearanceRelationship")
        let profile = defaults.dictionary(forKey:"abcProfile")
        defaults.removePersistentDomain(forName: group)
        defaults.set(dark,forKey:"appearanceDark");defaults.set(together,forKey:"appearanceRelationship")
        if let profile { defaults.set(profile,forKey:"abcProfile") }
    }
    static func eraseAll() throws {
        // Two abc accounts in one service; never erase other Keychain items.
        for name in ["code","private","peerCode","oneWayCode"] {
            let status=SecItemDelete(key(name) as CFDictionary)
            guard status==errSecSuccess || status==errSecItemNotFound else {throw KabarError.invalid("Kunci abc belum dapat dihapus")}
        }
        defaults.removePersistentDomain(forName:group)
        if let identifier=Bundle.main.bundleIdentifier {UserDefaults.standard.removePersistentDomain(forName:identifier)}
        // Release the app's disk cache before removing its database files.
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared=URLCache(memoryCapacity:0,diskCapacity:0,diskPath:nil)
        let manager=FileManager.default
        var roots:[URL]=[]
        for directory:FileManager.SearchPathDirectory in [.documentDirectory,.applicationSupportDirectory,.cachesDirectory] {
            roots += manager.urls(for:directory,in:.userDomainMask)
        }
        roots.append(manager.temporaryDirectory)
        if let groupURL=manager.containerURL(forSecurityApplicationGroupIdentifier:group) {
            for path in ["Documents","Library/Application Support","Library/Caches","tmp"] {roots.append(groupURL.appendingPathComponent(path))}
        }
        for root in roots where manager.fileExists(atPath:root.path) {
            for child in try manager.contentsOfDirectory(at:root,includingPropertiesForKeys:[.isSymbolicLinkKey]) {
                // removeItem removes a link itself, without following its destination.
                try manager.removeItem(at:child)
            }
        }
    }
    static func receive(_ packet: Packet, topic: String) throws -> Bool {
        guard incomingPairing()?.topic == topic,packet.state.revision > (isTwoWay ? peerState()?.revision ?? 0:state().revision) else {return false}
        try packet.state.validate()
        if isTwoWay {
            defaults.set(try JSONEncoder().encode(packet.state),forKey:"peerState")
            defaults.set(pairing().map{packet.reciprocates($0)} ?? false,forKey:"peerConfirmed")
            defaults.set(packet.seirama == false,forKey:"peerRevoked")
        } else {try save(packet.state)}
        return true
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
