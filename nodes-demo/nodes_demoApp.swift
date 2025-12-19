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
    
    var body: some Scene {
        WindowGroup {
            CanvasGridView()
                .environment(appModel)
        }
        
        ImmersiveSpace(id: "ImmersiveNodeMapView") {
            ImmersiveNodeMapView()
                .environment(appModel)
        }

    }
}
