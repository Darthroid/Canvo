//
//  AICreateCanvasView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 09.01.2026.
//

import SwiftUI

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct AICreateCanvasView: View {
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
                AppleIntelligenceOverlay(title: "Generating Canvas")
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
            .navigationTitle("AI Create Canvas")
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
                        isGenerating ||
                        ideas.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            isGenerating = true
            isIdeasFocused = false
            do {
                let schema = try await AIGenerationService.shared
                    .generaeteCanvas(prompt: ideas)

                let canvas = Canvas(from: schema)
                appModel.addCanvas(canvas)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }

            isGenerating = false
        }
    }
}
