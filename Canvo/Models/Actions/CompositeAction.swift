//
//  CompositeAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

public struct CompositeAction: CanvasAction {
    let id = UUID()
    
    let actions: [CanvasAction]
    
    func apply(on model: AppModel) {
        actions.forEach { $0.apply(on: model) }
    }
    
    func undo(on model: AppModel) {
        actions.reversed().forEach { $0.undo(on: model) }
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
