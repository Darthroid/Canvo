//
//  NodeDetailView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.11.2025.
//

import SwiftUI

struct NodeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel

    @State private var showDeleteConfirmation = false
    @State private var showEditor = false
    @State private var showLinkEditor = false

    let node: Node

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if node.detail.isEmpty {
                        Text("No description")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(node.detail)
                    }
                } header: {
                    Text("Description")
                }

                Section {
                    #if os(visionOS)
                    Text(node.positionDescriptionMeters)
                    #else
                    Text(node.positionDescription)
                    #endif
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
                        ForEach(appModel.nodesConnectedWith(node: node)) { connectedNode in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(connectedNode.name)
                                        .font(.body)
                                    Text(connectedNode.positionDescription)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button(role: .destructive) {
                                    appModel.removeConnectionsBetween(
                                        connectedNode,
                                        and: node
                                    )
                                } label: {
                                    Image(systemName: "xmark")
                                }
                                .buttonStyle(.borderless)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dismiss()
                                appModel.selectedNodeId = connectedNode.id
                            }
                        }
                    } header: {
                        Text("Connected Nodes")
                    }
                }
            }
            .navigationTitle(node.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
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
                            Label("Link", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                EditNodeView(
                    nodeId: node.id,
                    name: node.name,
                    detail: node.detail,
                    color: Color(uiColor: node.color ?? .white),
                    tagsRaw: node.tagsRaw ?? ""
                )
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

                Button("Cancel", role: .cancel) {}
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
