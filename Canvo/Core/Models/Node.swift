//
//  Node.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import Foundation
#if os(visionOS)
import RealityKit
import RealityKitContent
#endif
import SwiftData
import SwiftUI

@Model
public class Node: Identifiable, Codable {
//    @Attribute(.unique)
    public var id: String = UUID().uuidString
    var name: String = ""
    var detail: String = ""
    
    @Attribute(.externalStorage)
    var detailRichText: Data?

    /// Images stored as raw Data blobs (PNG/JPEG/etc)
    @Attribute(.externalStorage)
    var imagesData: Data?
    
    var x: Float = 0
    var y: Float = 0
    var z: Float = 0
    
    @Transient var isHidden: Bool = false
    
    /// Hex formatted color
    var colorRaw: String?
    
    var canvas: Canvas?
    
    var color: UIColor? {
        return UIColor(hex: colorRaw ?? "")
    }
    
    var position: SIMD3<Float> { .init(x, y, z) }
    var positionDescription: String { "(x:\(x), y:\(y), z:\(z))" }
    
    var tagsRaw: String? = ""
    
    var images: [Data] {
        get {
            guard let imagesData else { return [] }
            return (try? JSONDecoder().decode([Data].self, from: imagesData)) ?? []
        }
        set {
            imagesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var richText: AttributedString {
        get {
            guard let detailRichText else {
                return AttributedString(detail)
            }

            return (try? JSONDecoder().decode(
                AttributedString.self,
                from: detailRichText
            )) ?? AttributedString(detail)
        }
        set {
            detail = String(newValue.characters)
            detailRichText = try? JSONEncoder().encode(newValue)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, name, detail, x, y, z, colorRaw = "color", tags
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        detail = try values.decode(String.self, forKey: .detail)
        x = try values.decode(Float.self, forKey: .x)
        y = try values.decode(Float.self, forKey: .y)
        z = try values.decode(Float.self, forKey: .z)
        colorRaw = try values.decodeIfPresent(String.self, forKey: .colorRaw)
        tagsRaw = try values.decodeIfPresent(String.self, forKey: .tags)
    }
    
    init(id: String = UUID().uuidString, name: String, detail: String,
         x: Float, y: Float, z: Float, color: String? = nil, canvas: Canvas? = nil, tagsRaw: String? = nil, images: [Data] = []) {
        self.id = id
        self.name = name
        self.detail = detail
        self.x = x
        self.y = y
        self.z = z
        self.colorRaw = color
        self.canvas = canvas
        self.tagsRaw = tagsRaw
        self.images = images
    }
    
    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encode(detail, forKey: .detail)
        try values.encode(x, forKey: .x)
        try values.encode(y, forKey: .y)
        try values.encode(z, forKey: .z)
        try values.encodeIfPresent(colorRaw, forKey: .colorRaw)
        try values.encodeIfPresent(tagsRaw, forKey: .tags)
    }
}

extension Node {
    
    func toSchema() -> NodeSchema {
        NodeSchema(
            id: id,
            name: name,
            detail: detail,
            color: colorRaw,
            position: .init(x: x, y: y, z: z)
        )
    }
    
    convenience init(from schema: NodeSchema, canvas: Canvas? = nil) {
        self.init(
            id: schema.id,
            name: schema.name,
            detail: schema.detail,
            x: schema.position.x,
            y: schema.position.y,
            z: schema.position.z,
            color: schema.color,
            canvas: canvas
        )
    }
}

extension Node: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        return Node(
            id: self.id,
            name: self.name,
            detail: self.detail,
            x: self.x,
            y: self.y,
            z: self.z,
            color: self.colorRaw,
            canvas: self.canvas,
            tagsRaw: self.tagsRaw
        )
    }
}

#if os(visionOS)
public struct NodeDataComponent: Component {
    let node: Node
}
#endif

extension Node {
    var coverImageData: Data? {
        images.first
    }
}

extension Node {
    var renderHash: Int {
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(detail)
        hasher.combine(colorRaw)
        hasher.combine(imagesData?.count ?? 0)
        return hasher.finalize()
    }
}
