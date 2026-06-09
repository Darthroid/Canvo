//
//  CanvasRepository.swift
//  Canvo
//
//  Created by Олег Комаристый on 06.06.2026.
//

import SwiftData

@MainActor
public final class CanvasRepository {

    let container: ModelContainer

    var context: ModelContext {
        container.mainContext
    }

    init(container: ModelContainer) {
        self.container = container
    }

    func save() {
        guard context.hasChanges else { return }

        try? context.save()
    }
}
