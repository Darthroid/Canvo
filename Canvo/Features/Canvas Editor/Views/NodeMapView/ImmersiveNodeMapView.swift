//
//  ImmersiveNodeMapView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI
import RealityKit
import RealityKitContent
import SwiftData

struct ImmersiveNodeMapView: View {
    struct ConnectionVisualComponent: Component {
        var cylinder: ModelEntity
    }
    
    struct PinchComponent: Component {
        // Empty.
    }
    
    final class NodeLayoutCache {
        var sizes: [String: CGSize] = [:]
    }
    
    final class SceneCache {

        var nodeEntities: [String: Entity] = [:]

        var connectionEntities: [String: ModelEntity] = [:]
    }
    
    @Environment(AppModel.self) var appModel
    @EnvironmentObject var themeStore: ThemeStore
    
    @State private var draggedEntity: Entity?
    @State private var sceneCache = SceneCache()
    @State private var layoutCache = NodeLayoutCache()
    @State private var realityViewContent: RealityViewContent?
    
    @State private var dragStartPositions: [String: SIMD3<Float>] = [:]
    @State private var draggedNodeIds: Set<String> = []
    
    @State var magnification: CGFloat = 1.0
    
    @State var hasPinchIn = false
    @State var hasPinchOut = false
    
    private let uiToWorldScale: Float = 0.0012
    
    var body: some View {
        RealityView { content, attachments in
            realityViewContent = content

            updateEntities(
                in: content,
                attachments: attachments
            )

            updateConnections(in: content)
//            setupPinchArea()
        } update: { content, attachments in

            updateEntities(
                in: content,
                attachments: attachments
            )

            updateConnections(in: content)

        } attachments: {

            ForEach(appModel.visibleNodes) { node in
                Attachment(id: node.id) {
                    let isFocused = !appModel.session.focusNodeIds.isEmpty
                    NodeView(
                        node: node,
                        isSelected: appModel.session.selectedNodeIds.contains(node.id),
                        isExpanded: appModel.session.expandedNodeIds.contains(node.id),
                        isMatchingSearch: false,
                        toolbarEnabled: true,
                        onSizeChange: { size in
                            layoutCache.sizes[node.id] = size
                            DispatchQueue.main.async {
                                updateCollision(for: node.id, size: size)
                            }
                        },
                        onDetail: {
                            NotificationCenter.default.post(
                                name: .pinchOutWithNode,
                                object: nil,
                                userInfo: ["node": node]
                            )
                        },
                        onLink: {
                            NotificationCenter.default.post(
                                name: .linkWithNode,
                                object: nil,
                                userInfo: ["node": node]
                            )
                        },
                        onDelete: {
                            appModel.removeNode(node)
                        }
                    )
                    .frame(maxWidth: 400)
                    .opacity(!isFocused ? 1 : (appModel.session.focusNodeIds.contains(node.id) ? 1 : 0.1))
                }
            }
        }
        .gesture(selectiveDragGesture)
        .gesture(tapGesture)
        .gesture(doubleTapGesture)
        .gesture(pinchGesture())
        .onChange(of: appModel.connections) { oldValue, newValue in
            guard let content = realityViewContent else { return }
            updateConnections(in: content)
        }
    }
    
    // MARK: - Gestures
    
