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
    
    @EnvironmentObject private var themeStore: ThemeStore
    
    @State var showNodeForm = false
    
    @State private var showDetailNode: Node?
    @State private var showLinkToNode: Node?
    
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
                ForEach(appModel.tags ?? [], id: \.name) { tag in
                    Button {
                        appModel.toggleTag(tag)
                    } label: {
                        let isSelected = appModel.session.selectedTags.contains(tag)
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
                Label("Tag Filter", systemImage: appModel.session.selectedTags.isEmpty ? "tag" : "tag.fill")
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
    
    private var focusPanel: some View {
        HStack(spacing: 24) {
            
            Text("Focus mode")

            Button {
                appModel.session.focusNodeIds.removeAll()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .labelsHidden()
            #if os(visionOS)
            .clipShape(Circle())
            #endif
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if !os(visionOS)
        .glassEffect()
        #else
        .glassBackgroundEffect()
        #endif

    }

    var body: some View {
        
        VStack(spacing: 12) {
            Spacer()
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
            } else {
                if !appModel.session.focusNodeIds.isEmpty {
                    focusPanel
                }
                if !appModel.session.selectedNodeIds.isEmpty {
                    SelectedNodesPanel {
                        appModel.removeSelectedNodes()
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
                    .tint(themeStore.theme.canvasTheme.selection)
                    
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
        .onReceive(NotificationCenter.default.publisher(for: .linkWithNode)) { notification in
            guard let node = notification.userInfo?["node"] as? Node else {
                return
            }

            DispatchQueue.main.async {
                self.showLinkToNode = node
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
        .sheet(item: $showLinkToNode) { node in
            NavigationStack {
                LinkEditorView(fromNode: node)
            }
        }
        .sheet(isPresented: $showNodeForm) {
            CreateNodeView(position: appModel.session.pendingNodePosition)
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
                    appModel.aiGenerationService.error != nil
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
    }
    
    func addNewNode() {
        if let deviceAnchor = worldTracking.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
            // The position is stored in the 4th column of the transform matrix
            let cameraPosition = deviceAnchor.originFromAnchorTransform.columns.3
            let position = SIMD3(x: cameraPosition.x, y: cameraPosition.y, z: cameraPosition.z - 1.5)
            
            appModel.session.pendingNodePosition = GeometryService.iOSPosition(position)
            
            showNodeForm = true
        } else {
            appModel.session.pendingNodePosition = GeometryService.iOSPosition(.zero)
            
            showNodeForm = true
        }

    }
}
#endif
