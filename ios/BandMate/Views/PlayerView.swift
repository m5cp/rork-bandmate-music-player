import SwiftUI

struct PlayerView: View {
    let music: ParsedMusic
    let image: UIImage?
    let song: Song?
    @State private var viewModel = PlayerViewModel()
    @State private var hapticTrigger: Int = 0
    @State private var showInstrumentPicker: Bool = false
    @State private var showPracticeMode: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isRegular: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        ScrollView {
            if isRegular {
                HStack(alignment: .top, spacing: 32) {
                    VStack(spacing: 24) {
                        sheetPreview
                        nowPlayingInfo
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 24) {
                        progressSection
                        playbackControls
                        practiceModeButton
                        instrumentSection
                        tempoControl
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 24) {
                    sheetPreview
                    nowPlayingInfo
                    progressSection
                    playbackControls
                    practiceModeButton
                    instrumentSection
                    tempoControl
                }
                .padding()
            }
        }
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadMusic(music, image: image)
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .fullScreenCover(isPresented: $showPracticeMode) {
            PracticeModeView(music: music, instrument: viewModel.selectedInstrument)
        }
        .sheet(isPresented: $showInstrumentPicker) {
            InstrumentPickerView(
                selectedInstrument: Binding(
                    get: { viewModel.selectedInstrument },
                    set: { viewModel.updateInstrument($0) }
                ),
                onSelect: { instrument in
                    viewModel.updateInstrument(instrument)
                }
            )
            .presentationDetents([.large])
        }
    }

    private var sheetPreview: some View {
        Group {
            if let uiImage = image {
                Color(.secondarySystemBackground)
                    .frame(height: 220)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 16))
                    .accessibilityLabel("Sheet music preview for \(music.title ?? "Untitled")")
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 220)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 40))
                                .foregroundStyle(.tertiary)
                            Text(music.title ?? "Sheet Music")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("Sheet music placeholder for \(music.title ?? "Untitled")")
            }
        }
    }

    private var nowPlayingInfo: some View {
        VStack(spacing: 4) {
            Text(music.title ?? "Untitled")
                .font(.title3.bold())
            HStack(spacing: 16) {
                Label(music.keySignature, systemImage: "music.note")
                Label(music.timeSignatureDisplay, systemImage: "metronome")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(music.title ?? "Untitled"), Key of \(music.keySignature), \(music.timeSignatureDisplay) time")
    }

    private var progressSection: some View {
        VStack(spacing: 4) {
            ProgressView(value: viewModel.audioEngine.progress)
                .tint(viewModel.selectedInstrument.category.color)
                .accessibilityLabel("Playback progress")
                .accessibilityValue("\(Int(viewModel.audioEngine.progress * 100)) percent")

            HStack {
                Text(formatBeat(viewModel.audioEngine.currentBeat))
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatBeat(viewModel.audioEngine.totalBeats))
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(formatBeat(viewModel.audioEngine.currentBeat)) of \(formatBeat(viewModel.audioEngine.totalBeats))")
        }
    }

    private var playbackControls: some View {
        HStack(spacing: 40) {
            Button {
                viewModel.stopPlayback()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }
            .accessibilityLabel("Stop")
            .accessibilityHint("Stops playback and resets to the beginning")

            Button {
                viewModel.togglePlayback()
                hapticTrigger += 1
            } label: {
                Image(systemName: viewModel.audioEngine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(viewModel.selectedInstrument.category.color)
                    .contentTransition(reduceMotion ? .identity : .symbolEffect(.replace))
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: hapticTrigger)
            .accessibilityLabel(viewModel.audioEngine.isPlaying ? "Pause" : "Play")
            .accessibilityHint(viewModel.audioEngine.isPlaying ? "Pauses music playback" : "Starts playing the music")

            Button {
                viewModel.toggleLoop()
            } label: {
                Image(systemName: "repeat")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(viewModel.isLooping ? viewModel.selectedInstrument.category.color : .primary)
                    .symbolEffect(.bounce, value: reduceMotion ? false : viewModel.isLooping)
            }
            .accessibilityLabel("Loop")
            .accessibilityValue(viewModel.isLooping ? "On" : "Off")
            .accessibilityHint(viewModel.isLooping ? "Double tap to turn off looping" : "Double tap to repeat the music continuously")
        }
    }

    private var instrumentSection: some View {
        InstrumentChipBar(selectedInstrument: viewModel.selectedInstrument) {
            showInstrumentPicker = true
        }
    }

    private var practiceModeButton: some View {
        Button {
            viewModel.stopPlayback()
            showPracticeMode = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 42, height: 42)
                    Image(systemName: "mic.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Practice Mode")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("Record & get AI feedback")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Practice Mode")
        .accessibilityHint("Record yourself playing and get AI feedback")
    }

    @State private var tempoHaptic: Int = 0

    private var tempoControl: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tempo")
                    .font(.headline.bold())
                Spacer()
                Text("\(Int(viewModel.tempo)) BPM")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(viewModel.selectedInstrument.category.color)
            }

            Slider(value: Binding(
                get: { viewModel.tempo },
                set: { newValue in
                    viewModel.updateTempo(newValue)
                    tempoHaptic += 1
                }
            ), in: 40...240, step: 1)
            .tint(viewModel.selectedInstrument.category.color)
            .sensoryFeedback(.selection, trigger: tempoHaptic)
            .accessibilityLabel("Tempo")
            .accessibilityValue("\(Int(viewModel.tempo)) beats per minute")
        }
    }

    private func formatBeat(_ beat: Double) -> String {
        let seconds = (beat / viewModel.tempo) * 60
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
