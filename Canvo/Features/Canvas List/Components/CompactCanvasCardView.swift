//
//  CompactCanvasCardView.swift
//  Canvo
//
//  Created by Олег Комаристый on 25.05.2026.
//

import UIKit
import SwiftUI

struct CompactCanvasCardView: View {
    @Environment(AppModel.self) private var appModel
    @EnvironmentObject private var themeStore: ThemeStore

    let canvas: Canvas

    @State private var previewImage: UIImage?
    @State private var isPressed: Bool = false

    private var shouldHidePreview: Bool {
        canvas.isSecured
    }

    var updatedAt: String {
        let date = canvas.updatedAt

        if Calendar.current.isDateInToday(date) {
            return "Today, " + date.formatted(.dateTime.hour().minute())
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday, " + date.formatted(.dateTime.hour().minute())
        } else {
            return date.formatted(.dateTime.day().month(.twoDigits).year())
        }
    }

    var body: some View {
        HStack(spacing: 14) {

            preview

            VStack(alignment: .leading, spacing: 8) {

                HStack(spacing: 6) {
                    if canvas.isPined {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(themeStore.theme.canvasTheme.selection)
                    }

                    Text(canvas.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                Label(updatedAt, systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(canvas.nodes?.count ?? 0) nodes")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.06),
                                    .clear,
                                    .black.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
//        .scaleEffect(isPressed ? 0.985 : 1.0)
//        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isPressed)
//        .onLongPressGesture(
//            minimumDuration: 0.01,
//            pressing: { pressing in
//                isPressed = pressing
//            },
//            perform: {}
//        )
        .onAppear {
            loadPreview(for: canvas)
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasPreviewUpdated)) { notification in
            guard
                let canvasId = notification.userInfo?["canvasId"] as? String,
                canvasId == canvas.id
            else { return }

            loadPreview(for: canvas)
        }
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themeStore.theme.canvasTheme.background.opacity(0.9))
                .overlay {
                    LinearGradient(
                        colors: [
                            .white.opacity(0.08),
                            .clear,
                            .black.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

            if shouldHidePreview {
                VStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text("Secured")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

            } else if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .clipped()
                    .opacity(isPressed ? 0.85 : 1.0)

            } else {
                Image("canvas_placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .opacity(0.35)
            }
        }
        .frame(width: 92, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func loadPreview(for canvas: Canvas) {
        let url = appModel.previewService.getPreviewURL(for: canvas)

        Task.detached(priority: .utility) {
            guard let image = UIImage(contentsOfFile: url.path) else { return }

            await MainActor.run {
                self.previewImage = image
            }
        }
    }
}
