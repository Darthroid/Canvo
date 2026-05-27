//
//  PushWindowContent.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import SwiftUI

@available(visionOS 26.0, *)
struct ImmersiveMapToolbar: View {

    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        HStack {
            Button {
                appModel.undoAction()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.left")
            }
            .disabled(!appModel.actionService.canUndo)
            .labelStyle(.iconOnly)

            Button {
                appModel.redoAction()
            } label: {
                Label("Redo", systemImage: "arrow.uturn.right")
            }
            .disabled(!appModel.actionService.canRedo)
            .labelStyle(.iconOnly)
            
            Spacer()
            
            Button {
//                pendingNodePosition = visibleCenterPosition()
//                showNodeForm = true
            } label: {
                Image(systemName: "plus")
            }
            .keyboardShortcut("n", modifiers: [.command])
            .buttonStyle(.borderedProminent)
            .clipShape(Circle())
            .tint(.accent)
            
            Spacer()
            
            Menu {
                Button {
                    withAnimation {
                        if appModel.outlineOpen {
                            dismissWindow(id: "outline")
                        } else {
                            openWindow(id: "outline")
                        }
                        appModel.outlineOpen.toggle()
                    }
                } label: {
                    Label(appModel.outlineOpen ? "Hide Outline" : "Show Outline", systemImage: "list.bullet.indent")
                }
                
                Menu {
                    ForEach(appModel.currentCanvas?.tags ?? [], id: \.name) { tag in
                        Button {
                            appModel.toggleTag(tag)
                        } label: {
                            let isSelected = appModel.selectedTags.contains(tag)
                            if isSelected {
                                Label(tag.name, systemImage: "checkmark")
                            } else {
                                Text(tag.name)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        appModel.showAllTags()
                    } label: {
                        Text("Show All")
                    }
                } label: {
                    Label("Tag Filter", systemImage: appModel.selectedTags.isEmpty ? "tag" : "tag.fill")
                }
            } label: {
                Label("", systemImage: "ellipsis")
            }
            .labelStyle(.iconOnly)
            .clipShape(Circle())
            
            Button {
                dismissWindow(id: "ImmersiveMapToolbar")
                appModel.immersiveMapToolbarOpen = false
            } label: {
                Label("", systemImage: "xmark")
            }
            .labelStyle(.iconOnly)
        }
        .padding()
        #if os(visionOS)
        .glassBackgroundEffect()
        #endif
//        .persistentSystemOverlays(.hidden)
        .onChange(of: scenePhase, initial: true) {
            switch scenePhase {
            case .inactive, .background:
                appModel.immersiveMapToolbarOpen = false
            case .active:
                appModel.immersiveMapToolbarOpen = true
            @unknown default:
                appModel.immersiveMapToolbarOpen = false
            }
        }
    }
}
