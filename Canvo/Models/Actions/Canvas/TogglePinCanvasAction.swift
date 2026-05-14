//
//  TogglePinCanvasAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct TogglePinCanvasAction: CanvasAction {
    let id = UUID()
    
    let canvasId: String
    let oldValue: Bool
    let newValue: Bool
    
    func apply(on model: AppModel) {
        model.setPinInternal(canvasId: canvasId, value: newValue)
    }
    
    func undo(on model: AppModel) {
        model.setPinInternal(canvasId: canvasId, value: oldValue)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
