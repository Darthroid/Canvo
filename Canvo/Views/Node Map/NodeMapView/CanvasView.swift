//
//  CanvasView.swift
//  Canvo
//
//  Created by Олег Комаристый on 06.07.2026.
//

import SwiftUI

struct CanvasView: View {
    @Environment(AppModel.self) private var appModel
    @EnvironmentObject private var themeStore: ThemeStore

    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var nodeSizes: [String: CGSize]
    
    @State var dragStartPositions: [String: SIMD3<Float>] = [:]
    @State var draggedNodeIds: Set<String> = []

    let searchResults: [Node]
    let showGrid: Bool

    let onDetail: (Node) -> Void
    let onLink: (Node) -> Void
    let onDelete: (Node) -> Void
    
    var body: some View {
        ZStack {
            
            ZStack {
                let isFocused = appModel.session.focusMode != nil
                
                // Canvas grid
                if showGrid {
                    GridLayer(offset: offset, scale: scale)
                }
                
                let visibleNodes = appModel.visibleNodes
                let nodeMap = Dictionary(
                    uniqueKeysWithValues: visibleNodes.map { ($0.id, $0) }
                )

                let visibleConnections = appModel.visibleConnections
                
                ZStack {
                    // Connections
                    ForEach(visibleConnections) { c in
                        if let a = nodeMap[c.fromNodeId],
                           let b = nodeMap[c.toNodeId]  {
                            let shouldFocus = appModel.session.focusNodeIds.contains(c.fromNodeId) && appModel.session.focusNodeIds.contains(c.toNodeId)
                            ConnectionView(
                                fromCenter: a.position.position2D,
                                fromSize: nodeSizes[a.id] ?? .zero,
                                toCenter: b.position.position2D,
                                toSize: nodeSizes[b.id] ?? .zero
                            )
                            .stroke(
                                themeStore.theme.canvasTheme.connector,
                                lineWidth: 2
                            )
                            .opacity(!isFocused ? 1 : (shouldFocus ? 1 : 0.1))
                        }

                    }
                    
                    // Nodes
                    ForEach(visibleNodes) { node in
                        let isSelected = appModel.session.selectedNodeIds.contains(node.id)
                        let isExpanded = appModel.session.expandedNodeIds.contains(node.id)
                        let nodeView = NodeView(
                            node: node,
                            isSelected: isSelected,
                            isExpanded: isExpanded,
                            isMatchingSearch: searchResults.contains(where: { $0.id == node.id }),
                            toolbarEnabled: true,
                            onSizeChange: { size in
                                nodeSizes[node.id] = size
                            },
                            onDetail: { onDetail(node) },
                            onLink: { onLink(node) },
                            onDelete: { onDelete(node) }
                        )
                        .equatable()
                        .opacity(!isFocused ? 1 : (appModel.session.focusNodeIds.contains(node.id) ? 1 : 0.1))
                        .position(node.position.position2D)
                        .zIndex(isSelected || isExpanded ? 100 : 0)
                        .onTapGesture(count: 1) {
                            withAnimation {
                                if appModel.session.selectedNodeIds.contains(node.id) {
                                    appModel.session.selectedNodeIds.remove(node.id)
                                } else {
                                    appModel.session.selectedNodeIds.insert(node.id)
                                }
                            }
                        }
                        .onTapGesture(count: 2) {
                            withAnimation(.bouncy(duration: 0.2)) {
                                if appModel.session.expandedNodeIds.contains(node.id) {
                                    appModel.session.expandedNodeIds.remove(node.id)
                                } else {
                                    appModel.session.expandedNodeIds.insert(node.id)
                                }
                            }
                        }

                        if appModel.session.selectedNodeIds.contains(node.id) {
                            nodeView.gesture(nodeDrag(node))
                        } else {
                            nodeView
                        }
                    }
                    
                    // Debug marker for node creation (DO NOT REMOVE!)
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)
                        .position(
                            x: CGFloat(appModel.session.pendingNodePosition?.x ?? 0),
                            y: CGFloat(appModel.session.pendingNodePosition?.y ?? 0)
                        )
                        .opacity(appModel.session.pendingNodePosition == nil ? 0 : 0.7)
                }
                .scaleEffect(scale)
                .offset(offset)
                .coordinateSpace(name: "canvas")
            }
        }
        .coordinateSpace(name: "canvas")
//        .background(Color(uiColor: .secondarySystemFill))
        .background(
            themeStore.theme.canvasTheme.background
                .ignoresSafeArea()
        )
    }
}

extension CanvasView {
    func nodeDrag(_ node: Node) -> some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { value in
                // ignore if node is not selected
                guard appModel.session.selectedNodeIds.contains(node.id) else {
                    return
                }

                let movingIds = appModel.session.selectedNodeIds

                // remember start positions
                for id in movingIds {
                    if dragStartPositions[id] == nil,
                       let n = appModel.node(forId: id) {
                        dragStartPositions[id] = n.position
                    }
                }

                // ovserve all dragged nodes
                draggedNodeIds.formUnion(movingIds)

                // calculate offset
                let dx = Float(value.translation.width) / Float(scale)
                let dy = Float(value.translation.height) / Float(scale)

                // apply offset to nodes (without saving)
                for id in movingIds {
                    guard let start = dragStartPositions[id],
                          let n = appModel.node(forId: id) else { continue }
                    n.x = start.x + dx
                    n.y = start.y + dy
                }
            }
            .onEnded { _ in
                // gather data for batch actions
                var nodeIds: [String] = []
                var oldPositions: [SIMD3<Float>] = []
                var newPositions: [SIMD3<Float>] = []

                for id in draggedNodeIds {
                    guard let start = dragStartPositions[id],
                          let node = appModel.node(forId: id) else { continue }
                    let end = node.position
                    if start != end {
                        nodeIds.append(id)
                        oldPositions.append(start)
                        newPositions.append(end)
                    }
                }

                // if there are changes, perform batch actions
                if !nodeIds.isEmpty {
                    appModel.moveNodes(
                        ids: nodeIds,
                        oldPositions: oldPositions,
                        newPositions: newPositions
                    )
                }

                // cleanup
                for id in draggedNodeIds {
                    dragStartPositions.removeValue(forKey: id)
                }
                draggedNodeIds.removeAll()
            }
    }
}
