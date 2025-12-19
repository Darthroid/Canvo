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
    @Attribute(.unique) var id: String
    var name: String
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Node.canvas)
    var nodes: [Node] = []
    
    @Relationship(deleteRule: .cascade, inverse: \NodeConnection.canvas)
    var connections: [NodeConnection] = []
    
    init(id: String = UUID().uuidString, name: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, createdAt, updatedAt
    }
}
