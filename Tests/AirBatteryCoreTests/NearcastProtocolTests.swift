import XCTest
@testable import AirBatteryCore

final class NearcastProtocolTests: XCTestCase {
    private let code = "nc2-0123456789ABCDEFGHJKMNPQRS"
    private var keys: Nearcast.GroupKeys { Nearcast.keys(for: code)! }
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func payload(_ command: Nearcast.Command = .data, sender: String = "A", at date: Date? = nil, content: String = "[]") -> Nearcast.Payload {
        let sequence = UInt64((date ?? now).timeIntervalSince1970 * 1000)
        return Nearcast.Payload(sender: sender, name: "Mac A", command: command, sequence: sequence, content: Data(content.utf8))
    }

    // MARK: Group codes

    func testNewCodesAreValidAndDifferent() {
        let a = Nearcast.newGroupCode(), b = Nearcast.newGroupCode()
        XCTAssertEqual(a.count, 4 + 26)
        XCTAssertEqual(Nearcast.normalize(a), a)
        XCTAssertNotEqual(a, b)
    }

    func testNormalizeAcceptsTypingVariants() {
        XCTAssertEqual(Nearcast.normalize("  NC2-0123 4567-89ab cdef ghjk mnpq rs\n"), code)
    }

    func testNormalizeRejectsInvalidCodes() {
        XCTAssertNil(Nearcast.normalize("nc-aB3dE6gH9jK2mN5pQ8sT"))   // v1 Group ID
        XCTAssertNil(Nearcast.normalize("nc2-0123456789ABCDEFGHJKMNPQR"))  // 25 characters
        XCTAssertNil(Nearcast.normalize("nc2-0123456789ABCDEFGHJKMNPQRI")) // I isn't in the alphabet
        XCTAssertNil(Nearcast.normalize(""))
    }

    func testKeysDependOnTheCode() {
        XCTAssertEqual(Nearcast.keys(for: code)?.tag, Nearcast.keys(for: code.lowercased())?.tag)
        XCTAssertNotEqual(Nearcast.keys(for: code)?.tag, Nearcast.keys(for: Nearcast.newGroupCode())?.tag)
        XCTAssertNil(Nearcast.keys(for: "nc-aB3dE6gH9jK2mN5pQ8sT"))
    }

    // MARK: Messages

    func testSealAndOpen() throws {
        let message = payload(.notify, content: #"{"title":"Low battery"}"#)
        let data = try Nearcast.seal(message, keys: keys)
        XCTAssertEqual(Nearcast.open(data, keys: keys), message)
        // Nothing readable in clear
        let wire = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(wire.contains("Mac A"))
        XCTAssertFalse(wire.contains("notify"))
    }

    func testOtherGroupCantOpen() throws {
        let data = try Nearcast.seal(payload(), keys: keys)
        XCTAssertNil(Nearcast.open(data, keys: Nearcast.keys(for: Nearcast.newGroupCode())!))
    }

    func testTamperedMessageIsRejected() throws {
        let data = try Nearcast.seal(payload(), keys: keys)
        var envelope = try JSONDecoder().decode(Nearcast.Envelope.self, from: data)
        var box = envelope.box
        box[box.count - 20] ^= 1
        envelope = Nearcast.Envelope(v: envelope.v, tag: envelope.tag, box: box)
        XCTAssertNil(Nearcast.open(try JSONEncoder().encode(envelope), keys: keys))
        // Another version number in clear fails too (it's authenticated)
        let original = try JSONDecoder().decode(Nearcast.Envelope.self, from: data)
        XCTAssertNil(Nearcast.open(try JSONEncoder().encode(Nearcast.Envelope(v: 3, tag: original.tag, box: original.box)), keys: keys))
    }

    func testGarbageIsRejected() {
        XCTAssertNil(Nearcast.open(Data("{}".utf8), keys: keys))
        XCTAssertNil(Nearcast.open(Data([0, 1, 2]), keys: keys))
    }

    // MARK: Replays

    func testReplayIsRejected() {
        let guardian = Nearcast.ReplayGuard()
        let first = payload()
        XCTAssertTrue(guardian.accept(first, now: now))
        XCTAssertFalse(guardian.accept(first, now: now))
        XCTAssertTrue(guardian.accept(payload(at: now.addingTimeInterval(1)), now: now))
        // Senders are tracked separately
        XCTAssertTrue(guardian.accept(payload(sender: "B"), now: now))
    }

    func testOutOfOrderMessagesAreAccepted() {
        // Sent at once when a peer connects (request, then data): they may arrive swapped
        let guardian = Nearcast.ReplayGuard()
        let base = UInt64(now.timeIntervalSince1970 * 1000)
        let earlier = Nearcast.Payload(sender: "A", name: "Mac A", command: .resend, sequence: base + 1)
        let later = Nearcast.Payload(sender: "A", name: "Mac A", command: .data, sequence: base + 2)
        XCTAssertTrue(guardian.accept(later, now: now))
        XCTAssertTrue(guardian.accept(earlier, now: now))
        XCTAssertFalse(guardian.accept(earlier, now: now))
    }

    func testOldOrFutureMessagesAreRejected() {
        let guardian = Nearcast.ReplayGuard()
        XCTAssertFalse(guardian.accept(payload(at: now.addingTimeInterval(-301)), now: now))
        XCTAssertFalse(guardian.accept(payload(at: now.addingTimeInterval(301)), now: now))
        XCTAssertTrue(guardian.accept(payload(at: now.addingTimeInterval(-299)), now: now))
    }

    func testSequenceKeepsIncreasing() {
        let sequence = Nearcast.Sequence()
        let a = sequence.next(now: now), b = sequence.next(now: now), c = sequence.next(now: now.addingTimeInterval(-5))
        XCTAssertLessThan(a, b)
        XCTAssertLessThan(b, c)
        XCTAssertEqual(a, UInt64(now.timeIntervalSince1970 * 1000))
    }

    // MARK: Invitations

    func testInvitationToken() {
        let token = Nearcast.invitationToken(keys: keys, now: now)
        XCTAssertTrue(Nearcast.isValidInvitation(token, keys: keys, now: now.addingTimeInterval(30)))
        XCTAssertFalse(Nearcast.isValidInvitation(token, keys: keys, now: now.addingTimeInterval(400)))
        XCTAssertFalse(Nearcast.isValidInvitation(token, keys: Nearcast.keys(for: Nearcast.newGroupCode())!, now: now))
        XCTAssertFalse(Nearcast.isValidInvitation(nil, keys: keys, now: now))
        var forged = token
        forged[forged.count - 1] ^= 1
        XCTAssertFalse(Nearcast.isValidInvitation(forged, keys: keys, now: now))
    }
}
