import SwiftUI

struct LocalHostLobbyView: View {
    @EnvironmentObject private var app: AppModel
    @State private var started = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Host a Local Session")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))

                Text("Creates a Bonjour / Multipeer session on your Wi‑Fi or personal hotspot. Friends scan the QR (or enter the code) to join — no internet required.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(PartyTheme.mutedInk)

                if !started {
                    Button {
                        app.localHost.hostSession()
                        started = true
                    } label: {
                        Text("START HOSTING")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(PartyTheme.ink))
                    }
                    .buttonStyle(BounceButtonStyle())
                } else {
                    hostPanel
                }
            }
            .padding(20)
        }
        .background(PartyTheme.background.ignoresSafeArea())
        .navigationTitle("Local Host")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Keep session alive while navigating into games from lobby; only leave via button.
        }
    }

    private var hostPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session code")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(PartyTheme.mutedInk)
                    Text(app.localHost.sessionCode)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .tracking(6)
                }
                Spacer()
                statusChip
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(.white))

            if let payload = app.localHost.joinPayload {
                VStack(spacing: 10) {
                    QRCodeView(value: payload.qrString)
                    Text(payload.qrString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(PartyTheme.mutedInk)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity)
            }

            playersList

            Text("Pick a game for the lobby")
                .font(.system(size: 15, weight: .heavy, design: .rounded))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(GameRegistry.all) { game in
                    Button {
                        app.localHost.selectGame(game.id)
                    } label: {
                        Text(game.title)
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(game.bannerColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(app.localHost.lobby.selectedGame == game.id ? Color.white : .clear, lineWidth: 3)
                            )
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }

            if let selected = app.localHost.lobby.selectedGame {
                Button {
                    app.localHost.startSelectedGame()
                    app.playerCount = PlayerCount(rawValue: max(2, min(4, app.localHost.lobby.players.count))) ?? .two
                    app.path.append(.game(selected))
                } label: {
                    Text(app.localHost.lobby.selectedGame.map { "PLAY \($0.rawValue.uppercased())" } ?? "PLAY")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(PartyTheme.redPlayer))
                }
                .buttonStyle(BounceButtonStyle())

                if !GameRegistry.definition(for: selected).supportsLocalHostSync {
                    Text("Lobby is wired for all games. Live input sync ships first for Cup Pong & Animal Stack; others still launch on each device for pass-and-play style rounds.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(PartyTheme.mutedInk)
                }
            }

            Button("Stop hosting") {
                app.localHost.leave()
                started = false
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }
    }

    private var playersList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Players (\(app.localHost.lobby.players.count)/4)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
            ForEach(app.localHost.lobby.players) { player in
                HStack {
                    Circle()
                        .fill(player.isHost ? PartyTheme.redPlayer : PartyTheme.bluePlayer)
                        .frame(width: 12, height: 12)
                    Text(player.displayName + (player.isHost ? " (host)" : ""))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Spacer()
                    Text(player.isReady ? "READY" : "…")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(player.isReady ? PartyTheme.greenPlayer : PartyTheme.mutedInk)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white))
            }
            Text(app.localHost.statusText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(PartyTheme.mutedInk)
            if let error = app.localHost.lastError {
                Text(error)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(PartyTheme.redPlayer)
            }
        }
    }

    private var statusChip: some View {
        Text(app.localHost.connectedPeers.isEmpty ? "WAITING" : "LIVE")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(app.localHost.connectedPeers.isEmpty ? PartyTheme.mutedInk : PartyTheme.greenPlayer))
    }
}

struct JoinLocalHostView: View {
    @EnvironmentObject private var app: AppModel
    @State private var manualCode = ""
    @State private var scanning = false
    @State private var joined = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Join Local Host")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))

                Text("Connect to the same Wi‑Fi or the host’s iPhone hotspot, then scan their QR or type the 4-letter code.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(PartyTheme.mutedInk)

                Button {
                    scanning = true
                } label: {
                    Text("SCAN QR CODE")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(PartyTheme.bluePlayer))
                }
                .buttonStyle(BounceButtonStyle())

                HStack {
                    TextField("CODE", text: $manualCode)
                        .textInputAutocapitalization(.characters)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                    Button("JOIN") {
                        join(code: manualCode)
                    }
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .disabled(manualCode.count < 4)
                }

                if joined {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(app.localHost.statusText)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        ForEach(app.localHost.lobby.players) { player in
                            Text("• \(player.displayName)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        if app.localHost.lobby.phase == .playing, let game = app.localHost.lobby.selectedGame {
                            Button("Open \(GameRegistry.definition(for: game).title)") {
                                app.path.append(.game(game))
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        Button("Leave") {
                            app.localHost.leave()
                            joined = false
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                }
            }
            .padding(20)
        }
        .background(PartyTheme.background.ignoresSafeArea())
        .navigationTitle("Join")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $scanning) {
            NavigationStack {
                QRScannerView { value in
                    scanning = false
                    if let payload = JoinPayload.parse(value) {
                        app.localHost.joinSession(payload: payload)
                        joined = true
                    } else if value.count == 4 {
                        join(code: value)
                    }
                }
                .navigationTitle("Scan QR")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { scanning = false }
                    }
                }
            }
        }
    }

    private func join(code: String) {
        let payload = JoinPayload(
            sessionCode: code.uppercased(),
            serviceType: LocalHostController.serviceType,
            displayName: "Host",
            createdAt: Date().timeIntervalSince1970
        )
        app.localHost.joinSession(payload: payload)
        joined = true
    }
}
