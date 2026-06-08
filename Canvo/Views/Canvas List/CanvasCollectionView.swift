//
//  CanvasGridView.swift
//  nodes-demo
//
//  Created by Oleg Komaristy on 17.11.2025.
//

import SwiftUI
internal import UniformTypeIdentifiers
#if os(visionOS)
import RealityKit
import RealityKitContent
#endif

private enum ActiveAlert: Identifiable {
    case delete(Canvas)
    case replace(Canvas)

    var id: String {
        switch self {
        case .delete(let canvas):
            return "delete-\(canvas.id)"
        case .replace(let canvas):
            return "replace-\(canvas.id)"
        }
    }
}

struct CanvasCollectionView: View {
    @AppStorage("isCompactPresentation") var isCompactPresentation: Bool = false
    
    @Environment(AppModel.self) var appModel
    @State var showCreateCanvas: Bool = false
    @State var renameCanvas: Canvas?
    
    @State private var showError: Bool = false
    @State private var errorMessage: String?
    
    @State private var selectedFilter: CanvasFilter = .all

    @State var searchQuery = ""
    
    @State private var isShowingPicker = false
    
    @State private var activeAlert: ActiveAlert?
    
    private let minCardWidth: CGFloat = 320
    private let listSpacing: CGFloat = 18
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
                )
                .searchToolbarBehavior(.minimize)
                .toolbar {
                    #if !os(visionOS)
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
                    #else
                    DefaultToolbarItem(kind: .search, placement: .topBarTrailing)
                    #endif

                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Menu {
                                Button {
                                    isCompactPresentation = false
                                } label: {
                                    if !isCompactPresentation {
                                        Label("Grid", systemImage: "checkmark")
                                    } else {
                                        Text("Grid")
                                    }
                                }
                                
                                Button {
                                    isCompactPresentation = true
                                } label: {
                                    if isCompactPresentation {
                                        Label("List", systemImage: "checkmark")
                                    } else {
                                        Text("List")
                                    }
                                }
                            } label: {
                                Label("Display mode", systemImage: isCompactPresentation ? "list.bullet" : "square.grid.2x2" )
                            }
                            
                            Divider()
                            
                            Button {
                                isShowingPicker.toggle()
                            } label: {
                                Label("Import Canvas", systemImage: "square.and.arrow.down")
                            }
                            
                        } label: {
                            Label("", systemImage: "ellipsis")
                        }
                        .menuStyle(.button)
                        .labelStyle(.iconOnly)
                    }
                }
        }
        .fileImporter(
            isPresented: $isShowingPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task {
                    await processImport(from: url)
                }
            case .failure(let failure):
                showError.toggle()
                errorMessage = "Import failed" + "\n" + failure.localizedDescription
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
        .alert(
            "Error",
            isPresented: $showError
        ) {
            Button("OK") {
                // Handle the acknowledgement.
            }
        } message: {
            Text(errorMessage ?? "Something went wrong")
        }
        .alert(item: $activeAlert) { alert in
            switch alert {

            case .replace(let canvas):
                return Alert(
                    title: Text("Replace \(canvas.name)?"),
                    message: Text("This cannot be undone."),
                    primaryButton: .destructive(Text("Replace")) {
                        appModel.replaceCanvasAction(canvas)
                    },
                    secondaryButton: .cancel()
                )

            case .delete(let canvas):
                return Alert(
                    title: Text("Delete Canvas"),
                    message: Text("Are you sure you want to delete \(canvas.name)?"),
                    primaryButton: .destructive(Text("Delete")) {
                        appModel.deleteCanvasIdAction(canvas.id)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onDisappear {
            appModel.aiGenerationService.cancelCurrentTask()
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
        VStack {
            if displayedCanvases.isEmpty {
                VStack {
                    CanvasTabsView(selectedFilter: $selectedFilter)
                    
                    #if os(visionOS)
                    Spacer()
                    #endif
                    
                    ContentUnavailableView {
                        Label(emptyStateConfig.title, systemImage: emptyStateConfig.systemImage)
                    } description: {
                        Text(emptyStateConfig.description)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    
                    #if os(visionOS)
                    Spacer()
                    #endif
                }
            } else {
                GeometryReader { geo in
                    let availableWidth = geo.size.width - horizontalPadding * 2
                    let columnCount = max(Int(availableWidth / minCardWidth), 1)
                    let cardWidth = (availableWidth - CGFloat(columnCount - 1) * gridSpacing) / CGFloat(columnCount)
                    
                    ScrollView {
                        CanvasTabsView(selectedFilter: $selectedFilter)
                        
                        if isCompactPresentation {
                            LazyVStack(spacing: listSpacing) {
                                ForEach(displayedCanvases) { canvas in
                                    canvasCard(for: canvas)
                                }
                            }
                            .padding(.horizontal, horizontalPadding)
                        } else {
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
            
            #if os(visionOS)
            HStack {
                Spacer()
                Button {
                    showCreateCanvas = true
                } label: {
                    Image(systemName: "plus")
                }
                .tint(.accent)
                .clipShape(Circle())
            }
            .safeAreaPadding()
            #endif
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
            if isCompactPresentation {
                CompactCanvasCardView(canvas: canvas)
                    .environment(appModel)
                    .hoverEffect(.lift)
                    
            } else {
                CanvasCardView(canvas: canvas)
                    .environment(appModel)
                    .hoverEffect(.lift)
            }
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
                self.activeAlert = .delete(canvas)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func processImport(from url: URL) async {
        do {
            if let canvas = try await appModel.tryImport(from: url) {
                if !appModel.canvases.contains(where: {
                    $0.id == canvas.id
                }) {
                    appModel.importCanvasAction(canvas)
                } else {
                    self.activeAlert = .replace(canvas)
                }
            }
            
        } catch {
            showError.toggle()
            errorMessage = "Import Failed" + "\n" + error.localizedDescription
        }
    }
}

#Preview {
    CanvasCollectionView()
}
