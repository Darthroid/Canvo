//
//  AddNodeAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct AddNodeAction: CanvasAction {
    let id = UUID()
    
    let node: NodeSnapshot
    
    func apply(on model: AppModel) {
        model.insertNodeInternal(node)
    }
    
    func undo(on model: AppModel) {
        model.removeNodeInternal(id: node.id)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
