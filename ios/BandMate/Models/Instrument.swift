import Foundation
import SwiftUI

nonisolated enum InstrumentCategory: String, CaseIterable, Sendable, Identifiable {
    case woodwinds = "Woodwinds"
    case brass = "Brass"
    case percussion = "Percussion"
    case strings = "Strings"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .woodwinds: .teal
        case .brass: .orange
        case .percussion: .purple
        case .strings: .red
        }
    }

    var iconName: String {
        switch self {
        case .woodwinds: "wind"
        case .brass: "horn.fill"
        case .percussion: "metronome.fill"
        case .strings: "guitars.fill"
        }
    }
}

nonisolated enum Instrument: String, CaseIterable, Codable, Sendable, Identifiable {
    case piccolo = "Piccolo"
    case flute = "Flute"
    case oboe = "Oboe"
    case englishHorn = "English Horn"
    case clarinet = "Clarinet"
    case bassClarinet = "Bass Clarinet"
    case bassoon = "Bassoon"
    case sopranoSax = "Soprano Sax"
    case altoSax = "Alto Sax"
    case tenorSax = "Tenor Sax"
    case baritoneSax = "Baritone Sax"

    case trumpet = "Trumpet"
    case cornet = "Cornet"
    case flugelhorn = "Flugelhorn"
    case frenchHorn = "French Horn"
    case trombone = "Trombone"
    case bassTrombone = "Bass Trombone"
    case euphonium = "Euphonium"
    case tuba = "Tuba"

    case snare = "Snare Drum"
    case bassDrum = "Bass Drum"
    case timpani = "Timpani"
    case xylophone = "Xylophone"
    case marimba = "Marimba"
    case vibraphone = "Vibraphone"
    case glockenspiel = "Glockenspiel"
    case tubularBells = "Tubular Bells"
    case cymbals = "Cymbals"
    case triangle = "Triangle"

    case violin = "Violin"
    case viola = "Viola"
    case cello = "Cello"
    case doubleBass = "Double Bass"
    case harp = "Harp"

    var id: String { rawValue }

    var category: InstrumentCategory {
        switch self {
        case .piccolo, .flute, .oboe, .englishHorn, .clarinet, .bassClarinet, .bassoon,
             .sopranoSax, .altoSax, .tenorSax, .baritoneSax:
            .woodwinds
        case .trumpet, .cornet, .flugelhorn, .frenchHorn, .trombone, .bassTrombone, .euphonium, .tuba:
            .brass
        case .snare, .bassDrum, .timpani, .xylophone, .marimba, .vibraphone, .glockenspiel,
             .tubularBells, .cymbals, .triangle:
            .percussion
        case .violin, .viola, .cello, .doubleBass, .harp:
            .strings
        }
    }

    var iconName: String {
        switch self {
        case .piccolo: "waveform.path"
        case .flute: "wind"
        case .oboe: "music.note"
        case .englishHorn: "music.quarternote.3"
        case .clarinet: "waveform"
        case .bassClarinet: "waveform.badge.minus"
        case .bassoon: "waveform.path.ecg"
        case .sopranoSax: "music.mic"
        case .altoSax: "music.quarternote.3"
        case .tenorSax: "music.mic"
        case .baritoneSax: "music.mic.circle.fill"
        case .trumpet: "speaker.wave.2.fill"
        case .cornet: "speaker.wave.1.fill"
        case .flugelhorn: "speaker.wave.3.fill"
        case .frenchHorn: "horn.fill"
        case .trombone: "waveform.path.ecg.rectangle"
        case .bassTrombone: "waveform.path.ecg.rectangle.fill"
        case .euphonium: "music.note.list"
        case .tuba: "speaker.fill"
        case .snare: "circle.circle"
        case .bassDrum: "circle.fill"
        case .timpani: "target"
        case .xylophone: "pianokeys"
        case .marimba: "pianokeys"
        case .vibraphone: "waveform"
        case .glockenspiel: "sparkles"
        case .tubularBells: "bell.fill"
        case .cymbals: "burst.fill"
        case .triangle: "triangle.fill"
        case .violin: "guitars.fill"
        case .viola: "guitars"
        case .cello: "music.note"
        case .doubleBass: "music.note"
        case .harp: "waveform.path"
        }
    }

    var midiProgram: UInt8 {
        switch self {
        case .piccolo: 72
        case .flute: 73
        case .oboe: 68
        case .englishHorn: 69
        case .clarinet: 71
        case .bassClarinet: 71
        case .bassoon: 70
        case .sopranoSax: 64
        case .altoSax: 65
        case .tenorSax: 66
        case .baritoneSax: 67
        case .trumpet: 56
        case .cornet: 56
        case .flugelhorn: 56
        case .frenchHorn: 60
        case .trombone: 57
        case .bassTrombone: 57
        case .euphonium: 58
        case .tuba: 58
        case .snare: 0
        case .bassDrum: 0
        case .timpani: 47
        case .xylophone: 13
        case .marimba: 12
        case .vibraphone: 11
        case .glockenspiel: 9
        case .tubularBells: 14
        case .cymbals: 0
        case .triangle: 0
        case .violin: 40
        case .viola: 41
        case .cello: 42
        case .doubleBass: 43
        case .harp: 46
        }
    }

    var isPercussion: Bool {
        switch self {
        case .snare, .bassDrum, .cymbals, .triangle:
            true
        default:
            false
        }
    }

    var shortDescription: String {
        switch self {
        case .piccolo: "Bright, piercing high register"
        case .flute: "Light, airy melodic tone"
        case .oboe: "Warm, reedy double reed"
        case .englishHorn: "Rich, mellow alto oboe"
        case .clarinet: "Warm, versatile woodwind"
        case .bassClarinet: "Deep, dark clarinet voice"
        case .bassoon: "Rich, baritone double reed"
        case .sopranoSax: "Bright, penetrating soprano"
        case .altoSax: "Smooth, expressive jazz tone"
        case .tenorSax: "Full, warm midsection voice"
        case .baritoneSax: "Deep, powerful low sax"
        case .trumpet: "Bright, bold brass sound"
        case .cornet: "Warm, mellow brass tone"
        case .flugelhorn: "Soft, dark brass voice"
        case .frenchHorn: "Noble, majestic brass"
        case .trombone: "Powerful, sliding brass"
        case .bassTrombone: "Deep, resonant low brass"
        case .euphonium: "Rich, lyrical baritone"
        case .tuba: "Deep, foundational bass"
        case .snare: "Sharp, rhythmic attack"
        case .bassDrum: "Deep, thunderous boom"
        case .timpani: "Tuned, orchestral thunder"
        case .xylophone: "Bright, percussive melody"
        case .marimba: "Warm, resonant bars"
        case .vibraphone: "Shimmering, sustained tone"
        case .glockenspiel: "Sparkling, bell-like clarity"
        case .tubularBells: "Rich, church bell chimes"
        case .cymbals: "Shimmering crash & ride"
        case .triangle: "Delicate, crystalline ring"
        case .violin: "Expressive, soaring strings"
        case .viola: "Warm, alto string voice"
        case .cello: "Rich, deep string tone"
        case .doubleBass: "Foundation of the strings"
        case .harp: "Ethereal, flowing arpeggios"
        }
    }

    var midiChannel: UInt8 {
        switch self {
        case .snare, .bassDrum, .cymbals, .triangle:
            9
        default:
            0
        }
    }

    static func instruments(for category: InstrumentCategory) -> [Instrument] {
        allCases.filter { $0.category == category }
    }
}
