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
    @Environment(AppModel.self) private var appModel
    
    var isSelected: Bool {
        appModel.selectedNodeId == tree.node.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            HStack(spacing: 8) {
                
                if !tree.children.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .foregroundStyle(Color(isSelected ? .accent : .label))
                    .buttonStyle(.plain)
                } else {
                    Spacer().frame(width: 16)
                }
                
                Text(tree.node.name)
                    .foregroundStyle(Color(isSelected ? .accent : .label))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appModel.selectedNodeId = tree.node.id
                        appModel.centerOnNodeId = tree.node.id
                    }
            }
            .padding(.vertical, 8)
            
            if isExpanded {
                ForEach(tree.children) { child in
                    NodeTreeView(tree: child)
                        .padding(.leading, 16)
                        .environment(appModel)
                }
            }
        }
    }
}
