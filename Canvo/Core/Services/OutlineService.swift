//
//  OutlineService.swift
//  Canvo
//
//  Created by Олег Комаристый on 06.06.2026.
//

import Foundation

final class OutlineService {

    func buildOutline(
        nodes: [Node],
        connections: [NodeConnection]
    ) -> [NodeTree] {

        let nodeDict = Dictionary(
            uniqueKeysWithValues: nodes.map { ($0.id, $0) }
        )

        let childrenMap = buildChildrenMap(
            connections: connections
        )

        var roots = findRootNodes(
            nodes: nodes,
            connections: connections
        )

        if roots.isEmpty, let first = nodes.first {
            roots = [first]
        }

        return roots.map {
            buildTree(
                node: $0,
                nodeDict: nodeDict,
                childrenMap: childrenMap
            )
        }
    }

    // MARK: - Private

    private func buildChildrenMap(
        connections: [NodeConnection]
    ) -> [String: [String]] {

        var map: [String: [String]] = [:]

        for connection in connections {
            map[connection.fromNodeId, default: []]
                .append(connection.toNodeId)
        }

        return map
    }

    private func findRootNodes(
        nodes: [Node],
        connections: [NodeConnection]
    ) -> [Node] {

        let allToIds = Set(
            connections.map(\.toNodeId)
        )

        return nodes.filter {
            !allToIds.contains($0.id)
        }
    }

    private func buildTree(
        node: Node,
        nodeDict: [String: Node],
        childrenMap: [String: [String]],
        visited: Set<String> = []
    ) -> NodeTree {

        if visited.contains(node.id) {
            return NodeTree(
                id: node.id,
                node: node,
                children: []
            )
        }

        let newVisited = visited.union([node.id])

        let children = (childrenMap[node.id] ?? [])
            .compactMap { childId -> NodeTree? in

                guard let childNode = nodeDict[childId] else {
                    return nil
                }

                return buildTree(
                    node: childNode,
                    nodeDict: nodeDict,
                    childrenMap: childrenMap,
                    visited: newVisited
                )
            }

        return NodeTree(
            id: node.id,
            node: node,
            children: children
        )
    }
}
