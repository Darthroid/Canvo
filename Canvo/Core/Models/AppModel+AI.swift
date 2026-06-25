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
                    addCanvasFromAI(canvas)
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
            guard let canvas = session.currentCanvas else { return }
            
            var scope: [Node] = []
            
            switch selectedScope {
            case .selection:
                scope = session.selectedNodeIds.compactMap {
                    node(forId: $0)
                }
            case .canvas:
                scope = nodes
            }
            
            do {
                var nodes: [Node] = []
                var connections: [NodeConnection] = []
                for single in scope {
                    for try await schema in aiGenerationService
                        .extendGraph(nodes: [single], in: canvas, userInput: userPrompt) {
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
            guard let canvas = session.currentCanvas else { return }
            
            let scope: [Node] = session.selectedNodeIds.compactMap {
                node(forId: $0)
            }
            
            do {
                var summary: NodeSchema?
                let exclude = Array(Set(scope.flatMap { nodesConnectedWith(node: $0) }))
                let stream = aiGenerationService.summarizeGraph(scope: scope, exclude: exclude, in: canvas, userInput: userPrompt)
                
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
                
                
                let nodeSnapshot = SnapshotFactory.node(
                    id: summary.id,
                    name: summary.name,
                    detail: summary.detail,
                    position: scope.first?.position ?? summary.position.toSIMD3(),
                    color: summary.color,
                    tagsRaw: "",
                    images: []
                )
                
                let connectionsSnapshots = newConnections.map {
                    SnapshotFactory.connection(from: $0)
                }
                
                let addNodeAction = AddNodeAction(canvas: canvas, node: nodeSnapshot)
                let addConnectionsAction = connectionsSnapshots.map {
                    AddConnectionAction(connection: $0, canvas: canvas)
                }
                
                actionService.perform(addNodeAction)
                
                for action in addConnectionsAction {
                    actionService.perform(action)
                }
                
                actionService.endBatch()
                session.clearSelection()
                session.selectedNodeIds.insert(summary.id)

            } catch {
                print("error while generating canvas: \(error.localizedDescription)")
            }
        }
    }

}
