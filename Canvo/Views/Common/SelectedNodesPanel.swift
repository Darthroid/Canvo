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
            
            panelButton(systemImage: "trash") {
                onDelete()
            }
            
            panelButton(systemImage: "sparkles") {
                onAiEdit()
            }
            
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
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            #if os(visionOS)
            .clipShape(Circle())
            #endif
            
            panelButton(systemImage: "xmark") {
                withAnimation {
                    appModel.selectedNodeIds.removeAll()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical)
        #if !os(visionOS)
        .glassEffect()
        #else
        .glassBackgroundEffect()
        #endif

    }
    
    @ViewBuilder
    private func panelButton(
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 36, height: 36)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .labelsHidden()
        #if os(visionOS)
        .clipShape(Circle())
        #endif
    }
}
