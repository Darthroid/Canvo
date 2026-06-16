//
//  ToggleSecureCanvasAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 16.06.2026.
//


import Foundation

struct ToggleSecureCanvasAction: CanvasAction {
    let id = UUID()
    
    let canvasId: String
    let oldValue: Bool
    let newValue: Bool
    
    func apply(on model: AppModel) {
        model.mutationService.setSecured(
            canvasId: canvasId,
            value: newValue
        )
    }
    
    func undo(on model: AppModel) {
        model.mutationService.setSecured(
            canvasId: canvasId,
            value: oldValue
        )
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
