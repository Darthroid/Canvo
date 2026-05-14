//
//  AppModel+AI.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//


import Foundation

// MARK: - Generate Canvas from AI
extension AppModel {
    func generateCanvasStream(prompt: String) {
        Task {
            do {
                var finalCanvas: Canvas?
                for try await schema in AIGenerationService.shared.generateCanvasStream(prompt: prompt) {
                    let canvas = Canvas(from: schema)
                    finalCanvas = canvas
                }
                
                if let canvas = finalCanvas {
                    addCanvasFromAIAction(canvas)
                }
            } catch {
                print("error while generating canvas: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Edit Canvas with AI

extension AppModel {
    
    func generateNodes(selectedScope: AIScope, userPrompt: String) {
        Task {
            guard let canvas = currentCanvas else { return }
            
            var scope: [Node] = []
            
            switch selectedScope {
            case .selection:
                scope = selectedNodeIds.compactMap {
                    node(forId: $0)
                }
            case .visible:
                break
            case .canvas:
                scope = nodes
            }
            
            do {
                var nodes: [Node] = []
                var connections: [NodeConnection] = []
                for single in scope {
                    for try await schema in AIGenerationService.shared.extendNodes(nodes: [single], in: canvas, userInput: userPrompt) {
                        nodes += schema.0
                            .map { Node(from: $0) }
                        
                        connections += schema.1
                            .map { NodeConnection(from: $0) }
                    }
                }
                
                addNodesFromAIAction(Array(nodes), connections: Array(connections))

            } catch {
                print("error while generating canvas: \(error.localizedDescription)")
            }
        }
    }

    func summarizeNodes() {
//        Task {
//            await fakeRequest()
//
//            // TODO:
//            // summarize nodes
//        }
    }

}
