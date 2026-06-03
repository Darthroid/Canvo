//
//  EditNodeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 04.12.2025.
//

import SwiftUI
import RichTextKit

struct EditNodeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let nodeId: String

    @State var name: String
    @State var detail: String
    @State var color: Color
    @State var tagsRaw: String
    
    @State private var attributedDetail: NSAttributedString
    
    @StateObject private var context = RichTextContext()
    
    @FocusState private var isNameFocused: Bool
    
    init(node: Node) {
        self.nodeId = node.id

        _name = State(initialValue: node.name)
        _detail = State(initialValue: node.detail)
        _color = State(initialValue: Color(hex: node.colorRaw ?? "") ?? .white)
        _tagsRaw = State(initialValue: node.tagsRaw ?? "")

        let richText: NSAttributedString

        if let detailRichText = node.richText {
            richText = detailRichText
        } else {
            richText = NSAttributedString(string: node.detail)
        }

        _attributedDetail = State(initialValue: richText)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                        .textInputAutocapitalization(.sentences)
                    ColorPicker("Color", selection: $color, supportsOpacity: true)
                } header: {
                    Text("Name")
                }

                Section {
//                    TextField(
//                        "Description",
//                        text: $detail,
//                        axis: .vertical
//                    )
//                    .lineLimit(3...6)

                    RichTextEditor(
                        text: $attributedDetail,
                        context: context
                    )
                    .frame(minHeight: 200)
                    
                } header: {
                    Text("Description")
                }

//                Section {
//                    ColorPicker("Color", selection: $color, supportsOpacity: true)
//                }
                
                Section {
                    TextField(
                        "Tags (separate with commas)",
                        text: $tagsRaw,
                        axis: .horizontal
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                } header: {
                    Text("Tags")
                }
            }
            .navigationTitle("Edit Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        submit()
                        dismiss()
                    }
                    .disabled(
                        name.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isNameFocused = true
                }
            }
        }
    }
    
    private func submit() {
        guard let node = appModel.node(forId: nodeId) else { return }

        let snapshot = appModel.makeNodeSnapshotWithConnections(node)
        let oldNode = snapshot.node

        let richTextData = try? attributedDetail.data(
            from: NSRange(location: 0, length: attributedDetail.length),
            documentAttributes: [
                .documentType: NSAttributedString.DocumentType.rtfd
            ]
        )

        let newNode = NodeSnapshot(
            id: nodeId,
            name: name,
            detail: attributedDetail.string,
            detailRichText: richTextData,
            x: oldNode.x,
            y: oldNode.y,
            z: oldNode.z,
            color: color.toHex(includeAlpha: true),
            tagsRaw: tagsRaw
        )

        let action = UpdateNodeContentAction(
            nodeId: nodeId,
            old: oldNode,
            new: newNode
        )

        appModel.actionService.perform(action)

        dismiss()
    }
}
