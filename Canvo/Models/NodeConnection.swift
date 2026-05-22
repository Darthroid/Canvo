//
//  NodeConnection.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation
#if os(visionOS)
import RealityKit
import RealityKitContent
#endif
import SwiftData
import SwiftUI

@Model
class NodeConnection: Identifiable, Equatable, Codable {
//    @Attribute(.unique)
    var id: String = UUID().uuidString
    var fromNodeId: String = ""
    var toNodeId: String = ""
    
    var canvas: Canvas?
    
    init(id: String = UUID().uuidString, fromNodeId: String, toNodeId: String, canvas: Canvas? = nil) {
        self.id = id
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.canvas = canvas
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(fromNodeId, forKey: .fromNodeId)
        try container.encode(toNodeId, forKey: .toNodeId)
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fromNodeId = try container.decode(String.self, forKey: .fromNodeId)
        toNodeId = try container.decode(String.self, forKey: .toNodeId)
    }
    
    enum CodingKeys: CodingKey {
        case id
        case fromNodeId
        case toNodeId
    }
}

extension NodeConnection {
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    func toSchema() -> NodeConnectionSchema {
        .init(
            id: id,
            fromNodeId: fromNodeId,
            toNodeId: toNodeId
        )
    }
    
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    convenience init(from schema: NodeConnectionSchema, canvas: Canvas? = nil) {
        self.init(
            id: schema.id,
            fromNodeId: schema.fromNodeId,
            toNodeId: schema.toNodeId,
            canvas: canvas
        )
    }
}

#if os(visionOS)
struct ConnectionDataComponent: Component {
    let connection: NodeConnection
}
#endif
