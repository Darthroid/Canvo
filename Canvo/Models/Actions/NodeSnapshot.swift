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


extension NodeSnapshot {
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

extension NodeSnapshot {
    init(
        id: String,
        name: String,
        richText: AttributedString,
        x: Float,
        y: Float,
        z: Float,
        color: String?,
        tagsRaw: String?
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
            tagsRaw: tagsRaw
        )
    }
}
