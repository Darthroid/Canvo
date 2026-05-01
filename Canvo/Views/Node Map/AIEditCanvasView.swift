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
                AIOverlayView(title: .constant("Generating Ideas"))
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
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Describe what you want to add")
                            .font(.headline)
                        
                        Text("AI will extend your current canvas with new connected nodes")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("E.g. marketing strategy, user journey, app architecture", text: $ideas, axis: .vertical)
                            .focused($isIdeasFocused)
                            .textInputAutocapitalization(.sentences)
                            .lineLimit(10...15)
                    }
                    
                } footer: {
                    Text("Your input is used as a prompt for AI to extend the current canvas with additional nodes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
//            .navigationTitle("AI Edit Canvas")
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    HStack {
                        Text("Extend canvas with AI")
                            .font(.body)
                            .fontWeight(.semibold)
                        Text("BETA")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white)
                            .background(Capsule(style: .circular).fill(.black))
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                    .disabled(isGenerating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
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
        // TODO: new generation tools
        
//        Task {
//            guard let currentCanvas = appModel.currentCanvas else {
//                return
//            }
//            isGenerating = true
//            isIdeasFocused = false
//            do {
//                let schema = try await AIGenerationService.shared
//                    .generateNodes(prompt: ideas, in: currentCanvas)
//                    .generateNodesChunked(prompt: ideas, in: currentCanvas)
//
//                let nodes = schema.0.map { Node(from: $0) }
//                let connections = schema.1.map { NodeConnection(from: $0) }
//                
//                appModel.addNodes(nodes)
//                appModel.addConnections(connections)
//                
//                dismiss()
//            } catch {
//                errorMessage = error.localizedDescription
//                showErrorAlert = true
//            }
//
//            isGenerating = false
//        }
    }
}
