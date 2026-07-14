//
//  CanvasGridView.swift
//  nodes-demo
//
//  Created by Oleg Komaristy on 17.11.2025.
//

import SwiftUI
import UniformTypeIdentifiers
#if os(visionOS)
import RealityKit
import RealityKitContent
#endif

import CoreSpotlight
import LocalAuthentication

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
    @AppStorage("libraryViewStyle")
    private var viewStyle: LibraryViewStyle = .grid
    
    @Environment(AppModel.self) var appModel
    @EnvironmentObject private var themeStore: ThemeStore
    
    @State var showCreateCanvas: Bool = false
    @State var renameCanvas: Canvas?
    
    @State private var showError: Bool = false
    @State private var errorMessage: String?
    
    @State private var selectedFilter: CanvasFilter = .all

    @State var searchQuery = ""
    
    @State private var isShowingPicker = false
    
    @State private var activeAlert: ActiveAlert?
    
    @State private var showSettings: Bool = false
    
    // used when canvas created to open it immedeately
    @State private var navigationCanvas: Canvas?
    
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
                .ifAvailableIOS26(
                    new: {
                        if #available(iOS 26.0, *) {
                            $0.searchToolbarBehavior(.minimize)
                        }
                    },
                    fallback: {
                        $0
                    }
                )
                .navigationDestination(item: $navigationCanvas) { canvas in
                    NodeMapView()
                        .environment(appModel)
                        .environmentObject(themeStore)
                        .tint(themeStore.theme.canvasTheme.selection)
                        .id(themeStore.theme)
                }
                .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                    if let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
//                        appModel.switchToCanvas(identifier)
                        openCanvas(identifier)
                    }
                }
                .toolbar {
                    #if !os(visionOS)
                    if #available(iOS 26.0, *) {
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
                            .tint(themeStore.theme.canvasTheme.selection)
                            .id(themeStore.theme)
                        }
                    }
                    #else
                    if #available(iOS 26.0, *) {
                        DefaultToolbarItem(kind: .search, placement: .topBarTrailing)
                    }
                    #endif

                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                isShowingPicker.toggle()
                            } label: {
                                Label("Import Canvas", systemImage: "square.and.arrow.down")
                            }
                            
                            Divider()
                            
                            Button {
                                showSettings.toggle()
                            } label: {
                                Label("Settings", systemImage: "gearshape")
                            }
                            
                        } label: {
                            Label("", systemImage: "ellipsis")
                        }
                        .menuStyle(.button)
                        .labelStyle(.iconOnly)
                        .tint(themeStore.theme.canvasTheme.selection)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if #unavailable(iOS 26.0) {
                        Button {
                            showCreateCanvas = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .frame(width: 40, height: 40)
                        }
                        .buttonStyle(.borderedProminent)
                        .clipShape(Circle())
                        .tint(themeStore.theme.canvasTheme.selection)
                        .padding()
                    }
                }
        }
        .id(themeStore.theme)
        .fileImporter(
            isPresented: $isShowingPicker,
            allowedContentTypes: ImportService.supportedFormats,
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
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .environment(appModel)
                    .environmentObject(themeStore)
                    .preferredColorScheme(
                        themeStore.theme.colorScheme
                    )
                    .tint(themeStore.theme.canvasTheme.selection)
                    .id(themeStore.theme)
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
            String(localized: "Error"),
            isPresented: $showError
        ) {
            Button("OK") {
                // Handle the acknowledgement.
            }
        } message: {
            Text(errorMessage ?? String(localized: "Something went wrong"))
        }
        .alert(item: $activeAlert) { alert in
            switch alert {

            case .replace(let canvas):
                return Alert(
                    title: Text("Replace \(canvas.name)?"),
                    message: Text("This cannot be undone."),
                    primaryButton: .destructive(Text("Replace")) {
                        appModel.replaceCanvas(canvas)
                    },
                    secondaryButton: .cancel()
                )

            case .delete(let canvas):
                return Alert(
                    title: Text("Delete Canvas"),
                    message: Text("Are you sure you want to delete \(canvas.name)?"),
                    primaryButton: .destructive(Text("Delete")) {
                        appModel.deleteCanvas(canvas.id)
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onChange(of: appModel.session.currentCanvas) { _, newValue in
            navigationCanvas = newValue
        }
        .onDisappear {
            if #available(iOS 26.0, *) {
                appModel.aiGenerationService.cancelCurrentTask()
            }
        }
        .environment(
            \.canvasTheme,
             themeStore.theme.canvasTheme
        )
        .preferredColorScheme(
            themeStore.theme.colorScheme
        )
    }
    
    private var emptyStateConfig: (title: String, systemImage: String, description: String) {
        switch selectedFilter {
        case .all:
            return (
                searchQuery.isEmpty ? String(localized: "No Canvases Yet") : String(localized: "No Results"),
                searchQuery.isEmpty ? "rectangle.3.group" : "magnifyingglass",
                searchQuery.isEmpty ? String(localized: "Create a canvas manually or generate one with AI") : String(localized: "Try adjusting your search")
            )

        case .recent:
            return (
                String(localized: "No Recent Canvases"),
                "clock",
                String(localized: "Your recently edited canvases will show up here automatically")
            )

        case .favorites:
            return (
                String(localized: "No Favorites"),
                "star",
                String(localized: "Save important canvases for quick access anytime")
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
                        
                        if viewStyle == .list {
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
                .tint(themeStore.theme.canvasTheme.selection)
                .clipShape(Circle())
            }
            .safeAreaPadding()
            #endif
        }
        
    }
    
    @ViewBuilder func canvasCard(for canvas: Canvas) -> some View {
        Button {
//            appModel.switchToCanvas(canvas)
            openCanvas(canvas)
        } label: {
            if viewStyle == .list {
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
                appModel.toggleCanvasPin(canvas)
            } label: {
                Label(canvas.isPined ? "Remove from Favorites" : "Favorite", systemImage: canvas.isPined ? "star.slash" : "star")
            }
            Button {
                self.renameCanvas = canvas
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            
            Button {
                authenticateForCanvas { success in
                    if success {
                        appModel.toggleCanvasSecured(canvas)
                    }
                }
            } label: {
                Label(
                    canvas.isSecured ? "Disable Protection" : "Protect",
                    systemImage: canvas.isSecured ? "lock.open" : "lock"
                )
            }
            
            Button(role: .destructive) {
                self.activeAlert = .delete(canvas)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
    
    func processImport(from url: URL) async {
        do {
            if let canvas = try await appModel.tryImport(from: url) {
                if !appModel.canvases.contains(where: {
                    $0.id == canvas.id
                }) {
                    appModel.importCanvas(canvas)
                } else {
                    self.activeAlert = .replace(canvas)
                }
            }
            
        } catch {
            showError.toggle()
            errorMessage = String(localized: "Import Failed") + "\n" + error.localizedDescription
        }
    }
    
    private func authenticateForCanvas(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false)
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Access to protected canvas"
        ) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    private func openCanvas(_ id: String) {
        guard let canvas = appModel.canvas(forId: id) else { return }
        openCanvas(canvas)
    }
    
    private func openCanvas(_ canvas: Canvas) {
        if canvas.isSecured {
            authenticateForCanvas { success in
                if success {
                    appModel.switchToCanvas(canvas)
                }
            }
        } else {
            appModel.switchToCanvas(canvas)
        }
    }
}

#Preview {
    CanvasCollectionView()
}
