//
//  Untitled.swift
//  Canvo
//
//  Created by Олег Комаристый on 06.06.2026.
//

import SwiftData
import Foundation

public extension CanvasRepository {

    func fetchCanvases() throws -> [Canvas] {
        let descriptor = FetchDescriptor<Canvas>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    func canvas(id: String) -> Canvas? {
        try? context.fetch(
            FetchDescriptor<Canvas>(
                predicate: #Predicate<Canvas> {
                    $0.id == id
                }
            )
        ).first
    }

    func insertCanvas(id: String, name: String) {
        let canvas = Canvas(
            id: id,
            name: name
        )

        context.insert(canvas)
    }

    func insertCanvas(_ canvas: Canvas) {
        context.insert(canvas)
    }

    func deleteCanvas(id: String) {
        guard let canvas = canvas(id: id) else { return }

        context.delete(canvas)
    }

    func renameCanvas(
        id: String,
        name: String
    ) {
        guard let canvas = canvas(id: id) else { return }

        canvas.name = name
        canvas.updatedAt = Date()
    }

    func setPinned(
        canvasId: String,
        value: Bool
    ) {
        guard let canvas = canvas(id: canvasId) else { return }

        canvas.isPined = value
    }
    
    func setSecured(
        canvasId: String,
        value: Bool
    ) {
        guard let canvas = canvas(id: canvasId) else { return }

        canvas.isSecured = value
    }
}
