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
    
    private weak var model: AppModel?

    var currentCanvas: Canvas?

    var focusMode: FocusMode? = nil {
        didSet {
            setFocusedNodes()
        }
    }
    var focusNodeIds: Set<String> = []
    var selectedNodeIds: Set<String> = [] {
        didSet {
            setFocusedNodes()
        }
    }
    var expandedNodeIds: Set<String> = []

    var selectedTags: Set<Tag> = []

    var centerOnNodeId: String?
    var pendingNodePosition: SIMD3<Float>?
    
    func set(model: AppModel) {
        self.model = model
    }
    
    func cleareFocused() {
        focusMode = nil
        focusNodeIds.removeAll()
    }
    
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
        cleareFocused()
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
    
    func setFocusedNodes() {
        switch self.focusMode {
        case .selectedOnly:
            focusNodeIds.removeAll()
            for id in selectedNodeIds {
                focusNodeIds.insert(id)
            }
        case .context:
            focusNodeIds.removeAll()
            for id in selectedNodeIds {
                let connected = model?.nodeIds(connectedTo: id) ?? []
                focusNodeIds.insert(id)
                focusNodeIds.formUnion(connected)
            }
//            case .branch:
//                break
        default:
            break
        }
    }
}
