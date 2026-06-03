//
//  NodeSnapshot.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

struct NodeSnapshot: Sendable {
    let id: String
    let name: String
    let detail: String
    let detailRichText: Data?
    let x: Float
    let y: Float
    let z: Float
    let color: String?
    let tagsRaw: String?
}

struct ConnectionSnapshot: Sendable {
    let id: String
    let fromNodeId: String
    let toNodeId: String
}
