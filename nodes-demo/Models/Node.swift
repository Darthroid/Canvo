//
//  Node.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//
import Foundation
import RealityKit
import RealityKitContent
import SwiftData
import SwiftUI

@Model
class Node: Identifiable, Codable {
    @Attribute(.unique) var id: String
    var name: String
    var detail: String
    
    var x: Float
    var y: Float
    var z: Float
    
    /// Hex formatted color
    var colorRaw: String?
    
    var canvas: Canvas?
    
    var color: Color? {
        return Color(hex: colorRaw ?? "")
    }
    
    var position: SIMD3<Float> { .init(x, y, z) }
    var positionDescription: String { "(\(x), \(y), \(z))" }
    var positionDescriptionMeters: String { "(\(x)m, \(y)m, \(z)m)" }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, detail, x, y, z, colorRaw = "color"
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        detail = try values.decode(String.self, forKey: .detail)
        x = try values.decode(Float.self, forKey: .x)
        y = try values.decode(Float.self, forKey: .y)
        z = try values.decode(Float.self, forKey: .z)
        colorRaw = try values.decodeIfPresent(String.self, forKey: .colorRaw)
    }
    
    init(id: String = UUID().uuidString, name: String, detail: String,
         x: Float, y: Float, z: Float, color: String? = nil, canvas: Canvas? = nil) {
        self.id = id
        self.name = name
        self.detail = detail
        self.x = x
        self.y = y
        self.z = z
        self.colorRaw = color
        self.canvas = canvas
    }
    
    func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encode(detail, forKey: .detail)
        try values.encode(x, forKey: .x)
        try values.encode(y, forKey: .y)
        try values.encode(z, forKey: .z)
        try values.encodeIfPresent(colorRaw, forKey: .colorRaw)
    }
}

@Model
class NodeConnection: Identifiable, Equatable {
    @Attribute(.unique) var id: String
    var fromNodeId: String
    var toNodeId: String
    
    var canvas: Canvas?
    
    init(id: String = UUID().uuidString, fromNodeId: String, toNodeId: String, canvas: Canvas? = nil) {
        self.id = id
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.canvas = canvas
    }
}

struct NodeDataComponent: Component {
    let node: Node
}

struct ConnectionDataComponent: Component {
    let connection: NodeConnection
}
