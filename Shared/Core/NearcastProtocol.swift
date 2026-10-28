//
//  NearcastProtocol.swift
//  AirBattery
//
//  Nearcast v2 (D-029, docs/dev/NEARCAST-V2.md): group codes, keys, sealed messages, replay
//  protection and invitation tokens. Pure functions, tested with `swift test`; the transport
//  (MultipeerKit) lives in AirBattery/Supports/Multipeer.swift.
//

import Foundation
import CryptoKit

public enum Nearcast {
    public static let version = 2
    /// Bonjour service type (declared in Info.plist as _airbattery-n2._tcp and ._udp).
    public static let serviceType = "airbattery-n2"
    public static let codePrefix = "nc2-"
    /// Messages and invitations older or newer than this are refused (seconds).
    public static let maxClockSkew: TimeInterval = 300

    /// Crockford's base32 alphabet: no I, L, O or U, so a code read aloud or retyped is unambiguous.
    static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    static let codeLength = 26 // 26 × 5 bits = 130 bits of secret

    // MARK: Group code

    /// A new random group code, "nc2-" + 26 base32 characters.
    public static func newGroupCode() -> String {
        var generator = SystemRandomNumberGenerator()
        return codePrefix + String((0..<codeLength).map { _ in alphabet[Int(generator.next(upperBound: UInt32(alphabet.count)))] })
    }

    /// The canonical form of a group code typed or pasted by the user (any case, spaces and
    /// dashes after the prefix ignored), or nil if it isn't a valid v2 code. v1 Group IDs
    /// ("nc-" + 20 characters) are not valid.
    public static func normalize(_ code: String) -> String? {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.lowercased().hasPrefix(codePrefix) else { return nil }
        let body = trimmed.dropFirst(codePrefix.count).uppercased().filter { $0 != " " && $0 != "-" }
        guard body.count == codeLength, body.allSatisfy({ alphabet.contains($0) }) else { return nil }
        return codePrefix + body
    }

    // MARK: Keys

    public struct GroupKeys {
        let encryption: SymmetricKey
        let authentication: SymmetricKey
        /// Identifies the group's messages without revealing the secret (8 bytes).
        public let tag: Data
    }

    private static let salt = Data("AirBattery Plus Nearcast v2".utf8)

    public static func keys(for code: String) -> GroupKeys? {
        guard let code = normalize(code) else { return nil }
        let secret = SymmetricKey(data: Data(code.utf8))
        func derive(_ info: String) -> SymmetricKey {
            HKDF<SHA256>.deriveKey(inputKeyMaterial: secret, salt: salt, info: Data(info.utf8), outputByteCount: 32)
        }
        let authentication = derive("authentication")
        let tag = Data(HMAC<SHA256>.authenticationCode(for: Data("group-tag".utf8), using: authentication).prefix(8))
        return GroupKeys(encryption: derive("encryption"), authentication: authentication, tag: tag)
    }

    // MARK: Messages

    public enum Command: String, Codable {
        /// `content`: the sender's devices, as the JSON written to NearcastData.
        case data
        /// Asks the receiver to send its data back.
        case resend
        /// `content`: a JSON notification (battery alert forwarded to the other Macs).
        case notify
    }

    /// Everything a message carries, encrypted and authenticated as a whole.
    public struct Payload: Codable, Equatable {
        /// Random per installation (not the Mac's hardware UUID).
        public let sender: String
        /// Name shown to the other Macs.
        public let name: String
        public let command: Command
        /// Strictly increasing per sender: milliseconds since 1970 (see `Sequence`).
        public let sequence: UInt64
        public let content: Data

        public init(sender: String, name: String, command: Command, sequence: UInt64, content: Data = Data()) {
            self.sender = sender
            self.name = name
            self.command = command
            self.sequence = sequence
            self.content = content
        }
    }

    /// What travels on the network: nothing but the version and the group tag in clear.
    struct Envelope: Codable {
        let v: Int
        let tag: Data
        let box: Data
    }

