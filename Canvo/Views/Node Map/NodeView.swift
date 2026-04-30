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
    let isMatchingSearch: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var showDetail: Bool = false
    @State private var dashPhase: CGFloat = 0

    private var backgroundUIColor: UIColor {
        node.color ?? UIColor.systemBackground
    }

    private var titleColor: Color {
        Color(
            uiColor: backgroundUIColor.readableTextColor(
                isDarkMode: colorScheme == .dark
            )
        )
    }

    private var secondaryColor: Color {
        titleColor.opacity(0.75)
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                Text(node.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)

                if isSelected {
                    Text(node.detail.isEmpty ? "No description" : node.detail)
                        .font(.system(size: 14))
                        .foregroundColor(secondaryColor)
                        .multilineTextAlignment(.center)
                }
            }

            if isSelected {
                Button {
                    showDetail.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(titleColor.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(uiColor: backgroundUIColor))
                .overlay(
                    Group {
                        if isMatchingSearch {
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    Color.blue,
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
                                .stroke(titleColor.opacity(0.2), lineWidth: 1)
                        }
                    }
                )
        )
        .frame(maxWidth: 400)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                NodeDetailView(node: node)
            }
        }
    }
}
