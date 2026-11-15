import UIKit
import SwiftUI

struct BrainrotStackGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    private let bits = ["☕", "🛞", "🪿", "🐸", "📦", "🧢", "🍌", "🗿"]

    @State private var layers: [BrainLayer] = []
    @State private var slider: CGFloat = 0
    @State private var direction: CGFloat = 1
    @State private var currentPlayer = 0
    @State private var scores: [Int] = []
    @State private var showResult = false
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TurnBanner(playerIndex: currentPlayer, message: "\(PartyTheme.playerName(currentPlayer)) · drop the brainrot")

                ZStack(alignment: .bottom) {
                    Color(red: 0.90, green: 0.92, blue: 1.0)
                    VStack(spacing: 2) {
                        ForEach(layers.reversed()) { layer in
                            Text(layer.emoji)
                                .font(.system(size: 34))
                                .frame(width: layer.width, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(layer.color)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black, lineWidth: 2))
                                )
                                .offset(x: layer.x)
                        }
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.green)
                            .frame(width: 160, height: 16)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 2))
                    }
                    .padding(.bottom, 40)

                    Text(bits[layers.count % bits.count])
                        .font(.system(size: 36))
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2))
                        )
                        .offset(x: slider, y: -280)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: drop)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("Height \(layers.count)")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .padding(.bottom, 16)
            }
            .onAppear(perform: start)
            .onDisappear { timer?.invalidate() }

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

    private func start() {
        layers = []
        slider = 0
        direction = 1
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 45.0, repeats: true) { _ in
            slider += direction * 3.8
            if abs(slider) > 120 { direction *= -1 }
        }
    }

    private func drop() {
        let width = max(48, 140 - CGFloat(layers.count) * 8)
        let baseX = layers.last?.x ?? 0
        let piece = BrainLayer(
            id: UUID(),
            emoji: bits[layers.count % bits.count],
            width: width,
            x: slider,
            color: [Color.mint, .yellow, .purple, .orange, .cyan][layers.count % 5]
        )
        if !layers.isEmpty && abs(piece.x - baseX) > width * 0.55 {
            finish()
            return
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
            layers.append(piece)
        }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        if layers.count >= 10 { finish() }
    }

    private func finish() {
        timer?.invalidate()
        var next = scores
        if next.count <= currentPlayer { next.append(layers.count) } else { next[currentPlayer] = layers.count }
        scores = next
        if currentPlayer + 1 >= app.playerCount.rawValue {
            showResult = true
        } else {
            currentPlayer += 1
            start()
        }
    }

    private func restart() {
        scores = []
        currentPlayer = 0
        showResult = false
        start()
    }
}

struct BrainLayer: Identifiable {
    let id: UUID
    let emoji: String
    let width: CGFloat
    let x: CGFloat
    let color: Color
}
