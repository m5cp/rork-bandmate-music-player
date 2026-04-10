import SwiftUI
import AVFoundation
import AudioToolbox

struct MetronomeView: View {
    @State private var bpm: Double = 120
    @State private var isPlaying: Bool = false
    @State private var currentBeat: Int = 0
    @State private var beatsPerMeasure: Int = 4
    @State private var metronomeTask: Task<Void, Never>?
    @State private var flashOpacity: Double = 0
    @State private var pendulumAngle: Double = 0
    @State private var pulsePhase: Bool = false
    @State private var clickPlayer: AVAudioPlayer?
    @State private var accentPlayer: AVAudioPlayer?
    @State private var beatTrigger: Int = 0

    private let bpmRange: ClosedRange<Double> = 40...240

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 4)

            beatVisualization

            Spacer(minLength: 8)

            tempoDisplay
                .padding(.bottom, 8)

            tempoControls
                .padding(.horizontal)
                .padding(.bottom, 10)

            timeSignatureSelector
                .padding(.horizontal)
                .padding(.bottom, 12)

            playButton
                .padding(.bottom, 8)

            Spacer(minLength: 4)
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 1.0), trigger: beatTrigger)
        .onAppear {
            prepareAudioPlayers()
        }
        .onDisappear {
            stopMetronome()
        }
    }

    private var beatVisualization: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.08), lineWidth: 2)
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(
                        (currentBeat == 0 && isPlaying)
                            ? Color.red.opacity(0.5)
                            : Color.blue.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isPlaying ? (pulsePhase ? 1.15 : 0.85) : 1.0)
                    .opacity(isPlaying ? 1 : 0)

                Circle()
                    .fill(
                        (currentBeat == 0 && isPlaying)
                            ? RadialGradient(colors: [.red.opacity(0.2), .clear], center: .center, startRadius: 0, endRadius: 60)
                            : RadialGradient(colors: [.blue.opacity(0.15), .clear], center: .center, startRadius: 0, endRadius: 60)
                    )
                    .frame(width: 120, height: 120)
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
                    .frame(width: 16, height: 16)
                    .scaleEffect(pulsePhase ? 1.6 : 1.0)
                    .shadow(color: isPlaying ? (currentBeat == 0 ? .red.opacity(0.6) : .blue.opacity(0.5)) : .clear, radius: pulsePhase ? 12 : 4)
            }
            .frame(width: 130, height: 130)

            HStack(spacing: 12) {
                ForEach(0..<beatsPerMeasure, id: \.self) { beat in
                    let isActive = isPlaying && currentBeat == beat
                    let isDownbeat = beat == 0

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            isActive
                                ? (isDownbeat
                                    ? LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                                : LinearGradient(colors: [Color(.tertiarySystemFill), Color(.quaternarySystemFill)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: isDownbeat ? 10 : 8, height: isActive ? 28 : 14)
                        .shadow(color: isActive ? (isDownbeat ? .red.opacity(0.5) : .blue.opacity(0.4)) : .clear, radius: isActive ? 8 : 0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isActive)
                }
            }
            .frame(height: 30)
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
            .frame(width: 2.5, height: 42)
            .offset(y: -21)
            .rotationEffect(.degrees(pendulumAngle), anchor: .bottom)
    }

    private var tempoDisplay: some View {
        VStack(spacing: 2) {
            Text("\(Int(bpm))")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: bpm))
                .animation(.snappy(duration: 0.2), value: Int(bpm))

            Text("BPM")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(2)
                .textCase(.uppercase)

            Text(tempoMarking)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
                .animation(.easeInOut, value: tempoMarking)
        }
    }

    private var tempoControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                Button {
                    adjustBPM(by: -5)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }

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
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                }
            }

            HStack(spacing: 10) {
                ForEach([60, 80, 100, 120, 140], id: \.self) { preset in
                    let isSelected = Int(bpm) == preset
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            bpm = Double(preset)
                        }
                        if isPlaying { restartMetronome() }
                    } label: {
                        Text("\(preset)")
                            .font(.caption2.weight(.bold))
                            .monospacedDigit()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(isSelected ? Color.blue : Color(.tertiarySystemFill), in: Capsule())
                            .foregroundStyle(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var timeSignatureSelector: some View {
        HStack(spacing: 10) {
            Text("Time Sig")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Beats", selection: $beatsPerMeasure) {
                Text("2/4").tag(2)
                Text("3/4").tag(3)
                Text("4/4").tag(4)
                Text("6/8").tag(6)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)
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
                    .frame(width: 70, height: 70)
                    .shadow(color: isPlaying ? .red.opacity(0.3) : .blue.opacity(0.3), radius: 10, y: 3)

                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2.weight(.bold))
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

    private func prepareAudioPlayers() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }

        clickPlayer = generateTonePlayer(frequency: 800, duration: 0.03, amplitude: 0.5)
        accentPlayer = generateTonePlayer(frequency: 1200, duration: 0.04, amplitude: 0.8)
    }

    private func generateTonePlayer(frequency: Double, duration: Double, amplitude: Float) -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let frameCount = Int(sampleRate * duration)
        let dataSize = frameCount * 2
        var audioData = Data()

        let headerSize = 44
        var header = Data(count: headerSize)
        let totalSize = UInt32(headerSize + dataSize)
        header.replaceSubrange(0..<4, with: "RIFF".data(using: .ascii)!)
        withUnsafeBytes(of: (totalSize - 8).littleEndian) { header.replaceSubrange(4..<8, with: $0) }
        header.replaceSubrange(8..<12, with: "WAVE".data(using: .ascii)!)
        header.replaceSubrange(12..<16, with: "fmt ".data(using: .ascii)!)
        withUnsafeBytes(of: UInt32(16).littleEndian) { header.replaceSubrange(16..<20, with: $0) }
        withUnsafeBytes(of: UInt16(1).littleEndian) { header.replaceSubrange(20..<22, with: $0) }
        withUnsafeBytes(of: UInt16(1).littleEndian) { header.replaceSubrange(22..<24, with: $0) }
        withUnsafeBytes(of: UInt32(sampleRate).littleEndian) { header.replaceSubrange(24..<28, with: $0) }
        withUnsafeBytes(of: UInt32(sampleRate * 2).littleEndian) { header.replaceSubrange(28..<32, with: $0) }
        withUnsafeBytes(of: UInt16(2).littleEndian) { header.replaceSubrange(32..<34, with: $0) }
        withUnsafeBytes(of: UInt16(16).littleEndian) { header.replaceSubrange(34..<36, with: $0) }
        header.replaceSubrange(36..<40, with: "data".data(using: .ascii)!)
        withUnsafeBytes(of: UInt32(dataSize).littleEndian) { header.replaceSubrange(40..<44, with: $0) }
        audioData.append(header)

        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            let envelope = Float(1.0 - (t / duration))
            let attack: Float = min(1.0, Float(t * sampleRate / 20.0))
            let sample = sin(2.0 * Double.pi * frequency * t)
            let value = Int16(Float(sample) * amplitude * envelope * envelope * attack * 32767)
            withUnsafeBytes(of: value.littleEndian) { audioData.append(contentsOf: $0) }
        }

        return try? AVAudioPlayer(data: audioData)
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
        clickPlayer?.prepareToPlay()
        accentPlayer?.prepareToPlay()
        runMetronome()
    }

    private func stopMetronome() {
        isPlaying = false
        metronomeTask?.cancel()
        metronomeTask = nil
        currentBeat = 0
        withAnimation(.easeOut(duration: 0.3)) {
            flashOpacity = 0
            pulsePhase = false
            pendulumAngle = 0
        }
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

                playClick(isDownbeat: isDownbeat)
                beatTrigger += 1
                triggerBeatAnimation(isDownbeat: isDownbeat)

                let interval = 60.0 / bpm
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))

                guard !Task.isCancelled else { return }
                currentBeat = (currentBeat + 1) % beatsPerMeasure
            }
        }
    }

    private func playClick(isDownbeat: Bool) {
        if isDownbeat {
            accentPlayer?.currentTime = 0
            accentPlayer?.play()
        } else {
            clickPlayer?.currentTime = 0
            clickPlayer?.play()
        }
    }

    private func triggerBeatAnimation(isDownbeat: Bool) {
        withAnimation(.easeOut(duration: 0.08)) {
            flashOpacity = isDownbeat ? 1.0 : 0.6
            pulsePhase = true
        }

        let swingAngle: Double = min(30, 15 + (bpm / 20))
        let direction: Double = currentBeat % 2 == 0 ? 1 : -1
        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
            pendulumAngle = swingAngle * direction
        }

        withAnimation(.easeIn(duration: 0.35).delay(0.08)) {
            flashOpacity = 0
            pulsePhase = false
        }
    }
}
