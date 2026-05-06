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
        .commands {
            CommandGroup(replacing: .undoRedo) {

                Button {
                    appModel.actionService.undo()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.left")
                }
                .keyboardShortcut("z", modifiers: [.command])
                .disabled(!appModel.actionService.canUndo)
                
                Button {
                    appModel.actionService.redo()
                } label: {
                    Label("Redo", systemImage: "arrow.uturn.right")
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!appModel.actionService.canRedo)
            }
            
            CommandGroup(replacing: .toolbar) {
                Button {
                    NotificationCenter.default.post(name: .init(rawValue: "zoomin"), object: nil)
                } label: {
                    Label("Zoom In", systemImage: "plus.magnifyingglass")
                }
                .disabled(appModel.currentCanvas == nil)
                .keyboardShortcut("=", modifiers: [.command])
                
                Button {
                    NotificationCenter.default.post(name: .init(rawValue: "zoomout"), object: nil)
                }  label: {
                    Label("Zoom Out", systemImage: "minus.magnifyingglass")
                }
                .disabled(appModel.currentCanvas == nil)
                .keyboardShortcut("-", modifiers: [.command])
                
                Button ("Real Size"){
                    NotificationCenter.default.post(name: .init(rawValue: "resetzoom"), object: nil)
                }
                .disabled(appModel.currentCanvas == nil)
                .keyboardShortcut("0", modifiers: [.command])
            }
            
            CommandGroup(replacing: .sidebar) {
                Button {
                    NotificationCenter.default.post(name: .init(rawValue: "togglegrid"), object: nil)
                } label: {
                    Label("Show/Hide Grid",
                          systemImage: "squareshape.split.2x2.dotted.inside.and.outside"
                    )
                }
                .disabled(appModel.currentCanvas == nil)
                
                Button {
                    NotificationCenter.default.post(name: .init(rawValue: "outline"), object: nil)
                } label: {
                    Label("Show/Hide Outline",
                          systemImage: "list.bullet.indent"
                    )
                }
                .disabled(appModel.currentCanvas == nil)
                .keyboardShortcut("m", modifiers: [.command, .shift])
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
