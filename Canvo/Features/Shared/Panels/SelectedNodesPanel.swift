//
//  SelectedNodesPanel.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import SwiftUI

struct SelectedNodesPanel: View {
    @Environment(AppModel.self) private var appModel

    var isDemo: Bool = false
    var onDelete: () -> Void
    var onAiEdit: () -> Void
    var onDuplicate: () -> Void

    var body: some View {
        HStack(spacing: 24) {

            // count (circle badge)
            Text(isDemo ? "3" : "\(appModel.session.selectedNodeIds.count)")
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.primary.opacity(0.12)))
                .overlay(
                    Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )

            panelButton(systemImage: "trash") {
                onDelete()
            }

            if #available(iOS 26.0, *) {
                panelButton(systemImage: "sparkles") {
                    onAiEdit()
                }
                .disabled(!appModel.aiGenerationService.isAvailable)
            }

            panelButton(systemImage: "plus.square.on.square") {
                onDuplicate()
            }

            Menu {
                Menu {
                    ForEach(FocusMode.allCases) { mode in
                        Button {
                            appModel.session.focusMode = mode
                        } label: {
                            let isSelected = appModel.session.focusMode == mode
                            if isSelected {
                                Label(mode.title, systemImage: "checkmark")
                            } else {
                                Text(mode.title)
                            }
                        }
                    }
                } label : {
                    Label {
                        Text("Focus")
                    } icon: {
                        Image(systemName: "dot.viewfinder")
                    }
                }

                Menu {
                    Button {
                        selectAllChildren()
                    } label: {
                        Text("Child nodes")
                    }

                    Button {
                        selectAllConnected()
                    } label: {
                        Text("Connected")
                    }

                    Divider()

                    Button {
                        selectall()
                    } label: {
                        Text("All")
                    }

                } label: {
                    Label("Select", systemImage: "selection.pin.in.out")
                }

            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            #if os(visionOS)
            .clipShape(Circle())
            #endif

            panelButton(systemImage: "xmark") {
                withAnimation {
                    appModel.session.clearSelection()
                }
            }
            .background(.thinMaterial, in: Circle())
            .overlay(Circle().stroke(.white.opacity(0.08)))
        }
        .padding(.horizontal, 20)
        .padding(.vertical)
        #if !os(visionOS)
        .adaptiveGlass()
        #else
        .glassBackgroundEffect()
        #endif
    }

    @ViewBuilder
    private func panelButton(
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .labelsHidden()
        #if os(visionOS)
        .clipShape(Circle())
        #endif
    }

    private func selectall() {
        appModel.nodes
            .map(\.id)
            .forEach { appModel.session.selectedNodeIds.insert($0) }
    }

    private func selectAllConnected() {
        let allConnected = appModel.session.selectedNodeIds.flatMap {
            appModel.nodeIds(connectedTo: $0)
        }
        appModel.session.selectedNodeIds.formUnion(allConnected)
    }

    private func selectAllChildren() {
        let outline = appModel.outlineService.buildOutline(
            nodes: appModel.nodes,
            connections: appModel.connections
        )

        var childIds = Set<String>()

        for selectedId in appModel.session.selectedNodeIds {
            for tree in outline {
                collectDescendants(
                    of: selectedId,
                    in: tree,
                    result: &childIds
                )
            }
        }

        appModel.session.selectedNodeIds.formUnion(childIds)
    }

    private func collectDescendants(
        of nodeId: String,
        in tree: NodeTree,
        result: inout Set<String>
    ) {
        if tree.id == nodeId {
            collectAllChildren(
                from: tree,
                result: &result
            )
            return
        }

        for child in tree.children {
            collectDescendants(
                of: nodeId,
                in: child,
                result: &result
            )
        }
    }

    private func collectAllChildren(
        from tree: NodeTree,
        result: inout Set<String>
    ) {
        for child in tree.children {
            result.insert(child.id)
            collectAllChildren(
                from: child,
                result: &result
            )
        }
    }
}
