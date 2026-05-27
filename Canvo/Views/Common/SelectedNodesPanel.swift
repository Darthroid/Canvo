//
//  SelectedNodesPanel.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import SwiftUI

struct SelectedNodesPanel: View {
    @Environment(AppModel.self) private var appModel
    
    var onDelete: () -> Void
    var onAiEdit: () -> Void
    var onDuplicate: () -> Void
    
    
    var body: some View {
        HStack(spacing: 24) {
            Text(String(format: appModel.selectedNodeIds.count > 1 ? "%d items" : "%d item", appModel.selectedNodeIds.count))
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .labelsHidden()
            
            Button {
                onAiEdit()
            } label: {
                Image(systemName: "sparkles")
            }
            .buttonStyle(.plain)
            .labelsHidden()
            
            Menu {
                Button {
                    appModel.nodes
                        .map(\.id)
                        .forEach { appModel.selectedNodeIds.insert($0) }
                } label: {
                    Text("Select All")
                }
                
                Button {
                    onDuplicate()
                } label: {
                    Text("Duplicate")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .buttonStyle(.plain)
            .labelsHidden()
            
            Button {
                withAnimation {
                    appModel.selectedNodeIds.removeAll()
                }
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical)
        #if !os(visionOS)
        .glassEffect()
        #else
        .glassBackgroundEffect()
        #endif

    }
}
