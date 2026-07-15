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

    private let launchCountKey = "review.launchCount"
    private let lastPromptDateKey = "review.lastPromptDate"
    private let promptCountKey = "review.promptCount"
    private let engagementScoreKey = "review.engagementScore"

    var launchCount: Int {
        get { defaults.integer(forKey: launchCountKey) }
        set { defaults.set(newValue, forKey: launchCountKey) }
    }

    var lastPromptDate: Date? {
        get { defaults.object(forKey: lastPromptDateKey) as? Date }
        set { defaults.set(newValue, forKey: lastPromptDateKey) }
    }

    var promptCount: Int {
        get { defaults.integer(forKey: promptCountKey) }
        set { defaults.set(newValue, forKey: promptCountKey) }
    }

    var engagementScore: Int {
        get { defaults.integer(forKey: engagementScoreKey) }
        set { defaults.set(newValue, forKey: engagementScoreKey) }
    }

    func registerLaunch() {
        launchCount += 1
    }

    func addEngagement(points: Int) {
        engagementScore += points
    }

    func markPromptRequested() {
        promptCount += 1
        lastPromptDate = Date()
    }
}

struct ReviewPolicy {

    let minimumLaunches = 1
    let minimumEngagementScore = 5
    let cooldownDays = 14
    let maximumPromptAttempts = 3

    func canRequestReview(store: ReviewPromptStore) -> Bool {

        guard store.launchCount >= minimumLaunches else {
            return false
        }

        guard store.engagementScore >= minimumEngagementScore else {
            return false
        }

        guard store.promptCount < maximumPromptAttempts else {
            return false
        }

        if let lastPromptDate = store.lastPromptDate {
            let days = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0

            guard days >= cooldownDays else {
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

    private var requestTask: Task<Void, Never>?

    init(
        store: ReviewPromptStore = .init(),
        policy: ReviewPolicy = .init()
    ) {
        self.store = store
        self.policy = policy
    }

    func registerAppLaunch() {
        store.registerLaunch()
    }

    func handle(event: ReviewEvent) {

        switch event {
        case .canvasCreated:
            store.addEngagement(points: 1)

        case .canvasFirstNodeAdded:
            store.addEngagement(points: 1)

        case .canvasCompleted:
            store.addEngagement(points: 2)

        case .aiGenerationAccepted:
            store.addEngagement(points: 2)

        case .canvasExported:
            store.addEngagement(points: 3)
        }

        guard policy.canRequestReview(store: store) else {
            return
        }

        scheduleReviewRequest()
    }

    private func scheduleReviewRequest() {
        requestTask?.cancel()

        requestTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))

            guard !Task.isCancelled else {
                return
            }

            requestReview()
        }
    }

    private func requestReview() {
        guard
            let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else {
            return
        }

        store.markPromptRequested()
        AppStore.requestReview(in: scene)
    }
}
