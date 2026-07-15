//
//  LayoutNodesAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation


struct LayoutNodesAction: CanvasAction {
    let id = UUID()
    
    let nodeIds: [String]
    let oldPositions: [SIMD3<Float>]
    let newPositions: [SIMD3<Float>]
    
    func apply(on model: AppModel) {
        for (i, id) in nodeIds.enumerated() {
            model.mutationService.updatePosition(nodeId: id, position: newPositions[i])
        }
    }
    
    func undo(on model: AppModel) {
        for (i, id) in nodeIds.enumerated() {
            model.mutationService.updatePosition(nodeId: id, position: oldPositions[i])
        }
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
