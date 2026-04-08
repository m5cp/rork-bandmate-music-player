import SwiftUI
import AVFoundation
import Accelerate

struct TunerView: View {
    @State private var viewModel = TunerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            noteDisplay
                .padding(.bottom, 24)

            pitchIndicator
                .padding(.bottom, 32)

            frequencyDisplay
                .padding(.bottom, 40)

            referenceSelector
                .padding(.bottom, 24)

            micButton

            Spacer()
        }
        .padding(.horizontal)
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
        VStack(spacing: 8) {
            if viewModel.isListening {
                Text(viewModel.currentNote)
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(viewModel.tuningColor)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: viewModel.currentNote)

                Text("Octave \(viewModel.currentOctave)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                Text("--")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.tertiary)

                Text("Tap to start")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 120)
    }

    private var pitchIndicator: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                let width = geo.size.width
                let center = width / 2
                let centsOffset = viewModel.centsOff
                let maxCents: CGFloat = 50
                let position = center + (CGFloat(centsOffset) / maxCents) * (width / 2 - 20)

                ZStack {
                    HStack {
                        Text("♭")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("♯")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.secondary)
                    }

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.quaternarySystemFill))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.green)
                        .frame(width: 4, height: 20)
                        .position(x: center, y: geo.size.height / 2)

                    if viewModel.isListening && viewModel.currentFrequency > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(viewModel.tuningColor)
                            .frame(width: 12, height: 24)
                            .shadow(color: viewModel.tuningColor.opacity(0.5), radius: 6)
                            .position(x: max(20, min(width - 20, position)), y: geo.size.height / 2)
                            .animation(.spring(duration: 0.2), value: centsOffset)
                    }
                }
            }
            .frame(height: 40)
            .padding(.horizontal, 8)

            if viewModel.isListening && viewModel.currentFrequency > 0 {
                Text(viewModel.tuningText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(viewModel.tuningColor)
                    .animation(.easeInOut, value: viewModel.tuningText)
            }
        }
    }

    private var frequencyDisplay: some View {
        VStack(spacing: 4) {
            if viewModel.isListening && viewModel.currentFrequency > 0 {
                Text(String(format: "%.1f Hz", viewModel.currentFrequency))
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: Int(viewModel.currentFrequency))
            } else {
                Text("--- Hz")
                    .font(.system(.title3, design: .monospaced).weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            Text("Target: \(String(format: "%.1f Hz", viewModel.targetFrequency))")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var referenceSelector: some View {
        HStack(spacing: 12) {
            Text("Reference")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("Reference Pitch", selection: $viewModel.referencePitch) {
                Text("A = 440").tag(440.0)
                Text("A = 441").tag(441.0)
                Text("A = 442").tag(442.0)
                Text("A = 443").tag(443.0)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 280)
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
                    .frame(width: 80, height: 80)
                    .shadow(color: viewModel.isListening ? .red.opacity(0.3) : .green.opacity(0.3), radius: 12, y: 4)

                Image(systemName: viewModel.isListening ? "stop.fill" : "mic.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: viewModel.isListening)
    }
}
