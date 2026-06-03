//
//  NodeDetailView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI
import RichTextKit

struct NodeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel

    @State private var showDeleteConfirmation = false
    @State private var showEditor = false
    @State private var showLinkEditor = false

    let node: Node

    private var connectionlist: some View {
        ForEach(appModel.nodesConnectedWith(node: node)) { connectedNode in
            let isOutgoing = appModel.connections.first(where: { $0.fromNodeId == connectedNode.id || $0.toNodeId == connectedNode.id })?.fromNodeId == connectedNode.id
            HStack(spacing: 16) {
                Image(systemName: isOutgoing ?  "arrow.left" : "arrow.right")
                VStack(alignment: .leading) {
                    Text(connectedNode.name)
                        .font(.body)
                    Text(connectedNode.positionDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                
                Button {
                    let nodeId = connectedNode.id
                    
                    dismiss()
                    
                    DispatchQueue.main.async {
                        appModel.centerOnNodeId = nodeId
                        appModel.selectedNodeIds = [nodeId]
                    }
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.primary)
                .padding(12)
                .background(.primary.opacity(0.04))
                .clipShape(Circle())
                

                Button {
                    
                    guard let connection = appModel.connections.first(where: {
                        ($0.fromNodeId == connectedNode.id && $0.toNodeId == node.id) ||
                        ($0.fromNodeId == node.id && $0.toNodeId == connectedNode.id)
                    }) else { return }
                    
                    let snapshot = ConnectionSnapshot(
                        id: connection.id,
                        fromNodeId: connection.fromNodeId,
                        toNodeId: connection.toNodeId
                    )
                    
                    let action = RemoveConnectionAction(connection: snapshot)
                    appModel.actionService.perform(action)
                    
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
                .padding(12)
                .background(.primary.opacity(0.04))
                .clipShape(Circle())
                
            }
            .contentShape(Rectangle())
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                #if DEBUG
                Section {
                    Text(node.id)
                } header: {
                    Text("ID")
                }
                #endif
                
                Section {
                    if node.detail.isEmpty {
                        Text("No description")
                            .foregroundStyle(.secondary)
                    } else {
//                        Text(node.detail)
                        RichTextViewer(node.richText ?? .init())
                            .frame(minHeight: 400)
                    }
                } header: {
                    Text("Description")
                }

                Section {
                    Text(node.positionDescription)
                } header: {
                    Text("Position")
                }
                
                if !(node.tagsRaw ?? "").isEmpty {
                    Section {
                        Text(node.tagsRaw ?? "")
                    } header: {
                        Text("Tags")
                    }
                }

                if appModel.hasConnection(nodeId: node.id) {
                    Section {
                        connectionlist
                    } header: {
                        Text("Connected Nodes")
                    }
                }
            }
            .navigationTitle(node.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEditor = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button {
                            showLinkEditor = true
                        } label: {
                            Label("Link", systemImage: "link")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Label("", systemImage: "ellipsis")
                    }
                    .menuStyle(.button)
                    .labelStyle(.iconOnly)
                }
            }
            .sheet(isPresented: $showEditor) {
                EditNodeView(node: node)
            }
            .sheet(isPresented: $showLinkEditor) {
                LinkEditorView(fromNode: node)
            }
            .alert(
                "Delete Node",
                isPresented: $showDeleteConfirmation
            ) {
                Button("Delete", role: .destructive) {
                    dismiss()
                    
                    appModel.removeNode(node)
                }

                Button(role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this node?")
            }
        }
    }
}

#Preview {
    NodeDetailView(
        node: .init(
            id: UUID().uuidString,
            name: "Test Node",
            detail: "Description",
            x: 0,
            y: 0,
            z: 0
        )
    )
}
