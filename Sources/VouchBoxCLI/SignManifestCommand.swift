import ArgumentParser
import Foundation
import CryptoKit
import ManifestKit

struct SignManifestCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sign-manifest",
        abstract: "Tooling for publishers: generate keypair or sign a manifest JSON file.",
        subcommands: [Keygen.self, Sign.self]
    )

    struct Keygen: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Generate Ed25519 keypair, print to stdout.")
        func run() async throws {
            let key = Curve25519.Signing.PrivateKey()
            let priv = key.rawRepresentation.base64EncodedString()
            let pub = key.publicKey.rawRepresentation.base64EncodedString()
            print("PRIVATE_KEY (KEEP SECRET, store in 1Password / keychain):")
            print(priv)
            print()
            print("PUBLIC_KEY (paste into manifest publisher.publicKey):")
            print(pub)
        }
    }

    struct Sign: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Sign a manifest JSON file in place.")
        @Argument var manifestPath: String
        @Option(name: .shortAndLong, help: "Path to file containing private key (base64).") var keyFile: String

        func run() async throws {
            let keyB64 = try String(contentsOfFile: keyFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let keyData = Data(base64Encoded: keyB64) else {
                throw ValidationError("invalid key file (expected base64)")
            }
            let key = try Curve25519.Signing.PrivateKey(rawRepresentation: keyData)
            let url = URL(fileURLWithPath: manifestPath)
            let raw = try Data(contentsOf: url)
            guard var dict = try JSONSerialization.jsonObject(with: raw) as? [String: Any] else {
                throw ValidationError("manifest is not a JSON object")
            }
            dict.removeValue(forKey: "signature")
            let pubKey = key.publicKey.rawRepresentation.base64EncodedString()
            if var publisher = dict["publisher"] as? [String: Any] {
                publisher["publicKey"] = pubKey
                dict["publisher"] = publisher
            }
            let canonical = try CanonicalJSON.encode(dict)
            let signature = try key.signature(for: canonical).base64EncodedString()
            dict["signature"] = signature
            let final = try CanonicalJSON.encode(dict)
            try final.write(to: url, options: .atomic)
            print("✓ signed: \(manifestPath)")
            print("  publicKey: \(pubKey)")
        }
    }
}
