//
//  LinkEditorView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 07.12.2025.
//

import SwiftUI

struct LinkEditorView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let fromNode: Node

    @State private var selectedNodeId: String?
    @State private var searchText: String = ""

    var filteredNodes: [Node] {
        appModel.nodes
            .filter { $0.id != fromNode.id }
            .filter {
                guard !searchText.isEmpty else { return true }
                return $0.name.localizedCaseInsensitiveContains(searchText)
            }
    }

    var body: some View {
        NavigationStack {
            List(filteredNodes) { node in
                HStack {
                    VStack(alignment: .leading) {
                        Text(node.name)
                            .font(.body)
                        Text(node.positionDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if selectedNodeId == node.id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedNodeId = node.id
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Add Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        createLink()
                        dismiss()
                    }
                    .disabled(selectedNodeId == nil)
                }
            }
        }
    }
    
    private func createLink() {
        guard let toNodeId = selectedNodeId else { return }
//        guard let canvas = appModel.currentCanvas else { return }
        
        // prevent duplicates (same logic as before but now explicit)
        guard !appModel.connections.contains(where: {
            ($0.fromNodeId == fromNode.id && $0.toNodeId == toNodeId) ||
            ($0.fromNodeId == toNodeId && $0.toNodeId == fromNode.id)
        }) else { return }
        
        let snapshot = ConnectionSnapshot(
            id: UUID().uuidString,
            fromNodeId: fromNode.id,
            toNodeId: toNodeId
        )
        
        let action = AddConnectionAction(connection: snapshot)
        
        appModel.actionService.perform(action)
    }
}

#Preview {
    LinkEditorView(
        fromNode: .init(
            id: UUID().uuidString,
            name: "Source Node",
            detail: "",
            x: 0,
            y: 0,
            z: 0
        )
    )
}
