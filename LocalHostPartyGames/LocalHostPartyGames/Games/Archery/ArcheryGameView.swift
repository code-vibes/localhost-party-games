import UIKit
import SwiftUI

struct ArcheryGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var aimX: CGFloat = 0
    @State private var aimY: CGFloat = 0
    @State private var power: CGFloat = 0
    @State private var charging = false
    @State private var arrowFlying = false
    @State private var arrowPos: CGPoint = .zero
    @State private var currentPlayer = 0
    @State private var round = 0
    @State private var scores: [Int] = []
    @State private var lastHit = ""
    @State private var showResult = false
    @State private var wobbleTimer: Timer?

    private let maxRounds = 3

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TurnBanner(
                    playerIndex: currentPlayer,
                    message: "\(PartyTheme.playerName(currentPlayer)) · round \(min(round + 1, maxRounds))/\(maxRounds) · \(lastHit)"
                )

                ZStack {
                    LinearGradient(colors: [Color.green.opacity(0.2), Color.yellow.opacity(0.15)], startPoint: .top, endPoint: .bottom)

                    // Target
                    ZStack {
                        ForEach([(70, Color.blue.opacity(0.35)), (50, Color.white), (30, Color.red), (12, Color.yellow)], id: \.0) { size, color in
                            Circle()
                                .fill(color)
                                .overlay(Circle().stroke(.black, lineWidth: 2))
                                .frame(width: CGFloat(size * 2), height: CGFloat(size * 2))
                        }
                    }
                    .offset(x: aimX, y: -40 + aimY)

                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.system(size: 36, weight: .black))
                        .rotationEffect(.degrees(-90))
                        .offset(x: arrowPos.x, y: arrowFlying ? arrowPos.y : 170)
                        .opacity(arrowFlying ? 1 : 0.35)

                    // Power
                    VStack {
                        Spacer()
                        ProgressView(value: power)
                            .tint(PartyTheme.redPlayer)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard !arrowFlying, !showResult else { return }
                            if !charging {
                                charging = true
                                power = 0
                            }
                            power = min(1, power + 0.02)
                        }
                        .onEnded { _ in
                            guard charging, !arrowFlying else { return }
                            fire()
                        }
                )

                Text(scores.isEmpty ? "Hold to draw, release to fire" : displayScores)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.bottom, 16)
            }
            .onAppear(perform: startAimWobble)
            .onDisappear { wobbleTimer?.invalidate() }

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

    private var displayScores: String {
        ensureScoreSlots()
        return scores.enumerated().map { "\(PartyTheme.playerName($0.offset)): \($0.element)" }.joined(separator: " · ")
    }

    private var winnerTitle: String {
        ensureScoreSlots()
        guard let winner = scores.indices.max(by: { scores[$0] < scores[$1] }) else { return "Done" }
        return "\(PartyTheme.playerName(winner)) wins!"
    }

    private func ensureScoreSlots() {
        while scores.count < app.playerCount.rawValue { scores.append(0) }
    }

    private func startAimWobble() {
        ensureScoreSlots()
        wobbleTimer?.invalidate()
        wobbleTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard !arrowFlying else { return }
            aimX = sin(Date().timeIntervalSinceReferenceDate * 1.7) * 28
            aimY = cos(Date().timeIntervalSinceReferenceDate * 1.3) * 12
        }
    }

    private func fire() {
        charging = false
        arrowFlying = true
        let strength = 0.35 + power * 0.65
        let target = CGPoint(x: aimX * (1.2 - strength), y: -40 + aimY * (1.1 - strength))
        arrowPos = .init(x: 0, y: 170)
        withAnimation(.easeIn(duration: 0.45)) {
            arrowPos = target
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            scoreHit(at: target)
        }
    }

    private func scoreHit(at point: CGPoint) {
        let dist = sqrt(point.x * point.x + (point.y + 40) * (point.y + 40))
        let points: Int
        switch dist {
        case ..<14: points = 10; lastHit = "Bullseye! +10"
        case ..<32: points = 7; lastHit = "Inner ring +7"
        case ..<52: points = 4; lastHit = "White +4"
        case ..<72: points = 2; lastHit = "Blue +2"
        default: points = 0; lastHit = "Miss"
        }
        scores[currentPlayer] += points
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            arrowFlying = false
            power = 0
            advanceTurn()
        }
    }

    private func advanceTurn() {
        if currentPlayer + 1 >= app.playerCount.rawValue {
            currentPlayer = 0
            round += 1
            if round >= maxRounds {
                showResult = true
                return
            }
        } else {
            currentPlayer += 1
        }
    }

    private func restart() {
        scores = Array(repeating: 0, count: app.playerCount.rawValue)
        currentPlayer = 0
        round = 0
        lastHit = ""
        showResult = false
        arrowFlying = false
        power = 0
    }
}
