import SwiftUI

struct PlayerCountView: View {
    @EnvironmentObject private var app: AppModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            PartyTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text("How many players?")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(PartyTheme.ink)
                    .padding(.top, 8)

                Text("Pick a count for pass-and-play on this phone. Local Host works for 2–4 devices.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(PartyTheme.mutedInk)

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(PlayerCount.allCases) { count in
                        Button {
                            app.resetSessionScores(for: count)
                            app.path.append(.gameGrid)
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("\(count.rawValue)")
                                    .font(.system(size: 44, weight: .black, design: .rounded))
                                Text(count.title)
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                Text(count.subtitle)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(PartyTheme.mutedInk)
                                    .multilineTextAlignment(.leading)
                            }
                            .foregroundStyle(PartyTheme.ink)
                            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(.white)
                                    .shadow(color: PartyTheme.cardShadow, radius: 8, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(.white, lineWidth: 4)
                            )
                        }
                        .buttonStyle(BounceButtonStyle())
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("Players")
        .navigationBarTitleDisplayMode(.inline)
    }
}
