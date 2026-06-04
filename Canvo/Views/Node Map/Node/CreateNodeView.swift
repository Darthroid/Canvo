//
//  CreateNodeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 20.11.2025.
//

import SwiftUI

struct CreateNodeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let position: SIMD3<Float>?

    @State private var name: String = ""
//    @State private var detail: String = ""
    @State private var color: Color = .white
    @State private var tagsRaw: String = ""
    
    @State private var attributedDetail = AttributedString()
    
    @FocusState private var isNameFocused: Bool

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
                    
                    TextEditor(text: $attributedDetail)
                        .frame(minHeight: 200)
                } header: {
                    Text("Description")
                }
                
                Section {
                    TextField(
                        "Tags (separate with commas)",
                        text: $tagsRaw,
                        axis: .horizontal
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }  header: {
                    Text("Tags")
                }
            }
            .navigationTitle("Create Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        createNode()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isNameFocused = true
                }
            }
        }
    }
    
    private func createNode() {
        let id = UUID().uuidString

        let positionValue = position ?? SIMD3<Float>(0, 1.0, -1.5)

        let snapshot = NodeSnapshot(
            id: id,
            name: name,
            richText: attributedDetail,
            x: positionValue.x,
            y: positionValue.y,
            z: positionValue.z,
            color: color.toHex(includeAlpha: true),
            tagsRaw: tagsRaw
        )

        let action = AddNodeAction(node: snapshot)

        appModel.actionService.perform(action)
    }
}
