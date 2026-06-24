//
//  GraphMetrics.swift
//  Canvo
//
//  Created by Олег Комаристый on 24.06.2026.
//


struct GraphMetrics {

    /// total nodes in graph
    let nodeCount: Int

    /// total connections
    let connectionCount: Int

    /// average branching factor (how “wide” graph is)
    let averageDegree: Double

    /// how fragmented graph is (number of clusters)
    let clusterCount: Int

    /// density = connections / nodes
    let density: Double
}