import SwiftUI

struct WelcomeView: View {
    @State private var phase: Int = 0
    @State private var noteOffsets: [CGFloat] = Array(repeating: 300, count: 8)
    @State private var showTitle: Bool = false
    @State private var showSubtitle: Bool = false
    @State private var showButton: Bool = false
    @State private var fadeOut: Bool = false
    @State private var buttonReady: Bool = false
    @State private var pulseRing: Bool = false
    @State private var backgroundGlow: Bool = false
    @State private var staffLinesVisible: Bool = false
    @State private var meshPhase: Float = 0.0

    var onContinue: () -> Void

    private let musicalSymbols = ["music.note", "music.note.list", "music.quarternote.3", "music.mic", "guitars.fill", "pianokeys", "drum.fill", "speaker.wave.3.fill"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundLayer(size: geo.size)

                staffLines(size: geo.size)

                floatingNotes(size: geo.size)

                centerContent(size: geo.size)
            }
            .ignoresSafeArea()
        }
        .opacity(fadeOut ? 0 : 1)
        .scaleEffect(fadeOut ? 1.08 : 1.0)
        .onAppear {
            startSequence()
        }
    }

    @ViewBuilder
    private func backgroundLayer(size: CGSize) -> some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .black, Color(red: 0.05, green: 0.0, blue: 0.15), .black,
                Color(red: 0.0, green: 0.05, blue: 0.2), Color(red: 0.1, green: 0.0, blue: 0.25), Color(red: 0.0, green: 0.05, blue: 0.15),
                .black, Color(red: 0.05, green: 0.0, blue: 0.2), .black
            ]
        )
        .overlay {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(backgroundGlow ? 0.15 : 0.05),
                            Color.purple.opacity(backgroundGlow ? 0.08 : 0.02),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: size.width * 0.7
                    )
                )
                .scaleEffect(backgroundGlow ? 1.2 : 0.8)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: backgroundGlow)
        }
    }

    @ViewBuilder
    private func staffLines(size: CGSize) -> some View {
        let lineSpacing: CGFloat = 12
        let startY = size.height * 0.3

        ForEach(0..<5, id: \.self) { i in
            Rectangle()
                .fill(Color.white.opacity(staffLinesVisible ? 0.08 : 0.0))
                .frame(height: 1)
                .offset(y: startY + CGFloat(i) * lineSpacing - size.height / 2)
                .animation(.easeOut(duration: 0.6).delay(Double(i) * 0.1), value: staffLinesVisible)
        }

        let startY2 = size.height * 0.65
        ForEach(0..<5, id: \.self) { i in
            Rectangle()
                .fill(Color.white.opacity(staffLinesVisible ? 0.06 : 0.0))
                .frame(height: 1)
                .offset(y: startY2 + CGFloat(i) * lineSpacing - size.height / 2)
                .animation(.easeOut(duration: 0.6).delay(0.5 + Double(i) * 0.1), value: staffLinesVisible)
        }
    }

    @ViewBuilder
    private func floatingNotes(size: CGSize) -> some View {
        let positions: [(x: CGFloat, y: CGFloat, size: CGFloat, rotation: Double)] = [
            (0.15, 0.15, 28, -15),
            (0.85, 0.12, 22, 20),
            (0.08, 0.45, 20, -30),
            (0.92, 0.4, 26, 10),
            (0.2, 0.75, 24, 25),
            (0.8, 0.72, 20, -20),
            (0.5, 0.08, 18, 15),
            (0.55, 0.88, 22, -10),
        ]

        ForEach(0..<musicalSymbols.count, id: \.self) { i in
            let pos = positions[i]
            Image(systemName: musicalSymbols[i])
                .font(.system(size: pos.size, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.blue.opacity(0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(pos.rotation))
                .offset(y: noteOffsets[i])
                .position(x: size.width * pos.x, y: size.height * pos.y)
        }
    }

    @ViewBuilder
    private func centerContent(size: CGSize) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        fadeOut = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onContinue()
                    }
                } label: {
                    Text("Skip")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 60)
            .padding(.trailing, 8)

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseRing ? 1.8 : 1.0)
                    .opacity(pulseRing ? 0 : 0.5)
                    .animation(.easeOut(duration: 2).repeatForever(autoreverses: false), value: pulseRing)

                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseRing ? 1.4 : 1.0)
                    .opacity(pulseRing ? 0 : 0.3)
                    .animation(.easeOut(duration: 2).delay(0.5).repeatForever(autoreverses: false), value: pulseRing)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.purple.opacity(0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 72, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color.blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.breathe, isActive: phase >= 1)
            }
            .opacity(showTitle ? 1 : 0)
            .scaleEffect(showTitle ? 1 : 0.3)

            Spacer().frame(height: 40)

            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.system(.title3, design: .default, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)

                Text("KITB")
                    .font(.system(size: 46, weight: .black, design: .default).width(.expanded))
                    .tracking(12)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(white: 0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 30)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color.blue.opacity(0.6), Color.purple.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: showTitle ? 200 : 0, height: 2)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: showTitle)

                Text("Your AI Practice Companion")
                    .font(.system(.body, design: .default, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 15)
            }

            Spacer()

            Button {
                guard buttonReady else { return }
                withAnimation(.easeInOut(duration: 0.5)) {
                    fadeOut = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onContinue()
                }
            } label: {
                HStack(spacing: 12) {
                    Text("LET'S PLAY")
                        .font(.system(.headline, weight: .bold))
                        .tracking(3)

                    Image(systemName: "arrow.right")
                        .font(.system(.body, weight: .bold))
                        .symbolEffect(.wiggle, isActive: buttonReady)
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial, in: .capsule)
            }
            .buttonStyle(.plain)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 40)
            .sensoryFeedback(.impact(weight: .medium), trigger: buttonReady)

            Spacer().frame(height: 60)
        }
    }

    private func startSequence() {
        withAnimation(.easeOut(duration: 0.4)) {
            staffLinesVisible = true
        }

        backgroundGlow = true

        for i in 0..<musicalSymbols.count {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2 + Double(i) * 0.08)) {
                noteOffsets[i] = 0
            }
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.6)) {
            showTitle = true
            phase = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            pulseRing = true
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(1.2)) {
            showSubtitle = true
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.6)) {
            showButton = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            buttonReady = true
        }


    }
}
