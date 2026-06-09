//
//  CanvasSnapshot.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//


public struct CanvasSnapshot: Sendable {
    let id: String
    let name: String
    let isPinned: Bool
    
    let nodes: [NodeSnapshot]
    let connections: [ConnectionSnapshot]
    let tags: [String]
}
