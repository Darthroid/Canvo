//
//  AIEditCanvasView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 10.01.2026.
//

import SwiftUI
import FoundationModels

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct AIEditCanvasView: View {

    @Environment(AppModel.self) private var appModel
    @Binding var showEditor: Bool
    
    @State private var generationStage: String = ""
    
    @State private var errorMessage: String?
    
    @State private var aiResponse: String = ""
    @State private var showAiResponse: Bool = false
    
    var visibleScopeIds: Set<String>
    
    private var scopeNodesCount: Int {
        switch selectedScope {
        case .selection:
            appModel.selectedNodeIds.count
        case .visible:
            0//visibleScopeIds.count
        case .canvas:
            appModel.currentCanvas?.nodes?.count ?? 0
        }
    }


    // MARK: - State

    @State private var selectedMode: AIMode = .extend
    @State private var selectedScope: AIScope = .selection

    @State private var prompt = ""
    @State private var isGenerating = false

    @FocusState private var isPromptFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    modeSection
                    
                    scopeSection
                    
                    promptSection
                }
            }
            
            footer
            
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .title) {
                HStack {
                    Text("Edit Canvas with AI")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("BETA")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .background(.black, in: Capsule())
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(role: .close) {
                    withAnimation {
                        showEditor = false
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            if isGenerating {
                AIOverlayView(title: $generationStage)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPromptFocused = true
            }
        }

    }

    // MARK: - Mode

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            sectionTitle("Mode")

            ScrollView(.horizontal) {

                HStack(spacing: 12) {

                    ForEach(AIMode.allCases) { mode in

                        AIModeCard(
                            title: mode.title,
                            subtitle: mode.subtitle,
                            icon: mode.icon,
                            isSelected: selectedMode == mode
                        ) {
                            selectedMode = mode
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Scope

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            sectionTitle("Scope")

            HStack(spacing: 10) {

                ForEach([AIScope.selection, AIScope.canvas]) { scope in

                    Button {
                        selectedScope = scope
                    } label: {

                        Label(scope.title, systemImage: scope.icon)
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                    }
                    .background {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color(.tertiarySystemBackground))
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(
                                        selectedScope == scope
                                        ? Color.accentColor
                                        : Color.clear,
                                        lineWidth: 1.5
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    
                }
            }
            
            Text("Nodes in scope: \(scopeNodesCount)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            sectionTitle(selectedMode.promptTitle)

            TextField(
                selectedMode.placeholder,
                text: $prompt,
                axis: .vertical
            )
            .focused($isPromptFocused)
            .lineLimit(5...8)
            .textInputAutocapitalization(.sentences)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
    }

    // MARK: - Footer

    private var footer: some View {
        
        Button(action: runSelectedAction) {
            Label(title: {
                Text(selectedMode.actionTitle)
                    .font(.system(size: 17, weight: .semibold))
            }, icon: {
                Image(systemName: "sparkles")
            })
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
        .disabled(isGenerating || scopeNodesCount == 0)
        .opacity(!(isGenerating || scopeNodesCount == 0) ? 1 : 0.5)
        .sheet(isPresented: $showAiResponse) {
            NavigationStack {
                AIResponseView(response: $aiResponse)
            }
            .interactiveDismissDisabled()
        }
        
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
    }

    // MARK: - Actions

    private func runSelectedAction() {

        switch selectedMode {

        case .extend:
            generateNodes()

        case .summarize:
            summarizeNodes()

        case .explain:
            explainCanvas()
        }
    }
}

// MARK: - AI Action Handlers

extension AIEditCanvasView {
    
    private func generateNodes() {
        Task {
            isGenerating = true
            isPromptFocused = false
            generationStage = "Creating Canvas"
            guard let canvas = appModel.currentCanvas else { return }
            
            var scope: [Node] = []
            
            switch selectedScope {
            case .selection:
                scope = appModel.selectedNodeIds.compactMap {
                    appModel.node(forId: $0)
                }
            case .visible:
                break
            case .canvas:
                scope = appModel.nodes
            }
            
            do {
                var nodes: [Node] = []
                var connections: [NodeConnection] = []
                for single in scope {
                    for try await schema in AIGenerationService.shared.extendNodes(nodes: [single], in: canvas, userInput: prompt) {
                        nodes += schema.0.0
                            .map { Node(from: $0) }
                        
                        connections += schema.0.1
                            .map { NodeConnection(from: $0) }
                        
                        generationStage = schema.1
                    }
                }
                
                appModel.addNodesFromAIAction(Array(nodes), connections: Array(connections))
                showEditor = false

            } catch {
                print("error while generating canvas: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            
            isGenerating = false
            generationStage = ""
        }
    }

    private func summarizeNodes() {
        Task {
            await fakeRequest()

            // TODO:
            // summarize nodes
        }
    }

    private func explainCanvas() {
        Task {
            isGenerating = true
            isPromptFocused = false
            generationStage = "Creating Canvas"
            guard let canvas = appModel.currentCanvas else { return }
            
            var scope: [Node] = []
            
            switch selectedScope {
            case .selection:
                scope = appModel.selectedNodeIds.compactMap {
                    appModel.node(forId: $0)
                }
            case .visible:
                break
            case .canvas:
                scope = appModel.nodes
            }
            
            do {
                let stream = AIGenerationService.shared.askStereamed(prompt: prompt, nodes: scope, in: canvas)
                showAiResponse = true
                for try await chunk in stream {
                    aiResponse = chunk.content
                }
            } catch {
                print("error while generating canvas: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
            }
            
            isGenerating = false
            generationStage = ""
        }
    }

    private func fakeRequest() async {

        isGenerating = true
        isPromptFocused = false

        defer {
            isGenerating = false
        }

        try? await Task.sleep(for: .seconds(1.2))

        withAnimation {
            showEditor = false
        }
        
    }

}
