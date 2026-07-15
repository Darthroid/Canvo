//
//  CreateCanvasAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation


struct CreateCanvasAction: CanvasAction {
    let id = UUID()
    
    let canvasId: String
    let name: String
    
    func apply(on model: AppModel) {
        model.mutationService.insertCanvas(
            id: canvasId,
            name: name
        )
    }
    
    func undo(on model: AppModel) {
        model.mutationService.removeCanvas(id: canvasId)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}

struct CreateAICanvasAction: CanvasAction {
    let id = UUID()
    
    let canvas: Canvas
    
    func apply(on model: AppModel) {
        model.mutationService.insertCanvas(canvas)
    }
    
    func undo(on model: AppModel) {
        model.mutationService.removeCanvas(id: canvas.id)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
