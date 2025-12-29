//
//  NameCanvasView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 19.12.2025.
//

import SwiftUI

struct NameCanvasView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State var name: String = ""

    let isCreating: Bool
    let onSubmit: ((String) -> Void)?

    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(isCreating ? .done : .done)
                }
            }
            .navigationTitle(isCreating ? "Create Canvas" : "Rename Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isCreating ? "Create" : "Rename") {
                        onSubmit?(name)
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
