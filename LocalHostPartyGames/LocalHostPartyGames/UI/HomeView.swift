import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        ZStack {
            atmosphere

            VStack(spacing: 28) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Text("LOCAL HOST")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .tracking(4)
                        .foregroundStyle(PartyTheme.mutedInk)

                    Text("1234")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(PartyTheme.ink)
                        .shadow(color: PartyTheme.cardShadow, radius: 0, x: 0, y: 4)

                    Text("PARTY GAMES")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(PartyTheme.ink)

                    Text("Same-phone chaos or hotspot multiplayer.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(PartyTheme.mutedInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 14) {
                    Button {
                        app.path.append(.playerCount)
                    } label: {
                        primaryLabel("PLAY ON THIS PHONE")
                    }
                    .buttonStyle(BounceButtonStyle())

                    Button {
                        app.path.append(.localHostLobby)
                    } label: {
                        secondaryLabel("HOST LOCAL SESSION")
                    }
                    .buttonStyle(BounceButtonStyle())

                    Button {
                        app.path.append(.joinLocalHost)
                    } label: {
                        secondaryLabel("JOIN VIA QR / LAN")
                    }
                    .buttonStyle(BounceButtonStyle())
                }
                .padding(.horizontal, 24)

                Spacer()
                colorfulStrip
                    .padding(.bottom, 28)
            }
        }
        .navigationBarHidden(true)
    }

    private var atmosphere: some View {
        ZStack {
            PartyTheme.background.ignoresSafeArea()
            LinearGradient(
                colors: [
                    Color(red: 0.86, green: 0.93, blue: 1.0),
                    PartyTheme.background,
                    Color(red: 0.96, green: 0.93, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(PartyTheme.redPlayer.opacity(0.12))
                .frame(width: 220, height: 220)
                .blur(radius: 30)
                .offset(x: -120, y: -180)

            Circle()
                .fill(PartyTheme.bluePlayer.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 34)
                .offset(x: 140, y: 220)
        }
    }

    private func primaryLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(PartyTheme.ink)
            )
    }

    private func secondaryLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(PartyTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white)
                    .shadow(color: PartyTheme.cardShadow, radius: 10, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white, lineWidth: 3)
            )
    }

    private var colorfulStrip: some View {
        HStack(spacing: 10) {
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GameRegistry.all[i].bannerColor)
                    .frame(width: 42, height: 42)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(.white, lineWidth: 3)
                    )
                    .rotationEffect(.degrees(Double(i.isMultiple(of: 2) ? -6 : 6)))
            }
        }
    }
}
