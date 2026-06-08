//
//  CanvasRepository+Tags.swift
//  Canvo
//
//  Created by Олег Комаристый on 06.06.2026.
//


import SwiftData
import Foundation

public extension CanvasRepository {

    func createTag(
        name: String,
        canvas: Canvas
    ) {
        let tag = Tag(
            name: name,
            canvas: canvas
        )
        
        canvas.updatedAt = Date()

        context.insert(tag)
    }

    func deleteTag(_ tag: Tag) {
        tag.canvas?.updatedAt = Date()
        context.delete(tag)
    }
}
