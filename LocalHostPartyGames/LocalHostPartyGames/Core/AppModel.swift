import Foundation
import Combine

@MainActor
final class AppModel: ObservableObject {
    @Published var path: [AppRoute] = []
    @Published var playerCount: PlayerCount = .two
    @Published var sessionScores: [Int] = [0, 0, 0, 0]
    @Published var localHost = LocalHostController()

    func resetSessionScores(for count: PlayerCount) {
        playerCount = count
        sessionScores = Array(repeating: 0, count: count.rawValue)
    }

    func awardWin(to playerIndex: Int) {
        guard sessionScores.indices.contains(playerIndex) else { return }
        sessionScores[playerIndex] += 1
    }
}

enum AppRoute: Hashable {
    case playerCount
    case gameGrid
    case game(GameID)
    case localHostLobby
    case joinLocalHost
}

enum PlayerCount: Int, CaseIterable, Identifiable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .one: return "1 PLAYER"
        case .two: return "2 PLAYERS"
        case .three: return "3 PLAYERS"
        case .four: return "4 PLAYERS"
        }
    }

    var subtitle: String {
        switch self {
        case .one: return "Solo practice on this phone"
        case .two: return "Pass-and-play party classics"
        case .three, .four: return "Same phone or Local Host"
        }
    }
}
