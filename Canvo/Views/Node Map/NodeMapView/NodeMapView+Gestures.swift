//
//  NodeMapView+Gestures.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import SwiftUI

extension NodeMapView {
    
    var minScale: CGFloat { 0.1 }
    var maxScale: CGFloat { 4.0 }
    var zoomSensitivity: CGFloat { 0.35 }
    
    // MARK: - PAN
    
    var panGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                let dx = v.translation.width - lastPanTranslation.width
                let dy = v.translation.height - lastPanTranslation.height
                offset.width += dx
                offset.height += dy
                lastPanTranslation = v.translation
            }
            .onEnded { _ in
                lastPanTranslation = .zero
            }
    }
    
    // MARK: - ZOOM
    
    var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = 1 + (value - 1) * zoomSensitivity
                scale = min(max(baseScale * delta, minScale), maxScale)
                
                showZoomLevel = true
            }
            .onEnded { _ in
                baseScale = scale
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showZoomLevel = false
                }
            }
    }
    
    func applyZoom(multiplier: CGFloat) {
        let next = scale * multiplier
        let clamped = min(max(next, minScale), maxScale)
        scale = clamped
        baseScale = clamped
        showZoomLevel = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.showZoomLevel = false
        }
    }
    
    func setDefaultZoom() {
        scale = 1.0
        baseScale = 1.0
//        offset = .zero
    }
    
    // MARK: - NODE DRAG
    
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
