import SwiftUI

/// Flat colorful vector-style tile illustrations matching the 2P reference grid.
struct GameArtView: View {
    let gameID: GameID

    var body: some View {
        switch gameID {
        case .cupPong: cupPong
        case .wheelie: wheelie
        case .animalStack: animalStack
        case .basketballHoops: basketball
        case .brainrotStack: brainrot
        case .archery: archery
        }
    }

    private var cupPong: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let row = i < 3 ? 0 : (i < 5 ? 1 : 2)
                let col = i < 3 ? i : (i < 5 ? i - 3 : 0)
                let x = CGFloat(col) * 20 - CGFloat(row) * 10 - 10
                let y = CGFloat(row) * 16 + 18
                Capsule()
                    .fill(Color.red)
                    .overlay(Capsule().stroke(.black, lineWidth: 2))
                    .frame(width: 22, height: 28)
                    .offset(x: x, y: y)
            }
            Circle()
                .fill(.white)
                .overlay(Circle().stroke(.black, lineWidth: 2))
                .frame(width: 16, height: 16)
                .offset(x: 42, y: -28)
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(.white.opacity(0.85))
                    .frame(width: 10, height: 3)
                    .offset(x: CGFloat(28 + i * 8), y: CGFloat(-18 - i * 6))
            }
        }
    }

    private var wheelie: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.35))
                .frame(height: 18)
                .offset(y: 48)
            Circle()
                .stroke(.black, lineWidth: 3)
                .frame(width: 30, height: 30)
                .offset(x: -18, y: 18)
            Capsule()
                .fill(Color.red)
                .overlay(Capsule().stroke(.black, lineWidth: 2))
                .frame(width: 56, height: 18)
                .rotationEffect(.degrees(-30))
                .offset(x: 8, y: 4)
            Circle()
                .stroke(.black, lineWidth: 3)
                .frame(width: 22, height: 22)
                .offset(x: 28, y: -10)
            Circle()
                .fill(Color.red)
                .overlay(Circle().stroke(.black, lineWidth: 2))
                .frame(width: 18, height: 18)
                .offset(x: 4, y: -18)
        }
    }

    private var animalStack: some View {
        VStack(spacing: -4) {
            animalBlob(.cyan, "fish")
            animalBlob(.orange, "hare")
            animalBlob(.brown, "tortoise")
            animalBlob(.pink, "cat")
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.green)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(.black, lineWidth: 2))
                .frame(width: 70, height: 12)
        }
    }

    private func animalBlob(_ color: Color, _ icon: String) -> some View {
        ZStack {
            Capsule()
                .fill(color)
                .overlay(Capsule().stroke(.black, lineWidth: 2))
                .frame(width: 54, height: 22)
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.black.opacity(0.7))
        }
    }

    private var basketball: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.red)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(.black, lineWidth: 2))
                .frame(width: 54, height: 36)
                .offset(y: -18)
            Circle()
                .stroke(.orange, lineWidth: 4)
                .frame(width: 34, height: 34)
                .offset(y: 4)
            Circle()
                .fill(.orange)
                .overlay(Circle().stroke(.black, lineWidth: 2))
                .frame(width: 22, height: 22)
                .offset(x: 28, y: 28)
        }
    }

    private var brainrot: some View {
        VStack(spacing: 2) {
            stackBit(44, .mint, "cup.and.saucer.fill")
            stackBit(56, .yellow, "circle.circle")
            stackBit(50, .purple, "leaf.fill")
            stackBit(48, .white, "bird.fill")
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.green)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(.black, lineWidth: 2))
                .frame(width: 72, height: 12)
        }
    }

    private func stackBit(_ width: CGFloat, _ color: Color, _ icon: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 2))
                .frame(width: width, height: 18)
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
        }
    }

    private var archery: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.25))
                .overlay(Circle().stroke(.black, lineWidth: 2))
                .frame(width: 70, height: 70)
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(.black, lineWidth: 2))
                .frame(width: 46, height: 46)
            Circle()
                .fill(Color.red)
                .overlay(Circle().stroke(.black, lineWidth: 2))
                .frame(width: 22, height: 22)
            Circle()
                .fill(Color.yellow)
                .frame(width: 8, height: 8)
            Capsule()
                .fill(Color.brown)
                .frame(width: 8, height: 34)
                .offset(y: 48)
            Capsule()
                .fill(Color.gray)
                .frame(width: 42, height: 4)
                .rotationEffect(.degrees(-22))
                .offset(x: -8, y: -2)
        }
    }
}