    private var selectiveDragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .targetedToAnyEntity()
            .onChanged { value in
                guard let nodeComponent = value.entity.components[NodeDataComponent.self]
                else { return }

                let draggedNodeId = nodeComponent.node.id

                // Какие ноды двигаем
                let isDraggedNodeSelected =
                appModel.session.selectedNodeIds.contains(draggedNodeId)

                let movingIds: Set<String> = isDraggedNodeSelected
                    ? appModel.session.selectedNodeIds
                    : [draggedNodeId]

                // Если тащим невыделенную ноду — выделяем только её
                if !isDraggedNodeSelected {
                    appModel.session.selectedNodeIds = [draggedNodeId]
                }

                // Начало drag
                if draggedEntity == nil {
                    draggedEntity = value.entity

                    // Запоминаем стартовые позиции
                    for id in movingIds {
                        if dragStartPositions[id] == nil,
                           let node = appModel.node(forId: id) {
                            dragStartPositions[id] = node.position
                        }
                    }

                    draggedNodeIds.formUnion(movingIds)
                }

                // translation RealityKit -> canvas
                let movementScene = value.convert(
                    value.gestureValue.translation3D,
                    from: .local,
                    to: .scene
                )

                let scaleFactor: Float = 0.001

                let dx = movementScene.x / scaleFactor
                let dy = -movementScene.y / scaleFactor
                let dz = movementScene.z / scaleFactor
                // Двигаем все выбранные ноды
                for id in movingIds {
                    guard let start = dragStartPositions[id],
                          let node = appModel.node(forId: id)
                    else { continue }

                    let newPosition = SIMD3<Float>(
                        start.x + dx,
                        start.y + dy,
                        start.z + dz
                    )

                    // Только визуальный update
                    node.x = newPosition.x
                    node.y = newPosition.y
                    node.z = newPosition.z

                    // Обновляем entity
                    if let entity = sceneCache.nodeEntities[id] {
                        entity.position = GeometryService.visionOSPosition(node.position)
                    }

                    updateConnectionsForNode(nodeId: id)
                }
            }
            .onEnded { _ in


                // Batch action как в NodeMapView
                var nodeIds: [String] = []
                var oldPositions: [SIMD3<Float>] = []
                var newPositions: [SIMD3<Float>] = []

                for id in draggedNodeIds {
                    guard let start = dragStartPositions[id],
                          let node = appModel.node(forId: id)
                    else { continue }

                    let end = node.position

                    if start != end {
                        nodeIds.append(id)
                        oldPositions.append(start)
                        newPositions.append(end)
                    }
                }

                if !nodeIds.isEmpty {
                    appModel.moveNodes(
                        ids: nodeIds,
                        oldPositions: oldPositions,
                        newPositions: newPositions
                    )
                }

                // cleanup
                dragStartPositions.removeAll()
                draggedNodeIds.removeAll()
                draggedEntity = nil
            }
    }
    
    private var tapGesture: some Gesture {
        SpatialTapGesture(count: 1)
            .targetedToAnyEntity()
            .onEnded { value in
                
                guard let nodeComponent =
                        value.entity.components[NodeDataComponent.self]
                else { return }
                
                let nodeId = nodeComponent.node.id
                
                if appModel.session.selectedNodeIds.contains(nodeId) {
                    appModel.session.selectedNodeIds.remove(nodeId)
                } else {
                    appModel.session.selectedNodeIds.insert(nodeId)
                }
            }
    }
    
    private var doubleTapGesture: some Gesture {
        SpatialTapGesture(count: 2)
            .targetedToAnyEntity()
            .onEnded { value in
                
                guard let nodeComponent =
                        value.entity.components[NodeDataComponent.self]
                else { return }
                
                let nodeId = nodeComponent.node.id
                
                if appModel.session.expandedNodeIds.contains(nodeId) {
                    appModel.session.expandedNodeIds.remove(nodeId)
                } else {
                    appModel.session
                        .expandedNodeIds.insert(nodeId)
                }
            }
    }
    
    func pinchGesture() -> some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                                
                guard value.entity.components[PinchComponent.self] != nil, let node = value.entity.components[NodeDataComponent.self]?.node else {
                    return
                }
                
                let pinchInMagnification: CGFloat = 0.8
                let pinchOutMagnification: CGFloat = 1.2
                
                if !hasPinchIn && value.magnification <= pinchInMagnification {
                    hasPinchIn = true
                    
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: .pinchInWithNode,
                            object: nil,
                            userInfo: ["node": node]
                        )
                    }
                }
                
                if !hasPinchOut && value.magnification >= pinchOutMagnification {
                    hasPinchOut = true
                    
                    NotificationCenter.default.post(
                        name: .pinchOutWithNode,
                        object: nil,
                        userInfo: ["node": node]
                    )
                }
                
                magnification = value.magnification
            }
            .onEnded { _ in
                magnification = 1.0
                
                hasPinchIn = false
                hasPinchOut = false
            }
    }
    
