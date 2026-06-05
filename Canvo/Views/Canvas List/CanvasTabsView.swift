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
}


struct CanvasTabsView: View {
    @Binding var selectedFilter: CanvasFilter
    
    var body: some View {
        HStack {
            ForEach(CanvasFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        
                        Text(filter.rawValue)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(selectedFilter == filter ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if selectedFilter == filter {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentColor)
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
