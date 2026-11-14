import SwiftUI

enum GameID: String, CaseIterable, Identifiable, Codable, Hashable {
    case cupPong
    case wheelie
    case animalStack
    case basketballHoops
    case brainrotStack
    case archery

    var id: String { rawValue }
}

struct GameDefinition: Identifiable, Hashable {
    let id: GameID
    let title: String
    let bannerColor: Color
    let artBackground: Color
    let minPlayers: Int
    let maxPlayers: Int
    let supportsLocalHostSync: Bool
    let blurb: String
}

enum GameRegistry {
    static let all: [GameDefinition] = [
        GameDefinition(
            id: .cupPong,
            title: "CUP PONG",
            bannerColor: Color(red: 0.10, green: 0.45, blue: 0.42),
            artBackground: Color(red: 0.93, green: 0.97, blue: 0.95),
            minPlayers: 1,
            maxPlayers: 4,
            supportsLocalHostSync: true,
            blurb: "Flick the ball into the cups. First to clear the triangle wins."
        ),
        GameDefinition(
            id: .wheelie,
            title: "WHEELIE",
            bannerColor: Color(red: 0.08, green: 0.08, blue: 0.10),
            artBackground: Color(red: 0.78, green: 0.90, blue: 0.98),
            minPlayers: 1,
            maxPlayers: 4,
            supportsLocalHostSync: false,
            blurb: "Hold the balance in the green zone. Survive the longest."
        ),
        GameDefinition(
            id: .animalStack,
            title: "ANIMAL STACK",
            bannerColor: Color(red: 0.18, green: 0.55, blue: 0.95),
            artBackground: Color(red: 0.90, green: 0.96, blue: 1.0),
            minPlayers: 1,
            maxPlayers: 4,
            supportsLocalHostSync: true,
            blurb: "Drop animals onto the stack. Don't topple the tower."
        ),
        GameDefinition(
            id: .basketballHoops,
            title: "BASKETBALL HOOPS",
            bannerColor: Color(red: 0.20, green: 0.48, blue: 0.82),
            artBackground: Color(red: 0.94, green: 0.97, blue: 1.0),
            minPlayers: 1,
            maxPlayers: 4,
            supportsLocalHostSync: false,
            blurb: "Swipe to shoot. Most baskets before time runs out wins."
        ),
        GameDefinition(
            id: .brainrotStack,
            title: "BRAINROT STACK",
            bannerColor: Color(red: 0.08, green: 0.16, blue: 0.38),
            artBackground: Color(red: 0.93, green: 0.95, blue: 1.0),
            minPlayers: 1,
            maxPlayers: 4,
            supportsLocalHostSync: false,
            blurb: "Tap to drop chaotic meme objects. Build the tallest stack."
        ),
        GameDefinition(
            id: .archery,
            title: "ARCHERY",
            bannerColor: Color(red: 0.45, green: 0.52, blue: 0.22),
            artBackground: Color(red: 0.90, green: 0.95, blue: 0.82),
            minPlayers: 1,
            maxPlayers: 4,
            supportsLocalHostSync: false,
            blurb: "Aim and release. Closest to the bullseye scores."
        )
    ]

    static func definition(for id: GameID) -> GameDefinition {
        all.first { $0.id == id }!
    }

    static func games(for playerCount: PlayerCount) -> [GameDefinition] {
        all.filter { playerCount.rawValue >= $0.minPlayers && playerCount.rawValue <= $0.maxPlayers }
    }
}
