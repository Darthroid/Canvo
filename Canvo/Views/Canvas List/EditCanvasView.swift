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
        case .create, .aiCreate: return String(localized: "Create Canvas")
        case .edit: return String(localized:"Edit Canvas")
        }
    }
    
    var confirmActionTitle: String {
        switch self {
        case .create, .aiCreate: return String(localized:"Create")
        case .edit: return String(localized:"Rename")
        }
    }
}

struct EditCanvasView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var themeStore: ThemeStore
    
    @State private var mode: EditCanvasMode
    var editCanvas: Canvas?
    
    @State private var name: String = ""
    @State private var ideas: String = ""
    
    @State private var generationStyle: CanvasGenerationStyle = .tree
    
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
                        
                        // Mode cards
                        if mode != .edit {
                            VStack(spacing: 12) {
                                modeCard(
                                    title: String(localized: "Create manually"),
                                    subtitle: String(localized: "Start with an empty canvas"),
                                    icon: "pencil",
                                    current: .create
                                )

                                modeCard(
                                    title: String(localized: "Generate with AI"),
                                    subtitle: appModel.aiGenerationService.isAvailable
                                        ? String(localized: "Describe a topic and AI will build a canvas")
                                        : String(localized: "Currently not available"),
                                    icon: "sparkles",
                                    current: .aiCreate
                                )
                                .disabled(!appModel.aiGenerationService.isAvailable)
                            }
                            .padding(.top, 8)
                        }
                        
                        // Input
                        VStack(alignment: .leading, spacing: 8) {
                            if mode == .aiCreate {
                                VStack(alignment: .leading, spacing: 8) {

                                    Text("Layout")
                                        .font(.headline)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {

                                            layoutCard(
                                                style: .tree,
                                                imageName: "scheme_tree"
                                            )

                                            layoutCard(
                                                style: .radial,
                                                imageName: "scheme_radial"
                                            )
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            
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
            }
            .navigationTitle(mode.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        appModel.aiGenerationService.cancelCurrentTask()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: submit)
                        .disabled(!canSubmit)
                }
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

// MARK: - Actions

private extension EditCanvasView {
    
    func submit() {
        switch mode {
        case .create:
            appModel.createCanvas(name: name)
            
        case .aiCreate:
            appModel.generateCanvasStream(
                prompt: ideas,
                style: generationStyle
            )
            
        case .edit:
            guard let editCanvas else { return }
            appModel.renameCanvas(id: editCanvas.id, newName: name)
        }
        
        isNameFocused = false
        isIdeasFocused = false
        dismiss()
    }
}

// MARK: - Components

private extension EditCanvasView {
    
    func modeCard(title: String, subtitle: String, icon: String, current: EditCanvasMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = current
            }
        } label: {
            HStack(spacing: 16) {
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(themeStore.theme.canvasTheme.selection.opacity(0.15))
                    #if os(visionOS)
                    .foregroundStyle(.primary)
                    .background(.thinMaterial)
                    #else
                    .foregroundStyle(themeStore.theme.canvasTheme.selection)
                    #endif
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                    }
                    
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if mode == current {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(themeStore.theme.canvasTheme.selection)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 20))
    }
    
    @ViewBuilder
    func layoutCard(
        style: CanvasGenerationStyle,
        imageName: String
    ) -> some View {

        Button {
            generationStyle = style
        } label: {
            VStack(alignment: .center, spacing: 12) {

                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12)
                    )

                VStack(alignment: .leading) {
                    Text(style.title)
                        .font(.headline)
                        .lineLimit(2)

                    Text(style.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                Spacer(minLength: 0)
            }
            .frame(width: 160)
            .frame(maxHeight: .infinity)
            .padding(12)
            .background(.thinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        generationStyle == style
                        ? themeStore.theme.canvasTheme.selection
                        : .clear,
                        lineWidth: 2
                    )
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 20)
            )
        }
        .buttonStyle(.plain)
    }
}
