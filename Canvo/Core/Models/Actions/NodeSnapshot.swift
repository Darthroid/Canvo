//
//  NodeSnapshot.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation

public struct NodeSnapshot: Sendable {
    let id: String
    let name: String
    let detail: String
    let detailRichText: Data?
    let x: Float
    let y: Float
    let z: Float
    let color: String?
    let tagsRaw: String?
    let images: [Data]
}


public extension NodeSnapshot {
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
    }
}

public extension NodeSnapshot {
    init(
        id: String,
        name: String,
        richText: AttributedString,
        x: Float,
        y: Float,
        z: Float,
        color: String?,
        tagsRaw: String?,
        images: [Data]
    ) {
        self.init(
            id: id,
            name: name,
            detail: String(richText.characters),
            detailRichText: try? JSONEncoder().encode(richText),
            x: x,
            y: y,
            z: z,
            color: color,
            tagsRaw: tagsRaw,
            images: images
        )
    }
}
