//
//  AIModeCard.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//

import SwiftUI

// MARK: - Mode Card

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct AIModeCard: View {

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
            .frame(width: 160, height: 118, alignment: .topLeading)
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
