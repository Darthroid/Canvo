//
//  AIEditCanvasView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 10.01.2026.
//

import SwiftUI

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct AIEditCanvasView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var ideas: String = ""

    @State private var isGenerating: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    @FocusState private var isIdeasFocused: Bool
    
    var body: some View {
        ZStack {
            contentView // твой NavigationStack / Form

            if isGenerating {
                AIOverlayView(title: "Generating Ideas")
                    .zIndex(100)
            }
        }
        .alert("Generation Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    var contentView: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter your ideas", text: $ideas, axis: .vertical)
                        .focused($isIdeasFocused)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(10...15)
                }
            }
            .navigationTitle("AI Edit Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        generateCanvas()
                    }
                    .disabled(
                        isGenerating
                    )
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isIdeasFocused = true
                }
            }
        }
    }

    // MARK: - Actions

    private func generateCanvas() {
        Task {
            guard let currentCanvas = appModel.currentCanvas else {
                return
            }
            isGenerating = true
            isIdeasFocused = false
            do {
                let schema = try await AIGenerationService.shared
                    .generateNodes(prompt: ideas, in: currentCanvas)

                let nodes = schema.0.map { Node(from: $0) }
                let connections = schema.1.map { NodeConnection(from: $0) }
                
                appModel.addNodes(nodes)
                appModel.addConnections(connections)
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }

            isGenerating = false
        }
    }
}
