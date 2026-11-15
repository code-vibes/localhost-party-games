import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        NavigationStack(path: $app.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .playerCount:
                        PlayerCountView()
                    case .gameGrid:
                        TwoPlayerGamesView()
                    case .game(let id):
                        GameContainerView(gameID: id)
                    case .localHostLobby:
                        LocalHostLobbyView()
                    case .joinLocalHost:
                        JoinLocalHostView()
                    }
                }
        }
        .tint(PartyTheme.ink)
    }
}
