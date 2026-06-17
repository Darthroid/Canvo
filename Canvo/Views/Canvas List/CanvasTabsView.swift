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
    
    private var backgroundUIColor: UIColor {
        return UIColor(themeStore.theme.canvasTheme.selection)
    }

    private var titleColor: Color {
        Color(uiColor: backgroundUIColor.readableTextColor())
    }
    
    var body: some View {
        HStack {
            ForEach(CanvasFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        
                        Text(filter.title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(selectedFilter == filter ? titleColor : .primary)
                    }
                    .foregroundStyle(selectedFilter == filter ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if selectedFilter == filter {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(backgroundUIColor))
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}
