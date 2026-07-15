//
//  Canvo.swift
//  Canvo
//
//  Created by Oleg Komaristy on 17.11.2025.
//

import SwiftUI

@main
struct Canvo: App {
    @State private var appModel: AppModel = AppModel()
    @StateObject private var themeStore = ThemeStore()

    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    
    @ViewBuilder var mainContent: some View {
        if hasSeenOnboarding {
            if #available(iOS 26.0, *) {
                CanvasCollectionView()
                    .environment(appModel)
                    .environmentObject(themeStore)
                    .alert(
                        "Generation failed",
                        isPresented: Binding(
                            get: {
                                appModel.aiGenerationService.error != nil && !appModel.immersiveMapToolbarOpen
                            },
                            set: { newValue in
                                if !newValue {
                                    appModel.aiGenerationService.clearErrors()
                                }
                            }
                        ),
                        presenting: appModel.aiGenerationService.error
                    ) { detail in
                        Button("OK", role: .cancel) {
                            appModel.aiGenerationService.clearErrors()
                        }
                    } message: { detail in
                        Text(detail)
                    }
                    .overlay(alignment: .bottom) {
                        if appModel.aiGenerationService.isRunning {
                            AIGenerationSnackbar(
                                title: appModel.aiGenerationService.runningStage ?? "Generating",
                                onCancel: {
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                                        appModel.aiGenerationService.cancelCurrentTask()
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                            .transition(
                                .move(edge: .bottom)
                                .combined(with: .opacity)
                            )
                        }
                    }
            } else {
                CanvasCollectionView()
                    .environment(appModel)
                    .environmentObject(themeStore)
            }
        } else {
            OnboardingView(onFinish: {
                hasSeenOnboarding = true
            })
            .environmentObject(themeStore)
            .environment(appModel)
        }
    }
    
    var body: some Scene {
        WindowGroup(id: "MainWindow") {
            mainContent
                .tint(themeStore.theme.canvasTheme.selection)
            // Focus: When the immersive space is showing, hide the content.
                .opacity(appModel.immersiveMapOpen ? 0 : 1)
            // Focus: We can also hide the window drag bar and controls
                .persistentSystemOverlays(appModel.immersiveMapOpen ? .hidden : .visible)
                .onAppear {
                    appModel.reviewRequestService.registerAppLaunch()
                }
        }
//        #if os(visionOS)
//        .windowStyle(.plain)
//        #endif
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
                .disabled(appModel.session.currentCanvas == nil)
                .keyboardShortcut("=", modifiers: [.command])
                
                Button {
                    NotificationCenter.default.post(name: .init(rawValue: "zoomout"), object: nil)
                }  label: {
                    Label("Zoom Out", systemImage: "minus.magnifyingglass")
                }
                .disabled(appModel.session.currentCanvas == nil)
                .keyboardShortcut("-", modifiers: [.command])
                
                Button ("Real Size"){
                    NotificationCenter.default.post(name: .init(rawValue: "resetzoom"), object: nil)
                }
                .disabled(appModel.session.currentCanvas == nil)
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
                .disabled(appModel.session.currentCanvas == nil)
                
                Button {
                    NotificationCenter.default.post(name: .init(rawValue: "outline"), object: nil)
                } label: {
                    Label("Show/Hide Outline",
                          systemImage: "list.bullet.indent"
                    )
                }
                .disabled(appModel.session.currentCanvas == nil)
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }
        #if os(visionOS)
        WindowGroup(id: "ImmersiveMapToolbar") {
            ImmersiveMapToolbar()
                .environment(appModel)
                .environmentObject(themeStore)
        }
        .defaultSize(CGSize(width: 500, height: 1200))
        .windowStyle(.plain)
        .defaultWindowPlacement { _, context in
            if let mainWindow = context.windows.first(where: { $0.id == "MainWindow" }) {
                return WindowPlacement(.below(mainWindow))
            }
            return WindowPlacement(.none)
        }
        
        ImmersiveSpace(id: "ImmersiveNodeMapView") {
            ImmersiveNodeMapView()
                .environment(appModel)
                .environmentObject(themeStore)
        }
        Window("Outline", id: "outline") {
            OutlineView(preferredWidth: nil, style: .sheet)
                .environment(appModel)
                .environmentObject(themeStore)
        }
        .defaultSize(width: 400, height: 800)
        .defaultWindowPlacement { _, context in
            if let mainWindow = context.windows.first(where: { $0.id == "MainWindow" }), !appModel.immersiveMapToolbarOpen {
                return WindowPlacement(.leading(mainWindow))
            } else if let toolbarWindow = context.windows.first(where: { $0.id == "ImmersiveMapToolbar" }) {
                return WindowPlacement(.leading(toolbarWindow))
            }
            return WindowPlacement(.none)
        }
        #endif
    }
}
