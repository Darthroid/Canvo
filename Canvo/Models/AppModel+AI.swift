//
//  AppModel+AI.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//


import Foundation

// MARK: - Generate Canvas from AI
extension AppModel {
    func generateCanvasStream(prompt: String, style: CanvasGenerationStyle = .tree) {
        Task {
            do {
                var finalCanvas: Canvas?
                for try await schema in aiGenerationService.generateCanvasStream(
                    prompt: prompt,
                    style: style
                ) {
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
                    for try await schema in aiGenerationService.extendNodes(nodes: [single], in: canvas, userInput: userPrompt) {
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

    func summarizeNodes(userPrompt: String) {
        Task {
            guard let canvas = currentCanvas else { return }
            
            let scope: [Node] = selectedNodeIds.compactMap {
                node(forId: $0)
            }
            
            do {
                var summary: NodeSchema?
                let exclude = Array(Set(scope.flatMap { nodesConnectedWith(node: $0) }))
                let stream = try await aiGenerationService.summarize(exclude: exclude, scope: scope, userInput: userPrompt, in: canvas)
                
                for try await chunk in stream {
                    summary = chunk
                }
                
                guard let summary else { return }
                
                // connect new summary node with related nodes
                let connectedNodes = Set(scope.flatMap { self.nodesConnectedWith(node: $0) })
                
                let newConnections = connectedNodes.map {
                    NodeConnection(fromNodeId: $0.id, toNodeId: summary.id)
                }
              
                // delete current scope to replace with summarized
                actionService.beginBatch()
                for node in scope {
                    removeNode(node)
                }
                
                let nodeSnapshot = NodeSnapshot(
                    id: summary.id,
                    name: summary.name,
                    detail: summary.detail,
                    detailRichText: nil,
                    x: scope.first?.x ?? summary.position.x,
                    y: scope.first?.y ?? summary.position.y,
                    z: scope.first?.z ?? summary.position.z,
                    color: summary.color,
                    tagsRaw: nil
                )
                
                let connectionsSnapshots = newConnections.map {
                    ConnectionSnapshot(id: $0.id, fromNodeId: $0.fromNodeId, toNodeId: $0.toNodeId)
                }
                
                let addNodeAction = AddNodeAction(node: nodeSnapshot)
                let addConnectionsAction = connectionsSnapshots.map {
                    AddConnectionAction(connection: $0)
                }
                
                actionService.perform(addNodeAction)
                
                for action in addConnectionsAction {
                    actionService.perform(action)
                }
                
                actionService.endBatch()
                selectedNodeIds.removeAll()

            } catch {
                print("error while generating canvas: \(error.localizedDescription)")
            }
        }
    }

}
