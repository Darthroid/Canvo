//
//  NodeTreeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 15.04.2026.
//
import SwiftUI

struct NodeTreeView: View {
    let tree: NodeTree
    
    @State private var isExpanded = true
    
    var body: some View {
        if tree.children.isEmpty {
            Text(tree.node.name)
        } else {
            DisclosureGroup(tree.node.name, isExpanded: $isExpanded) {
                ForEach(tree.children) { child in
                    NodeTreeView(tree: child)
                }
            }
        }
    }
}
