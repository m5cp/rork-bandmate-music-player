import SwiftUI
import AVFoundation

struct MetronomeView: View {
    @State private var bpm: Double = 120
    @State private var isPlaying: Bool = false
    @State private var currentBeat: Int = 0
    @State private var beatsPerMeasure: Int = 4
    @State private var metronomeTask: Task<Void, Never>?
    @State private var beatScale: CGFloat = 1.0
    @State private var flashOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var pendulumAngle: Double = 0
    @State private var pulsePhase: Bool = false
    @State private var clickEngine: MetronomeClickEngine?

    private let bpmRange: ClosedRange<Double> = 40...240

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            beatVisualization
                .padding(.bottom, 40)

            tempoDisplay
                .padding(.bottom, 32)

            tempoDialControl
                .padding(.bottom, 32)

            timeSignatureSelector
                .padding(.bottom, 40)

            playButton

            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            clickEngine = MetronomeClickEngine()
        }
        .onDisappear {
            stopMetronome()
            clickEngine?.cleanup()
        }
    }

    private var beatVisualization: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.08), lineWidth: 3)
                    .frame(width: 160, height: 160)

                Circle()
                    .stroke(
                        (currentBeat == 0 && isPlaying)
                            ? Color.red.opacity(0.5)
                            : Color.blue.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(ringScale)
                    .opacity(isPlaying ? 1 : 0)

                Circle()
                    .fill(
                        (currentBeat == 0 && isPlaying)
                            ? RadialGradient(colors: [.red.opacity(0.2), .clear], center: .center, startRadius: 0, endRadius: 80)
                            : RadialGradient(colors: [.blue.opacity(0.15), .clear], center: .center, startRadius: 0, endRadius: 80)
                    )
                    .frame(width: 160, height: 160)
                    .opacity(flashOpacity)

                pendulumArm

                Circle()
                    .fill(
                        isPlaying
                            ? (currentBeat == 0
                                ? LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : LinearGradient(colors: [Color(.quaternarySystemFill), Color(.tertiarySystemFill)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 20, height: 20)
                    .scaleEffect(pulsePhase ? 1.6 : 1.0)
                    .shadow(color: isPlaying ? (currentBeat == 0 ? .red.opacity(0.6) : .blue.opacity(0.5)) : .clear, radius: pulsePhase ? 16 : 4)
            }
            .frame(width: 170, height: 170)

            HStack(spacing: 14) {
                ForEach(0..<beatsPerMeasure, id: \.self) { beat in
                    let isActive = isPlaying && currentBeat == beat
                    let isDownbeat = beat == 0

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isActive
                                ? (isDownbeat
                                    ? LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                                : LinearGradient(colors: [Color(.tertiarySystemFill), Color(.quaternarySystemFill)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: isDownbeat ? 10 : 8, height: isActive ? 32 : 16)
                        .shadow(color: isActive ? (isDownbeat ? .red.opacity(0.5) : .blue.opacity(0.4)) : .clear, radius: isActive ? 10 : 0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isActive)
                }
            }
            .frame(height: 36)
        }
    }

    private var pendulumArm: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: isPlaying ? [.blue.opacity(0.6), .cyan.opacity(0.3)] : [Color(.tertiarySystemFill)],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3, height: 56)
            .offset(y: -28)
            .rotationEffect(.degrees(pendulumAngle), anchor: .bottom)
    }

    private var tempoDisplay: some View {
        VStack(spacing: 6) {
            Text("\(Int(bpm))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: bpm))
                .animation(.snappy(duration: 0.2), value: Int(bpm))

            Text("BPM")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(2)
                .textCase(.uppercase)

            Text(tempoMarking)
                .font(.caption.weight(.medium))
                .foregroundStyle(.tertiary)
                .animation(.easeInOut, value: tempoMarking)
        }
    }

    private var tempoDialControl: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                Button {
                    adjustBPM(by: -5)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: bpm)

                Slider(value: $bpm, in: bpmRange, step: 1)
                    .tint(.blue)
                    .onChange(of: bpm) { _, _ in
                        if isPlaying {
                            restartMetronome()
                        }
                    }

                Button {
                    adjustBPM(by: 5)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: bpm)
            }

            HStack(spacing: 12) {
                ForEach([60, 80, 100, 120, 140], id: \.self) { preset in
                    let isSelected = Int(bpm) == preset
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            bpm = Double(preset)
                        }
                        if isPlaying { restartMetronome() }
                    } label: {
                        Text("\(preset)")
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.blue : Color(.tertiarySystemFill), in: Capsule())
                            .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var timeSignatureSelector: some View {
        HStack(spacing: 12) {
            Text("Time Signature")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Beats", selection: $beatsPerMeasure) {
                Text("2/4").tag(2)
                Text("3/4").tag(3)
                Text("4/4").tag(4)
                Text("6/8").tag(6)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)
            .onChange(of: beatsPerMeasure) { _, _ in
                currentBeat = 0
                if isPlaying { restartMetronome() }
            }
        }
    }

    private var playButton: some View {
        Button {
            toggleMetronome()
        } label: {
            ZStack {
                Circle()
                    .fill(isPlaying
                        ? LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: isPlaying ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 12, y: 4)

                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPlaying)
    }

    private var tempoMarking: String {
        switch Int(bpm) {
        case 40..<60: return "Largo"
        case 60..<66: return "Larghetto"
        case 66..<76: return "Adagio"
        case 76..<108: return "Andante"
        case 108..<120: return "Moderato"
        case 120..<140: return "Allegro"
        case 140..<168: return "Vivace"
        case 168..<200: return "Presto"
        case 200...240: return "Prestissimo"
        default: return ""
        }
    }

    private func adjustBPM(by amount: Double) {
        let newBPM = max(bpmRange.lowerBound, min(bpmRange.upperBound, bpm + amount))
        withAnimation(.spring(duration: 0.2)) {
            bpm = newBPM
        }
        if isPlaying { restartMetronome() }
    }

    private func toggleMetronome() {
        if isPlaying {
            stopMetronome()
        } else {
            startMetronome()
        }
    }

    private func startMetronome() {
        isPlaying = true
        currentBeat = 0
        clickEngine?.start()
        runMetronome()
    }

    private func stopMetronome() {
        isPlaying = false
        metronomeTask?.cancel()
        metronomeTask = nil
        currentBeat = 0
        clickEngine?.stop()
    }

    private func restartMetronome() {
        metronomeTask?.cancel()
        currentBeat = 0
        runMetronome()
    }

    private func runMetronome() {
        metronomeTask?.cancel()
        metronomeTask = Task {
            while !Task.isCancelled && isPlaying {
                let isDownbeat = currentBeat == 0
                clickEngine?.playClick(isDownbeat: isDownbeat)
                triggerBeatAnimation(isDownbeat: isDownbeat)

                let interval = 60.0 / bpm
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))

                guard !Task.isCancelled else { return }
                currentBeat = (currentBeat + 1) % beatsPerMeasure
            }
        }
    }

    private func triggerBeatAnimation(isDownbeat: Bool) {
        withAnimation(.easeOut(duration: 0.08)) {
            flashOpacity = isDownbeat ? 1.0 : 0.6
            pulsePhase = true
            ringScale = 1.15
        }

        let swingAngle: Double = min(30, 15 + (bpm / 20))
        let direction: Double = currentBeat % 2 == 0 ? 1 : -1
        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
            pendulumAngle = swingAngle * direction
        }

        withAnimation(.easeIn(duration: 0.35).delay(0.08)) {
            flashOpacity = 0
            pulsePhase = false
            ringScale = 0.8
        }
    }
}

