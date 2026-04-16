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

struct CanvasTabsView: View {
    @Binding var selectedFilter: CanvasFilter
    
    var body: some View {
        HStack {
            Picker("", selection: $selectedFilter) {
                ForEach(CanvasFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}

enum CanvasFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case recent = "Recent"
    case favorites = "Favorites"
    
    var id: String { rawValue }
}

struct CanvasCollectionView: View {
    @Environment(AppModel.self) var appModel
    @State var showCreateCanvas: Bool = false
    @State var showAICreateCanvas: Bool = false
    @State var renameCanvas: Canvas?
    @State var deleteCanvas: Canvas?
    
    @State private var selectedFilter: CanvasFilter = .all

    @State var searchQuery = ""
    
    private let minCardWidth: CGFloat = 320
    private let gridSpacing: CGFloat = 24
    private let horizontalPadding: CGFloat = 24
    
    var displayedCanvases: [Canvas] {
        var result = appModel.canvases
        
        // 1. Filter by tab
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            result = result.filter { $0.isPined }
        case .recent:
            result = result
                .filter { $0.updatedAt.isWithinWeek() }
                .sorted { $0.updatedAt > $1.updatedAt }
        }
        
        // 2. Search
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            canvasesGrid
                .navigationTitle(Text("Canvo"))
                .navigationBarTitleDisplayMode(.large)
                .searchable(
                    text: $searchQuery,
//                    prompt: "Search canvases"
                )
//                .toolbar {
//                    ToolbarItemGroup(placement: .primaryAction) {
//                        Button {
//                            showCreateCanvas = true
//                        } label: {
//                            Image(systemName: "plus")
//                        }
//                        if #available(iOS 26, macOS 26, visionOS 26, *),
//                           AIGenerationService.shared.isAvailable {
//                            Button {
//                                showAICreateCanvas = true
//                            } label: {
//                                Image(systemName: "apple.intelligence")
//                            }
//                        }
//                    }
//                }
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Spacer()
                        
                        Button {
                            showCreateCanvas = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(Color.accentColor)
                                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                                )
                        }
                        .glassEffect()
                        .padding(.trailing, 20)
                        .padding(.bottom, 8)
                    }
                }
        }
        .sheet(isPresented: $showAICreateCanvas) {
            if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                AICreateCanvasView()
            }
        }
        .sheet(isPresented: $showCreateCanvas) {
            NameCanvasView(isCreating: true, onSubmit: { name in
                appModel.createCanvas(name: name)
            })
            .environment(appModel)
        }
        .sheet(item: $renameCanvas) { canvas in
            NameCanvasView(name: canvas.name, isCreating: false, onSubmit: { name in
                appModel.renameCanvas(id: canvas.id, name: name)
            })
            .environment(appModel)
        }
        .alert(item: $deleteCanvas) { canvas in
            Alert(
                title: Text("Delete Canvas"),
                message: Text("Are you sure you want to delete \(canvas.name)? This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    if let index = appModel.canvases.firstIndex(where: { $0.id == canvas.id }) {
                        appModel.removeCanvas(at: IndexSet([index]))
                    }
                },
                secondaryButton: .cancel()
            )
        }
        
    }
    
    var canvasesGrid: some View {
        VStack {
            CanvasTabsView(selectedFilter: $selectedFilter)
            GeometryReader { geo in
                let availableWidth = geo.size.width - horizontalPadding * 2
                let columnCount = max(Int(availableWidth / minCardWidth), 1)
                let cardWidth = (availableWidth - CGFloat(columnCount - 1) * gridSpacing) / CGFloat(columnCount)

                if displayedCanvases.isEmpty {
                    ContentUnavailableView(
                        searchQuery.isEmpty ? "No Canvases" : "Nothing found",
                        systemImage: searchQuery.isEmpty ? "rectangle.split.3x3" : "exclamationmark.magnifyingglass",
                        description: Text(
                            searchQuery.isEmpty
                            ? "Tap the + button to create your first canvas"
                            : "Try changing the request"
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }  else {
                    ScrollView {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.fixed(cardWidth), spacing: gridSpacing),
                                count: columnCount
                            ),
                            spacing: gridSpacing
                        ) {
                            ForEach(displayedCanvases) { canvas in
                                canvasCard(for: canvas)
                                    .frame(width: cardWidth)
                            }
                        }
                        .padding(horizontalPadding)
                    }
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
                Label(canvas.isPined ? "Remove from Favorites" : "Favorite", systemImage: canvas.isPined ? "star.slash" : "star")
            }
            Button {
                self.renameCanvas = canvas
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                self.deleteCanvas = canvas
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
                                colors: [.accentColorSecondary.opacity(0.3), .accentColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 160)
                    
                    // Canvas icon (fallback when no preview exists)
//                    Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
//                        .font(.system(size: 48, weight: .medium))
                    Image("canvas_placeholder")
                        .resizable()
                        .frame(maxWidth: 80, maxHeight: 80)
                        .opacity(0.5)
                        .foregroundStyle(
                            .linearGradient(
                                colors: [.accentColorSecondary, .accentColor],
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
                Text(canvas.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Metadata footer
                HStack {
                    Label(
                        canvas.updatedAt
                            .formatted(
                                .dateTime
                                .day()
                                .month(.twoDigits)
                                .year()
                                .hour()
                                .minute()
                            ),
                        systemImage: "calendar"
                    )
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

#Preview {
    CanvasCollectionView()
}
