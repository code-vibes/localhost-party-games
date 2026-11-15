import UIKit
import SwiftUI

struct AnimalStackGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    private let animals = ["🐱", "🐶", "🐯", "🐮", "🐸", "🐧", "🦊", "🐷"]
    private let colors: [Color] = [.pink, .orange, .yellow, .mint, .cyan, .purple, .brown, .indigo]

    @State private var stack: [StackedAnimal] = []
    @State private var fallingX: CGFloat = 0
    @State private var direction: CGFloat = 1
    @State private var currentPlayer = 0
    @State private var scores: [Int] = []
    @State private var alive = true
    @State private var showResult = false
    @State private var ticker: Timer?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TurnBanner(playerIndex: currentPlayer, message: "\(PartyTheme.playerName(currentPlayer)) · tap to drop")

                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        Color(red: 0.88, green: 0.95, blue: 1.0)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                            .frame(height: 18)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 30)

                        ForEach(stack) { item in
                            animalView(item)
                                .position(x: geo.size.width / 2 + item.x, y: geo.size.height - 50 - CGFloat(item.level) * 36)
                        }

                        if alive {
                            animalView(StackedAnimal(id: UUID(), index: stack.count, x: fallingX, level: stack.count))
                                .position(x: geo.size.width / 2 + fallingX, y: 70)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { drop(in: geo.size.width) }
                }

                Text("Stack: \(stack.count)")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .padding(.bottom, 16)
            }
            .onAppear(perform: startRound)
            .onDisappear { ticker?.invalidate() }

            if showResult {
                RoundResultOverlay(
                    title: winnerTitle,
                    detail: scores.enumerated().map { "\(PartyTheme.playerName($0.offset)): \($0.element)" }.joined(separator: " · "),
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

    private var winnerTitle: String {
        guard let winner = scores.indices.max(by: { scores[$0] < scores[$1] }) else { return "Done" }
        return "\(PartyTheme.playerName(winner)) wins!"
    }

    private func animalView(_ item: StackedAnimal) -> some View {
        Text(animals[item.index % animals.count])
            .font(.system(size: 30))
            .padding(6)
            .background(
                Capsule()
                    .fill(colors[item.index % colors.count].opacity(0.85))
                    .overlay(Capsule().stroke(.black, lineWidth: 2))
            )
    }

    private func startRound() {
        stack = []
        fallingX = 0
        direction = 1
        alive = true
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1.0 / 40.0, repeats: true) { _ in
            guard alive else { return }
            fallingX += direction * 3.2
            if abs(fallingX) > 110 { direction *= -1 }
        }
    }

    private func drop(in width: CGFloat) {
        guard alive else { return }
        let previousX = stack.last?.x ?? 0
        let next = StackedAnimal(id: UUID(), index: stack.count, x: fallingX, level: stack.count)
        if !stack.isEmpty && abs(next.x - previousX) > 48 {
            crash()
            return
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            stack.append(next)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if stack.count >= 12 {
            finishRound()
        }
    }

    private func crash() {
        alive = false
        ticker?.invalidate()
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            finishRound()
        }
    }

    private func finishRound() {
        var nextScores = scores
        if nextScores.count <= currentPlayer {
            nextScores.append(stack.count)
        } else {
            nextScores[currentPlayer] = stack.count
        }
        scores = nextScores
        if currentPlayer + 1 >= app.playerCount.rawValue {
            showResult = true
        } else {
            currentPlayer += 1
            startRound()
        }
    }

    private func restart() {
        scores = []
        currentPlayer = 0
        showResult = false
        startRound()
    }
}

struct StackedAnimal: Identifiable {
    let id: UUID
    let index: Int
    let x: CGFloat
    let level: Int
}
