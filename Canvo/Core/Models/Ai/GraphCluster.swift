//
//  GraphCluster.swift
//  Canvo
//
//  Created by Олег Комаристый on 24.06.2026.
//


struct GraphCluster {

    let name: String

    /// semantic keywords representing cluster meaning
    let keywords: [String]

    /// nodes belonging to this cluster
    let nodes: [NodeSchema]
}