import SwiftUI
import SwiftData

struct SampleLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDifficulty: SamplePiece.Difficulty?
    @State private var navigationPath = NavigationPath()

    private var filteredPieces: [SamplePiece] {
        guard let difficulty = selectedDifficulty else { return SampleMusicService.pieces }
        return SampleMusicService.pieces.filter { $0.difficulty == difficulty }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    difficultyFilter
                    piecesList
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sample Library")
            .navigationDestination(for: PlayerRoute.self) { route in
                PlayerView(music: route.music, image: route.image, song: route.song)
            }
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

    private var piecesList: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredPieces) { piece in
                Button {
                    playSample(piece)
                } label: {
                    SamplePieceRow(piece: piece)
                }
                .buttonStyle(.plain)

                if piece.id != filteredPieces.last?.id {
                    Divider()
                        .padding(.leading, 72)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
        .padding(.horizontal)
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.blue : Color(.tertiarySystemGroupedBackground), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct SamplePieceRow: View {
    let piece: SamplePiece

    var body: some View {
        HStack(spacing: 14) {
            difficultyBadge

            VStack(alignment: .leading, spacing: 3) {
                Text(piece.title)
                    .font(.body.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(piece.composer)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(piece.keySignature)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("\(piece.tempo) BPM")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(piece.title) by \(piece.composer), \(piece.difficulty.rawValue), \(piece.keySignature), \(piece.tempo) BPM")
        .accessibilityHint("Double tap to play")
    }

    private var difficultyBadge: some View {
        Image(systemName: piece.difficulty.iconName)
            .font(.title2.weight(.bold))
            .foregroundStyle(difficultyColor)
            .frame(width: 40, height: 40)
    }

    private var difficultyColor: Color {
        switch piece.difficulty {
        case .beginner: .green
        case .intermediate: .orange
        case .advanced: .red
        }
    }
}
