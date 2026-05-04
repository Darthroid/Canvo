//
//  CreateTagAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct CreateTagAction: CanvasAction {
    let id = UUID()
    
    let tagName: String
    
    func apply(on model: AppModel) {
        model.createTagInternal(name: tagName)
    }
    
    func undo(on model: AppModel) {
        model.deleteTagInternal(name: tagName)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
