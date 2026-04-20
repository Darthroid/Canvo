//
//  EditNodeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 04.12.2025.
//

import SwiftUI

struct EditNodeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let nodeId: String

    @State var name: String
    @State var detail: String
    @State var color: Color
    @State var tagsRaw: String

    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                        .textInputAutocapitalization(.sentences)
                }

                Section {
                    TextField(
                        "Description",
                        text: $detail,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }

                Section {
                    ColorPicker("Color", selection: $color, supportsOpacity: true)
                }
                
                Section {
                    TextField(
                        "Tags (separate with commas)",
                        text: $tagsRaw,
                        axis: .horizontal
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
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
                        appModel.updateNode(
                            id: nodeId,
                            name: name,
                            detail: detail,
                            color: color.toHex(includeAlpha: true),
                            tagsRaw: tagsRaw
                        )
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
}
