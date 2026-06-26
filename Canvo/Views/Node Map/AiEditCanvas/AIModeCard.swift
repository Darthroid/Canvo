//
//  AIModeCard.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//

import SwiftUI

struct AIModeCard: View {
    
    @EnvironmentObject private var themeStore: ThemeStore

    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool

    let action: () -> Void

    var body: some View {

        Button(action: action) {

            VStack(alignment: .leading, spacing: 10) {

                HStack(alignment: .firstTextBaseline, spacing: 8) {

                    Image(systemName: icon)
                        .font(.headline)
                        .symbolRenderingMode(.hierarchical)

                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(width: 160, height: 90, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .strokeBorder(
                                isSelected
                                ? themeStore.theme.canvasTheme.selection
                                : Color.clear,
                                lineWidth: 1.5
                            )
                    }
            }
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }
}
