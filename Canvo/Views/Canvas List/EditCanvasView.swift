//
//  NameCanvasView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 19.12.2025.
//

import SwiftUI

enum EditCanvasMode: String, CaseIterable, Identifiable {
    case create = "Create", aiCreate = "AI", edit = "Edit"
    
    var id: String { rawValue }
    
    var navTitle: String {
        switch self {
        case .create, .aiCreate: return "Create Canvas"
        case .edit: return "Edit Canvas"
        }
    }
    
    var confirmActionTitle: String {
        switch self {
        case .create, .aiCreate: return "Create"
        case .edit: return "Rename"
        }
    }
}

struct EditCanvasView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var mode: EditCanvasMode
    var editCanvas: Canvas?
    
    @State private var name: String = ""
    @State private var ideas: String = ""
    
    @State private var isGenerating: Bool = false
    @State private var generationStage: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    
    @FocusState private var isIdeasFocused: Bool
    @FocusState private var isNameFocused: Bool
    
    init(mode: EditCanvasMode, editCanvas: Canvas? = nil) {
        _mode = State(initialValue: mode)
        _name = State(initialValue: editCanvas?.name ?? "")
        self.editCanvas = editCanvas
    }
    
    var canSubmit: Bool {
        if mode == .aiCreate {
            return !ideas.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // MARK: Mode cards
                        if mode != .edit {
                            VStack(spacing: 12) {
                                modeCard(
                                    title: "Create manually",
                                    subtitle: "Start with an empty canvas",
                                    icon: "pencil",
                                    current: .create
                                )

                                modeCard(
                                    title: "Generate with AI", isBeta: true,
                                    subtitle: AIGenerationService.shared.isAvailable
                                        ? "Describe a topic and AI will build a canvas"
                                        : "Currently not available",
                                    icon: "sparkles",
                                    current: .aiCreate
                                )
                                .disabled(!AIGenerationService.shared.isAvailable)
                            }
                            .padding(.top, 8)
                        }
                        
                        // MARK: Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text(mode == .aiCreate ? "Ideas" : "Name")
                                .font(.headline)
                            
                            if mode == .aiCreate {
                                TextField(
                                    "E.g. launching a startup: idea, market, MVP, marketing",
                                    text: $ideas,
                                    axis: .vertical
                                )
                                .focused($isIdeasFocused)
                                .padding()
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .lineLimit(5...10)
                                
                                Text("AI will generate a structured canvas based on your description")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                TextField("Canvas name", text: $name)
                                    .focused($isNameFocused)
                                    .padding()
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
                
                // MARK: Bottom CTA
                VStack {
                    Spacer()
                    
                    Button(action: submit) {
                        Text(mode == .aiCreate ? "Generate with AI" : mode.confirmActionTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.9), Color.accentColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!canSubmit)
                    .opacity(canSubmit ? 1 : 0.5)
                    .padding()
                }
            }
            .navigationTitle(mode.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) { dismiss() }
                }
            }
            .overlay {
                if isGenerating {
                    AIOverlayView(title: $generationStage)
                }
            }
            .alert("Generation Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if mode == .aiCreate {
                        isIdeasFocused = true
                    } else {
                        isNameFocused = true
                    }
                }
            }
        }
    }
}

// MARK: - Components

private extension EditCanvasView {
    
    func modeCard(title: String, isBeta: Bool = false, subtitle: String, icon: String, current: EditCanvasMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = current
            }
        } label: {
            HStack(spacing: 16) {
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                        if isBeta {
                            Text("BETA")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(.white)
                                .background(Capsule(style: .circular).fill(.black))
                        }
                    }
                    
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if mode == current {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
            )
        }
        .buttonStyle(.plain)
    }
    
    func submit() {
        switch mode {
        case .create:
            appModel.createCanvasAction(name: name)
            dismiss()
            
        case .aiCreate:
//            generateCanvas()
            generateCanvasStream()
            
        case .edit:
            guard let editCanvas else { return }
            appModel.renameCanvasAction(id: editCanvas.id, newName: name)
            dismiss()
        }
    }
    
    func generateCanvasStream() {
        Task {
            isGenerating = true
            generationStage = "Creating Canvas"
            isIdeasFocused = false
            
            do {
                var finalCanvas: Canvas?
                for try await schema in AIGenerationService.shared.generateCanvasStream(prompt: ideas) {
                    let canvas = Canvas(from: schema.0)
                    generationStage = schema.1
                    finalCanvas = canvas
                }
                
                if let canvas = finalCanvas {
                    appModel.addCanvasFromAIAction(canvas)
                    dismiss()
                }
            } catch {
                print("error while generating canvas: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
            
            isGenerating = false
            generationStage = ""
        }
    }
    
//    func generateCanvas() {
//        Task {
//            isGenerating = true
//            isIdeasFocused = false
//            
//            do {
//                let schema = try await AIGenerationService.shared
//                    .generaeteCanvas(prompt: ideas)
//
//                let canvas = Canvas(from: schema)
//                appModel.addCanvas(canvas)
//                dismiss()
//            } catch {
//                errorMessage = error.localizedDescription
//                showErrorAlert = true
//            }
//            
//            isGenerating = false
//        }
//    }
}
