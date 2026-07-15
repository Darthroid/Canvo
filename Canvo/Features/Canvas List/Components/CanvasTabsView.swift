//
//  CanvasTabsView.swift
//  Canvo
//
//  Created by Олег Комаристый on 05.06.2026.
//

import SwiftUI

enum CanvasFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case recent = "Recent"
    case favorites = "Favorites"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return String(localized: "All")
        case .recent:
            return String(localized: "Recent")
        case .favorites:
            return String(localized: "Favorites")
        }
    }
}

struct CanvasTabsView: View {
    @Binding var selectedFilter: CanvasFilter
    @EnvironmentObject private var themeStore: ThemeStore

    private var accent: Color {
        themeStore.theme.canvasTheme.selection
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(CanvasFilter.allCases) { filter in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        selectedFilter = filter
                    }
                } label: {
                    tab(filter)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func tab(_ filter: CanvasFilter) -> some View {
        let isSelected = selectedFilter == filter

        Text(filter.title)
            .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                        ? accent.opacity(0.18)
                        : Color.clear
                    )
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(.ultraThinMaterial.opacity(0.6))
                        }
                    }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected
                        ? accent.opacity(0.35)
                        : .white.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isSelected ? 1.03 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.85), value: selectedFilter)
    }
}
