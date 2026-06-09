//
//  NodeTree.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 15.04.2026.
//


struct NodeTree: Identifiable {
    let id: String
    let node: Node
    var children: [NodeTree]
}
