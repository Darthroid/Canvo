//
//  GraphState.swift
//  Canvo
//
//  Created by Олег Комаристый on 24.06.2026.
//


import Foundation

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct GraphState {

    let nodes: [NodeSchema]
    let connections: [NodeConnectionSchema]

    /// Structural + semantic grouping of the graph
    let clusters: [GraphCluster]

    /// Optional derived metrics for future prompt conditioning
    let metrics: GraphMetrics
}