import SwiftUI
import SwiftData

struct ResultsView: View {
    let music: ParsedMusic
    let image: UIImage
    @Binding var navigationPath: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSaved: Bool = false
    @State private var savedSong: Song?
    @State private var appeared: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                sheetPreview
                musicInfo
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sheetPreview: some View {
        Color(.secondarySystemBackground)
            .frame(height: 200)
            .overlay {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .allowsHitTesting(false)
            }
            .clipShape(.rect(cornerRadius: 16))
            .opacity(appeared ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (appeared ? 0 : 20))
            .animation(reduceMotion ? nil : .spring(response: 0.5), value: appeared)
            .onAppear { appeared = true }
            .accessibilityLabel("Scanned sheet music for \(music.title ?? "Untitled")")
    }

    private var musicInfo: some View {
        VStack(spacing: 16) {
            if let title = music.title {
                Text(title)
                    .font(.title2.bold())
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                InfoCard(icon: "music.note", label: "Key", value: music.keySignature)
                InfoCard(icon: "metronome", label: "Time", value: music.timeSignatureDisplay)
                InfoCard(icon: "speedometer", label: "Tempo", value: "\(music.tempo) BPM")
                InfoCard(icon: "note.text", label: "Notes", value: "\(music.noteCount)")
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: reduceMotion ? 0 : (appeared ? 0 : 20))
        .animation(reduceMotion ? nil : .spring(response: 0.5).delay(0.1), value: appeared)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                navigationPath.append(PlayerRoute(music: music, image: image, song: savedSong))
            } label: {
                Label("Play Music", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                saveSong()
            } label: {
                Label(isSaved ? "Saved" : "Save to Library", systemImage: isSaved ? "checkmark.circle.fill" : "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(isSaved)
            .sensoryFeedback(.success, trigger: isSaved)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: reduceMotion ? 0 : (appeared ? 0 : 20))
        .animation(reduceMotion ? nil : .spring(response: 0.5).delay(0.2), value: appeared)
    }

    private func saveSong() {
        let song = Song(
            title: music.title ?? "Untitled",
            keySignature: music.keySignature,
            timeSignature: music.timeSignatureDisplay,
            tempo: music.tempo,
            noteCount: music.noteCount,
            imageData: image.jpegData(compressionQuality: 0.7)
        )
        song.setNotes(music.notes)
        modelContext.insert(song)
        savedSong = song
        isSaved = true
    }
}

struct InfoCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(.blue)
            Text(value)
                .font(.headline.bold())
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