    private static func associatedData(_ tag: Data) -> Data {
        return Data("nearcast-v\(version)".utf8) + tag
    }

    public static func seal(_ payload: Payload, keys: GroupKeys) throws -> Data {
        let plaintext = try JSONEncoder().encode(payload)
        let box = try AES.GCM.seal(plaintext, using: keys.encryption, authenticating: associatedData(keys.tag))
        guard let combined = box.combined else { throw CryptoKitError.incorrectParameterSize }
        return try JSONEncoder().encode(Envelope(v: version, tag: keys.tag, box: combined))
    }

    /// The payload of a message from this group, or nil (other group or version, tampered,
    /// not decryptable). Replays are checked separately (`ReplayGuard`).
    public static func open(_ data: Data, keys: GroupKeys) -> Payload? {
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              envelope.v == version, envelope.tag == keys.tag,
              let box = try? AES.GCM.SealedBox(combined: envelope.box),
              let plaintext = try? AES.GCM.open(box, using: keys.encryption, authenticating: associatedData(keys.tag)) else { return nil }
        return try? JSONDecoder().decode(Payload.self, from: plaintext)
    }

    // MARK: Replay protection

    /// Gives each sent message a sequence number that keeps increasing across restarts
    /// (it's a timestamp), even for several messages in the same millisecond.
    public final class Sequence {
        private let lock = NSLock()
        private var last: UInt64 = 0
        public init() {}
        public func next(now: Date = Date()) -> UInt64 {
            lock.lock(); defer { lock.unlock() }
            last = max(last + 1, UInt64(max(0, now.timeIntervalSince1970) * 1000))
            return last
        }
    }

    /// Refuses a message whose sequence is too far from the local clock, or that was already
    /// accepted from the same sender. Messages may arrive out of order (a Mac sends several at
    /// once when a peer connects): "not newer than the last one" refused valid ones.
    public final class ReplayGuard {
        private let lock = NSLock()
        private var seen: [String: Set<UInt64>] = [:]
        public init() {}
        public func accept(_ payload: Payload, now: Date = Date()) -> Bool {
            let sent = Double(payload.sequence) / 1000
            guard abs(sent - now.timeIntervalSince1970) <= maxClockSkew else { return false }
            lock.lock(); defer { lock.unlock() }
            // Sequences older than the window are refused by the clock check: forget them
            let oldest = UInt64(max(0, (now.timeIntervalSince1970 - maxClockSkew) * 1000))
            var sequences = seen[payload.sender, default: []].filter { $0 >= oldest }
            guard sequences.insert(payload.sequence).inserted else { return false }
            seen[payload.sender] = sequences
            return true
        }
    }

    // MARK: Invitations

    /// Sent with each MultipeerKit invitation, so that Macs outside the group aren't let into
    /// the session: 8-byte timestamp (seconds) + 16 bytes of HMAC.
    public static func invitationToken(keys: GroupKeys, now: Date = Date()) -> Data {
        var seconds = UInt64(max(0, now.timeIntervalSince1970)).bigEndian
        let time = withUnsafeBytes(of: &seconds) { Data($0) }
        return time + invitationMAC(time, keys: keys)
    }

    public static func isValidInvitation(_ token: Data?, keys: GroupKeys, now: Date = Date()) -> Bool {
        guard let token, token.count == 24 else { return false }
        let time = token.prefix(8)
        let seconds = time.reduce(UInt64(0)) { $0 << 8 | UInt64($1) }
        guard abs(Double(seconds) - now.timeIntervalSince1970) <= maxClockSkew else { return false }
        return constantTimeEqual(invitationMAC(Data(time), keys: keys), Data(token.suffix(16)))
    }

    /// Compares two MACs without stopping at the first difference (no timing leak).
    static func constantTimeEqual(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else { return false }
        return zip(a, b).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }

    private static func invitationMAC(_ time: Data, keys: GroupKeys) -> Data {
        return Data(HMAC<SHA256>.authenticationCode(for: Data("invitation".utf8) + time, using: keys.authentication).prefix(16))
    }
}
