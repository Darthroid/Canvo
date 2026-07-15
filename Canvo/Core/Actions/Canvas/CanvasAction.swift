//
//  CanvasAction.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation


protocol CanvasAction {
    var id: UUID { get }
    
    func apply(on model: AppModel)
    func undo(on model: AppModel)
    
    func canMerge(with other: CanvasAction) -> Bool
    func merged(with other: CanvasAction) -> CanvasAction
}
