//
//  CanvasLayoutService.swift
//  Canvo
//
//  Created by Олег Комаристый on 26.06.2026.
//

import Foundation

struct CanvasLayoutService {

    func computeCentroid(_ positions: [Position3DSchema]) -> Position3DSchema {
        guard !positions.isEmpty else {
            return .init(x: 0, y: 0, z: 0)
        }

        let sum = positions.reduce((x: Float(0), y: Float(0), z: Float(0))) {
            ($0.x + $1.x, $0.y + $1.y, $0.z + $1.z)
        }

        return .init(
            x: sum.x / Float(positions.count),
            y: sum.y / Float(positions.count),
            z: sum.z / Float(positions.count)
        )
    }

    func layoutNodesInCircle(
        nodes: inout [NodeSchema],
        centerNodeId: String,
        radius: Float = 300
    ) {
        guard let centerIndex = nodes.firstIndex(where: { $0.id == centerNodeId }) else {
            return
        }

        nodes[centerIndex].position = .init(x: 0, y: 0, z: 0)

        let others = nodes.indices.filter { $0 != centerIndex }
        let count = others.count

        guard count > 0 else {
            return
        }

        for (i, index) in others.enumerated() {
            let angle = (2 * Float.pi * Float(i)) / Float(count)

            nodes[index].position = .init(
                x: radius * cos(angle),
                y: radius * sin(angle),
                z: 0
            )
        }
    }

    func layoutWithCollisionAvoidance(
        nodes: inout [NodeSchema],
        center: Position3DSchema,
        allNodes: [NodeSchema],
        radius: Float = 220
    ) {
        guard !nodes.isEmpty else {
            return
        }

        let direction = findBestExpansionDirection(
            from: center,
            occupied: allNodes
        )

        let clusterCenter = findBestPositionInField(
            preferredDirection: direction,
            origin: center,
            allNodes: allNodes,
            radiusStart: radius
        )

        let baseAngle = atan2(direction.y, direction.x)
        let spread: Float = .pi / 3

        var occupied = allNodes

        for index in nodes.indices {

            let angleOffset: Float

            if nodes.count == 1 {
                angleOffset = 0
            } else {
                let t = Float(index) / Float(nodes.count - 1)
                angleOffset = -spread / 2 + spread * t
            }

            let candidate = Position3DSchema(
                x: clusterCenter.x + cos(baseAngle + angleOffset) * 90,
                y: clusterCenter.y + sin(baseAngle + angleOffset) * 140,
                z: center.z
            )

            nodes[index].position = candidate
            occupied.append(nodes[index])
        }
    }

    func findBestExpansionDirection(
        from center: Position3DSchema,
        occupied: [NodeSchema]
    ) -> SIMD2<Float> {

        guard !occupied.isEmpty else {
            return SIMD2<Float>(0, 1)
        }

        let nearbyNodes = occupied.filter {

            let dx = $0.position.x - center.x
            let dy = $0.position.y - center.y

            let distanceSquared = dx * dx + dy * dy

            return distanceSquared < 900 * 900
        }

        guard !nearbyNodes.isEmpty else {
            return SIMD2<Float>(0, 1)
        }

        let sectors = 24

        var bestDirection = SIMD2<Float>(0, 1)
        var bestScore = -Float.infinity

        for sector in 0..<sectors {

            let angle = (Float(sector) / Float(sectors)) * (.pi * 2)

            let direction = SIMD2<Float>(
                cos(angle),
                sin(angle)
            )

            var score: Float = 0

            for node in nearbyNodes {

                let dx = node.position.x - center.x
                let dy = node.position.y - center.y

                let distance = sqrt(dx * dx + dy * dy)

                guard distance > 1 else {
                    continue
                }

                let normalized = SIMD2<Float>(
                    dx / distance,
                    dy / distance
                )

                let alignment =
                    normalized.x * direction.x +
                    normalized.y * direction.y

                if alignment > 0 {
                    score -= alignment * (1_000 / max(distance, 100))
                }
            }

            if score > bestScore {
                bestScore = score
                bestDirection = direction
            }
        }

        return bestDirection
    }

    func findBestPositionInField(
        preferredDirection: SIMD2<Float>,
        origin: Position3DSchema,
        allNodes: [NodeSchema],
        radiusStart: Float = 220
    ) -> Position3DSchema {

        let baseAngle = atan2(
            preferredDirection.y,
            preferredDirection.x
        )

        for radius in stride(
            from: radiusStart,
            through: radiusStart + 1200,
            by: 25
        ) {

            for offset in stride(
                from: -Float.pi / 2,
                through: Float.pi / 2,
                by: Float.pi / 24
            ) {

                let angle = baseAngle + offset

                let candidate = Position3DSchema(
                    x: origin.x + cos(angle) * radius,
                    y: origin.y + sin(angle) * radius,
                    z: origin.z
                )

                let testNode = NodeSchema(
                    id: UUID().uuidString,
                    name: "",
                    detail: "",
                    position: candidate
                )

                let collision = allNodes.contains {
                    isOverlapping(testNode, $0)
                }

                if !collision {
                    return candidate
                }
            }
        }

        return .init(
            x: origin.x + preferredDirection.x * radiusStart,
            y: origin.y + preferredDirection.y * radiusStart,
            z: origin.z
        )
    }

    private func isOverlapping(
        _ a: NodeSchema,
        _ b: NodeSchema
    ) -> Bool {

        let dx = abs(a.position.x - b.position.x)
        let dy = abs(a.position.y - b.position.y)

        return dx < 420 && dy < 180
    }
}
