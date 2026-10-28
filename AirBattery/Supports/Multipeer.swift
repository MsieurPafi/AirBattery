//
//  Multipeer.swift
//  AirBattery
//
//  Created by apple on 2024/6/10.
//
//  Nearcast v2 transport (D-029). The protocol itself (group codes, keys, sealed messages,
//  replays, invitation tokens) is in Shared/Core/NearcastProtocol.swift. v1 (service type
//  "airbattery-nc", 23-character Group IDs) was removed: see docs/dev/NEARCAST-V2.md.
//

import SwiftUI
import Foundation
import CryptoKit
import MultipeerKit

class MultipeerService: ObservableObject {
    let transceiver: MultipeerTransceiver
    /// Names of the Macs in the session (only group members get in), for the settings.
    @Published private(set) var connectedNames: [String] = []
    private let sequence = Nearcast.Sequence()
    private let replays = Nearcast.ReplayGuard()
    private let sendLock = NSLock()
    private var lastSentData = Data()
    private var lastSentTime: TimeInterval = 0

    /// Keys of the group code in the settings, or nil if Nearcast can't run.
    static var groupKeys: Nearcast.GroupKeys? {
        return Nearcast.keys(for: ud.string(forKey: "ncGroupID") ?? "")
    }

    /// Random per installation: identifies this Mac to the others (v1 sent the hardware UUID).
    static var senderID: String {
        if let id = ud.string(forKey: "ncSenderID"), !id.isEmpty { return id }
        let id = UUID().uuidString
        ud.set(id, forKey: "ncSenderID")
        return id
    }

    init(serviceType: String) {
        let security = MultipeerConfiguration.Security(identity: nil, encryptionPreference: .required) { _, context, decide in
            // Only Macs that know the group code get into the session
            guard let keys = MultipeerService.groupKeys else { return decide(false) }
            decide(Nearcast.isValidInvitation(context, keys: keys))
        }
        let configuration = MultipeerConfiguration(
            serviceType: serviceType,
            peerName: getMacDeviceName(),
            defaults: ud,
            security: security,
            invitation: .custom { _ in
                guard let keys = MultipeerService.groupKeys else { return nil }
                return (context: Nearcast.invitationToken(keys: keys), timeout: 10)
            })
        transceiver = MultipeerTransceiver(configuration: configuration)

        transceiver.receive(Data.self) { [weak self] data, peer in
            DispatchQueue.global().async { self?.handle(data, from: peer) }
        }
        transceiver.availablePeersDidChange = { [weak self] _ in self?.updateConnectedPeers() }
        transceiver.peerDisconnected = { [weak self] peer in
            Log.nearcast.notice("Peer disconnected: \(peer.name)")
            self?.updateConnectedPeers()
        }
        // A Mac that joins gets our data, and sends us its own
        transceiver.peerConnected = { [weak self] peer in
            Log.nearcast.notice("Peer connected: \(peer.name)")
            self?.updateConnectedPeers()
            DispatchQueue.global().async {
                self?.send(.resend, to: peer)
                self?.sendData(to: peer)
            }
        }
    }

    private func handle(_ data: Data, from peer: Peer) {
        guard let keys = MultipeerService.groupKeys,
              let payload = Nearcast.open(data, keys: keys) else {
            Log.nearcast.error("Ignored a Nearcast message from \(peer.name): not from this group, or tampered")
            return
        }
        guard replays.accept(payload) else {
            Log.nearcast.error("Ignored a replayed or out-of-date Nearcast message from \(peer.name)")
            return
        }
        switch payload.command {
        case .data:
            // Same file format as before: the sender's devices, in JSON
            guard (try? JSONSerialization.jsonObject(with: payload.content)) is [Any] else { return }
            let url = ncFolder.appendingPathComponent(ncFileName(for: payload.sender) + ".json")
            try? payload.content.write(to: url, options: .atomic)
            Log.nearcast.debug("Data received from \(payload.name)")
        case .resend:
            sendData(to: peer, force: true)
        case .notify:
            if let info = try? JSONDecoder().decode(NCNotification.self, from: payload.content) {
                createNotification(title: info.title, message: "\(info.info) (\(payload.name))")
            }
        }
    }

    private func updateConnectedPeers() {
        let names = connectedPeers().map(\.name).sorted()
        DispatchQueue.main.async { if self.connectedNames != names { self.connectedNames = names } }
    }

    func resume() {
        guard MultipeerService.groupKeys != nil else { return }
        transceiver.resume()
        Log.nearcast.notice("Nearcast is running")
    }

    func stop() {
        transceiver.stop()
        DispatchQueue.main.async { self.connectedNames = [] }
        Log.nearcast.notice("Nearcast has stopped")
    }

    private func connectedPeers() -> [Peer] {
        return removeDuplicatesPeer(peers: transceiver.availablePeers.filter { $0.isConnected })
    }

    private func send(_ command: Nearcast.Command, content: Data = Data(), to peer: Peer? = nil) {
        guard let keys = MultipeerService.groupKeys else { return }
        let payload = Nearcast.Payload(sender: MultipeerService.senderID, name: ud.string(forKey: "deviceName") ?? "Mac",
                                       command: command, sequence: sequence.next(), content: content)
        guard let data = try? Nearcast.seal(payload, keys: keys) else {
            Log.nearcast.error("Failed to seal a Nearcast message")
            return
        }
        let peers = peer.map { [$0] } ?? connectedPeers()
        if !peers.isEmpty { transceiver.send(data, to: peers) }
    }

    /// This Mac's devices, as written to the other Macs' NearcastData folders.
    private func currentData() -> Data? {
        var allDevices = AirBatteryModel.getAll()
        allDevices.insert(ib2ab(InternalBattery.status), at: 0)
        return try? JSONEncoder().encode(allDevices)
    }

    /// Sends this Mac's devices to one peer, or to all of them when something changed (or every
    /// 5 minutes, so the others never see this Mac as gone). v1 sent everything at each interval.
    func sendData(to peer: Peer? = nil, force: Bool = false) {
        guard let data = currentData() else { return }
        if peer == nil && !force {
            let now = Date().timeIntervalSince1970
            sendLock.lock()
            let due = data != lastSentData || now - lastSentTime >= 300
            if due { lastSentData = data; lastSentTime = now }
            sendLock.unlock()
            guard due else { return }
        }
        send(.data, content: data, to: peer)
    }

    /// Asks every connected Mac for its data (on wake, or when the list is opened).
    func refreshAll() {
        Log.nearcast.debug("Pulling data")
        send(.resend)
    }

    /// Forwards a battery alert to the other Macs.
    func sendNotification(title: String, info: String) {
        guard let content = try? JSONEncoder().encode(NCNotification(type: 0, title: title, info: info, atta: "")) else { return }
        send(.notify, content: content)
    }
}

func removeDuplicatesPeer(peers: [Peer]) -> [Peer] {
    var seenIDs = Set<String>()
    return peers.filter { seenIDs.insert($0.id).inserted }
}

struct NCNotification: Codable {
    /// 0 = normal (other values were v1 error notices)
    let type: Int
    let title: String
    let info: String
    let atta: String
}

/// File name for a peer's data. The sender ID is authenticated in v2, but a hash keeps any
/// unexpected character out of the path (AUDIT-2026-10-25, Nearcast 1).
func ncFileName(for sender: String) -> String {
    if sender.range(of: "^[A-Za-z0-9-]{1,64}$", options: .regularExpression) != nil { return sender }
    return SHA256.hash(data: Data(sender.utf8)).map { String(format: "%02x", $0) }.joined()
}
