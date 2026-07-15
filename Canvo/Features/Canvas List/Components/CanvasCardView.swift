//
//  CanvasCardView.swift
//  Canvo
//
//  Created by Олег Комаристый on 20.04.2026.
//

import SwiftUI

struct CanvasCardView: View {
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
            return date.formatted(.dateTime.day().month(.twoDigits).year().hour().minute())
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: Preview
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
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
                    VStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.secondary)

                        Text("Secured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .opacity(isPressed ? 0.85 : 1.0)
                } else {
                    Image("canvas_placeholder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .opacity(0.35)
                        .foregroundStyle(themeStore.theme.canvasTheme.selection)
                }
            }
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )

            // MARK: Meta
            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 8) {
                    if canvas.isPined {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(themeStore.theme.canvasTheme.selection)
                    }

                    Text(canvas.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer()
                }

                HStack {
                    Label(updatedAt, systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(String(localized: "\(canvas.nodes?.count ?? 0) nodes"))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
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
//        .scaleEffect(isPressed ? 0.98 : 1.0)
//        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isPressed)
//        .onTapGesture {}
//        .onLongPressGesture(
//            minimumDuration: 0.01,
//            pressing: { pressing in
//                isPressed = pressing
//            },
//            perform: {}
//        )
        .onAppear {
            previewImage = loadPreview(for: canvas)
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasPreviewUpdated)) { notification in
            guard
                let canvasId = notification.userInfo?["canvasId"] as? String,
                canvasId == canvas.id
            else { return }

            DispatchQueue.main.async {
                self.previewImage = loadPreview(for: canvas)
            }
        }
    }

    private func loadPreview(for canvas: Canvas) -> UIImage? {
        let url = appModel.previewService.getPreviewURL(for: canvas)
        return UIImage(contentsOfFile: url.path)
    }
}
