import Testing
@testable import ManifestKit

@Test func catalogContainsLifedeverApps() {
    let urls = BuiltInCatalog.lifedeverManifestURLs
    #expect(urls.contains { $0.host == "www.lifedever.com" || $0.host == "lifedever.com" })
    #expect(urls.count >= 1)
}