@MainActor
class MetronomeClickEngine {
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var highClickBuffer: AVAudioPCMBuffer?
    private var lowClickBuffer: AVAudioPCMBuffer?

    init() {
        setupEngine()
    }

    private func setupEngine() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()

        engine.attach(player)

        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        engine.connect(player, to: engine.mainMixerNode, format: format)

        highClickBuffer = generateClickBuffer(frequency: 1200, duration: 0.03, sampleRate: sampleRate, amplitude: 0.8, format: format)
        lowClickBuffer = generateClickBuffer(frequency: 800, duration: 0.025, sampleRate: sampleRate, amplitude: 0.5, format: format)

        self.engine = engine
        self.playerNode = player
    }

    private func generateClickBuffer(frequency: Double, duration: Double, sampleRate: Double, amplitude: Float, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData?[0] else { return nil }

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(1.0 - (t / duration))
            let attackEnvelope: Float = min(1.0, Float(t * sampleRate / 20.0))
            let sample = sin(2.0 * Double.pi * frequency * t)
            channelData[i] = Float(sample) * amplitude * envelope * envelope * attackEnvelope
        }

        return buffer
    }

    func start() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            engine?.prepare()
            try engine?.start()
            playerNode?.play()
        } catch {
            print("Metronome engine start error: \(error)")
        }
    }

    func stop() {
        playerNode?.stop()
        engine?.stop()
    }

    func playClick(isDownbeat: Bool) {
        guard let player = playerNode,
              let buffer = isDownbeat ? highClickBuffer : lowClickBuffer else { return }

        if engine?.isRunning != true {
            start()
        }

        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    func cleanup() {
        stop()
        if let player = playerNode {
            engine?.detach(player)
        }
        engine = nil
        playerNode = nil
    }
}
