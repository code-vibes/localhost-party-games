import UIKit
import SwiftUI

struct BasketballHoopsGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var scores: [Int]
    @State private var currentPlayer = 0
    @State private var timeLeft = 12.0
    @State private var ball: CGSize = .zero
    @State private var flying = false
    @State private var hoopX: CGFloat = 0
    @State private var showResult = false
    @State private var timer: Timer?
    @State private var hoopTimer: Timer?

    init() {
        _scores = State(initialValue: [])
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TurnBanner(playerIndex: currentPlayer, message: "\(PartyTheme.playerName(currentPlayer)) · swipe up to shoot · \(Int(timeLeft))s")

                ZStack {
                    LinearGradient(colors: [Color.blue.opacity(0.12), Color.orange.opacity(0.12)], startPoint: .top, endPoint: .bottom)

                    // Hoop
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(width: 90, height: 54)
                        Circle()
                            .stroke(Color.orange, lineWidth: 6)
                            .frame(width: 64, height: 64)
                            .offset(y: -12)
                    }
                    .offset(x: hoopX, y: -80)
                    .animation(.easeInOut(duration: 0.9), value: hoopX)

                    // Ball
                    Circle()
                        .fill(.orange)
                        .overlay(
                            Circle().stroke(.black.opacity(0.35), lineWidth: 2)
                        )
                        .frame(width: 44, height: 44)
                        .offset(x: ball.width, y: 150 + ball.height)
                }
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            guard !flying, timeLeft > 0 else { return }
                            shoot(translation: value.translation)
                        }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("Score \(currentScore)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .padding(.bottom, 18)
            }
            .onAppear(perform: startTurn)
            .onDisappear {
                timer?.invalidate()
                hoopTimer?.invalidate()
            }

            if showResult {
                RoundResultOverlay(
                    title: winnerTitle,
                    detail: displayScores,
                    onAgain: restart,
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

    private var currentScore: Int {
        scores.indices.contains(currentPlayer) ? scores[currentPlayer] : 0
    }

    private var displayScores: String {
        scores.enumerated().map { "\(PartyTheme.playerName($0.offset)): \($0.element)" }.joined(separator: " · ")
    }

    private var winnerTitle: String {
        guard let winner = scores.indices.max(by: { scores[$0] < scores[$1] }) else { return "Done" }
        return "\(PartyTheme.playerName(winner)) wins!"
    }

    private func startTurn() {
        if scores.count <= currentPlayer { scores.append(0) }
        timeLeft = 12
        ball = .zero
        flying = false
        timer?.invalidate()
        hoopTimer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1
            if timeLeft <= 0 {
                timer?.invalidate()
                hoopTimer?.invalidate()
                endTurn()
            }
        }
        hoopTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { _ in
            hoopX = CGFloat.random(in: -110...110)
        }
    }

    private func shoot(translation: CGSize) {
        flying = true
        let target = CGSize(width: translation.width * 0.8 + hoopX * 0.2, height: -260 + min(0, translation.height))
        withAnimation(.easeOut(duration: 0.5)) {
            ball = target
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let dx = ball.width - hoopX
            let dy = (150 + ball.height) + 80
            if abs(dx) < 36 && abs(dy) < 50 {
                scores[currentPlayer] += 1
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
            withAnimation(.easeIn(duration: 0.2)) { ball = .zero }
            flying = false
        }
    }

    private func endTurn() {
        if currentPlayer + 1 >= app.playerCount.rawValue {
            showResult = true
        } else {
            currentPlayer += 1
            startTurn()
        }
    }

    private func restart() {
        scores = []
        currentPlayer = 0
        showResult = false
        startTurn()
    }
}
