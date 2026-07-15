//
//  AIEditCanvasView.swift
//  Canvo
//

import SwiftUI
import FoundationModels

@available(iOS 26.0, *)
struct AIEditCanvasView: View {

    @Environment(AppModel.self) private var appModel
    @EnvironmentObject private var themeStore: ThemeStore

    @Binding var showEditor: Bool

    @State private var aiResponse: String = ""
    @State private var showAiResponse: Bool = false

    @State private var selectedMode: AIMode = .extend
    @State private var selectedScope: AIScope = .selection

    @State private var prompt = ""
    @FocusState private var isPromptFocused: Bool

    private var scopeNodesCount: Int {
        switch selectedScope {
        case .selection:
            return appModel.session.selectedNodeIds.count
        case .canvas:
            return appModel.session.currentCanvas?.nodes?.count ?? 0
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {

                    modeSection
                    scopeSection
                    promptSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }

            footer
                .padding(.horizontal, horizontalPadding)
                .padding(.bottom, 14)
                .padding(.top, 8)
        }
        .navigationTitle("Edit Canvas with AI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .close) {
                        withAnimation(.snappy) {
                            showEditor = false
                        }
                    }
                } else {
                    Button("Cancel") {
                        withAnimation(.snappy) {
                            showEditor = false
                        }
                    }
                }
            }
        }
        .frame(maxWidth: contentWidth)
        .frame(maxWidth: .infinity)
        .background(backgroundView)
        .onChange(of: selectedMode) { _, mode in
            switch mode {
            case .summarize:
                selectedScope = .selection
            case .extend:
                selectedScope = .selection
            case .explain:
                selectedScope = .canvas
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPromptFocused = true
            }
        }
    }

    // MARK: - Mode

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 10) {

            ScrollView(.horizontal) {
                HStack(spacing: 10) {

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
                            in: .rect(cornerRadius: 22, style: .continuous)
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
        VStack(alignment: .leading, spacing: 8) {

            sectionTitle("Scope")

            HStack(spacing: 10) {
                ForEach([AIScope.selection, AIScope.canvas]) { scope in

                    Button {
                        selectedScope = scope
                    } label: {

                        VStack(spacing: 2) {
                            Label(scope.title, systemImage: scope.icon)
                                .font(.subheadline.weight(.medium))

                            Text("\(count(for: scope)) nodes")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                    }
                    .disabled(selectedMode == .summarize && scope == .canvas)
                    .background {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.tertiarySystemBackground))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .strokeBorder(
                                        selectedScope == scope
                                        ? themeStore.theme.canvasTheme.selection
                                        : Color.clear,
                                        lineWidth: 1.5
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
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
            .lineLimit(4...7)
            .textInputAutocapitalization(.sentences)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(borderColor)
                    }
            }
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

    private func count(for scope: AIScope) -> Int {
        switch scope {
        case .selection:
            return appModel.session.selectedNodeIds.count
        case .canvas:
            return appModel.session.currentCanvas?.nodes?.count ?? 0
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline.weight(.semibold))
    }

    private var horizontalPadding: CGFloat {
        #if os(visionOS)
        28
        #else
        16
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
        Color.white.opacity(0.15)
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

@available(iOS 26.0, *)
extension AIEditCanvasView {

    private func explainCanvas() {
        Task {
            isPromptFocused = false

            guard let canvas = appModel.session.currentCanvas else { return }

            let scope: [Node] = {
                switch selectedScope {
                case .selection:
                    return appModel.session.selectedNodeIds.compactMap {
                        appModel.node(forId: $0)
                    }
                case .canvas:
                    return appModel.nodes
                }
            }()

            do {
                let stream = appModel.aiGenerationService.askGraph(
                    scope: scope,
                    userInput: prompt,
                    in: canvas
                )

                for try await chunk in stream {
                    aiResponse = chunk
                }

            } catch {
                print("error while generating canvas: \(error.localizedDescription)")
            }
        }
    }
}
