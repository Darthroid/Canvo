//
//  PushWindowContent.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import SwiftUI
import ARKit

#if os(visionOS)
struct ImmersiveMapToolbar: View {

    @Environment(AppModel.self) private var appModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State var showNodeForm = false
    
    @State private var showDetailNode: Node?
    
    let session = ARKitSession()
    let worldTracking = WorldTrackingProvider()
    
    var menuButton: some View {
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
            
            Toggle(isOn: Binding(
                get: { appModel.aiEditorOpen },
                set: { newValue in
                    appModel.aiEditorOpen = newValue
                }
            ).animation()) {
                Label("AI Editor", systemImage: "sparkles")
            }
            
        } label: {
            Label("", systemImage: "ellipsis")
        }
        .labelStyle(.iconOnly)
        .clipShape(Circle())
    }

    var body: some View {
        
        VStack(spacing: 12) {
            Spacer()
            if AIGenerationService.shared.isRunning {
                AIGenerationSnackbar(
                    title: AIGenerationService.shared.runningStage ?? "Generating",
                    onCancel: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                            AIGenerationService.shared.cancelCurrentTask()
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .transition(
                    .move(edge: .bottom)
                    .combined(with: .opacity)
                )
            } else {
                if !appModel.selectedNodeIds.isEmpty {
                    SelectedNodesPanel {
                        appModel.deleteSelectedNodes()
                    } onAiEdit: {
                        appModel.aiEditorOpen.toggle()
                    } onDuplicate: {
                        appModel.duplicateSelectedNodes()
                    }
                    .glassBackgroundEffect()
                }
                
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
                        addNewNode()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                    .clipShape(Circle())
                    .tint(.accent)
                    
                    Spacer()
                    
                    menuButton
                    
                    Button {
                        dismissWindow(id: "ImmersiveMapToolbar")
                        appModel.immersiveMapToolbarOpen = false
                    } label: {
                        Label("", systemImage: "xmark")
                    }
                    .labelStyle(.iconOnly)
                }
                .padding()
                .glassBackgroundEffect()
            }
        }
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
        .onReceive(NotificationCenter.default.publisher(for: .pinchOutWithNode)) { notification in
            guard let node = notification.userInfo?["node"] as? Node else {
                return
            }

            DispatchQueue.main.async {
                self.showDetailNode = node
            }
        }
        .onAppear {
            Task {
                _ = await session.requestAuthorization(for: [.worldSensing, .handTracking])
                try? await session.run([worldTracking])
            }
        }
        .sheet(item: $showDetailNode) { node in
            NavigationStack {
                NodeDetailView(node: node)
            }
        }
        .sheet(isPresented: $showNodeForm) {
            CreateNodeView(position: appModel.pendingNodePosition)
                .environment(appModel)
        }
        .sheet(isPresented: Binding(
            get: { appModel.aiEditorOpen },
            set: { newValue in
                appModel.aiEditorOpen = newValue
            }
        )) {
            if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                NavigationStack {
                    AIEditCanvasView(showEditor: Binding(
                        get: { appModel.aiEditorOpen },
                        set: { newValue in
                            appModel.aiEditorOpen = newValue
                        }
                    ), visibleScopeIds: [])
                        .environment(appModel)
                        .presentationBackground(Color(.secondarySystemBackground))
                }
            }
        }
        .alert(
            "Generation failed",
            isPresented: Binding(
                get: {
                    AIGenerationService.shared.error != nil
                },
                set: { newValue in
                    if !newValue {
                        AIGenerationService.shared.clearErrors()
                    }
                }
            ),
            presenting: AIGenerationService.shared.error
        ) { detail in
            Button("OK", role: .cancel) {
                AIGenerationService.shared.clearErrors()
            }
        } message: { detail in
            Text(detail)
        }
    }
    
    func addNewNode() {
        if let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
            // The position is stored in the 4th column of the transform matrix
            let cameraPosition = deviceAnchor.originFromAnchorTransform.columns.3
            let position = SIMD3(x: cameraPosition.x, y: cameraPosition.y, z: cameraPosition.z - 1.5)
            
            appModel.pendingNodePosition = GeometryService.iOSPosition(position)
            
            showNodeForm = true
        } else {
            appModel.pendingNodePosition = GeometryService.iOSPosition(.zero)
            
            showNodeForm = true
        }

    }
}
#endif
