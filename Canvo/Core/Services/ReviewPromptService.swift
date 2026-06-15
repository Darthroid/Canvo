//
//  ReviewPromptService.swift
//  Canvo
//
//  Created by Олег Комаристый on 15.06.2026.
//

import Foundation
import StoreKit
import SwiftUI

enum ReviewEvent: String {
    case canvasCreated
    case canvasFirstNodeAdded
    case canvasCompleted
    case aiGenerationAccepted
    case canvasExported
}

final class ReviewPromptStore {

    private let defaults = UserDefaults.standard

    private let lastPromptDateKey = "review.lastPromptDate"
    private let promptCountKey = "review.promptCount"

    var lastPromptDate: Date? {
        get { defaults.object(forKey: lastPromptDateKey) as? Date }
        set { defaults.set(newValue, forKey: lastPromptDateKey) }
    }

    var promptCount: Int {
        get { defaults.integer(forKey: promptCountKey) }
        set { defaults.set(newValue, forKey: promptCountKey) }
    }

    func increment() {
        promptCount += 1
        lastPromptDate = Date()
    }
}

struct ReviewPolicy {

    let minimumSessions: Int = 2
    let cooldownDays: Int = 3

    func canRequestReview(store: ReviewPromptStore, sessionCount: Int) -> Bool {

        if sessionCount < minimumSessions {
            return false
        }

        if let last = store.lastPromptDate {
            let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
            if days < cooldownDays {
                return false
            }
        }

        return true
    }
}

@MainActor
final class ReviewPromptService {

    private let store: ReviewPromptStore
    private let policy: ReviewPolicy

    private var sessionCount: Int = 0

    init(store: ReviewPromptStore = .init(),
         policy: ReviewPolicy = .init()) {
        self.store = store
        self.policy = policy
    }

    func registerAppLaunch() {
        sessionCount += 1
    }

    func handle(event: ReviewEvent) {
        guard policy.canRequestReview(store: store,
                                      sessionCount: sessionCount) else {
            return
        }

        switch event {

        case .canvasCompleted,
             .canvasExported,
             .aiGenerationAccepted:

            scheduleReviewRequest()

        default:
            break
        }
    }

    private func scheduleReviewRequest() {
        // даём UI “успокоиться”
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            requestReview()
        }
    }

    private func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        store.increment()
        AppStore.requestReview(in: scene)
    }
}
