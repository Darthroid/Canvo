//
//  SelectedNodesPanel.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import SwiftUI

struct SelectedNodesPanel: View {
    @Environment(AppModel.self) private var appModel
    
    var isDemo: Bool = false
    var onDelete: () -> Void
    var onAiEdit: () -> Void
    var onDuplicate: () -> Void
    
    
    var body: some View {
        HStack(spacing: 24) {
            if isDemo { // used for onboarding screen
                Text(String(format: String(localized: "%d items"), 3))
            } else {
                Text(String(format: appModel.session.selectedNodeIds.count > 1 ? String(localized: "%d items") : String(localized: "%d item"), appModel.session.selectedNodeIds.count))
            }
            
            
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
                        .forEach { appModel.session.selectedNodeIds.insert($0) }
                } label: {
                    Label {
                        Text("Select All")
                    } icon: {
                        Image(systemName: "selection.pin.in.out")
                    }
                }
                
                Button {
                    onDuplicate()
                } label: {
                    Label {
                        Text("Duplicate")
                    } icon: {
                        Image(systemName: "plus.square.on.square")
                    }
                }
                
                Divider()
                
                Button {
                    for id in appModel.session.selectedNodeIds {
                        appModel.session.focusNodeIds.insert(id)
                    }
                } label: {
                    Label {
                        Text("Focus")
                    } icon: {
                        Image(systemName: "dot.viewfinder")
                    }
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
                    appModel.session.clearSelection()
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
