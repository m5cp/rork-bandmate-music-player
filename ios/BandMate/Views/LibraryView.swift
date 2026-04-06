import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.createdAt, order: .reverse) private var songs: [Song]
    @State private var searchText: String = ""
    @State private var navigationPath = NavigationPath()

    private var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return songs }
        return songs.filter { $0.title.localizedStandardContains(searchText) }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if songs.isEmpty {
                    ContentUnavailableView(
                        "No Songs Yet",
                        systemImage: "music.note.list",
                        description: Text("Scan or upload sheet music to start building your library.")
                    )
                } else {
                    List {
                        ForEach(filteredSongs) { song in
                            Button {
                                openSong(song)
                            } label: {
                                SongRow(song: song)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    modelContext.delete(song)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .searchable(text: $searchText, prompt: "Search songs")
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: PlayerRoute.self) { route in
                PlayerView(music: route.music, image: route.image, song: route.song)
            }
        }
    }

    private func openSong(_ song: Song) {
        song.lastPlayedAt = Date()
        if let notes = song.parsedNotes {
            let music = ParsedMusic(
                notes: notes,
                timeSignatureTop: Int(song.timeSignature.split(separator: "/").first ?? "4") ?? 4,
                timeSignatureBottom: Int(song.timeSignature.split(separator: "/").last ?? "4") ?? 4,
                keySignature: song.keySignature,
                tempo: song.tempo,
                title: song.title
            )
            var image: UIImage?
            if let data = song.imageData {
                image = UIImage(data: data)
            }
            navigationPath.append(PlayerRoute(music: music, image: image, song: song))
        }
    }
}

struct SongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 14) {
            if let data = song.imageData, let uiImage = UIImage(data: data) {
                Color(.tertiarySystemBackground)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.tertiary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.body.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(song.keySignature)
                    Text("•")
                    Text(song.timeSignature)
                    Text("•")
                    Text("\(song.tempo) BPM")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(song.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(song.title), \(song.keySignature), \(song.timeSignature), \(song.tempo) BPM, saved \(song.createdAt.formatted(.dateTime.month(.abbreviated).day()))")
        .accessibilityHint("Double tap to play")
    }
}
