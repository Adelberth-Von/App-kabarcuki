#if DEBUG
import Foundation
import Security
import UserNotifications

enum CleanupProbe {
    static let other:[String:Any]=[kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:"id.abc.qa.other",kSecAttrAccount as String:"disposable-fixture"]
    static func roots()->[URL] {
        let manager=FileManager.default
        var roots=manager.urls(for:.documentDirectory,in:.userDomainMask)+manager.urls(for:.applicationSupportDirectory,in:.userDomainMask)+manager.urls(for:.cachesDirectory,in:.userDomainMask)+[manager.temporaryDirectory]
        if let group=manager.containerURL(forSecurityApplicationGroupIdentifier:SharedStore.group) {
            roots += ["Documents","Library/Application Support","Library/Caches","tmp"].map{group.appendingPathComponent($0)}
        };return roots
    }
    static func inspect(seed:Bool)throws->[String:Any] {
        if seed {
            guard SharedStore.pairing() != nil else {throw NSError(domain:"QA",code:1)}
            for name in ["peerCode","oneWayCode"] {try SharedStore.saveSecret(Data("abc-qa-unused".utf8),name:name)}
            SharedStore.defaults.set([["topic":"fixture","body":"encrypted-fixture"]],forKey:"retiredQueue")
            SharedStore.defaults.set(Data("fixture".utf8),forKey:"peerState")
            SharedStore.defaults.set("fixture",forKey:"abcQaExtra");UserDefaults.standard.set("fixture",forKey:"abcQaExtra")
            for root in roots(){try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);try Data([1]).write(to:root.appendingPathComponent("abc-qa-cleanup.txt"))}
            SecItemDelete(other as CFDictionary);var item=other;item[kSecValueData as String]=Data([1]);guard SecItemAdd(item as CFDictionary,nil)==errSecSuccess else {throw NSError(domain:"QAKeychain",code:1)}
        }
        let preserved=SecItemCopyMatching(other as CFDictionary,nil)==errSecSuccess
        let result:[String:Any]=["filesClear":roots().allSatisfy{!FileManager.default.fileExists(atPath:$0.appendingPathComponent("abc-qa-cleanup.txt").path)},
            "extraPreferencesClear":SharedStore.defaults.object(forKey:"abcQaExtra")==nil && UserDefaults.standard.object(forKey:"abcQaExtra")==nil,
            "secretsClear":["code","private","peerCode","oneWayCode"].allSatisfy{SharedStore.secret($0)==nil},
            "twoWayStateClear":SharedStore.defaults.object(forKey:"peerState")==nil && SharedStore.defaults.object(forKey:"retiredQueue")==nil,"otherKeychainPreserved":preserved]
        if !seed {SecItemDelete(other as CFDictionary)} // Remove only this test's unrelated service fixture.
        return result
    }
}
#endif
