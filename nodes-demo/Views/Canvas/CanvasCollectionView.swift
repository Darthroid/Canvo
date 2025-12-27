//
//  CanvasGridView.swift
//  nodes-demo
//
//  Created by Oleg Komaristy on 17.11.2025.
//

import SwiftUI
#if os(visionOS)
import RealityKit
import RealityKitContent
#endif

struct CanvasCollectionView: View {
    @Environment(AppModel.self) var appModel
    @State var showCreateCanvas: Bool = false
    @State private var gridLayout = [GridItem(.adaptive(minimum: 280), spacing: 20)]
    
    var body: some View {
        NavigationStack {
            canvasesGrid
                .navigationTitle("Nodes Demo")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCreateCanvas = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
        .sheet(isPresented: $showCreateCanvas) {
            CreateCanvasView()
                .environment(appModel)
        }
    }
    
    var canvasesGrid: some View {
        ZStack {
            if appModel.canvases.isEmpty {
                ContentUnavailableView(
                    "No Canvases",
                    systemImage: "rectangle.split.3x3",
                    description: Text("Tap the + button to create your first canvas")
                )
                .zIndex(1)
            }
            
            ScrollView {
                LazyVGrid(columns: gridLayout, spacing: 24) {
                    ForEach(appModel.canvases) { canvas in
                        NavigationLink {
                            NodeMapView()
                                .environment(appModel)
                                .onAppear {
                                    appModel.switchToCanvas(canvas)
                                }
                        } label: {
                            CanvasCardView(canvas: canvas)
                                .hoverEffect(.highlight)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                if let index = appModel.canvases.firstIndex(where: { $0.id == canvas.id }) {
                                    appModel.removeCanvas(at: IndexSet([index]))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
    }
}

struct CanvasCardView: View {
    let canvas: Canvas
    
    @State private var previewURL: URL
    @State private var lastUpdateId = UUID()
    
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
                        .scaledToFill()
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
                                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 160)
                    
                    // Canvas icon (fallback when no preview exists)
                    Image(systemName: "rectangle.split.3x3")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
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
                Text(canvas.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Metadata footer
                HStack {
                    Label(
                        canvas.updatedAt.formatted(.dateTime.day().month().year().hour().minute()),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Node count badge
                    Label("\(canvas.nodes.count) nodes", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(canvas.nodes.count > 0 ? .blue : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(canvas.nodes.count > 0 ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        )
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
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .frame(height: 320)
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

#Preview {
    CanvasCollectionView()
}
