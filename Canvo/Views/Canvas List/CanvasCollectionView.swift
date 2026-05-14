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
//            Picker("", selection: $selectedFilter) {
//                ForEach(CanvasFilter.allCases) { filter in
//                    Text(filter.rawValue).tag(filter)
//                }
//            }
//            .pickerStyle(.segmented)
//            .fixedSize()
            ForEach(CanvasFilter.allCases) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 6) {
                        
                        Text(filter.rawValue)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(selectedFilter == filter ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if selectedFilter == filter {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentColor)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.secondarySystemBackground))
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                
            }
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
                .searchToolbarBehavior(.minimize)
                .toolbar {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            showCreateCanvas = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .clipShape(Capsule())
                        .tint(.accent)
                    }
                }
        }
        .sheet(isPresented: $showCreateCanvas) {
            EditCanvasView(mode: .create)
                .environment(appModel)
        }
        .sheet(item: $renameCanvas) { canvas in
            EditCanvasView(mode: .edit, editCanvas: canvas)
                .environment(appModel)
        }
        .alert(item: $deleteCanvas) { canvas in
            Alert(
                title: Text("Delete Canvas"),
                message: Text("Are you sure you want to delete \(canvas.name)? This cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    
                    if let id = appModel.canvases.first(where: { $0.id == canvas.id })?.id {
                        appModel.deleteCanvasIdAction(id)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        
    }
    
    private var emptyStateConfig: (title: String, systemImage: String, description: String) {
        switch selectedFilter {
        case .all:
            return (
                searchQuery.isEmpty ? "No Canvases Yet" : "No Results",
                searchQuery.isEmpty ? "rectangle.3.group" : "magnifyingglass",
                searchQuery.isEmpty ? "Create a canvas manually or generate one with AI" : "Try adjusting your search"
            )

        case .recent:
            return (
                "No Recent Canvases",
                "clock",
                "Your recently edited canvases will show up here automatically"
            )

        case .favorites:
            return (
                "No Favorites",
                "star",
                "Save important canvases for quick access anytime"
            )
        }
    }
    
    @ViewBuilder
    var canvasesGrid: some View {
        if displayedCanvases.isEmpty {
            VStack {
                CanvasTabsView(selectedFilter: $selectedFilter)
                ContentUnavailableView {
                    Label(emptyStateConfig.title, systemImage: emptyStateConfig.systemImage)
                } description: {
                    Text(emptyStateConfig.description)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
        } else {
            GeometryReader { geo in
                let availableWidth = geo.size.width - horizontalPadding * 2
                let columnCount = max(Int(availableWidth / minCardWidth), 1)
                let cardWidth = (availableWidth - CGFloat(columnCount - 1) * gridSpacing) / CGFloat(columnCount)
                ScrollView {
                    CanvasTabsView(selectedFilter: $selectedFilter)
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
                appModel.toggleCanvasPinAction(canvas)
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

#Preview {
    CanvasCollectionView()
}
