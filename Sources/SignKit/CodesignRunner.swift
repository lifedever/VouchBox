import Foundation
import VouchBoxCore

public struct SignatureInfo: Sendable, Equatable {
    public let identifier: String
    public let designatedRequirement: String
    public let teamIdentifier: String?
}

public actor CodesignRunner {
    public init() {}

    public func resign(
        bundle: URL,
        identifier: String,
        designatedRequirement: String
    ) async throws {
        let result = try await run(
            executable: "/usr/bin/codesign",
            args: [
                "--force", "--deep", "--no-strict",
                "--sign", "-",
                "--identifier", identifier,
                "--requirements", designatedRequirement,
                bundle.path
            ]
        )
        guard result.exitCode == 0 else {
            throw VouchBoxError.codesignFailed(stderr: result.stderr)
        }
    }

    public func inspect(_ bundle: URL) async throws -> SignatureInfo {
        let infoResult = try await run(
            executable: "/usr/bin/codesign",
            args: ["-dv", bundle.path]
        )
        guard infoResult.exitCode == 0 else {
            throw VouchBoxError.codesignFailed(stderr: infoResult.stderr)
        }
        let info = infoResult.stderr // codesign -dv writes to stderr
        let identifier = extract(prefix: "Identifier=", in: info) ?? ""
        let teamID = extract(prefix: "TeamIdentifier=", in: info)

        let drResult = try await run(
            executable: "/usr/bin/codesign",
            args: ["-d", "-r-", bundle.path]
        )
        let drCombined = drResult.stdout + "\n" + drResult.stderr
        let drLine = drCombined
            .split(separator: "\n")
            .first { $0.contains("designated =>") }
            .map(String.init) ?? ""

        return SignatureInfo(
            identifier: identifier,
            designatedRequirement: drLine,
            teamIdentifier: teamID == "not set" ? nil : teamID
        )
    }

    private func extract(prefix: String, in text: String) -> String? {
        for line in text.split(separator: "\n") where line.hasPrefix(prefix) {
            return String(line.dropFirst(prefix.count))
        }
        return nil
    }

    struct ProcessResult {
        let exitCode: Int32
        let stdout: String
        let stderr: String
    }

    private func run(executable: String, args: [String]) async throws -> ProcessResult {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ProcessResult, Error>) in
            do {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: executable)
                proc.arguments = args
                let outPipe = Pipe()
                let errPipe = Pipe()
                proc.standardOutput = outPipe
                proc.standardError = errPipe
                proc.terminationHandler = { p in
                    let stdout = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    let stderr = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    cont.resume(returning: ProcessResult(exitCode: p.terminationStatus, stdout: stdout, stderr: stderr))
                }
                try proc.run()
            } catch {
                cont.resume(throwing: error)
            }
        }
    }
}
