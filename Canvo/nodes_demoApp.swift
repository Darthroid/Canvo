//
//  nodes_demoApp.swift
//  nodes-demo
//
//  Created by Oleg Komaristy on 17.11.2025.
//

import SwiftUI

@main
struct nodes_demoApp: App {
    @State private var appModel: AppModel = AppModel()
    
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                CanvasCollectionView()
                    .environment(appModel)
            } else {
                OnboardingView(onFinish: {
                    hasSeenOnboarding = true
                })
                .environment(appModel)
            }
        }
        #if os(visionOS)
        ImmersiveSpace(id: "ImmersiveNodeMapView") {
            ImmersiveNodeMapView()
                .environment(appModel)
        }
        #endif
    }
}
