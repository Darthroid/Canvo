//
//  CompactCanvasCardView.swift
//  Canvo
//
//  Created by Олег Комаристый on 25.05.2026.
//

import UIKit
import SwiftUI

struct CompactCanvasCardView: View {
    let canvas: Canvas

    @State private var previewImage: UIImage?

    var updatedAt: String {
        let date = canvas.updatedAt

        if Calendar.current.isDateInToday(date) {
            return "Today, " + date.formatted(
                .dateTime.hour().minute()
            )
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday, " + date.formatted(
                .dateTime.hour().minute()
            )
        } else {
            return date.formatted(
                .dateTime.day()
                    .month(.twoDigits)
                    .year()
            )
        }
    }

    init(canvas: Canvas) {
        self.canvas = canvas
        self._previewImage = State(
            initialValue: Self.loadPreview(for: canvas)
        )
    }

    var body: some View {
        HStack(spacing: 16) {

            preview

            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 6) {
                    if canvas.isPined {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    Text(canvas.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                
                Label(updatedAt, systemImage: "calendar")
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(canvas.nodes?.count ?? 0) nodes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    Color(uiColor: .lightGray).opacity(0.1),
                    lineWidth: 1
                )
        )
        .onReceive(NotificationCenter.default.publisher(for: .canvasPreviewUpdated)) { notification in
            guard
                let canvasId = notification.userInfo?["canvasId"] as? String,
                canvasId == canvas.id
            else { return }

            previewImage = Self.loadPreview(for: canvas)
        }
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            if let previewImage {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.background)

                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .accentColorSecondary.opacity(0.3),
                                .accent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image("canvas_placeholder")
                    .resizable()
                    .frame(maxWidth: 36, maxHeight: 36)
                    .opacity(0.5)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.accentColorSecondary, .accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
        }
        .frame(width: 96, height: 72)
        .clipShape(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    private static func loadPreview(for canvas: Canvas) -> UIImage? {
        let url = CanvasPreviewService.shared.getPreviewURL(for: canvas)
        return UIImage(contentsOfFile: url.path)
    }
}
