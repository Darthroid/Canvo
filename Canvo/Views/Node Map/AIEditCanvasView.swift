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
    @Binding var showEditor: Bool
    
    private var scopeNodesCount: Int {
        switch selectedScope {
        case .selection:
            appModel.selectedNodeIds.count
        case .visible:
            0
        case .canvas:
            appModel.currentCanvas?.nodes?.count ?? 0
        }
    }

    // MARK: - Mode

    enum AIMode: String, CaseIterable, Identifiable {
        case extend
        case summarize
        case explain

        var id: String { rawValue }

        var title: String {
            switch self {
            case .extend: "Expand"
            case .summarize: "Summarize"
            case .explain: "Explain"
            }
        }

        var subtitle: String {
            switch self {
            case .extend:
                "Generate related ideas"
            case .summarize:
                "Compress selected content"
            case .explain:
                "Explain concepts and links"
            }
        }

        var icon: String {
            switch self {
            case .extend:
                "sparkles"
            case .summarize:
                "text.redaction"
            case .explain:
                "text.bubble"
            }
        }

        var actionTitle: String {
            switch self {
            case .extend:
                "Generate Nodes"
            case .summarize:
                "Create Summary"
            case .explain:
                "Explain Canvas"
            }
        }

        var loadingTitle: String {
            switch self {
            case .extend:
                "Generating Nodes"
            case .summarize:
                "Creating Summary"
            case .explain:
                "Generating Explanation"
            }
        }

        var promptTitle: String {
            switch self {
            case .extend:
                "What should AI add?"
            case .summarize:
                "What should AI focus on?"
            case .explain:
                "What do you want explained?"
            }
        }

        var placeholder: String {
            switch self {
            case .extend:
                "Add onboarding flow and monetization ideas..."
            case .summarize:
                "Summarize into concise product requirements..."
            case .explain:
                "Explain how these systems interact..."
            }
        }
    }

    // MARK: - Scope

    enum AIScope: String, CaseIterable, Identifiable {
        case selection
        case visible
        case canvas

        var id: String { rawValue }

        var title: String {
            switch self {
            case .selection:
                "Selection"
            case .visible:
                "Visible"
            case .canvas:
                "Entire Canvas"
            }
        }

        var icon: String {
            switch self {
            case .selection:
                "selection.pin.in.out"
            case .visible:
                "eye"
            case .canvas:
                "square.grid.3x3"
            }
        }
    }

    // MARK: - State

    @State private var selectedMode: AIMode = .extend
    @State private var selectedScope: AIScope = .visible

    @State private var prompt = ""
    @State private var isGenerating = false

    @FocusState private var isPromptFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            header

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    modeSection
                    
                    scopeSection
                    
                    promptSection
                }
            }
            
            footer
            
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay {
            if isGenerating {
                AIOverlayView(title: .constant(selectedMode.loadingTitle))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPromptFocused = true
            }
        }

    }

    // MARK: - Header

    private var header: some View {
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
            
            Spacer()
            
            Button {
                withAnimation {
                    showEditor = false
                }
            } label: {
                Image(systemName: "xmark")
                    .padding(4)
            }
            .clipShape(.circle)
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
        }
    }

    // MARK: - Mode

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            sectionTitle("Mode")

            ScrollView(.horizontal) {

                HStack(spacing: 12) {

                    ForEach(AIMode.allCases) { mode in

                        ModeCard(
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

                ForEach(AIScope.allCases) { scope in

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
        .disabled(isGenerating)
        .opacity(!isGenerating ? 1 : 0.5)
        
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

    // MARK: - AI Stubs

    private func generateNodes() {
        Task {
            await fakeRequest()

            // TODO:
            // generate nodes
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
            await fakeRequest()

            // TODO:
            // explain canvas
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

// MARK: - Mode Card

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
private struct ModeCard: View {

    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool

    let action: () -> Void

    var body: some View {

        Button(action: action) {

            VStack(alignment: .leading, spacing: 10) {

                Image(systemName: icon)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 3) {

                    Text(title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(width: 190, height: 118, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(
                                isSelected
                                ? Color.accentColor
                                : Color.clear,
                                lineWidth: 1.5
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }
}
