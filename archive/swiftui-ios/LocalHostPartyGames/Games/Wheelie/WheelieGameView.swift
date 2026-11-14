import UIKit
import SwiftUI

struct WheelieGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var balance: Double = 0
    @State private var velocity: Double = 0
    @State private var holding = false
    @State private var alive = true
    @State private var elapsed: TimeInterval = 0
    @State private var scores: [Double] = []
    @State private var currentPlayer = 0
    @State private var showResult = false
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TurnBanner(
                    playerIndex: currentPlayer,
                    message: alive
                        ? "\(PartyTheme.playerName(currentPlayer)) · hold in the green zone"
                        : "Crashed!"
                )

                ZStack {
                    LinearGradient(colors: [Color(red: 0.7, green: 0.88, blue: 1), Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                    road
                    bike
                    meter
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 12) {
                    Text(String(format: "Time %.1fs", elapsed))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                    Text(holding ? "HOLDING ▲" : "Press & hold to lean up")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(PartyTheme.mutedInk)

                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(holding ? PartyTheme.redPlayer : PartyTheme.ink)
                        .frame(height: 64)
                        .overlay(
                            Text(alive ? "HOLD" : "NEXT")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        )
                        .padding(.horizontal, 24)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if alive { holding = true }
                                }
                                .onEnded { _ in
                                    holding = false
                                    if !alive { advanceAfterCrash() }
                                }
                        )
                }
                .padding(.bottom, 20)
            }
            .onAppear(perform: startRound)
            .onDisappear { timer?.invalidate() }

            if showResult {
                RoundResultOverlay(
                    title: winnerTitle,
                    detail: scores.enumerated().map { "\(PartyTheme.playerName($0.offset)): \(String(format: "%.1fs", $0.element))" }.joined(separator: " · "),
                    onAgain: restartMatch,
                    onDone: {
                        if let winner = scores.indices.max(by: { scores[$0] < scores[$1] }) {
                            app.awardWin(to: winner)
                        }
                        dismiss()
                    }
                )
            }
        }
    }

    private var winnerTitle: String {
        guard let winner = scores.indices.max(by: { scores[$0] < scores[$1] }) else { return "Done" }
        return "\(PartyTheme.playerName(winner)) wins!"
    }

    private var road: some View {
        VStack {
            Spacer()
            Rectangle()
                .fill(Color.gray.opacity(0.55))
                .frame(height: 70)
                .overlay(
                    HStack(spacing: 18) {
                        ForEach(0..<8, id: \.self) { _ in
                            Capsule().fill(.yellow).frame(width: 28, height: 6)
                        }
                    }
                )
        }
    }

    private var bike: some View {
        Image(systemName: "bicycle")
            .font(.system(size: 64, weight: .bold))
            .foregroundStyle(PartyTheme.redPlayer)
            .rotationEffect(.degrees(balance * 55 - 20))
            .offset(y: 40)
            .animation(.interactiveSpring(), value: balance)
    }

    private var meter: some View {
        VStack {
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.8)).frame(height: 14)
                Capsule().fill(Color.green.opacity(0.7)).frame(width: 70, height: 14).offset(x: 90)
                Circle()
                    .fill(PartyTheme.redPlayer)
                    .frame(width: 18, height: 18)
                    .offset(x: CGFloat(balance) * 220)
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)
            Spacer()
        }
    }

    private func startRound() {
        balance = 0.45
        velocity = 0
        elapsed = 0
        alive = true
        holding = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            tick()
        }
    }

    private func tick() {
        guard alive else { return }
        let force = holding ? -0.012 : 0.010
        velocity += force + Double.random(in: -0.004...0.004)
        balance = min(1, max(0, balance + velocity))
        elapsed += 1.0 / 30.0
        if balance <= 0.02 || balance >= 0.98 {
            alive = false
            holding = false
            timer?.invalidate()
            messageCrash()
        }
    }

    private func messageCrash() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    private func advanceAfterCrash() {
        var next = scores
        if next.count <= currentPlayer {
            next.append(elapsed)
        } else {
            next[currentPlayer] = elapsed
        }
        scores = next
        if currentPlayer + 1 >= app.playerCount.rawValue {
            showResult = true
        } else {
            currentPlayer += 1
            startRound()
        }
    }

    private func restartMatch() {
        scores = []
        currentPlayer = 0
        showResult = false
        startRound()
    }
}
