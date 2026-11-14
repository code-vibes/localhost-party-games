import UIKit
import SwiftUI

struct CupPongGameView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var cupsRemaining: [Bool] = Array(repeating: true, count: 6)
    @State private var currentPlayer = 0
    @State private var ballOffset: CGSize = .zero
    @State private var isFlying = false
    @State private var aim: CGSize = .zero
    @State private var message = "Drag and release to throw"
    @State private var showResult = false
    @State private var winnerIndex: Int?

    private let cupPositions: [CGPoint] = [
        .init(x: -40, y: -10), .init(x: 0, y: -10), .init(x: 40, y: -10),
        .init(x: -20, y: 30), .init(x: 20, y: 30),
        .init(x: 0, y: 70)
    ]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                TurnBanner(playerIndex: currentPlayer, message: "\(PartyTheme.playerName(currentPlayer)) · \(message)")

                ZStack {
                    LinearGradient(colors: [Color.cyan.opacity(0.15), Color.teal.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    table
                    ball
                }
                .gesture(dragGesture)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Text("Cups left: \(cupsRemaining.filter { $0 }.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .padding(.bottom, 12)
            }

            if showResult, let winnerIndex {
                RoundResultOverlay(
                    title: "\(PartyTheme.playerName(winnerIndex)) wins!",
                    detail: "Cleared the cup triangle.",
                    onAgain: resetMatch,
                    onDone: {
                        app.awardWin(to: winnerIndex)
                        dismiss()
                    }
                )
            }
        }
    }

    private var table: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.15, green: 0.45, blue: 0.4))
                .frame(width: 220, height: 180)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white, lineWidth: 4))
            ForEach(cupPositions.indices, id: \.self) { i in
                if cupsRemaining[i] {
                    Capsule()
                        .fill(Color.red)
                        .overlay(Capsule().stroke(.black, lineWidth: 2))
                        .frame(width: 34, height: 42)
                        .position(x: 160 + cupPositions[i].x, y: 140 + cupPositions[i].y)
                }
            }
            .frame(width: 320, height: 280)
        }
    }

    private var ball: some View {
        Circle()
            .fill(.white)
            .overlay(Circle().stroke(.black, lineWidth: 2))
            .frame(width: 28, height: 28)
            .offset(x: ballOffset.width + aim.width, y: 160 + ballOffset.height + aim.height)
            .shadow(radius: 3, y: 2)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !isFlying, !showResult else { return }
                aim = CGSize(width: value.translation.width * 0.35, height: min(0, value.translation.height * 0.35))
            }
            .onEnded { value in
                guard !isFlying, !showResult else { return }
                throwBall(with: value.translation)
            }
    }

    private func throwBall(with translation: CGSize) {
        isFlying = true
        message = "Ball in flight…"
        let target = CGSize(width: translation.width * 0.9, height: -180 + translation.height * 0.2)
        withAnimation(.easeOut(duration: 0.55)) {
            ballOffset = target
            aim = .zero
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            resolveThrow(at: target)
        }
    }

    private func resolveThrow(at target: CGSize) {
        let point = CGPoint(x: target.width, y: target.height + 160)
        var hit: Int?
        for (i, cup) in cupPositions.enumerated() where cupsRemaining[i] {
            let cupPoint = CGPoint(x: cup.x, y: cup.y + 40)
            let dx = point.x - cupPoint.x
            let dy = point.y - cupPoint.y
            if dx * dx + dy * dy < 38 * 38 {
                hit = i
                break
            }
        }

        if let hit {
            cupsRemaining[hit] = false
            message = "Cup down!"
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            message = "Miss — next player"
            currentPlayer = (currentPlayer + 1) % app.playerCount.rawValue
        }

        withAnimation(.easeIn(duration: 0.25)) {
            ballOffset = .zero
        }
        isFlying = false

        if cupsRemaining.allSatisfy({ !$0 }) {
            winnerIndex = currentPlayer
            showResult = true
        }
    }

    private func resetMatch() {
        cupsRemaining = Array(repeating: true, count: 6)
        currentPlayer = 0
        ballOffset = .zero
        aim = .zero
        message = "Drag and release to throw"
        showResult = false
        winnerIndex = nil
        isFlying = false
    }
}
