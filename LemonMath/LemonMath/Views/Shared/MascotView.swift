//
//  MascotView.swift
//  LemonMath
//
//  The cute magical pen mascot for Lemon Math
//

import SwiftUI

struct MascotView: View {
    @Binding var isAnimating: Bool
    @State private var floatOffset: CGFloat = 0
    @State private var sparkleOpacity: Double = 0
    @State private var glowIntensity: Double = 0.5

    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            LemonMathColors.lemonYellow.opacity(glowIntensity),
                            LemonMathColors.lemonYellow.opacity(0)
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .scaleEffect(1.5)
                .blur(radius: 10)

            // Main mascot body
            MascotShape()
                .offset(y: floatOffset)
                .scaleEffect(isAnimating ? 1.1 : 1.0)

            // Sparkles
            SparklesView(opacity: sparkleOpacity)
        }
        .onAppear {
            startFloatingAnimation()
            startGlowAnimation()
        }
        .onChange(of: isAnimating) { oldValue, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.3)) {
                    sparkleOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        sparkleOpacity = 0
                        isAnimating = false
                    }
                }
            }
        }
    }

    private func startFloatingAnimation() {
        withAnimation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true)
        ) {
            floatOffset = -8
        }
    }

    private func startGlowAnimation() {
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 0.8
        }
    }
}

// MARK: - Mascot Shape (Cute Magical Pen)
struct MascotShape: View {
    var body: some View {
        ZStack {
            // Body (lemon-shaped with pen characteristics)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            LemonMathColors.lemonYellow,
                            LemonMathColors.lemonDark
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 90)
                .shadow(color: LemonMathColors.lemonDark.opacity(0.3), radius: 4, y: 2)

            // Face
            VStack(spacing: 4) {
                // Eyes
                HStack(spacing: 16) {
                    EyeView()
                    EyeView()
                }

                // Smile
                SmileView()
            }
            .offset(y: -5)

            // Wizard hat / Pen tip
            WizardHatView()
                .offset(y: -55)

            // Magic wand / Pen nib
            PenNibView()
                .offset(y: 50)

            // Blush
            HStack(spacing: 30) {
                Circle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: 12, height: 12)
                Circle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
            .offset(y: 5)
        }
    }
}

struct EyeView: View {
    @State private var blink = false

    var body: some View {
        ZStack {
            // White of eye
            Ellipse()
                .fill(.white)
                .frame(width: 14, height: blink ? 2 : 16)

            // Pupil
            if !blink {
                Circle()
                    .fill(.black)
                    .frame(width: 8, height: 8)
                    .offset(y: 2)

                // Eye shine
                Circle()
                    .fill(.white)
                    .frame(width: 3, height: 3)
                    .offset(x: 2, y: 0)
            }
        }
        .onAppear {
            startBlinking()
        }
    }

    private func startBlinking() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                blink = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    blink = false
                }
            }
        }
    }
}

struct SmileView: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: 20, y: 0),
                control: CGPoint(x: 10, y: 10)
            )
        }
        .stroke(Color.black.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        .frame(width: 20, height: 10)
    }
}

struct WizardHatView: View {
    var body: some View {
        ZStack {
            // Hat cone
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "7C4DFF"),
                            Color(hex: "536DFE")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 40, height: 35)

            // Star on hat
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundStyle(.yellow)
                .offset(y: -5)

            // Hat brim
            Ellipse()
                .fill(Color(hex: "7C4DFF"))
                .frame(width: 50, height: 12)
                .offset(y: 14)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct PenNibView: View {
    var body: some View {
        ZStack {
            // Nib body
            Triangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "B0BEC5"),
                            Color(hex: "78909C")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 20, height: 25)
                .rotationEffect(.degrees(180))

            // Ink tip
            Circle()
                .fill(Color(hex: "1A237E"))
                .frame(width: 6, height: 6)
                .offset(y: 12)
        }
    }
}

struct SparklesView: View {
    let opacity: Double
    @State private var sparklePositions: [SparklePosition] = []

    var body: some View {
        ZStack {
            ForEach(sparklePositions) { sparkle in
                Image(systemName: "sparkle")
                    .font(.system(size: sparkle.size))
                    .foregroundStyle(
                        sparkle.color.opacity(opacity * sparkle.baseOpacity)
                    )
                    .offset(x: sparkle.x, y: sparkle.y)
                    .rotationEffect(.degrees(sparkle.rotation))
            }
        }
        .onAppear {
            generateSparkles()
        }
    }

    private func generateSparkles() {
        sparklePositions = (0..<8).map { _ in
            SparklePosition(
                x: CGFloat.random(in: -60...60),
                y: CGFloat.random(in: -60...60),
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: 0...360),
                baseOpacity: Double.random(in: 0.5...1.0),
                color: [LemonMathColors.lemonYellow, .white, LemonMathColors.accent].randomElement()!
            )
        }
    }
}

struct SparklePosition: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let rotation: Double
    let baseOpacity: Double
    let color: Color
}

// MARK: - Mini Mascot for Other Views
struct MiniMascotView: View {
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            // Simplified body
            Capsule()
                .fill(LemonMathColors.lemonYellow)
                .frame(width: size * 0.6, height: size)

            // Simple face
            VStack(spacing: 2) {
                HStack(spacing: size * 0.15) {
                    Circle().fill(.black).frame(width: size * 0.1)
                    Circle().fill(.black).frame(width: size * 0.1)
                }
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.2, y: 0),
                        control: CGPoint(x: size * 0.1, y: size * 0.08)
                    )
                }
                .stroke(Color.black.opacity(0.7), lineWidth: 1.5)
                .frame(width: size * 0.2, height: size * 0.1)
            }
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        MascotView(isAnimating: .constant(false))
            .frame(width: 150, height: 150)

        MiniMascotView(size: 50)
    }
    .padding()
    .background(Color.adaptiveBackground)
}
