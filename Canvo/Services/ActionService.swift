//
//  ActionManager.swift
//  Canvo
//
//  Created by Олег Комаристый on 04.05.2026.
//

import Foundation


@MainActor
@Observable
final class ActionService {
    
    // MARK: - State
    
    private var undoStack: [CanvasAction] = []
    private var redoStack: [CanvasAction] = []
    
    private let maxStackSize: Int
    
    private weak var model: AppModel?
    
    // batching
    private var currentBatch: [CanvasAction] = []
    private var isBatching: Bool = false
    
    // merge window
    private var lastActionTimestamp: Date?
    private let mergeTimeWindow: TimeInterval = 0.4
    
    // MARK: - Init
    
    init(maxStackSize: Int = 100) {
        self.maxStackSize = maxStackSize
    }
    
    func set(model: AppModel) {
        self.model = model
    }
    
    func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    // MARK: - Perform
    
    func perform(_ action: CanvasAction) {
        guard let model else { return }
        
        if isBatching {
            currentBatch.append(action)
            action.apply(on: model)
            return
        }
        
        let now = Date()
        
        // merge logic
        if let last = undoStack.last,
           let lastTime = lastActionTimestamp,
           now.timeIntervalSince(lastTime) < mergeTimeWindow,
           last.canMerge(with: action) {
            
            let merged = last.merged(with: action)
            undoStack.removeLast()
            undoStack.append(merged)
            
            // IMPORTANT: apply only delta (новое состояние)
            action.apply(on: model)
        } else {
            undoStack.append(action)
            action.apply(on: model)
            
            trimStackIfNeeded()
        }
        
        redoStack.removeAll()
        lastActionTimestamp = now
    }
    
    // MARK: - Undo / Redo
    
    func undo() {
        guard let model, let action = undoStack.popLast() else { return }
        
        action.undo(on: model)
        redoStack.append(action)
    }
    
    func redo() {
        guard let model, let action = redoStack.popLast() else { return }
        
        action.apply(on: model)
        undoStack.append(action)
    }
    
    // MARK: - Batching
    
    func beginBatch() {
        guard !isBatching else { return }
        isBatching = true
        currentBatch = []
    }
    
    func endBatch() {
        guard let model, isBatching else { return }
        
        isBatching = false
        
        guard !currentBatch.isEmpty else { return }
        
        let composite = CompositeAction(actions: currentBatch)
        
        undoStack.append(composite)
        redoStack.removeAll()
        
        trimStackIfNeeded()
        
        // один save после всей пачки
        model.save()
        
        currentBatch = []
    }
    
    func cancelBatch() {
        guard let model, isBatching else { return }
        
        // откат применённых действий
        for action in currentBatch.reversed() {
            action.undo(on: model)
        }
        
        currentBatch = []
        isBatching = false
    }
    
    // MARK: - Helpers
    
    private func trimStackIfNeeded() {
        if undoStack.count > maxStackSize {
            undoStack.removeFirst(undoStack.count - maxStackSize)
        }
    }
    
    // MARK: - Debug
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
}
