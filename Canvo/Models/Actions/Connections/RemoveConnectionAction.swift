//
//  RemoveConnectionAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct RemoveConnectionAction: CanvasAction {
    let id = UUID()
    
    let connection: ConnectionSnapshot
    
    func apply(on model: AppModel) {
        model.removeConnectionInternal(id: connection.id)
    }
    
    func undo(on model: AppModel) {
        model.insertConnectionInternal(connection)
    }
    
    func canMerge(with other: CanvasAction) -> Bool { false }
    func merged(with other: CanvasAction) -> CanvasAction { self }
}
