import Foundation

struct SamplePiece: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let composer: String
    let difficulty: Difficulty
    let keySignature: String
    let timeSignature: String
    let tempo: Int
    let notes: [MusicNote]

    nonisolated enum Difficulty: String, CaseIterable, Sendable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var color: String {
            switch self {
            case .beginner: "green"
            case .intermediate: "orange"
            case .advanced: "red"
            }
        }

        var iconName: String {
            switch self {
            case .beginner: "1.circle.fill"
            case .intermediate: "2.circle.fill"
            case .advanced: "3.circle.fill"
            }
        }
    }

    static func == (lhs: SamplePiece, rhs: SamplePiece) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var parsedMusic: ParsedMusic {
        let parts = timeSignature.split(separator: "/")
        return ParsedMusic(
            notes: notes,
            timeSignatureTop: Int(parts.first ?? "4") ?? 4,
            timeSignatureBottom: Int(parts.last ?? "4") ?? 4,
            keySignature: keySignature,
            tempo: tempo,
            title: title
        )
    }
}

@MainActor
struct SampleMusicService {

    static let pieces: [SamplePiece] = [
        odeToJoy,
        twinkleTwinkle,
        amazingGrace,
        odeToJoyHarmonized,
        simpleGifts,
        auraLee,
        canonInD,
        starsAndStripesTheme,
        minuetInG,
        greensleeves
    ]

    // MARK: - Ode to Joy (Beethoven) - Beginner
    static let odeToJoy = SamplePiece(
        title: "Ode to Joy",
        composer: "Ludwig van Beethoven",
        difficulty: .beginner,
        keySignature: "C Major",
        timeSignature: "4/4",
        tempo: 100,
        notes: buildOdeToJoy()
    )

