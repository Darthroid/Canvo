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
    @State private var editingNode: Node?
    @State private var linkNode: Node?

    let node: Node

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    cover

                    HStack {

                        EditorBlock(title: String(localized: "Name")) {
                            Text(node.name.isEmpty ? String(localized: "Untitled node") : node.name)
                                .font(.system(size: 20, weight: .medium))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        EditorBlock(title: String(localized: "Color")) {
                            Circle()
                                .fill(
                                    Color(hex: node.colorRaw ?? "")
                                    ?? .white
                                )
                                .frame(width: 28, height: 28)
                        }
                    }

                    EditorBlock(title: String(localized: "Detail")) {
                        if node.richText.characters.isEmpty {
                            Text("No description")
                                .foregroundStyle(.secondary)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        } else {
                            Text(node.richText)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        }
                    }

                    if let tags = node.tagsRaw,
                       !tags.trimmingCharacters(
                        in: .whitespacesAndNewlines
                       ).isEmpty {

                        EditorBlock(title: String(localized: "Tags")) {
                            Text(tags)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        }
                    }

                    if appModel.hasConnection(nodeId: node.id) {

                        EditorBlock(title: String(localized: "Connected Nodes")) {
                            VStack(spacing: 12) {
                                connectionList
                            }
                        }
                    }
                    
                    EditorBlock(title: String(localized: "Position")) {
                        Text(node.positionDescription)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }

                    #if DEBUG

                    EditorBlock(title: String(localized: "ID")) {
                        Text(node.id)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }
                    #endif
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
//            .navigationTitle("Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            editingNode = node
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button {
                            linkNode = node
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
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(item: $editingNode) { node in
                NodeEditorView(node: node)
                    .interactiveDismissDisabled()
            }
            .sheet(item: $linkNode) { node in
                LinkEditorView(fromNode: node)
                    .interactiveDismissDisabled()
            }
            .alert(
                "Delete Node",
                isPresented: $showDeleteConfirmation
            ) {
                Button("Delete", role: .destructive) {
                    dismiss()
                    appModel.removeNode(node)
                }

                Button("Cancel", role: .cancel) { }

            } message: {
                Text("Are you sure you want to delete this node?")
            }
        }
    }
}

private extension NodeDetailView {

    var cover: some View {
        Group {
            if let data = node.images.first,
               let uiImage = UIImage(data: data) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .clipped()
            }
        }
    }

    var connectionList: some View {
        ForEach(appModel.nodesConnectedWith(node: node)) { connectedNode in

            let isOutgoing = appModel.connections.first(where: {
                $0.fromNodeId == connectedNode.id ||
                $0.toNodeId == connectedNode.id
            })?.fromNodeId == connectedNode.id

            HStack(spacing: 12) {
                
                Image(
                    systemName: isOutgoing
                    ? "arrow.left"
                    : "arrow.right"
                )
                .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    
                    Text(connectedNode.name)
                        .foregroundStyle(.primary)
                    
                    Text(connectedNode.positionDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    focusOnNode(connectedNode)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.primary)
                .padding(12)
                .background(.primary.opacity(0.04))
                .clipShape(Circle())
                
                Button {
                    removeConnection(for: connectedNode)
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
    
    func focusOnNode(_ connectedNode: Node) {
        let nodeId = connectedNode.id

        dismiss()

        DispatchQueue.main.async {
            appModel.session.centerOnNodeId = nodeId
            appModel.session.selectedNodeIds = [nodeId]
        }
    }
    
    func removeConnection(for connectedNode: Node) {
        guard let connection = appModel.connections.first(where: {
            ($0.fromNodeId == connectedNode.id && $0.toNodeId == node.id)
            || ($0.fromNodeId == node.id && $0.toNodeId == connectedNode.id)
        }) else {
            return
        }

        appModel.removeConnection(connection)

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
