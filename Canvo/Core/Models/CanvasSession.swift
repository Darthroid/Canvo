//
//  CanvasSession.swift
//  Canvo
//
//  Created by Олег Комаристый on 09.06.2026.
//

import Foundation
import Observation
import RealityKit

@Observable
final class CanvasSession {

    var currentCanvas: Canvas?

    var selectedNodeIds: Set<String> = []
    var expandedNodeIds: Set<String> = []

    var selectedTags: Set<Tag> = []

    var centerOnNodeId: String?
    var pendingNodePosition: SIMD3<Float>?
    
    
    func clearSelection() {
        selectedNodeIds.removeAll()
    }

    func clearExpanded() {
        expandedNodeIds.removeAll()
    }

    func clearFilters() {
        selectedTags.removeAll()
    }

    func reset() {
        clearSelection()
        clearExpanded()
        clearFilters()
    }

    func switchTo(
        _ canvas: Canvas?,
        actionService: ActionService
    ) {
        actionService.clear()

        reset()

        currentCanvas = canvas

        canvas?.nodes?.forEach {
            $0.isHidden = false
        }
    }

    func toggleTag(_ tag: Tag) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}
