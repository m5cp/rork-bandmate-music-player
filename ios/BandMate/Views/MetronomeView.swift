import SwiftUI
import AVFoundation

struct MetronomeView: View {
    @State private var bpm: Double = 120
    @State private var isPlaying: Bool = false
    @State private var currentBeat: Int = 0
    @State private var beatsPerMeasure: Int = 4
    @State private var metronomeTask: Task<Void, Never>?
    @State private var beatScale: CGFloat = 1.0
    @State private var audioPlayer: AVAudioPlayer?

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
        .onDisappear {
            stopMetronome()
        }
    }

    private var beatVisualization: some View {
        HStack(spacing: 16) {
            ForEach(0..<beatsPerMeasure, id: \.self) { beat in
                let isActive = isPlaying && currentBeat == beat
                let isDownbeat = beat == 0

                Circle()
                    .fill(
                        isActive
                            ? (isDownbeat
                                ? LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : LinearGradient(colors: [Color(.tertiarySystemFill), Color(.quaternarySystemFill)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: isActive ? 28 : 20, height: isActive ? 28 : 20)
                    .shadow(color: isActive ? (isDownbeat ? .red.opacity(0.4) : .blue.opacity(0.4)) : .clear, radius: 8)
                    .animation(.spring(duration: 0.15), value: isActive)
            }
        }
        .frame(height: 36)
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
        setupAudioSession()
        runMetronome()
    }

    private func stopMetronome() {
        isPlaying = false
        metronomeTask?.cancel()
        metronomeTask = nil
        currentBeat = 0
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

                let interval = 60.0 / bpm
                try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))

                guard !Task.isCancelled else { return }
                currentBeat = (currentBeat + 1) % beatsPerMeasure
            }
        }
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func playClick(isDownbeat: Bool) {
        AudioServicesPlaySystemSound(isDownbeat ? 1057 : 1104)
    }
}
