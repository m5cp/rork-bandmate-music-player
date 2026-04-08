import Foundation
import SwiftUI

nonisolated struct Achievement: Identifiable, Codable, Sendable {
    let id: String
    let title: String
    let detail: String
    let icon: String
    let requirement: Int
    var unlocked: Bool
    var unlockedDate: Date?

    init(id: String, title: String, detail: String, icon: String, requirement: Int, unlocked: Bool = false, unlockedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.detail = detail
        self.icon = icon
        self.requirement = requirement
        self.unlocked = unlocked
        self.unlockedDate = unlockedDate
    }
}

@Observable
@MainActor
class GamificationManager {
    static let shared = GamificationManager()

    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalPracticeSessions: Int = 0
    var totalPracticeMinutes: Int = 0
    var uniqueInstruments: Set<String> = []
    var totalSongsScanned: Int = 0
    var achievements: [Achievement] = []
    var newlyUnlockedAchievement: Achievement?

    private let streakKey = "practiceStreak"
    private let longestStreakKey = "longestPracticeStreak"
    private let lastPracticeDateKey = "lastPracticeDate"
    private let totalSessionsKey = "totalPracticeSessions"
    private let totalMinutesKey = "totalPracticeMinutes"
    private let instrumentsKey = "uniqueInstrumentsPlayed"
    private let songsScannedKey = "totalSongsScanned"
    private let achievementsKey = "unlockedAchievements"

    init() {
        loadData()
        setupAchievements()
    }

    private func loadData() {
        let defaults = UserDefaults.standard
        currentStreak = defaults.integer(forKey: streakKey)
        longestStreak = defaults.integer(forKey: longestStreakKey)
        totalPracticeSessions = defaults.integer(forKey: totalSessionsKey)
        totalPracticeMinutes = defaults.integer(forKey: totalMinutesKey)
        totalSongsScanned = defaults.integer(forKey: songsScannedKey)

        if let instruments = defaults.stringArray(forKey: instrumentsKey) {
            uniqueInstruments = Set(instruments)
        }

        checkStreakContinuity()
    }

    private func checkStreakContinuity() {
        let defaults = UserDefaults.standard
        guard let lastDate = defaults.object(forKey: lastPracticeDateKey) as? Date else { return }
        let calendar = Calendar.current

        if calendar.isDateInToday(lastDate) || calendar.isDateInYesterday(lastDate) {
            return
        }

        currentStreak = 0
        defaults.set(0, forKey: streakKey)
    }

    func recordPracticeSession(instrument: String, durationSeconds: TimeInterval) {
        let defaults = UserDefaults.standard
        let calendar = Calendar.current

        totalPracticeSessions += 1
        defaults.set(totalPracticeSessions, forKey: totalSessionsKey)

        let minutes = max(1, Int(durationSeconds / 60))
        totalPracticeMinutes += minutes
        defaults.set(totalPracticeMinutes, forKey: totalMinutesKey)

        uniqueInstruments.insert(instrument)
        defaults.set(Array(uniqueInstruments), forKey: instrumentsKey)

        let lastDate = defaults.object(forKey: lastPracticeDateKey) as? Date
        let today = Date()

        if let last = lastDate, calendar.isDateInToday(last) {
        } else if let last = lastDate, calendar.isDateInYesterday(last) {
            currentStreak += 1
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
            defaults.set(longestStreak, forKey: longestStreakKey)
        }

        defaults.set(currentStreak, forKey: streakKey)
        defaults.set(today, forKey: lastPracticeDateKey)

        checkAchievements()
    }

    func recordSongScanned() {
        totalSongsScanned += 1
        UserDefaults.standard.set(totalSongsScanned, forKey: songsScannedKey)
        checkAchievements()
    }

