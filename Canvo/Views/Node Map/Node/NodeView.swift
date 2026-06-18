//
//  NodeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.01.2026.
//

import SwiftUI

struct NodeView: View {
    let node: Node
    let isSelected: Bool
    let isExpanded: Bool
    let isMatchingSearch: Bool
    let toolbarEnabled: Bool
    var onSizeChange: ((CGSize) -> Void)?

    @EnvironmentObject var themeStore: ThemeStore

    var onDetail: (() -> Void)?
    var onLink: (() -> Void)?
    var onDelete: (() -> Void)?

    @State private var dashPhase: CGFloat = 0

    private var backgroundUIColor: UIColor {
        if let color = node.color {
            return color
        }

        return UIColor(themeStore.theme.canvasTheme.nodeBackground)
    }

    private var titleColor: Color {
        Color(uiColor: backgroundUIColor.readableTextColor())
    }

    private var secondaryColor: Color {
        titleColor.opacity(0.75)
    }

    private var borderColor: Color {
        if node.color != nil {
            return titleColor.opacity(0.2)
        }

        return themeStore.theme.canvasTheme.nodeBorder.opacity(0.2)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {

                if let data = node.coverImageData,
                   let uiImage = decodeCover(data) {

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .clipped()
                        .padding(.top, 4)
                }

                Text(node.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)

                if isExpanded {
                    if node.richText.characters.isEmpty {
                        Text("No description")
                            .font(.system(size: 14))
                            .foregroundColor(secondaryColor)
                    } else {
                        Text(node.richText)
                            .foregroundStyle(titleColor)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, isExpanded ? 64 : 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(uiColor: backgroundUIColor))
                .overlay {
                    if isMatchingSearch {
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                themeStore.theme.canvasTheme.selection,
                                style: StrokeStyle(
                                    lineWidth: 3,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: [6, 6],
                                    dashPhase: dashPhase
                                )
                            )
                            .onAppear {
                                dashPhase = 0

                                withAnimation(
                                    .linear(duration: 1.2)
                                    .repeatForever(autoreverses: false)
                                ) {
                                    dashPhase = -24
                                }
                            }
                            .onDisappear {
                                dashPhase = 0
                            }
                    } else {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                isSelected ? themeStore.theme.canvasTheme.selection : borderColor,
                                lineWidth: isSelected ? 2 : 1
                            )
                    }
                }
        )
        .background {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        onSizeChange?(proxy.size)
                    }
                    .onChange(of: proxy.size) { _, newSize in
                        onSizeChange?(newSize)
                    }
            }
        }
        .overlay(alignment: .bottom) {
            if isExpanded, toolbarEnabled {
                floatingToolbar
                    .padding(.horizontal, 20)
                    .offset(y: 22)

                #if os(visionOS)
                    .frame(minWidth: 400)
                #endif
            }
        }
        .frame(maxWidth: 400, maxHeight: 600)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .zIndex(isSelected || isExpanded ? 1 : 0)
    }

    private var floatingToolbar: some View {
        HStack(spacing: 10) {
            toolbarButton(
                icon: "info.circle",
                action: {
                    onDetail?()
                }
            )

            toolbarButton(
                icon: "link",
                action: {
                    onLink?()
                }
            )

            toolbarButton(
                icon: "trash",
                isDestructive: true,
                action: {
                    onDelete?()
                }
            )
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func toolbarButton(
        icon: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isDestructive ? .red : .primary)
                .frame(width: 36, height: 36)
                .background(titleColor.opacity(0.08))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NodeView(
        node: .init(
            name: "Project Roadmap",
            detail: """
            Detail information about the title node goes here.
            It can contain several lines of text and is shown only when expanded.
            """,
            x: 0,
            y: 0,
            z: 0,
            color: "#a94fed"
        ),
        isSelected: false,
        isExpanded: true,
        isMatchingSearch: false,
        toolbarEnabled: true
    )
}