    private static func buildOdeToJoy() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("E", 4, 64), ("E", 4, 64), ("F", 4, 65), ("G", 4, 67),
            ("G", 4, 67), ("F", 4, 65), ("E", 4, 64), ("D", 4, 62),
            ("C", 4, 60), ("C", 4, 60), ("D", 4, 62), ("E", 4, 64),
            ("E", 4, 64), ("D", 4, 62), ("D", 4, 62),
            ("E", 4, 64), ("E", 4, 64), ("F", 4, 65), ("G", 4, 67),
            ("G", 4, 67), ("F", 4, 65), ("E", 4, 64), ("D", 4, 62),
            ("C", 4, 60), ("C", 4, 60), ("D", 4, 62), ("E", 4, 64),
            ("D", 4, 62), ("C", 4, 60), ("C", 4, 60)
        ]
        return buildNotes(from: pitches, durations: Array(repeating: 1.0, count: 13) + [1.5, 0.5] + Array(repeating: 1.0, count: 13) + [1.5, 0.5])
    }

    // MARK: - Twinkle Twinkle Little Star - Beginner
    static let twinkleTwinkle = SamplePiece(
        title: "Twinkle Twinkle Little Star",
        composer: "Traditional",
        difficulty: .beginner,
        keySignature: "C Major",
        timeSignature: "4/4",
        tempo: 90,
        notes: buildTwinkleTwinkle()
    )

    private static func buildTwinkleTwinkle() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("C", 4, 60), ("C", 4, 60), ("G", 4, 67), ("G", 4, 67),
            ("A", 4, 69), ("A", 4, 69), ("G", 4, 67),
            ("F", 4, 65), ("F", 4, 65), ("E", 4, 64), ("E", 4, 64),
            ("D", 4, 62), ("D", 4, 62), ("C", 4, 60),
            ("G", 4, 67), ("G", 4, 67), ("F", 4, 65), ("F", 4, 65),
            ("E", 4, 64), ("E", 4, 64), ("D", 4, 62),
            ("G", 4, 67), ("G", 4, 67), ("F", 4, 65), ("F", 4, 65),
            ("E", 4, 64), ("E", 4, 64), ("D", 4, 62),
            ("C", 4, 60), ("C", 4, 60), ("G", 4, 67), ("G", 4, 67),
            ("A", 4, 69), ("A", 4, 69), ("G", 4, 67),
            ("F", 4, 65), ("F", 4, 65), ("E", 4, 64), ("E", 4, 64),
            ("D", 4, 62), ("D", 4, 62), ("C", 4, 60)
        ]
        let durations: [Double] = [
            1, 1, 1, 1, 1, 1, 2,
            1, 1, 1, 1, 1, 1, 2,
            1, 1, 1, 1, 1, 1, 2,
            1, 1, 1, 1, 1, 1, 2,
            1, 1, 1, 1, 1, 1, 2,
            1, 1, 1, 1, 1, 1, 2
        ]
        return buildNotes(from: pitches, durations: durations)
    }

    // MARK: - Amazing Grace - Beginner
    static let amazingGrace = SamplePiece(
        title: "Amazing Grace",
        composer: "Traditional",
        difficulty: .beginner,
        keySignature: "G Major",
        timeSignature: "3/4",
        tempo: 80,
        notes: buildAmazingGrace()
    )

    private static func buildAmazingGrace() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("D", 4, 62),
            ("G", 4, 67), ("B", 4, 71), ("G", 4, 67),
            ("B", 4, 71), ("A", 4, 69),
            ("G", 4, 67), ("E", 4, 64),
            ("D", 4, 62),
            ("G", 4, 67), ("B", 4, 71), ("G", 4, 67),
            ("B", 4, 71), ("A", 4, 69),
            ("D", 5, 74),
            ("B", 4, 71),
            ("D", 5, 74), ("B", 4, 71), ("D", 5, 74),
            ("B", 4, 71), ("A", 4, 69),
            ("G", 4, 67), ("E", 4, 64),
            ("D", 4, 62),
            ("G", 4, 67), ("B", 4, 71), ("G", 4, 67),
            ("B", 4, 71), ("A", 4, 69),
            ("G", 4, 67)
        ]
        let durations: [Double] = [
            1,
            2, 1, 2,
            1, 2,
            2, 1,
            2,
            2, 1, 2,
            1, 2,
            3,
            2,
            1, 1, 1,
            2, 1,
            2, 1,
            2,
            2, 1, 2,
            1, 2,
            3
        ]
        return buildNotes(from: pitches, durations: durations)
    }

    // MARK: - Ode to Joy (Harmonized) - Intermediate
    static let odeToJoyHarmonized = SamplePiece(
        title: "Ode to Joy (Harmony)",
        composer: "Ludwig van Beethoven",
        difficulty: .intermediate,
        keySignature: "G Major",
        timeSignature: "4/4",
        tempo: 108,
        notes: buildOdeToJoyHarmonized()
    )

    private static func buildOdeToJoyHarmonized() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("B", 4, 71), ("B", 4, 71), ("C", 5, 72), ("D", 5, 74),
            ("D", 5, 74), ("C", 5, 72), ("B", 4, 71), ("A", 4, 69),
            ("G", 4, 67), ("G", 4, 67), ("A", 4, 69), ("B", 4, 71),
            ("B", 4, 71), ("A", 4, 69), ("A", 4, 69),
            ("B", 4, 71), ("B", 4, 71), ("C", 5, 72), ("D", 5, 74),
            ("D", 5, 74), ("C", 5, 72), ("B", 4, 71), ("A", 4, 69),
            ("G", 4, 67), ("G", 4, 67), ("A", 4, 69), ("B", 4, 71),
            ("A", 4, 69), ("G", 4, 67), ("G", 4, 67),
            ("A", 4, 69), ("A", 4, 69), ("B", 4, 71), ("G", 4, 67),
            ("A", 4, 69), ("B", 4, 71), ("C", 5, 72), ("B", 4, 71), ("G", 4, 67),
            ("A", 4, 69), ("B", 4, 71), ("C", 5, 72), ("B", 4, 71), ("A", 4, 69),
            ("G", 4, 67), ("A", 4, 69), ("D", 4, 62),
            ("B", 4, 71), ("B", 4, 71), ("C", 5, 72), ("D", 5, 74),
            ("D", 5, 74), ("C", 5, 72), ("B", 4, 71), ("A", 4, 69),
            ("G", 4, 67), ("G", 4, 67), ("A", 4, 69), ("B", 4, 71),
            ("A", 4, 69), ("G", 4, 67), ("G", 4, 67)
        ]
        var durations: [Double] = Array(repeating: 1.0, count: 13)
        durations += [1.5, 0.5]
        durations += Array(repeating: 1.0, count: 13)
        durations += [1.5, 0.5]
        durations += [1, 1, 1, 1, 1, 0.5, 0.5, 1, 1, 1, 0.5, 0.5, 1, 1, 1, 1, 2]
        durations += Array(repeating: 1.0, count: 13)
        durations += [1.5, 0.5]
        return buildNotes(from: pitches, durations: durations)
    }

    // MARK: - Simple Gifts - Intermediate
    static let simpleGifts = SamplePiece(
        title: "Simple Gifts",
        composer: "Elder Joseph Brackett",
        difficulty: .intermediate,
        keySignature: "F Major",
        timeSignature: "4/4",
        tempo: 108,
        notes: buildSimpleGifts()
    )

    private static func buildSimpleGifts() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("C", 4, 60), ("C", 4, 60),
            ("F", 4, 65), ("F", 4, 65), ("G", 4, 67), ("A", 4, 69),
            ("A", 4, 69), ("A", 4, 69), ("G", 4, 67), ("A", 4, 69),
            ("Bb", 4, 70), ("A", 4, 69), ("G", 4, 67), ("F", 4, 65),
            ("G", 4, 67), ("F", 4, 65), ("C", 4, 60), ("C", 4, 60),
            ("F", 4, 65), ("F", 4, 65), ("G", 4, 67), ("A", 4, 69),
            ("A", 4, 69), ("A", 4, 69), ("G", 4, 67), ("A", 4, 69),
            ("Bb", 4, 70), ("C", 5, 72), ("Bb", 4, 70), ("A", 4, 69),
            ("G", 4, 67), ("F", 4, 65)
        ]
        let durations: [Double] = [
            1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            2, 2
        ]
        return buildNotes(from: pitches, durations: durations)
    }

    // MARK: - Aura Lee - Intermediate
    static let auraLee = SamplePiece(
        title: "Aura Lee",
        composer: "George R. Poulton",
        difficulty: .intermediate,
        keySignature: "C Major",
        timeSignature: "4/4",
        tempo: 96,
        notes: buildAuraLee()
    )

    private static func buildAuraLee() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("C", 4, 60), ("D", 4, 62), ("E", 4, 64), ("F", 4, 65),
            ("G", 4, 67), ("G", 4, 67), ("A", 4, 69), ("G", 4, 67),
            ("E", 4, 64), ("E", 4, 64), ("F", 4, 65), ("E", 4, 64),
            ("D", 4, 62), ("D", 4, 62),
            ("C", 4, 60), ("D", 4, 62), ("E", 4, 64), ("F", 4, 65),
            ("G", 4, 67), ("G", 4, 67), ("A", 4, 69), ("G", 4, 67),
            ("E", 4, 64), ("E", 4, 64), ("D", 4, 62), ("D", 4, 62),
            ("C", 4, 60)
        ]
        let durations: [Double] = [
            1, 1, 1, 1,
            2, 1, 1,
            2, 1, 1,
            2, 2,
            1, 1, 1, 1,
            2, 1, 1,
            2, 1, 1,
            2, 1, 1,
            4
        ]
        return buildNotes(from: pitches, durations: durations)
    }

    // MARK: - Canon in D (Theme) - Advanced
    static let canonInD = SamplePiece(
        title: "Canon in D (Theme)",
        composer: "Johann Pachelbel",
        difficulty: .advanced,
        keySignature: "D Major",
        timeSignature: "4/4",
        tempo: 72,
        notes: buildCanonInD()
    )

    private static func buildCanonInD() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("F#", 5, 78), ("E", 5, 76), ("D", 5, 74), ("C#", 5, 73),
            ("B", 4, 71), ("A", 4, 69), ("B", 4, 71), ("C#", 5, 73),
            ("D", 5, 74), ("C#", 5, 73), ("B", 4, 71), ("A", 4, 69),
            ("G", 4, 67), ("F#", 4, 66), ("G", 4, 67), ("A", 4, 69),
            ("F#", 4, 66), ("D", 4, 62), ("E", 4, 64), ("F#", 4, 66),
            ("G", 4, 67), ("A", 4, 69), ("A", 4, 69), ("G", 4, 67),
            ("F#", 4, 66), ("E", 4, 64), ("F#", 4, 66), ("D", 4, 62),
            ("E", 4, 64), ("F#", 4, 66), ("G", 4, 67), ("A", 4, 69),
            ("B", 4, 71), ("A", 4, 69), ("G", 4, 67), ("F#", 4, 66),
            ("E", 4, 64), ("F#", 4, 66), ("E", 4, 64), ("D", 4, 62)
        ]
        return buildNotes(from: pitches, durations: Array(repeating: 1.0, count: pitches.count))
    }

    // MARK: - Stars and Stripes (Theme) - Advanced
    static let starsAndStripesTheme = SamplePiece(
        title: "Stars and Stripes Forever (Theme)",
        composer: "John Philip Sousa",
        difficulty: .advanced,
        keySignature: "Bb Major",
        timeSignature: "2/2",
        tempo: 120,
        notes: buildStarsAndStripes()
    )

    private static func buildStarsAndStripes() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("Bb", 4, 70), ("D", 5, 74), ("D", 5, 74), ("D", 5, 74),
            ("Eb", 5, 75), ("D", 5, 74), ("C", 5, 72), ("Bb", 4, 70),
            ("A", 4, 69), ("Bb", 4, 70), ("C", 5, 72), ("D", 5, 74),
            ("Bb", 4, 70), ("C", 5, 72),
            ("F", 5, 77), ("F", 5, 77), ("F", 5, 77),
            ("G", 5, 79), ("F", 5, 77), ("Eb", 5, 75), ("D", 5, 74),
            ("C", 5, 72), ("D", 5, 74), ("Eb", 5, 75), ("F", 5, 77),
            ("D", 5, 74), ("Bb", 4, 70)
        ]
        let durations: [Double] = [
            1, 1.5, 0.5, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            2, 2,
            1.5, 0.5, 1,
            1, 1, 1, 1,
            1, 1, 1, 1,
            2, 2
        ]
        return buildNotes(from: pitches, durations: durations)
    }

    // MARK: - Minuet in G Major (Bach) - Intermediate
    static let minuetInG = SamplePiece(
        title: "Minuet in G Major",
        composer: "Christian Petzold",
        difficulty: .intermediate,
        keySignature: "G Major",
        timeSignature: "3/4",
        tempo: 108,
        notes: buildMinuetInG()
    )

    private static func buildMinuetInG() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("D", 5, 74),
            ("G", 4, 67), ("A", 4, 69), ("B", 4, 71), ("C", 5, 72), ("D", 5, 74),
            ("G", 4, 67), ("G", 4, 67),
            ("E", 5, 76), ("C", 5, 72), ("D", 5, 74), ("E", 5, 76), ("F#", 5, 78),
            ("G", 5, 79), ("G", 4, 67), ("G", 4, 67),
            ("C", 5, 72), ("D", 5, 74), ("C", 5, 72), ("B", 4, 71), ("A", 4, 69),
            ("B", 4, 71), ("C", 5, 72), ("B", 4, 71), ("A", 4, 69), ("G", 4, 67),
            ("F#", 4, 66), ("G", 4, 67), ("A", 4, 69), ("B", 4, 71), ("G", 4, 67),
            ("B", 4, 71), ("A", 4, 69)
        ]
        let durations: [Double] = [
            2,
            1, 1, 1, 1, 1,
            1, 2,
            1, 1, 1, 1, 1,
            1, 1, 1,
            1, 1, 1, 1, 1,
            1, 1, 1, 1, 1,
            1, 1, 1, 1, 1,
            2, 1
        ]
        return buildNotes(from: pitches, durations: durations)
    }

    // MARK: - Greensleeves - Advanced
    static let greensleeves = SamplePiece(
        title: "Greensleeves",
        composer: "Traditional (16th Century)",
        difficulty: .advanced,
        keySignature: "A Minor",
        timeSignature: "3/4",
        tempo: 96,
        notes: buildGreensleeves()
    )

    private static func buildGreensleeves() -> [MusicNote] {
        let pitches: [(String, Int, Int)] = [
            ("A", 4, 69),
            ("C", 5, 72), ("D", 5, 74), ("E", 5, 76),
            ("F", 5, 77), ("E", 5, 76),
            ("D", 5, 74), ("B", 4, 71),
            ("G", 4, 67), ("A", 4, 69), ("B", 4, 71),
            ("C", 5, 72), ("A", 4, 69),
            ("A", 4, 69), ("G#", 4, 68), ("A", 4, 69),
            ("B", 4, 71), ("G#", 4, 68),
            ("E", 4, 64),
            ("A", 4, 69),
            ("C", 5, 72), ("D", 5, 74), ("E", 5, 76),
            ("F", 5, 77), ("E", 5, 76),
            ("D", 5, 74), ("B", 4, 71),
            ("G", 4, 67), ("A", 4, 69), ("B", 4, 71),
            ("C", 5, 72), ("B", 4, 71), ("A", 4, 69),
            ("G#", 4, 68), ("F#", 4, 66), ("G#", 4, 68),
            ("A", 4, 69)
        ]
        let durations: [Double] = [
            1,
            2, 1, 1.5,
            0.5, 1,
            2, 1,
            1.5, 0.5, 1,
            2, 1,
            1.5, 0.5, 1,
            2, 1,
            3,
            1,
            2, 1, 1.5,
            0.5, 1,
            2, 1,
            1.5, 0.5, 1,
            1, 1, 1,
            1, 1, 1,
            3
        ]
        return buildNotes(from: pitches, durations: durations)
    }

    // MARK: - Helper

    private static func buildNotes(from pitches: [(String, Int, Int)], durations: [Double]) -> [MusicNote] {
        var notes: [MusicNote] = []
        var beat: Double = 0
        for i in 0..<min(pitches.count, durations.count) {
            let (name, octave, midi) = pitches[i]
            let dur = durations[i]
            notes.append(MusicNote(
                pitch: midi,
                duration: dur,
                startBeat: beat,
                noteName: name,
                octave: octave
            ))
            beat += dur
        }
        return notes
    }
}
