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
    @EnvironmentObject private var themeStore: ThemeStore
    
    @Binding var showEditor: Bool

    @State private var aiResponse: String = ""
    @State private var showAiResponse: Bool = false

    var visibleScopeIds: Set<String>

    private var scopeNodesCount: Int {
        switch selectedScope {
        case .selection:
            appModel.session.selectedNodeIds.count
        case .visible:
            0
        case .canvas:
            appModel.session.currentCanvas?.nodes?.count ?? 0
        }
    }

    // MARK: - State

    @State private var selectedMode: AIMode = .extend
    @State private var selectedScope: AIScope = .selection

    @State private var prompt = ""

    @FocusState private var isPromptFocused: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    modeSection

                    scopeSection

                    promptSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }

            footer
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 20)
                .padding(.top, 12)
        }
        .navigationTitle("Edit Canvas with AI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) {
                    withAnimation(.snappy) {
                        showEditor = false
                    }
                }
            }
        }
        .frame(maxWidth: contentWidth)
        .frame(maxWidth: .infinity)
        .background(backgroundView)
        .onChange(of: selectedMode) { _, _ in
            if selectedMode == .summarize {
                selectedScope = .selection
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
        VStack(alignment: .leading, spacing: 14) {

            sectionTitle(String(localized: "Mode"))

            ScrollView(.horizontal) {
                HStack(spacing: 14) {

                    ForEach(AIMode.allCases) { mode in

                        AIModeCard(
                            title: mode.title,
                            subtitle: mode.subtitle,
                            icon: mode.icon,
                            isSelected: selectedMode == mode
                        ) {
                            selectedMode = mode
                        }
                        #if os(visionOS)
                        .glassBackgroundEffect(
                            in: .rect(
                                cornerRadius: 22,
                                style: .continuous
                            )
                        )
                        #endif
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Scope

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            sectionTitle(String(localized: "Scope"))

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
                                        ? themeStore.theme.canvasTheme.selection
                                        : Color.clear,
                                        lineWidth: 1.5
                                    )
                            }
                    }
                    .disabled(selectedMode == .summarize && scope == .canvas)
                    .buttonStyle(.plain)
                    #if os(visionOS)
                    .glassBackgroundEffect()
                    #endif
                }
            }
            
            Text("Nodes in scope: \(scopeNodesCount)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionTitle(selectedMode.promptTitle)

            TextField(
                selectedMode.placeholder,
                text: $prompt,
                axis: .vertical
            )
            .focused($isPromptFocused)
            .lineLimit(6...10)
            .textInputAutocapitalization(.sentences)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(borderColor)
                    }
            }
            #if os(visionOS)
            .glassBackgroundEffect(
                in: .rect(
                    cornerRadius: 22,
                    style: .continuous
                )
            )
            #endif
        }
    }

    // MARK: - Footer

    private var footer: some View {

        Button(action: runSelectedAction) {
            Label(selectedMode.actionTitle, systemImage: "sparkles")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(themeStore.theme.canvasTheme.selection)
        .disabled(appModel.aiGenerationService.isRunning || scopeNodesCount == 0)
        .sheet(isPresented: $showAiResponse) {
            NavigationStack {
                AIResponseView(response: $aiResponse)
                    .environment(appModel)
            }
            .interactiveDismissDisabled()
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3.weight(.semibold))
    }

    private var horizontalPadding: CGFloat {
        #if os(visionOS)
        32
        #else
        20
        #endif
    }

    private var contentWidth: CGFloat? {
        #if os(visionOS)
        820
        #else
        nil
        #endif
    }

    private var cardBackground: some ShapeStyle {
        #if os(visionOS)
        .clear
        #else
        Color(.tertiarySystemBackground)
        #endif
    }

    private var borderColor: Color {
        #if os(visionOS)
        .white.opacity(0.15)
        #else
        Color.primary.opacity(0.08)
        #endif
    }

    @ViewBuilder
    private var backgroundView: some View {
        #if os(visionOS)
        Color.clear
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    // MARK: - Actions

    private func runSelectedAction() {
        isPromptFocused = false

        switch selectedMode {
        case .extend:
            appModel.generateNodes(
                selectedScope: selectedScope,
                userPrompt: prompt
            )
            showEditor = false

        case .summarize:
            appModel.summarizeNodes(userPrompt: prompt)
            showEditor = false

        case .explain:
            explainCanvas()
            showAiResponse = true
        }
    }
}

// MARK: - AI Action Handlers

extension AIEditCanvasView {

    private func explainCanvas() {
        Task {
            isPromptFocused = false

            guard let canvas = appModel.session.currentCanvas else {
                return
            }

            var scope: [Node] = []

            switch selectedScope {

            case .selection:
                scope = appModel.session.selectedNodeIds.compactMap {
                    appModel.node(forId: $0)
                }

            case .visible:
                break

            case .canvas:
                scope = appModel.nodes
            }

            do {
                let stream = appModel.aiGenerationService
                    .askQuestions(
                        scope: scope,
                        userInput: prompt,
                        in: canvas
                    )

                for try await chunk in stream {
                    aiResponse = chunk
                }

            } catch {
                print(
                    "error while generating canvas: \(error.localizedDescription)"
                )
            }
        }
    }
}
