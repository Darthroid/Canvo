@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct GraphStateBuilder {

    static func build(
        nodes: [NodeSchema],
        connections: [NodeConnectionSchema]
    ) -> GraphState {

        let clusters = buildClusters(
            from: nodes,
            connections: connections
        )

        let metrics = buildMetrics(
            nodes: nodes,
            connections: connections,
            clusterCount: clusters.count
        )

        return GraphState(
            nodes: nodes,
            connections: connections,
            clusters: clusters,
            metrics: metrics
        )
    }

    // MARK: - Metrics

    private static func buildMetrics(
        nodes: [NodeSchema],
        connections: [NodeConnectionSchema],
        clusterCount: Int
    ) -> GraphMetrics {

        let nodeCount = nodes.count
        let connectionCount = connections.count

        let density: Double = nodeCount > 0
            ? Double(connectionCount) / Double(nodeCount)
            : 0

        let averageDegree: Double = nodeCount > 0
            ? (Double(connectionCount) * 2.0) / Double(nodeCount)
            : 0

        return GraphMetrics(
            nodeCount: nodeCount,
            connectionCount: connectionCount,
            averageDegree: averageDegree,
            clusterCount: clusterCount,
            density: density
        )
    }

    // MARK: - Clusters

    private static func buildClusters(
        from nodes: [NodeSchema],
        connections: [NodeConnectionSchema]
    ) -> [GraphCluster] {

        guard !nodes.isEmpty else {
            return []
        }

        let nodeLookup = Dictionary(
            uniqueKeysWithValues: nodes.map { ($0.id, $0) }
        )

        var adjacency: [String: Set<String>] = [:]

        for connection in connections {
            adjacency[connection.fromNodeId, default: []]
                .insert(connection.toNodeId)

            adjacency[connection.toNodeId, default: []]
                .insert(connection.fromNodeId)
        }

        var visited = Set<String>()
        var clusters: [GraphCluster] = []

        for node in nodes {

            guard !visited.contains(node.id) else {
                continue
            }

            var queue: [String] = [node.id]
            var clusterNodes: [NodeSchema] = []

            while !queue.isEmpty {

                let currentId = queue.removeFirst()

                guard !visited.contains(currentId) else {
                    continue
                }

                visited.insert(currentId)

                guard let currentNode = nodeLookup[currentId] else {
                    continue
                }

                clusterNodes.append(currentNode)

                let neighbors = adjacency[currentId] ?? []

                for neighborId in neighbors where !visited.contains(neighborId) {
                    queue.append(neighborId)
                }
            }

            let keywords = extractKeywords(from: clusterNodes)

            let cluster = GraphCluster(
                name: clusterName(from: clusterNodes),
                keywords: keywords,
                nodes: clusterNodes
            )

            clusters.append(cluster)
        }

        return clusters
    }

    // MARK: - Helpers

    private static func clusterName(
        from nodes: [NodeSchema]
    ) -> String {

        nodes
            .map(\.name)
            .min(by: { $0.count < $1.count })
            ?? "Cluster"
    }

    private static func extractKeywords(
        from nodes: [NodeSchema]
    ) -> [String] {

        let stopWords: Set<String> = [
            "the", "a", "an", "of", "to", "and",
            "in", "on", "for", "with", "is"
        ]

        var keywords: [String] = []

        for node in nodes {

            let words = node.name
                .lowercased()
                .split(separator: " ")
                .map(String.init)
                .filter { !stopWords.contains($0) }

            keywords.append(contentsOf: words)
        }

        let uniqueKeywords = Array(Set(keywords)).sorted()

        return Array(uniqueKeywords.prefix(8))
    }
}
