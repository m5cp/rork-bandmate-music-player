import SwiftUI
import AVFoundation
import Accelerate

struct TunerView: View {
    @State private var viewModel = TunerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 4)

            noteDisplay

            Spacer(minLength: 8)

            pitchIndicator
                .padding(.horizontal)
                .padding(.bottom, 12)

            frequencyDisplay
                .padding(.bottom, 12)

            referenceToneButton
                .padding(.bottom, 10)

            referenceSelector
                .padding(.horizontal)
                .padding(.bottom, 12)

            micButton
                .padding(.bottom, 8)

            Spacer(minLength: 4)
        }
        .sensoryFeedback(.success, trigger: viewModel.inTuneTrigger)
        .onDisappear {
            viewModel.stop()
        }
        .overlay {
            if viewModel.permissionDenied {
                VStack(spacing: 16) {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Microphone Access Required")
                        .font(.headline)
                    Text("Enable microphone access in Settings to use the tuner.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var noteDisplay: some View {
        VStack(spacing: 4) {
            if viewModel.isListening {
                Text(viewModel.currentNote)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.tuningColor)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: viewModel.currentNote)

                Text("Octave \(viewModel.currentOctave)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)

                Text("Tap mic to start")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 100)
    }

    private var pitchIndicator: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let width = geo.size.width
                let center = width / 2
                let centsOffset = viewModel.centsOff
                let maxCents: CGFloat = 50
                let position = center + (CGFloat(centsOffset) / maxCents) * (width / 2 - 20)

                ZStack {
                    HStack {
                        Text("♭")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("♯")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.secondary)
                    }

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.quaternarySystemFill))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.green)
                        .frame(width: 3, height: 16)
                        .position(x: center, y: geo.size.height / 2)

                    if viewModel.isListening && viewModel.currentFrequency > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(viewModel.tuningColor)
                            .frame(width: 10, height: 20)
                            .shadow(color: viewModel.tuningColor.opacity(0.5), radius: 6)
                            .position(x: max(20, min(width - 20, position)), y: geo.size.height / 2)
                            .animation(.spring(duration: 0.2), value: centsOffset)
                    }
                }
            }
            .frame(height: 32)

            if viewModel.isListening && viewModel.currentFrequency > 0 {
                Text(viewModel.tuningText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(viewModel.tuningColor)
                    .animation(.easeInOut, value: viewModel.tuningText)
            }
        }
    }

    private var frequencyDisplay: some View {
        VStack(spacing: 2) {
            if viewModel.isListening && viewModel.currentFrequency > 0 {
                Text(String(format: "%.1f Hz", viewModel.currentFrequency))
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: Int(viewModel.currentFrequency))
            } else {
                Text("--- Hz")
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            Text("Target: \(String(format: "%.1f Hz", viewModel.targetFrequency))")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var referenceToneButton: some View {
        Button {
            viewModel.toggleReferenceTone()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isPlayingTone ? "speaker.wave.2.fill" : "speaker.fill")
                    .font(.caption.weight(.bold))
                    .contentTransition(.symbolEffect(.replace))
                Text(viewModel.isPlayingTone ? "Stop Tone" : "Reference Tone")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(viewModel.isPlayingTone ? .white : .blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                viewModel.isPlayingTone
                    ? AnyShapeStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color.blue.opacity(0.12)),
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isPlayingTone)
    }

    private var referenceSelector: some View {
        HStack(spacing: 10) {
            Text("Ref")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Reference Pitch", selection: $viewModel.referencePitch) {
                Text("440").tag(440.0)
                Text("441").tag(441.0)
                Text("442").tag(442.0)
                Text("443").tag(443.0)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 220)
        }
    }

    private var micButton: some View {
        Button {
            if viewModel.isListening {
                viewModel.stop()
            } else {
                viewModel.start()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(viewModel.isListening
                        ? LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 70, height: 70)
                    .shadow(color: viewModel.isListening ? .red.opacity(0.3) : .green.opacity(0.3), radius: 10, y: 3)

                Image(systemName: viewModel.isListening ? "stop.fill" : "mic.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isListening)
    }
}
