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
    @State private var detail: String = ""
    @State private var color: Color = .white
    @State private var tagsRaw: String = ""

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
                        appModel.addNode(
                            name: name,
                            detail: detail,
                            position: position.map {
                                (x: $0.x, y: $0.y, z: $0.z)
                            },
                            color: color.toHex(includeAlpha: true),
                            tagsRaw: tagsRaw
                        )
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
}
