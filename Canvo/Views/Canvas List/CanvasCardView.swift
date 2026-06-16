//
//  CanvasCardView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 20.04.2026.
//

import SwiftUI

struct CanvasCardView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.canvasTheme) private var theme

    let canvas: Canvas

    @State private var previewImage: UIImage?
    
    private var shouldHidePreview: Bool {
        canvas.isSecured
    }

    var updatedAt: String {
        let date = canvas.updatedAt

        if Calendar.current.isDateInToday(date) {
            return String(localized: "Today, ") + date.formatted(
                .dateTime
                    .hour()
                    .minute()
            )
        } else if Calendar.current.isDateInYesterday(date) {
            return String(localized: "Yesterday, ") + date.formatted(
                .dateTime
                    .hour()
                    .minute()
            )
        } else {
            return date.formatted(
                .dateTime
                    .day()
                    .month(.twoDigits)
                    .year()
                    .hour()
                    .minute()
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                if shouldHidePreview {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            theme.background
                        )
                        .frame(height: 160)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(theme.connector)
                } else if let previewImage {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
//                        #if os(visionOS)
//                        .fill(Color("MapBackground").opacity(0.8))
//                        #else
//                        .fill(.background)
//                        #endif
                        .fill(theme.background)
                        .frame(height: 160)

                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 160)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            theme.background
                        )
                        .frame(height: 160)

                    Image("canvas_placeholder")
                        .resizable()
                        .frame(maxWidth: 80, maxHeight: 80)
                        .opacity(0.5)
                        .foregroundStyle(
                            theme.selection
                        )
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if canvas.isPined {
                        Image(systemName: "star.fill")
                            .font(.callout)
                            .foregroundStyle(.blue)
                    }

                    Text(canvas.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack {
                    Label(updatedAt, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(String(localized: "\(canvas.nodes?.count ?? 0) nodes"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color(uiColor: .lightGray).opacity(0.1), lineWidth: 1)
        )
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
