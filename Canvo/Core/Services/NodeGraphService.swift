//
//  NodeGraphService.swift
//  Canvo
//
//  Created by Олег Комаристый on 09.06.2026.
//


import Foundation

final class NodeGraphService {

    func hasConnection(
        nodeId: String,
        connections: [NodeConnection]
    ) -> Bool {
        connections.contains {
            $0.fromNodeId == nodeId ||
            $0.toNodeId == nodeId
        }
    }

    func connectedNodes(
        for node: Node,
        nodesById: [String: Node],
        connections: [NodeConnection]
    ) -> [Node] {

        let relatedConnections = connections.filter {
            $0.fromNodeId == node.id ||
            $0.toNodeId == node.id
        }

        return relatedConnections.compactMap { connection in
            let otherId =
                connection.fromNodeId == node.id
                ? connection.toNodeId
                : connection.fromNodeId

            return nodesById[otherId]
        }
    }

    func visibleNodes(
        nodes: [Node],
        selectedTags: Set<Tag>
    ) -> [Node] {
        
        print("visibleNodes recalculated")

        guard !selectedTags.isEmpty else {
            return nodes
        }

        let selectedNames = Set(
            selectedTags.map(\.name)
        )

        return nodes.filter { node in
            let tags = Set(
                (node.tagsRaw ?? "").parseTags()
            )

            return !tags.isDisjoint(with: selectedNames)
        }
    }

    func visibleConnections(
        nodes: [Node],
        connections: [NodeConnection],
        selectedTags: Set<Tag>
    ) -> [NodeConnection] {
        
        print("visibleConnections recalculated")

        let visibleNodes = visibleNodes(
            nodes: nodes,
            selectedTags: selectedTags
        )

        let visibleIds = Set(
            visibleNodes.map(\.id)
        )

        return connections.filter {
            visibleIds.contains($0.fromNodeId) &&
            visibleIds.contains($0.toNodeId)
        }
    }
}
