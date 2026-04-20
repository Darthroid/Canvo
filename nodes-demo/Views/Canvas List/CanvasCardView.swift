//
//  CanvasCardView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 20.04.2026.
//

import SwiftUI

struct CanvasCardView: View {
    let canvas: Canvas
    
    @State private var previewURL: URL
    @State private var lastUpdateId = UUID()
    
    var updatedAt: String {
        let date = canvas.updatedAt
        if Calendar.current.isDateInToday(date) {
            return "Today, " + date.formatted(
                .dateTime
                    .hour()
                    .minute()
            )
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday, " + date.formatted(
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
    
    init(canvas: Canvas) {
        self.canvas = canvas
        self._previewURL = State(initialValue: CanvasPreviewService.shared.getPreviewURL(for: canvas))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Card header with gradient background
            ZStack {
                if CanvasPreviewService.shared.hasPreview(for: canvas) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.background)
                        .frame(height: 160)
                    
                    Image(contentsOfFile: previewURL.path())
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 160)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .id(lastUpdateId)
                } else {
                    // Background shape with fixed size
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.accentColorSecondary.opacity(0.3), .accent.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 160)
                    
                    Image("canvas_placeholder")
                        .resizable()
                        .frame(maxWidth: 80, maxHeight: 80)
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
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            
            // Card content
            VStack(alignment: .leading, spacing: 12) {
                // Canvas name
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
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                
                // Metadata footer
                HStack {
                    Label(updatedAt, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Node count badge
                    Text("\(canvas.nodes?.count ?? 0) nodes")
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
        .onReceive(NotificationCenter.default.publisher(for: .canvasPreviewUpdated)) { notification in
            if let canvasId = notification.userInfo?["canvasId"] as? String,
               canvasId == canvas.id {
                // Force update by changing the URL (append timestamp)
                let newURL = CanvasPreviewService.shared.getPreviewURL(for: canvas)
                self.previewURL = newURL
                self.lastUpdateId = UUID()
            }
        }
    }
}
