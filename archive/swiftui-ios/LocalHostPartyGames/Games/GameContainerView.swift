import SwiftUI

struct GameContainerView: View {
    @EnvironmentObject private var app: AppModel
    let gameID: GameID

    private var definition: GameDefinition { GameRegistry.definition(for: gameID) }

    var body: some View {
        ZStack {
            PartyTheme.background.ignoresSafeArea()
            gameBody
        }
        .navigationTitle(definition.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var gameBody: some View {
        switch gameID {
        case .cupPong:
            CupPongGameView()
        case .wheelie:
            WheelieGameView()
        case .animalStack:
            AnimalStackGameView()
        case .basketballHoops:
            BasketballHoopsGameView()
        case .brainrotStack:
            BrainrotStackGameView()
        case .archery:
            ArcheryGameView()
        }
    }
}

struct TurnBanner: View {
    let playerIndex: Int
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(PartyTheme.playerColor(playerIndex))
                .frame(width: 18, height: 18)
            Text(message)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(PartyTheme.ink)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.92))
    }
}

struct RoundResultOverlay: View {
    let title: String
    let detail: String
    let onAgain: () -> Void
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                Text(detail)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(PartyTheme.mutedInk)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button("Again", action: onAgain)
                        .buttonStyle(.borderedProminent)
                    Button("Done", action: onDone)
                        .buttonStyle(.bordered)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.white)
            )
        }
    }
}
