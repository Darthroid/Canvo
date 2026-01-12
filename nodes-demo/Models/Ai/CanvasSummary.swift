//
//  CanvasSummary.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 10.01.2026.
//

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct CanvasSummary {
    let mainIdea: String?
    let clusters: [String]
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct CanvasChunk {
    let nodeIds: Set<String>
    let nodes: [NodeSchema]
    let connections: [NodeConnectionSchema]
}
