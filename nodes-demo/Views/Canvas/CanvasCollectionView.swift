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

struct CanvasSectionHeaderView: View {
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "pin.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(title.uppercased())
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}


struct CanvasCollectionView: View {
    @Environment(AppModel.self) var appModel
    @State var showCreateCanvas: Bool = false
    @State var selectedCanvas: Canvas?
    
    private let minCardWidth: CGFloat = 320
    private let gridSpacing: CGFloat = 24
    private let horizontalPadding: CGFloat = 24
    
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
            NameCanvasView(isCreating: true, onSubmit: { name in
                appModel.createCanvas(name: name)
            })
            .environment(appModel)
        }
        .sheet(item: $selectedCanvas) { canvas in
            NameCanvasView(name: canvas.name, isCreating: false, onSubmit: { name in
                appModel.renameCanvas(id: canvas.id, name: name)
            })
            .environment(appModel)
        }
    }
    
    var canvasesGrid: some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width - horizontalPadding * 2
            let columnCount = max(Int(availableWidth / minCardWidth), 1)
            let cardWidth = (availableWidth - CGFloat(columnCount - 1) * gridSpacing) / CGFloat(columnCount)

            if appModel.canvases.isEmpty {
                ContentUnavailableView(
                    "No Canvases",
                    systemImage: "rectangle.split.3x3",
                    description: Text("Tap the + button to create your first canvas")
                )
                .zIndex(1)
            } else {
                ScrollView {
                    if appModel.canvases.contains(where: { $0.isPined }) {

                        CanvasSectionHeaderView(title: "Pinned")
                            .padding(.horizontal, horizontalPadding)

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(
                                rows: [GridItem(.fixed(cardWidth))],
                                spacing: gridSpacing
                            ) {
                                ForEach(appModel.canvases.filter(\.isPined)) { canvas in
                                    canvasCard(for: canvas)
                                        .frame(width: cardWidth)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                        }

                        Divider()
                            .padding(.horizontal, horizontalPadding)
                    }

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.fixed(cardWidth), spacing: gridSpacing),
                            count: columnCount
                        ),
                        spacing: gridSpacing
                    ) {
                        ForEach(appModel.canvases.filter { !$0.isPined }) { canvas in
                            canvasCard(for: canvas)
                                .frame(width: cardWidth)
                        }
                    }
                    .padding(horizontalPadding)
                }
            }
        }
    }

    
    @ViewBuilder func canvasCard(for canvas: Canvas) -> some View {
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
            Button {
                appModel.setPin(!canvas.isPined, forCanvas: canvas)
            } label: {
                Label(canvas.isPined ? "Unpin" : "Pin", systemImage: canvas.isPined ? "pin.slash" : "pin")
            }
            Button {
                self.selectedCanvas = canvas
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
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

#Preview {
    CanvasCollectionView()
}
