import SwiftUI
import SwiftData
import PhotosUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.lastPlayedAt, order: .reverse) private var recentSongs: [Song]
    @State private var viewModel = HomeViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var navigationPath = NavigationPath()
    @AppStorage("hasUsedApp") private var hasUsedApp: Bool = false
    @State private var showPracticeMode: Bool = false
    @State private var practiceTargetSong: Song?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greetingSection
                    actionCards
                    practiceCard
                    if !hasUsedApp {
                        howItWorksSection
                    }
                    if !recentlyPlayed.isEmpty {
                        recentlyPlayedSection
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("KITB")
            .navigationDestination(for: ProcessingRoute.self) { route in
                ProcessingView(image: route.image, navigationPath: $navigationPath)
            }
            .navigationDestination(for: PlayerRoute.self) { route in
                PlayerView(music: route.music, image: route.image, song: route.song)
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraProxyView { image in
                    viewModel.handleCapturedImage(image)
                    viewModel.showCamera = false
                }
            }
            .photosPicker(isPresented: $viewModel.showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, newValue in
                guard let item = newValue else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.handleSelectedImage(uiImage)
                    }
                }
            }
            .onChange(of: viewModel.showProcessing) { _, show in
                if show, let image = viewModel.selectedImage {
                    viewModel.showProcessing = false
                    hasUsedApp = true
                    navigationPath.append(ProcessingRoute(image: image))
                }
            }
            .sheet(isPresented: $viewModel.showDocumentPicker) {
                DocumentPickerView { image in
                    viewModel.handleSelectedImage(image)
                    viewModel.showDocumentPicker = false
                }
            }
            .fullScreenCover(isPresented: $showPracticeMode) {
                if let song = practiceTargetSong, let notes = song.parsedNotes {
                    let music = ParsedMusic(
                        notes: notes,
                        timeSignatureTop: Int(song.timeSignature.split(separator: "/").first ?? "4") ?? 4,
                        timeSignatureBottom: Int(song.timeSignature.split(separator: "/").last ?? "4") ?? 4,
                        keySignature: song.keySignature,
                        tempo: song.tempo,
                        title: song.title
                    )
                    let instrument = Instrument(rawValue: song.preferredInstrument) ?? .trumpet
                    PracticeModeView(music: music, instrument: instrument)
                } else {
                    PracticeModeView(music: nil, instrument: nil)
                }
            }
        }
    }

    private var recentlyPlayed: [Song] {
        recentSongs.filter { $0.lastPlayedAt != nil }.prefix(10).map { $0 }
    }

    private var practiceCard: some View {
        Button {
            if let lastSong = recentlyPlayed.first {
                practiceTargetSong = lastSong
            } else {
                practiceTargetSong = nil
            }
            showPracticeMode = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.red, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 52, height: 52)
                    Image(systemName: "mic.fill")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Practice & Record")
                        .font(.headline.bold())
                        .foregroundStyle(.primary)
                    Text("Record yourself & get AI feedback")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.red.opacity(0.08), Color.orange.opacity(0.06)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: .rect(cornerRadius: 16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(colors: [.red.opacity(0.2), .orange.opacity(0.15)], startPoint: .leading, endPoint: .trailing),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Practice and Record")
        .accessibilityHint("Record yourself playing and get AI feedback")
        .padding(.horizontal)
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingText)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Ready to practice?")
                .font(.title2.bold())
        }
        .padding(.horizontal)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var actionCards: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.showCamera = true
            } label: {
                ActionCardLabel(
                    icon: "camera.fill",
                    title: "Scan Music",
                    subtitle: "Point your camera at printed sheet music",
                    gradient: [Color.blue, Color.cyan]
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Button {
                    viewModel.showPhotoPicker = true
                } label: {
                    SmallActionCardLabel(
                        icon: "photo.on.rectangle",
                        title: "Photo Library",
                        color: .indigo
                    )
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.showDocumentPicker = true
                } label: {
                    SmallActionCardLabel(
                        icon: "doc.fill",
                        title: "Upload PDF",
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Played")
                .font(.headline.bold())
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(recentlyPlayed) { song in
                        Button {
                            openSong(song)
                        } label: {
                            RecentSongCard(song: song)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 16)
            .scrollIndicators(.hidden)
        }
    }

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("How It Works")
                    .font(.title3.bold())
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.4)) { hasUsedApp = true }
                } label: {
                    Text("Dismiss")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(Array(howItWorksSteps.enumerated()), id: \.offset) { index, step in
                    JourneyStepRow(
                        step: step,
                        stepNumber: index + 1,
                        isLast: index == howItWorksSteps.count - 1
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var howItWorksSteps: [(icon: String, color: Color, title: String, detail: String)] {
        [
            ("camera.fill", .blue, "Scan or Upload", "Snap a photo of sheet music or pick from your library."),
            ("wand.and.stars", .purple, "AI Reads the Notes", "Notes, key, tempo — detected instantly."),
            ("pianokeys", .teal, "Pick Your Instrument", "30+ instruments across all families."),
            ("play.fill", .green, "Listen & Practice", "Adjust tempo, loop sections, play at your pace.")
        ]
    }

    private var samplePiecesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sample Library")
                    .font(.headline.bold())
                Spacer()
                NavigationLink {
                    SampleLibraryView()
                } label: {
                    Text("See All")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(SampleMusicService.pieces.prefix(5)) { piece in
                        Button {
                            playSample(piece)
                        } label: {
                            SamplePieceCard(piece: piece)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 16)
            .scrollIndicators(.hidden)
        }
    }

    private func playSample(_ piece: SamplePiece) {
        let music = piece.parsedMusic
        navigationPath.append(PlayerRoute(music: music, image: nil))
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

struct ActionCardLabel: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .rect(cornerRadius: 14)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.bold())
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityHint(subtitle)
    }
}

struct SmallActionCardLabel: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

struct RecentSongCard: View {
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
                        LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 140, height: 100)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.blue)
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

struct SamplePieceCard: View {
    let piece: SamplePiece

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .fill(cardGradient)
                .frame(width: 140, height: 100)
                .overlay {
                    VStack(spacing: 4) {
                        Image(systemName: "music.note")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text(piece.difficulty.rawValue)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(piece.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(piece.composer)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 140)
    }

    private var cardGradient: LinearGradient {
        switch piece.difficulty {
        case .beginner:
            LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .intermediate:
            LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .advanced:
            LinearGradient(colors: [.red, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct JourneyStepRow: View {
    let step: (icon: String, color: Color, title: String, detail: String)
    let stepNumber: Int
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [step.color, step.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: step.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }

                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [step.color.opacity(0.5), howItWorksNextColor.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2.5)
                        .frame(minHeight: 36)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Step \(stepNumber)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(step.color)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.top, 2)

                Text(step.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)

                Text(step.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, isLast ? 0 : 8)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(stepNumber): \(step.title). \(step.detail)")
    }

    private var howItWorksNextColor: Color {
        let colors: [Color] = [.blue, .purple, .teal, .green]
        let nextIndex = min(stepNumber, colors.count - 1)
        return colors[nextIndex]
    }
}

struct ProcessingRoute: Hashable {
    let id = UUID()
    let image: UIImage

    static func == (lhs: ProcessingRoute, rhs: ProcessingRoute) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PlayerRoute: Hashable {
    let id = UUID()
    let music: ParsedMusic
    let image: UIImage?
    let song: Song?

    init(music: ParsedMusic, image: UIImage?, song: Song? = nil) {
        self.music = music
        self.image = image
        self.song = song
    }

    static func == (lhs: PlayerRoute, rhs: PlayerRoute) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
