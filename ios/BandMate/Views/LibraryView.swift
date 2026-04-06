import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.createdAt, order: .reverse) private var songs: [Song]
    @State private var searchText: String = ""
    @State private var navigationPath = NavigationPath()
    @State private var selectedSegment: LibrarySegment = .mySongs
    @State private var viewMode: ViewMode = .grid
    @State private var selectedDifficulty: SamplePiece.Difficulty?
    @State private var songToDelete: Song?
    @State private var showDeleteConfirmation: Bool = false

    nonisolated enum LibrarySegment: String, CaseIterable {
        case mySongs = "My Songs"
        case samples = "Samples"
    }

    nonisolated enum ViewMode: String {
        case grid
        case list
    }

    private var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return songs }
        return songs.filter { $0.title.localizedStandardContains(searchText) }
    }

    private var recentlyPlayed: [Song] {
        songs.filter { $0.lastPlayedAt != nil }
            .sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
            .prefix(6).map { $0 }
    }

    private var filteredSamples: [SamplePiece] {
        guard let difficulty = selectedDifficulty else { return SampleMusicService.pieces }
        return SampleMusicService.pieces.filter { $0.difficulty == difficulty }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                Picker("Section", selection: $selectedSegment) {
                    ForEach(LibrarySegment.allCases, id: \.rawValue) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                Group {
                    switch selectedSegment {
                    case .mySongs:
                        mySongsContent
                    case .samples:
                        samplesContent
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedSegment == .mySongs && !songs.isEmpty {
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                viewMode = viewMode == .grid ? .list : .grid
                            }
                        } label: {
                            Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                                .contentTransition(.symbolEffect(.replace))
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: selectedSegment == .mySongs ? "Search songs" : "Search samples")
            .navigationDestination(for: PlayerRoute.self) { route in
                PlayerView(music: route.music, image: route.image, song: route.song)
            }
            .confirmationDialog("Delete Song", isPresented: $showDeleteConfirmation, presenting: songToDelete) { song in
                Button("Delete", role: .destructive) {
                    withAnimation { modelContext.delete(song) }
                }
            } message: { song in
                Text("Are you sure you want to delete \"\(song.title)\"?")
            }
        }
    }

    // MARK: - My Songs

    @ViewBuilder
    private var mySongsContent: some View {
        if songs.isEmpty {
            ContentUnavailableView {
                Label("No Songs Yet", systemImage: "music.note.list")
            } description: {
                Text("Scan or upload sheet music from the Home tab to start building your library.")
            }
        } else if filteredSongs.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !recentlyPlayed.isEmpty && searchText.isEmpty {
                        recentSection
                    }

                    allSongsSection
                }
                .padding(.vertical, 12)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.blue)
                Text("Recently Played")
                    .font(.headline.bold())
            }
            .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 14) {
                    ForEach(recentlyPlayed) { song in
                        Button {
                            openSong(song)
                        } label: {
                            RecentLibraryCard(song: song)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 16)
            .scrollIndicators(.hidden)
        }
    }

    private var allSongsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.blue)
                Text("All Songs")
                    .font(.headline.bold())
                Spacer()
                Text("\(filteredSongs.count) \(filteredSongs.count == 1 ? "song" : "songs")")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if viewMode == .grid {
                songGrid
            } else {
                songList
            }
        }
    }

    private var songGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 14)], spacing: 14) {
            ForEach(filteredSongs) { song in
                Button {
                    openSong(song)
                } label: {
                    LibrarySongCard(song: song)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        songToDelete = song
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var songList: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredSongs) { song in
                Button {
                    openSong(song)
                } label: {
                    LibrarySongRow(song: song)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        songToDelete = song
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                if song.id != filteredSongs.last?.id {
                    Divider()
                        .padding(.leading, 76)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Samples

    @ViewBuilder
    private var samplesContent: some View {
        let filtered: [SamplePiece] = {
            var result = filteredSamples
            if !searchText.isEmpty {
                result = result.filter {
                    $0.title.localizedStandardContains(searchText) ||
                    $0.composer.localizedStandardContains(searchText)
                }
            }
            return result
        }()

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                difficultyFilter
                    .padding(.top, 8)

                if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { piece in
                            Button {
                                playSample(piece)
                            } label: {
                                SamplePieceRow(piece: piece)
                            }
                            .buttonStyle(.plain)

                            if piece.id != filtered.last?.id {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var difficultyFilter: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedDifficulty == nil) {
                    withAnimation(.spring(duration: 0.3)) { selectedDifficulty = nil }
                }
                ForEach(SamplePiece.Difficulty.allCases, id: \.rawValue) { difficulty in
                    FilterChip(title: difficulty.rawValue, isSelected: selectedDifficulty == difficulty) {
                        withAnimation(.spring(duration: 0.3)) { selectedDifficulty = difficulty }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
    }

    // MARK: - Actions

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

    private func playSample(_ piece: SamplePiece) {
        let song = Song(
            title: piece.title,
            keySignature: piece.keySignature,
            timeSignature: piece.timeSignature,
            tempo: piece.tempo,
            noteCount: piece.notes.count
        )
        song.setNotes(piece.notes)
        modelContext.insert(song)
        song.lastPlayedAt = Date()
        navigationPath.append(PlayerRoute(music: piece.parsedMusic, image: nil, song: song))
    }
}

// MARK: - Card Components

struct LibrarySongCard: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let data = song.imageData, let uiImage = UIImage(data: data) {
                Color(.tertiarySystemBackground)
                    .frame(height: 120)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(topLeadingRadius: 12, topTrailingRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.15), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.blue.opacity(0.4))
                    }
                    .clipShape(.rect(topLeadingRadius: 12, topTrailingRadius: 12))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(song.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    MetadataPill(text: song.keySignature, color: .blue)
                    MetadataPill(text: "\(song.tempo)", color: .orange)
                }

                if let lastPlayed = song.lastPlayedAt {
                    Text(lastPlayed, style: .relative)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(song.title), \(song.keySignature), \(song.tempo) BPM")
        .accessibilityHint("Double tap to play")
    }
}

struct MetadataPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct LibrarySongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 14) {
            if let data = song.imageData, let uiImage = UIImage(data: data) {
                Color(.tertiarySystemBackground)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.15), .purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.blue.opacity(0.5))
                    }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(song.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(song.keySignature)
                    Text("·")
                    Text(song.timeSignature)
                    Text("·")
                    Text("\(song.tempo) BPM")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(song.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
                Image(systemName: "play.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(song.title), \(song.keySignature), \(song.tempo) BPM")
        .accessibilityHint("Double tap to play")
    }
}

struct RecentLibraryCard: View {
    let song: Song

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let data = song.imageData, let uiImage = UIImage(data: data) {
                Color(.tertiarySystemBackground)
                    .frame(width: 140, height: 100)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.15)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 140, height: 100)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.blue.opacity(0.5))
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(song.keySignature)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 140)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(song.title), Key of \(song.keySignature)")
        .accessibilityHint("Double tap to play")
    }
}