    private func setupAchievements() {
        let unlockedIDs = Set(UserDefaults.standard.stringArray(forKey: achievementsKey) ?? [])

        achievements = [
            Achievement(id: "first_practice", title: "First Notes", detail: "Complete your first practice session", icon: "music.note", requirement: 1, unlocked: unlockedIDs.contains("first_practice")),
            Achievement(id: "five_sessions", title: "Getting Started", detail: "Complete 5 practice sessions", icon: "flame", requirement: 5, unlocked: unlockedIDs.contains("five_sessions")),
            Achievement(id: "ten_sessions", title: "Dedicated Musician", detail: "Complete 10 practice sessions", icon: "flame.fill", requirement: 10, unlocked: unlockedIDs.contains("ten_sessions")),
            Achievement(id: "twentyfive_sessions", title: "Practice Pro", detail: "Complete 25 practice sessions", icon: "star.fill", requirement: 25, unlocked: unlockedIDs.contains("twentyfive_sessions")),
            Achievement(id: "fifty_sessions", title: "Virtuoso", detail: "Complete 50 practice sessions", icon: "crown.fill", requirement: 50, unlocked: unlockedIDs.contains("fifty_sessions")),
            Achievement(id: "streak_3", title: "Three-Peat", detail: "Maintain a 3-day practice streak", icon: "bolt.fill", requirement: 3, unlocked: unlockedIDs.contains("streak_3")),
            Achievement(id: "streak_7", title: "Weekly Warrior", detail: "Maintain a 7-day practice streak", icon: "bolt.circle.fill", requirement: 7, unlocked: unlockedIDs.contains("streak_7")),
            Achievement(id: "streak_30", title: "Monthly Master", detail: "Maintain a 30-day practice streak", icon: "trophy.fill", requirement: 30, unlocked: unlockedIDs.contains("streak_30")),
            Achievement(id: "multi_instrument_3", title: "Multi-Talented", detail: "Practice with 3 different instruments", icon: "guitars.fill", requirement: 3, unlocked: unlockedIDs.contains("multi_instrument_3")),
            Achievement(id: "multi_instrument_5", title: "One-Person Band", detail: "Practice with 5 different instruments", icon: "music.mic.circle.fill", requirement: 5, unlocked: unlockedIDs.contains("multi_instrument_5")),
            Achievement(id: "first_scan", title: "Sheet Reader", detail: "Scan your first piece of sheet music", icon: "doc.text.viewfinder", requirement: 1, unlocked: unlockedIDs.contains("first_scan")),
            Achievement(id: "ten_scans", title: "Library Builder", detail: "Scan 10 pieces of sheet music", icon: "books.vertical.fill", requirement: 10, unlocked: unlockedIDs.contains("ten_scans")),
            Achievement(id: "hour_practiced", title: "Hour of Power", detail: "Practice for a total of 60 minutes", icon: "clock.fill", requirement: 60, unlocked: unlockedIDs.contains("hour_practiced")),
            Achievement(id: "five_hours", title: "Marathon Musician", detail: "Practice for a total of 5 hours", icon: "timer", requirement: 300, unlocked: unlockedIDs.contains("five_hours")),
        ]
    }

    private func checkAchievements() {
        var unlockedIDs = Set(UserDefaults.standard.stringArray(forKey: achievementsKey) ?? [])
        var newUnlock: Achievement?

        for i in achievements.indices {
            guard !achievements[i].unlocked else { continue }
            let met: Bool
            switch achievements[i].id {
            case "first_practice", "five_sessions", "ten_sessions", "twentyfive_sessions", "fifty_sessions":
                met = totalPracticeSessions >= achievements[i].requirement
            case "streak_3", "streak_7", "streak_30":
                met = currentStreak >= achievements[i].requirement
            case "multi_instrument_3", "multi_instrument_5":
                met = uniqueInstruments.count >= achievements[i].requirement
            case "first_scan", "ten_scans":
                met = totalSongsScanned >= achievements[i].requirement
            case "hour_practiced", "five_hours":
                met = totalPracticeMinutes >= achievements[i].requirement
            default:
                met = false
            }

            if met {
                achievements[i].unlocked = true
                achievements[i].unlockedDate = Date()
                unlockedIDs.insert(achievements[i].id)
                newUnlock = achievements[i]
            }
        }

        if !unlockedIDs.isEmpty {
            UserDefaults.standard.set(Array(unlockedIDs), forKey: achievementsKey)
        }

        if let achievement = newUnlock {
            newlyUnlockedAchievement = achievement
        }
    }

    var streakEmoji: String {
        switch currentStreak {
        case 0: return ""
        case 1...2: return "🔥"
        case 3...6: return "🔥🔥"
        case 7...13: return "🔥🔥🔥"
        case 14...29: return "💪🔥"
        default: return "👑🔥"
        }
    }

    var unlockedCount: Int {
        achievements.filter(\.unlocked).count
    }
}
