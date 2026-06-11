//
//  EditNodeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 04.12.2025.
//

import SwiftUI

@Observable
fileprivate final class EditNodeModel {
    let nodeId: String

    var name: String
    var attributedDetail: AttributedString
    var color: Color
    var tagsRaw: String

    init(node: Node) {
        nodeId = node.id
        name = node.name
        attributedDetail = node.richText
        color = Color(hex: node.colorRaw ?? "") ?? .white
        tagsRaw = node.tagsRaw ?? ""
    }
}

struct EditNodeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let nodeId: String
    
    @State private var model: EditNodeModel
        
    @FocusState private var isNameFocused: Bool
    
    init(node: Node) {
        nodeId = node.id
        _model = State(initialValue: EditNodeModel(node: node))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    
                    TextField("Name", text: $model.name)
                        .focused($isNameFocused)
                        .textInputAutocapitalization(.sentences)
                    ColorPicker("Color", selection: $model.color, supportsOpacity: true)
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

                    TextEditor(text: $model.attributedDetail)
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
                        text: $model.tagsRaw,
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
                        model.name.trimmingCharacters(
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
        appModel.editNode(
            nodeId: nodeId,
            name: model.name,
            attributedDetail: model.attributedDetail,
            color: model.color,
            tagsRaw: model.tagsRaw
        )

        dismiss()
    }
}
