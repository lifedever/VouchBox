import Foundation

public struct UserManifestStore {
    private static let key = "VouchBox.userManifestURLs"

    public static func load() -> [URL] {
        let arr = UserDefaults.standard.stringArray(forKey: key) ?? []
        return arr.compactMap { URL(string: $0) }
    }

    public static func save(_ urls: [URL]) {
        UserDefaults.standard.set(urls.map(\.absoluteString), forKey: key)
    }

    public static func add(_ url: URL) {
        var urls = load()
        guard !urls.contains(url) else { return }
        urls.append(url)
        save(urls)
    }

    public static func remove(_ url: URL) {
        save(load().filter { $0 != url })
    }
}
