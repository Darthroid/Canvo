//
//  Canvas.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 15.12.2025.
//

import SwiftData
import Foundation

@Model
public class Canvas: Identifiable, Codable {
//    @Attribute(.unique)
    public var id: String = UUID().uuidString
    var name: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var isPined: Bool = false
    
    var isSecured: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \Node.canvas)
    var nodes: [Node]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \Tag.canvas)
    var tags: [Tag]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \NodeConnection.canvas)
    var connections: [NodeConnection]? = []
    
    init(id: String = UUID().uuidString, name: String, isPined: Bool = false, isSecured: Bool = false, nodes: [Node] = [], connections: [NodeConnection] = []) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPined = isPined
        self.isSecured = isSecured
        self.nodes = nodes
        self.connections = connections
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
        isPined = try container.decodeIfPresent(Bool.self, forKey: .isPined) ?? false
        isSecured = try container.decodeIfPresent(Bool.self, forKey: .isSecured) ?? false
        nodes = try container.decode([Node].self, forKey: .nodes)
        connections = try container.decode([NodeConnection].self, forKey: .connections)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isPined, forKey: .isPined)
        try container.encode(isSecured, forKey: .isSecured)
        try container.encode(nodes, forKey: .nodes)
        try container.encode(connections, forKey: .connections)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, createdAt, updatedAt, isPined, isSecured, connections, nodes, tags
    }
}

extension Canvas {
    
    func toSchema() -> CanvasSchema {
        CanvasSchema(
            id: id,
            name: name,
            nodes: nodes?.map { $0.toSchema() } ?? [],
            connections: connections?.map { $0.toSchema() } ?? []
        )
    }
    
    convenience init(from schema: CanvasSchema) {
        self.init(
            id: schema.id,
            name: schema.name,
            isPined: false,
            isSecured: false,
            nodes: schema.nodes.map { Node(from: $0) },
            connections: schema.connections.map { NodeConnection(from: $0) }
        )
    }
}

