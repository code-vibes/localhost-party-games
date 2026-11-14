import SwiftUI

struct TwoPlayerGamesView: View {
    @EnvironmentObject private var app: AppModel

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            PartyTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(GameRegistry.games(for: app.playerCount)) { game in
                            Button {
                                app.path.append(.game(game.id))
                            } label: {
                                GameTileView(game: game)
                            }
                            .buttonStyle(BounceButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                PlayerScoreBar(
                    playerCount: app.playerCount,
                    scores: app.sessionScores
                )
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        "\(app.playerCount.rawValue) PLAYER GAMES"
    }
}

struct GameTileView: View {
    let game: GameDefinition

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                game.artBackground
                GameArtView(gameID: game.id)
                    .padding(10)
            }
            .frame(height: 132)

            Text(game.title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(game.bannerColor)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PartyTheme.tileBorder, lineWidth: 5)
        )
        .shadow(color: PartyTheme.cardShadow, radius: 6, y: 3)
        .aspectRatio(0.92, contentMode: .fit)
    }
}

struct PlayerScoreBar: View {
    let playerCount: PlayerCount
    let scores: [Int]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<playerCount.rawValue, id: \.self) { index in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(PartyTheme.playerColor(index))
                            .frame(width: 54, height: 54)
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text("\(scores.indices.contains(index) ? scores[index] : 0)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(PartyTheme.ink)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(.white))
                        .overlay(Circle().stroke(PartyTheme.playerColor(index).opacity(0.35), lineWidth: 2))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .background(
            Rectangle()
                .fill(.white.opacity(0.92))
                .shadow(color: PartyTheme.cardShadow, radius: 8, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
