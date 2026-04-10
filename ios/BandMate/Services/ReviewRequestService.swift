import StoreKit
import SwiftUI

@Observable
@MainActor
class ReviewRequestService {
    static let shared = ReviewRequestService()

    private let practiceCountKey = "reviewPracticeCount"
    private let lastReviewRequestDateKey = "lastReviewRequestDate"
    private let hasEverRequestedKey = "hasEverRequestedReview"

    private var practiceCountSinceLastAsk: Int {
        get { UserDefaults.standard.integer(forKey: practiceCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: practiceCountKey) }
    }

    private var lastRequestDate: Date? {
        get { UserDefaults.standard.object(forKey: lastReviewRequestDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastReviewRequestDateKey) }
    }

    private var hasEverRequested: Bool {
        get { UserDefaults.standard.bool(forKey: hasEverRequestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasEverRequestedKey) }
    }

    func recordPracticeCompleted() {
        practiceCountSinceLastAsk += 1
    }

    func requestReviewIfAppropriate() {
        guard shouldAskForReview() else { return }

        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            SKStoreReviewController.requestReview(in: scene)
            lastRequestDate = Date()
            practiceCountSinceLastAsk = 0
            hasEverRequested = true
        }
    }

    private func shouldAskForReview() -> Bool {
        if !hasEverRequested {
            return practiceCountSinceLastAsk >= 3
        }

        guard let lastDate = lastRequestDate else {
            return practiceCountSinceLastAsk >= 3
        }

        let daysSinceLastAsk = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSinceLastAsk >= 60 && practiceCountSinceLastAsk >= 5
    }
}
