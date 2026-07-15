//
//  CreateTagAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct CreateTagAction: CanvasAction {
    let id = UUID()
    
    let canvas: Canvas
    let tagName: String
    
    func apply(on model: AppModel) {
        model.tagsService.createTag(name: tagName, canvas: canvas)
    }
    
    func undo(on model: AppModel) {
        model.tagsService.deleteTag(name: tagName, canvas: canvas)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
