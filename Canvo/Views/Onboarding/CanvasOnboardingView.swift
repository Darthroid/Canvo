//
//  CanvasOnboardingView.swift
//  Canvo
//
//  Created by Олег Комаристый on 15.06.2026.
//

import SwiftUI

struct CanvasOnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {

            HStack {
                Spacer()
                Button("Skip") {
                    dismiss()
                }
                .padding()
            }

            ZStack {
                SelectNodeSlide(isActive: currentPage == 0)
                    .opacity(currentPage == 0 ? 1 : 0)
                    .allowsHitTesting(currentPage == 0)

                OpenNodeSlide(isActive: currentPage == 1)
                    .opacity(currentPage == 1 ? 1 : 0)
                    .allowsHitTesting(currentPage == 1)

                MultiSelectSlide(isActive: currentPage == 2)
                    .opacity(currentPage == 2 ? 1 : 0)
                    .allowsHitTesting(currentPage == 2)
            }
            .animation(.easeInOut(duration: 0.2), value: currentPage)

            Button {
                if currentPage < 2 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    dismiss()
                }
            } label: {
                Text(currentPage == 2 ? "Get Started" : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .padding(.top, 12)
        }
        .background(Color("MapBackground"))
    }
}

// MARK: - Slide 1

private struct SelectNodeSlide: View {
    let isActive: Bool

    @State private var isSelected = false
    @State private var showTouch = false
    @State private var touchPulse = false
    @State private var task: Task<Void, Never>?

    private let node = Node(
        name: "Project Idea",
        detail: "",
        x: 0,
        y: 0,
        z: 0,
        color: "#FFFFFF"
    )

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                NodeView(
                    node: node,
                    isSelected: isSelected,
                    isExpanded: false,
                    isMatchingSearch: false,
                    toolbarEnabled: true
                )

                if showTouch {
                    TouchIndicator(isActive: touchPulse)
                        .offset(x: 40, y: -10)
                }
            }

            VStack(spacing: 12) {
                Text("Select Nodes")
                    .font(.title.bold())

                Text("Tap a node to select it for editing, moving, or AI actions.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()
        }
        .onAppear {
            guard isActive else { return }
            start()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                start()
            } else {
                stop()
                reset()
            }
        }
    }

    private func reset() {
        isSelected = false
        showTouch = false
        touchPulse = false
    }

    private func stop() {
        task?.cancel()
        task = nil
    }

    private func start() {
        stop()

        task = Task {
            while !Task.isCancelled {
                reset()

                try? await Task.sleep(for: .seconds(0.8))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    showTouch = true
                }

                touchPulse = true
                try? await Task.sleep(for: .milliseconds(250))

                touchPulse = false
                try? await Task.sleep(for: .milliseconds(200))

                isSelected = true

                try? await Task.sleep(for: .seconds(1.5))
            }
        }
    }
}

// MARK: - Slide 2

private struct OpenNodeSlide: View {
    let isActive: Bool

    @State private var isExpanded = false
    @State private var showTouch = false
    @State private var touchPulse = false
    @State private var task: Task<Void, Never>?

    private let node = Node(
        name: "Project Plan",
        detail: "Research\nTimeline\nLaunch strategy",
        x: 0,
        y: 0,
        z: 0,
        color: "#FFFFFF"
    )

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                NodeView(
                    node: node,
                    isSelected: false,
                    isExpanded: isExpanded,
                    isMatchingSearch: false,
                    toolbarEnabled: true
                )

