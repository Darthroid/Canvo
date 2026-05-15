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

    @State private var selectedNodeIds: Set<String> = []
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

                    if selectedNodeIds.contains(node.id) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
//                    selectedNodeId = node.id
                    if selectedNodeIds.contains(node.id) {
                        selectedNodeIds.remove(node.id)
                    } else {
                        selectedNodeIds.insert(node.id)
                    }
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
                    .disabled(selectedNodeIds.isEmpty)
                }
            }
            .onAppear {
                selectedNodeIds = Set(appModel.nodesConnectedWith(node: fromNode).map { $0.id })
            }
        }
    }
    
    private func createLink() {
        guard !selectedNodeIds.isEmpty else { return }
        
        appModel.actionService.beginBatch()
        selectedNodeIds.forEach { toNodeId in
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
        appModel.actionService.endBatch()
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
