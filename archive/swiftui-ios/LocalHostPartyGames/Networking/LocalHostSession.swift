import Foundation
import UIKit
import MultipeerConnectivity
import Combine

enum LocalHostRole: String, Codable {
    case host
    case client
}

struct LobbyPlayer: Identifiable, Codable, Hashable {
    let id: String
    var displayName: String
    var isHost: Bool
    var isReady: Bool
}

struct JoinPayload: Codable, Hashable {
    let sessionCode: String
    let serviceType: String
    let displayName: String
    let createdAt: TimeInterval

    var qrString: String {
        // localhostparty://join?code=ABCD&svc=lhost-party
        "localhostparty://join?code=\(sessionCode)&svc=\(serviceType)&name=\(displayName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? displayName)"
    }

    static func parse(_ raw: String) -> JoinPayload? {
        guard let url = URL(string: raw),
              url.scheme == "localhostparty",
              url.host == "join",
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { return nil }
        let dict = Dictionary(uniqueKeysWithValues: items.compactMap { item -> (String, String)? in
            guard let value = item.value else { return nil }
            return (item.name, value)
        })
        guard let code = dict["code"], let svc = dict["svc"] else { return nil }
        return JoinPayload(
            sessionCode: code,
            serviceType: svc,
            displayName: dict["name"] ?? "Host",
            createdAt: Date().timeIntervalSince1970
        )
    }
}

struct GameLobbyState: Codable, Hashable {
    var sessionCode: String
    var hostName: String
    var players: [LobbyPlayer]
    var selectedGame: GameID?
    var phase: Phase

    enum Phase: String, Codable {
        case lobby
        case countdown
        case playing
        case results
    }
}

enum LocalHostMessage: Codable {
    case hello(LobbyPlayer)
    case lobby(GameLobbyState)
    case ready(String)
    case selectGame(GameID)
    case startGame(GameID)
    case gameEvent(GameID, String)
    case chat(String)

    private enum Kind: String, Codable {
        case hello, lobby, ready, selectGame, startGame, gameEvent, chat
    }

    private enum CodingKeys: String, CodingKey {
        case kind, player, lobby, playerID, gameID, event, text
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .hello(let player):
            try c.encode(Kind.hello, forKey: .kind)
            try c.encode(player, forKey: .player)
        case .lobby(let lobby):
            try c.encode(Kind.lobby, forKey: .kind)
            try c.encode(lobby, forKey: .lobby)
        case .ready(let id):
            try c.encode(Kind.ready, forKey: .kind)
            try c.encode(id, forKey: .playerID)
        case .selectGame(let id):
            try c.encode(Kind.selectGame, forKey: .kind)
            try c.encode(id, forKey: .gameID)
        case .startGame(let id):
            try c.encode(Kind.startGame, forKey: .kind)
            try c.encode(id, forKey: .gameID)
        case .gameEvent(let id, let event):
            try c.encode(Kind.gameEvent, forKey: .kind)
            try c.encode(id, forKey: .gameID)
            try c.encode(event, forKey: .event)
        case .chat(let text):
            try c.encode(Kind.chat, forKey: .kind)
            try c.encode(text, forKey: .text)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .kind) {
        case .hello:
            self = .hello(try c.decode(LobbyPlayer.self, forKey: .player))
        case .lobby:
            self = .lobby(try c.decode(GameLobbyState.self, forKey: .lobby))
        case .ready:
            self = .ready(try c.decode(String.self, forKey: .playerID))
        case .selectGame:
            self = .selectGame(try c.decode(GameID.self, forKey: .gameID))
        case .startGame:
            self = .startGame(try c.decode(GameID.self, forKey: .gameID))
        case .gameEvent:
            self = .gameEvent(
                try c.decode(GameID.self, forKey: .gameID),
                try c.decode(String.self, forKey: .event)
            )
        case .chat:
            self = .chat(try c.decode(String.self, forKey: .text))
        }
    }
}

@MainActor
final class LocalHostController: NSObject, ObservableObject {
    static let serviceType = "lhost-party"

    @Published var role: LocalHostRole?
    @Published var sessionCode: String = ""
    @Published var joinPayload: JoinPayload?
    @Published var lobby = GameLobbyState(sessionCode: "", hostName: "", players: [], selectedGame: nil, phase: .lobby)
    @Published var connectedPeers: [MCPeerID] = []
    @Published var statusText: String = "Idle"
    @Published var lastError: String?

    private var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var myPlayerID = UUID().uuidString

    override init() {
        super.init()
    }