                if showTouch {
                    TouchIndicator(isActive: touchPulse)
                        .offset(x: 40, y: -20)
                }
            }

            VStack(spacing: 12) {
                Text("Open Details")
                    .font(.title.bold())

                Text("Double-tap a selected node to view and edit its content.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()
        }
        .onAppear {
            guard isActive else { return }
            start()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                start()
            } else {
                stop()
                reset()
            }
        }
    }

    private func reset() {
        isExpanded = false
        showTouch = false
        touchPulse = false
    }

    private func stop() {
        task?.cancel()
        task = nil
    }

    private func start() {
        stop()

        task = Task {
            while !Task.isCancelled {
                reset()

                try? await Task.sleep(for: .seconds(0.8))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    showTouch = true
                }

                // tap 1
                touchPulse = true
                try? await Task.sleep(for: .milliseconds(180))
                touchPulse = false

                try? await Task.sleep(for: .milliseconds(120))

                // tap 2
                touchPulse = true
                try? await Task.sleep(for: .milliseconds(180))
                touchPulse = false

                try? await Task.sleep(for: .milliseconds(200))

                isExpanded = true

                try? await Task.sleep(for: .seconds(1.8))
            }
        }
    }
}

// MARK: - Slide 3

private struct MultiSelectSlide: View {
    let isActive: Bool

    @State private var selectedCount = 0
    @State private var showPanel = false
    @State private var showAITap = false
    @State private var task: Task<Void, Never>?

    private let nodes: [Node] = [
        .init(name: "Ideas", detail: "", x: 0, y: 0, z: 0, color: "#FFFFFF"),
        .init(name: "Research", detail: "", x: 0, y: 0, z: 0, color: "#FFFFFF"),
        .init(name: "Tasks", detail: "", x: 0, y: 0, z: 0, color: "#FFFFFF")
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {

                ForEach(Array(nodes.enumerated()), id: \.offset) { index, node in
                    NodeView(
                        node: node,
                        isSelected: index < selectedCount,
                        isExpanded: false,
                        isMatchingSearch: false,
                        toolbarEnabled: false
                    )
                }

                if showPanel {
                    ZStack {
                        SelectedNodesPanel(
                            isDemo: true,
                            onDelete: {},
                            onAiEdit: {},
                            onDuplicate: {}
                        )
                        .frame(maxWidth: 400)

                        if showAITap {
                            AIHintTap()
                                .offset(x: 35, y: 0)
                                .zIndex(1)
                        }
                    }
                }
            }

            VStack(spacing: 12) {
                Text("Use AI with Context")
                    .font(.title.bold())

                Text("Select multiple nodes and let AI analyze, organize, or expand your ideas.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()
        }
        .onAppear {
            guard isActive else { return }
            start()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                start()
            } else {
                stop()
                reset()
            }
        }
    }

    private func reset() {
        selectedCount = 0
        showPanel = false
        showAITap = false
    }

    private func stop() {
        task?.cancel()
        task = nil
    }

    private func start() {
        stop()

        task = Task {
            while !Task.isCancelled {
                reset()

                try? await Task.sleep(for: .seconds(0.7))
                guard !Task.isCancelled else { return }

                selectedCount = 1
                try? await Task.sleep(for: .milliseconds(300))

                selectedCount = 2
                try? await Task.sleep(for: .milliseconds(300))

                selectedCount = 3
                try? await Task.sleep(for: .milliseconds(500))

                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    showPanel = true
                }

                try? await Task.sleep(for: .seconds(0.6))

                showAITap = true
                try? await Task.sleep(for: .milliseconds(180))
                showAITap = false

                try? await Task.sleep(for: .seconds(1.8))
            }
        }
    }
}

// MARK: - Touch Indicator

private struct TouchIndicator: View {
    let isActive: Bool

    var body: some View {
        Circle()
            .fill(Color.accentColorSecondary)
            .frame(width: 44, height: 44)
            .scaleEffect(isActive ? 1.6 : 0.5)
            .opacity(isActive ? 0 : 0.9)
            .animation(.easeOut(duration: 0.2), value: isActive)
    }
}

private struct AIHintTap: View {
    @State private var active = false

    var body: some View {
        Circle()
            .fill(Color.accentColorSecondary)
            .frame(width: 44, height: 44)
            .scaleEffect(active ? 1.6 : 0.6)
            .opacity(active ? 0 : 0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 0.18)) {
                    active = true
                }
            }
    }
}
