//
//  Canvas.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 15.12.2025.
//

import SwiftData
import Foundation

@Model
class Canvas: Identifiable, Codable {
//    @Attribute(.unique)
    var id: String = UUID().uuidString
    var name: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var isPined: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \Node.canvas)
    var nodes: [Node]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \Tag.canvas)
    var tags: [Tag]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \NodeConnection.canvas)
    var connections: [NodeConnection]? = []
    
    init(id: String = UUID().uuidString, name: String, isPined: Bool = false, nodes: [Node] = [], connections: [NodeConnection] = []) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPined = isPined
        self.nodes = nodes
        self.connections = connections
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isPined = try container.decode(Bool.self, forKey: .isPined)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isPined, forKey: .isPined)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, createdAt, updatedAt, isPined
    }
}

extension Canvas {
    @available(iOS 26.0, *)
    func toSchema() -> CanvasSchema {
        CanvasSchema(
            id: id,
            name: name,
            nodes: nodes?.map { $0.toSchema() } ?? [],
            connections: connections?.map { $0.toSchema() } ?? []
        )
    }
    
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    convenience init(from schema: CanvasSchema) {
        self.init(
            id: schema.id,
            name: schema.name,
            isPined: false,
            nodes: schema.nodes.map { Node(from: $0) },
            connections: schema.connections.map { NodeConnection(from: $0) }
        )
    }
}

extension Canvas {
    
    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    func makeSemanticSummary(maxClusters: Int = 6) -> String {
        let names = nodes?.map(\.name) ?? []

        let clusters = Dictionary(grouping: names) { name in
            name.split(separator: " ").first.map(String.init) ?? name
        }
        .sorted { $0.value.count > $1.value.count }
        .prefix(maxClusters)
        .map { "\($0.key): \($0.value.count) nodes" }

        let mainIdea = nodes?.first {
            abs($0.position.x) < 1 && abs($0.position.y) < 1
        }?.name

        var result = "Canvas overview:\n"
        if let mainIdea { result += "- Main idea: \(mainIdea)\n" }
        result += "- Clusters:\n"
        clusters.forEach { result += "  - \($0)\n" }

        return result
    }
}

extension Canvas {

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    func makeChunks(maxNodesPerChunk: Int = 4) -> [CanvasChunk] {
        var chunks: [CanvasChunk] = []
        var buffer: [NodeSchema] = []

        for node in (nodes ?? []) {
            buffer.append(node.toSchema())

            if buffer.count >= maxNodesPerChunk {
                chunks.append(buildChunk(from: buffer))
                buffer.removeAll()
            }
        }

        if !buffer.isEmpty {
            chunks.append(buildChunk(from: buffer))
        }

        return chunks
    }

    @available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
    private func buildChunk(from nodes: [NodeSchema]) -> CanvasChunk {
        let ids = Set(nodes.map(\.id))
        let relatedConnections = connections?.filter {
            ids.contains($0.fromNodeId) || ids.contains($0.toNodeId)
        }.map { $0.toSchema() } ?? []

        return CanvasChunk(
            nodeIds: ids,
            nodes: nodes,
            connections: relatedConnections
        )
    }
}