// MARK: - Drawing connections

    private func updateEntities(
        in content: RealityViewContent,
        attachments: RealityViewAttachments
    ) {

        let currentNodeIds = Set(appModel.nodes.map(\.id))
        let existingNodeIds = Set(sceneCache.nodeEntities.keys)

        let removedIds = existingNodeIds.subtracting(currentNodeIds)

        for id in removedIds {
            if let entity = sceneCache.nodeEntities[id] {
                entity.removeFromParent()
                sceneCache.nodeEntities.removeValue(forKey: id)
            }
        }

        for node in appModel.nodes {

            let position = GeometryService.visionOSPosition(node.position)

            if let entity = sceneCache.nodeEntities[node.id] {

                entity.position = position

            } else {

                guard let attachment =
                        attachments.entity(for: node.id)
                else { continue }

                let root = Entity()

                root.position = position

                attachment.position = .zero

                attachment.components.set(
                    BillboardComponent()
                )

                root.addChild(attachment)

                root.components.set(
                    InputTargetComponent()
                )

                root.components.set(
                    HoverEffectComponent()
                )

                root.components.set(
                    PinchComponent()
                )

                root.components.set(
                    NodeDataComponent(node: node)
                )

                sceneCache.nodeEntities[node.id] = root

                content.add(root)
            }
        }
    }
    
    private func updateConnections(in content: RealityViewContent) {
        let currentConnectionIds = Set(appModel.connections.map { $0.id })
        let existingConnectionIds = Set(sceneCache.connectionEntities.keys)
        
        // Remove old connections
        let removedConnectionIds = existingConnectionIds.subtracting(currentConnectionIds)
        for id in removedConnectionIds {
            if let entity = sceneCache.connectionEntities[id] {
                entity.removeFromParent()
                sceneCache.connectionEntities.removeValue(forKey: id)
            }
        }
        
        for connection in appModel.connections {
            guard let fromNode = appModel.nodes.first(where: { $0.id == connection.fromNodeId }),
                  let toNode = appModel.nodes.first(where: { $0.id == connection.toNodeId }) else { continue }
            
            if let existingConnection = sceneCache.connectionEntities[connection.id] {

                guard
                    let fromEntity = sceneCache.nodeEntities[connection.fromNodeId],
                    let toEntity = sceneCache.nodeEntities[connection.toNodeId]
                else { continue }

                updateConnectionEntity(
                    existingConnection,
                    startPosition: fromEntity.position(relativeTo: nil),
                    endPosition: toEntity.position(relativeTo: nil)
                )
            } else {
                // Create new connection
                let connectionEntity = createConnectionEntity(from: fromNode, to: toNode, for: connection)
                sceneCache.connectionEntities[connection.id] = connectionEntity
                content.add(connectionEntity)
                print("ADD CONNECTION", connection.id)
            }
        }
    }
    
    private func createConnectionEntity(
        from fromNode: Node,
        to toNode: Node,
        for connection: NodeConnection
    ) -> ModelEntity {

        print("CREATE CONNECTION", connection.id)
        
        let connectionEntity = ModelEntity()

        let cylinderMesh = MeshResource.generateCylinder(
            height: 1.0,
            radius: 0.001
        )

        let material = SimpleMaterial(
            color: .darkGray.withAlphaComponent(0.5),
            roughness: .float(0.8),
            isMetallic: false
        )

        let cylinder = ModelEntity(
            mesh: cylinderMesh,
            materials: [material]
        )

        connectionEntity.addChild(cylinder)

        connectionEntity.components.set(
            ConnectionDataComponent(connection: connection)
        )

        connectionEntity.components.set(
            ConnectionVisualComponent(cylinder: cylinder)
        )

        updateConnectionEntity(
            connectionEntity,
            startPosition: GeometryService.visionOSPosition(fromNode.position),
            endPosition: GeometryService.visionOSPosition(toNode.position)
        )

        return connectionEntity
    }
    
    private func updateConnectionEntity(
        _ connectionEntity: ModelEntity,
        startPosition: SIMD3<Float>,
        endPosition: SIMD3<Float>
    ) {

        guard let visual =
            connectionEntity.components[
                ConnectionVisualComponent.self
            ]
        else {
            return
        }

        let cylinder = visual.cylinder

        let vector = endPosition - startPosition
        let distance = length(vector)

        guard distance > 0.001 else {
            cylinder.isEnabled = false
            return
        }

        cylinder.isEnabled = true

        let direction = normalize(vector)

        connectionEntity.position =
            (startPosition + endPosition) / 2

        let yAxis = SIMD3<Float>(0, 1, 0)

        let dotValue = dot(yAxis, direction)

        if abs(dotValue) > 0.999 {

            connectionEntity.orientation =
                simd_quatf(
                    angle: dotValue > 0 ? 0 : .pi,
                    axis: [1, 0, 0]
                )

        } else {

            let axis = normalize(
                cross(yAxis, direction)
            )

            let angle = acos(dotValue)

            connectionEntity.orientation =
                simd_quatf(
                    angle: angle,
                    axis: axis
                )
        }

        cylinder.scale =
            SIMD3<Float>(
                1,
                distance,
                1
            )
    }
    
    private func updateConnectionsForNode(nodeId: String) {

        let relevantConnections = appModel.connections.filter {
            $0.fromNodeId == nodeId ||
            $0.toNodeId == nodeId
        }

        for connection in relevantConnections {

            guard
                let connectionEntity = sceneCache.connectionEntities[connection.id],
                let fromEntity = sceneCache.nodeEntities[connection.fromNodeId],
                let toEntity = sceneCache.nodeEntities[connection.toNodeId]
            else {
                continue
            }

            let startPosition = fromEntity.position(relativeTo: nil)
            let endPosition = toEntity.position(relativeTo: nil)

            updateConnectionEntity(
                connectionEntity,
                startPosition: startPosition,
                endPosition: endPosition
            )
        }
    }
    
    // MARK: - Drawing nodes
    
    private func updateCollision(for id: String, size: CGSize) {

        guard let entity = sceneCache.nodeEntities[id] else { return }

        let width = Float(size.width) * uiToWorldScale
        let height = Float(size.height) * uiToWorldScale

        let shape = ShapeResource.generateBox(
            width: width,
            height: height * 0.75,
            depth: 0.02
        )
        .offsetBy(
            translation: [0, height * 0.1, 0]
        )

        entity.components.set(
            CollisionComponent(
                shapes: [shape]
            )
        )
    }
}
