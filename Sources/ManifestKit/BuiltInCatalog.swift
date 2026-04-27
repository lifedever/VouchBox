import Foundation

public enum BuiltInCatalog {
    /// Hard-coded list of lifedever-maintained manifests.
    /// Updates ship as part of the VouchBox binary; users don't see this list directly.
    public static let lifedeverManifestURLs: [URL] = [
        URL(string: "https://www.lifedever.com/.well-known/vouchbox/shotmemo.json")!,
        URL(string: "https://www.lifedever.com/.well-known/vouchbox/pastememo.json")!,
        URL(string: "https://www.lifedever.com/.well-known/vouchbox/vouchbox.json")!,
    ]
}