    func hostSession(displayName: String = UIDevice.current.name) {
        tearDown()
        role = .host
        sessionCode = Self.makeCode()
        peerID = MCPeerID(displayName: displayName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        let discovery: [String: String] = ["code": sessionCode, "name": displayName]
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: discovery, serviceType: Self.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()

        let hostPlayer = LobbyPlayer(id: myPlayerID, displayName: displayName, isHost: true, isReady: true)
        lobby = GameLobbyState(
            sessionCode: sessionCode,
            hostName: displayName,
            players: [hostPlayer],
            selectedGame: nil,
            phase: .lobby
        )
        joinPayload = JoinPayload(
            sessionCode: sessionCode,
            serviceType: Self.serviceType,
            displayName: displayName,
            createdAt: Date().timeIntervalSince1970
        )
        statusText = "Hosting \(sessionCode) — waiting for players"
    }

    func joinSession(payload: JoinPayload, displayName: String = UIDevice.current.name) {
        tearDown()
        role = .client
        sessionCode = payload.sessionCode
        joinPayload = payload
        peerID = MCPeerID(displayName: displayName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: payload.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        statusText = "Looking for host \(payload.sessionCode)…"
    }

    func setReady(_ ready: Bool) {
        guard let idx = lobby.players.firstIndex(where: { $0.id == myPlayerID }) else { return }
        lobby.players[idx].isReady = ready
        broadcast(.ready(myPlayerID))
        if role == .host { broadcastLobby() }
    }

    func selectGame(_ id: GameID) {
        guard role == .host else { return }
        lobby.selectedGame = id
        broadcast(.selectGame(id))
        broadcastLobby()
    }

    func startSelectedGame() {
        guard role == .host, let game = lobby.selectedGame else { return }
        lobby.phase = .playing
        broadcast(.startGame(game))
        broadcastLobby()
    }

    func leave() {
        tearDown()
        role = nil
        statusText = "Left session"
    }

    private func tearDown() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        connectedPeers = []
        lastError = nil
    }

    private func broadcastLobby() {
        broadcast(.lobby(lobby))
    }

    private func broadcast(_ message: LocalHostMessage) {
        guard let session, !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func send(_ message: LocalHostMessage, to peers: [MCPeerID]) {
        guard let session else { return }
        do {
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func handle(message: LocalHostMessage, from peer: MCPeerID) {
        switch message {
        case .hello(let player):
            if role == .host {
                if !lobby.players.contains(where: { $0.id == player.id }) {
                    lobby.players.append(player)
                }
                broadcastLobby()
            }
        case .lobby(let state):
            lobby = state
            statusText = "Lobby \(state.sessionCode) · \(state.players.count) players"
        case .ready(let id):
            if let idx = lobby.players.firstIndex(where: { $0.id == id }) {
                lobby.players[idx].isReady = true
            }
        case .selectGame(let id):
            lobby.selectedGame = id
        case .startGame(let id):
            lobby.selectedGame = id
            lobby.phase = .playing
            statusText = "Starting \(GameRegistry.definition(for: id).title)"
        case .gameEvent, .chat:
            break
        }
    }

    private static func makeCode() -> String {
        let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<4).map { _ in alphabet.randomElement()! })
    }
}

extension LocalHostController: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            connectedPeers = session.connectedPeers
            switch state {
            case .connected:
                statusText = "Connected to \(peerID.displayName)"
                if role == .client {
                    let me = LobbyPlayer(id: myPlayerID, displayName: self.peerID.displayName, isHost: false, isReady: false)
                    send(.hello(me), to: [peerID])
                } else {
                    broadcastLobby()
                }
            case .connecting:
                statusText = "Connecting to \(peerID.displayName)…"
            case .notConnected:
                statusText = "Disconnected from \(peerID.displayName)"
                lobby.players.removeAll { $0.displayName == peerID.displayName && !$0.isHost }
                if role == .host { broadcastLobby() }
            @unknown default:
                break
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            guard let message = try? JSONDecoder().decode(LocalHostMessage.self, from: data) else { return }
            handle(message: message, from: peerID)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension LocalHostController: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Task { @MainActor in lastError = error.localizedDescription }
    }

    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

extension LocalHostController: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        Task { @MainActor in lastError = error.localizedDescription }
    }

    nonisolated func browser(
        _ browser: MCNearbyServiceBrowser,
        foundPeer peerID: MCPeerID,
        withDiscoveryInfo info: [String: String]?
    ) {
        Task { @MainActor in
            guard let code = info?["code"], code == sessionCode, let session else { return }
            statusText = "Found host \(peerID.displayName)"
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 12)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

