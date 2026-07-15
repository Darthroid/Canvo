import SwiftUI
import SwiftData
import StoreKit

struct NodeMapView: View {
    @Environment(AppModel.self) var appModel
    
    @AppStorage("hasSeenCanvasOnboarding")
    private var hasSeenCanvasOnboarding: Bool = false
    
    @AppStorage("applyThemeToExports")
    var applyThemeToExports = true
    
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass
    
    @Environment(\.verticalSizeClass)
    private var verticalSizeClass
    
    @Environment(\.openWindow)
    private var openWindow
    
    @EnvironmentObject var themeStore: ThemeStore
    
    #if os(visionOS)
    @Environment(\.pushWindow)
    private var pushWindow
    #endif
    @Environment(\.dismissWindow)
    private var dismissWindow
    
    var isCompact: Bool {
        return horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
#if os(visionOS)
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
#endif
        
    @State private var nodeSizes: [String: CGSize] = [:]
    
    @State var scale: CGFloat = 1.0
    @State var baseScale: CGFloat = 1.0
    @State var offset: CGSize = .zero
    @State var lastPanTranslation: CGSize = .zero
    @State var lastDragTranslation: CGSize = .zero
    
    @State private var showGrid = true
    
    @State private var showNodeForm = false
    @State private var showtagsFilter: Bool = false
    
    @State private var containerSize: CGSize = .zero
    
    @State private var searchPresented = false
    @State private var searchText = ""
    @State private var searchResults: [Node] = []
    @State private var selectedSearchResultIndex = 0
    @FocusState private var isSearchFieldFocused: Bool
    
    @State private var showDetailNode: Node?
    @State private var showLinkToNode: Node?
    @State private var showDeleteNode: Node?
    
    @State var showZoomLevel = false

    let searchAnimationDuration: Double = 0.5
    
    @State var generatedPreview: UIImage?
    @State var generatedJSON: Data?
    @State var generatedMarkdown: Data?
    @State var generatedMarkdownPackage: URL?
    @State var showShareSheet = false
    @State var selectedFormat: ExportFormat = .png

    @AppStorage("screenDismissCount")
    private var screenDismissCount = 0
    
    private var updatedAt: String? {
        guard let date = appModel.session.currentCanvas?.updatedAt else { return nil }
        
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
    
    // MARK: Notifications
    private var zoomIn = NotificationCenter.default.publisher(for: .init("zoomin"))
    private var zoomOut = NotificationCenter.default.publisher(for: .init("zoomout"))
    private var resetZoom = NotificationCenter.default.publisher(for: .init("resetzoom"))
    private var outline = NotificationCenter.default.publisher(for: .init("outline"))
    private var toggleGrid = NotificationCenter.default.publisher(for: .init("togglegrid"))
    
    private func visibleCenterPosition() -> SIMD3<Float> {
        let screenCenterX = containerSize.width / 2
        let screenCenterY = containerSize.height / 2
        
        let canvasX = (screenCenterX - offset.width) / scale
        let canvasY = (screenCenterY - offset.height) / scale
        
        return SIMD3(Float(canvasX), Float(canvasY), 0)
    }
    
    // Функция для центрирования ноды
    private func centerOnNode(_ node: Node, animated: Bool = true) {
        let nodePosition = node.position.position2D
        
        // Центр экрана
        let screenCenterX = containerSize.width / 2
        let screenCenterY = containerSize.height / 2
        
        // Вычисляем нужный offset для центрирования ноды
        // Формула: offset = screenCenter - nodePosition * scale
        let targetOffset = CGSize(
            width: screenCenterX - nodePosition.x * scale,
            height: screenCenterY - nodePosition.y * scale
        )
        
        if animated {
            withAnimation(.easeInOut(duration: searchAnimationDuration)) {
                offset = targetOffset
            }
        } else {
            offset = targetOffset
        }
        
        // Выделяем ноду
        appModel.session.selectedNodeIds = [node.id]
    }
    
    // Функция поиска нод
    private func performSearch() {
        if searchText.isEmpty {
            searchResults = []
            return
        }
        
        let query = searchText.lowercased()
        searchResults = appModel.nodes.filter { node in
            !node.isHidden &&
            (node.name.lowercased().contains(query) ||
             node.detail.lowercased().contains(query))
        }
        
        selectedSearchResultIndex = 0
        if let firstResult = searchResults.first {
            centerOnNode(firstResult)
        }
    }
    
    // Переход к следующему результату поиска
    private func goToNextSearchResult() {
        guard !searchResults.isEmpty else { return }
        
        selectedSearchResultIndex = (selectedSearchResultIndex + 1) % searchResults.count
        if let node = searchResults[safe: selectedSearchResultIndex] {
            centerOnNode(node)
        }
    }
    
    // Переход к предыдущему результату поиска
    private func goToPreviousSearchResult() {
        guard !searchResults.isEmpty else { return }
        
        selectedSearchResultIndex = (selectedSearchResultIndex - 1 + searchResults.count) % searchResults.count
        if let node = searchResults[safe: selectedSearchResultIndex] {
            centerOnNode(node)
        }
    }
    
    private var focusPanel: some View {
        HStack(spacing: 24) {
            
            Text("Focus mode")

            Button {
                appModel.session.focusMode = nil
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .labelsHidden()
            #if os(visionOS)
            .clipShape(Circle())
            #endif
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        #if !os(visionOS)
        .adaptiveGlass()
        #else
        .glassBackgroundEffect()
        #endif

    }
    
    private var oldSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search nodes", text: $searchText)
                .focused($isSearchFieldFocused)
            
            Button {
                withAnimation(.snappy) {
                    searchPresented = false
                    searchText = ""
                    searchResults = []
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // CANVAS
                CanvasView(
                    scale: $scale,
                    offset: $offset,
                    nodeSizes: $nodeSizes,
                    searchResults: searchResults,
                    showGrid: showGrid,
                    onDetail: { showDetailNode = $0 },
                    onLink: { showLinkToNode = $0 },
                    onDelete: { showDeleteNode = $0 }
                )
                    .ignoresSafeArea()
                
                // UI LAYER
                VStack(spacing: 0) {
                    if #unavailable(iOS 26.0) {
                        VStack(spacing: 0) {
                            if searchPresented {
                                
                                oldSearchBar
                                
                                if !searchText.isEmpty && !searchResults.isEmpty {
                                    SearchResultsBar(
                                        index: selectedSearchResultIndex,
                                        total: searchResults.count,
                                        onNext: goToNextSearchResult,
                                        onPrev: goToPreviousSearchResult
                                    )
                                    .padding(.top, 8)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }

                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                    
                    if showZoomLevel {
                        Text(String(format: "%.0f %%", scale * 100))
                            .frame(width: 60)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            #if !os(visionOS)
                            .adaptiveGlass()
                            #else
                            .glassBackgroundEffect()
                            #endif
                    }
                    
                    // Focus mode
                    if appModel.session.focusMode != nil {
                        focusPanel
                    }
                    
                    // This spacer pushes content below nav bar
                    if !isCompact {
                        Color.clear
                            .frame(height: 40)
                    }
                    
                    
                    ZStack(alignment: .topLeading) {
                        
                        // sidebar
                        #if !os(visionOS)
                        if appModel.outlineOpen && !isCompact {
                            let size = min(300, geo.size.width - 40)
                            HStack {
                                OutlineView(preferredWidth: size, style: .overlay)
                                    .environment(appModel)
                                    
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .leading))
                        }
                        #endif
                    }
                    
                    Spacer()
                    
                    if appModel.session.selectedNodeIds.count > 0 {
                        SelectedNodesPanel {
                            appModel.removeSelectedNodes()
                        } onAiEdit: {
                            appModel.aiEditorOpen.toggle()
                        } onDuplicate: {
                            appModel.duplicateSelectedNodes()
                        }
                    }
                    
                    #if os(visionOS)
                    HStack {
                        Spacer()
                        Button {
                            appModel.session.pendingNodePosition = visibleCenterPosition()
                            showNodeForm = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .keyboardShortcut("n", modifiers: [.command])
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .clipShape(Circle())
                        .tint(themeStore.theme.canvasTheme.selection)
                    }
                    .safeAreaPadding()
                    #endif
                    #if !os(visionOS)
                    if #unavailable(iOS 26.0) {
                        
                        HStack {
                            Button {
                                withAnimation(.snappy) {
                                    searchPresented = true
                                }

                                DispatchQueue.main.async {
                                    isSearchFieldFocused = true
                                }
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.title2.weight(.semibold))
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color.primary)
                            .adaptiveGlass()
                            .clipShape(Circle())
                            .padding(.leading, 20)
                            .padding(.bottom, 20)
                            
                            Spacer()
                            
                            Button {
                                appModel.session.pendingNodePosition = visibleCenterPosition()
                                showNodeForm = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2.weight(.semibold))
                                    .frame(width: 40, height: 40)
                            }
                            .keyboardShortcut("n", modifiers: [.command])
                            .buttonStyle(.borderedProminent)
                            .clipShape(Circle())
                            .tint(themeStore.theme.canvasTheme.selection)
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                    #endif
                }
            }
            .onAppear {
                // set offset so map zero coordinates will be on screen center
                offset = CGSize(width: geo.size.width / 2, height: geo.size.height / 2)
                containerSize = geo.size
            }
            .onChange(of: geo.size) { oldSize, newSize in
                containerSize = newSize
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    searchResults = []
                } else {
                    performSearch()
                }
            }
            .onChange(of: appModel.session.centerOnNodeId, { _, _ in
                guard let node = appModel.visibleNodes.first(where: {
                    $0.id == appModel.session.centerOnNodeId
                }) else { return }
                centerOnNode(node, animated: true)
            })
            .sheet(isPresented: Binding(
                get: { showShareSheet && (generatedPreview != nil || generatedJSON != nil || generatedMarkdown != nil || generatedMarkdownPackage != nil) },
                set: { newValue in
                    if !newValue {
                        showShareSheet = false
                        generatedPreview = nil
                        generatedJSON = nil
                        generatedMarkdown = nil
                    }
                }
            )) {
                if let generatedPreview {
                    ShareSheet(
                        item: ShareImageItem(
                            image: generatedPreview,
                            title: appModel.session.currentCanvas?.name ?? String(localized: "Canvas Export"),
                            format: selectedFormat
                        )
                    )
                } else if let generatedJSON {
                    ShareSheet(
                        item: ShareJSONItem(
                            jsonData: generatedJSON,
                            filename: appModel.session.currentCanvas?.name ?? String(localized: "Canvas Export")
                        )
                    )
                } else if let generatedMarkdown {
                    ShareSheet(
                        item: ShareMarkdownItem(
                            markdownData: generatedMarkdown,
                            filename: appModel.session.currentCanvas?.name ?? String(localized: "Canvas Export")
                        )
                    )
                } else if let generatedMarkdownPackage {
                    ShareSheet(
                        item: ShareMarkdownPackageItem(
                            archiveURL: generatedMarkdownPackage,
                            filename: appModel.session.currentCanvas?.name ?? String(localized: "Canvas Export")
                        )
                    )
                }
            }
            #if !os(visionOS)
            .sheet(isPresented: Binding(
                get: { appModel.outlineOpen && isCompact },
                set: { newValue in
                    if !newValue {
                        appModel.outlineOpen = false
                    }
                }
            )) {
                OutlineView(preferredWidth: nil, style: .sheet)
                    .environment(appModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            #endif
            .sheet(isPresented: $showNodeForm) {
                NodeEditorView(position: appModel.session.pendingNodePosition)
                    .environment(appModel)
            }
            .sheet(item: $showDetailNode) { node in
                NodeDetailView(node: node)
                    .environment(appModel)
            }
            .sheet(item: $showLinkToNode) { node in
                NavigationStack {
                    LinkEditorView(fromNode: node)
                        .interactiveDismissDisabled()
                        .presentationDetents(
                            UIDevice.current.userInterfaceIdiom == .pad
                            ? [.large]
                            : [.medium, .large]
                        )
                }
            }
            .sheet(isPresented: Binding(
                get: { appModel.aiEditorOpen && !appModel.immersiveMapToolbarOpen },
                set: { newValue in
                    appModel.aiEditorOpen = newValue
                }
            )) {
                if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                    NavigationStack {
                        AIEditCanvasView(showEditor: Binding(
                            get: { appModel.aiEditorOpen },
                            set: { newValue in
                                appModel.aiEditorOpen = newValue
                            }
                        ))
                        .environment(appModel)
                        .presentationBackground(Color(.secondarySystemBackground))
                    }
                    .presentationDetents(
                        UIDevice.current.userInterfaceIdiom == .pad
                        ? [.large]
                        : [.medium, .large]
                    )
                }
            }
            .sheet(isPresented: Binding(get: {
                !hasSeenCanvasOnboarding
            }, set: { val in
                hasSeenCanvasOnboarding = !val
            })) {
                CanvasOnboardingView()
                    .environmentObject(themeStore)
                    .onDisappear {
                        hasSeenCanvasOnboarding = true
                    }
            }
            .alert(
                "Delete Node",
                isPresented: Binding(
                    get: {
                        showDeleteNode != nil
                    },
                    set: { newValue in
                        if !newValue {
                            showDeleteNode = nil
                        }
                    }
                ),
                presenting: showDeleteNode
            ) { node in
                Button("Delete", role: .destructive) {
                    appModel.removeNode(node)
                }
                Button("Cancel") {}
            } message: { _ in
                Text("Are you sure you want to delete this node?")
            }
            .navigationBarTitleDisplayMode(.inline)
            .ifAvailableIOS26(new: {
                if #available(iOS 26.0, *) {
                    $0.searchable(
                        text: $searchText,
                        prompt: "Search nodes"
                    )
                    .searchToolbarBehavior(.minimize)
                    .overlay(alignment: .top) {
                        if !searchText.isEmpty && !searchResults.isEmpty {
                            SearchResultsBar(
                                index: selectedSearchResultIndex,
                                total: searchResults.count,
                                onNext: goToNextSearchResult,
                                onPrev: goToPreviousSearchResult
                            )
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
            }, fallback: {
                $0
            })
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        appModel.undoAction()
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.left")
                    }
                    .disabled(!appModel.actionService.canUndo)

                    Button {
                        appModel.redoAction()
                    } label: {
                        Label("Redo", systemImage: "arrow.uturn.right")
                    }
                    .disabled(!appModel.actionService.canRedo)
                    
                }

                if #available(iOS 26.0, *) {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    
                    Menu {
                        Text(appModel.session.currentCanvas?.name ?? "Canvo")
                            .font(.headline)
                        Divider()

                        Menu {
                            Button {
                                exportAsImage(format: .jpeg)
                            } label: {
                                Text("JPEG")
                            }
                            
                            Button {
                                exportAsImage(format: .png)
                            } label: {
                                Text("PNG")
                            }
                            
                            Button {
                                exportJSON()
                            } label: {
                                Text("Canvas JSON")
                            }
                            
                            Menu {
                                Button {
                                    exportMarkdown()
                                } label: {
                                    Text("Markdown (.md)")
                                }
                                
                                Button {
                                    exportMarkdownPackage()
                                } label: {
                                    Text("Markdown + Images (.zip)")
                                }
                                
                            } label: {
                                Text("Markdown")
                            }

                        } label: {
                            Label("Export As", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            printCanvas()
                        } label: {
                            Label("Print", systemImage: "printer")
                        }
                        
                        Divider()
                        
#if os(visionOS)
                    // visionOS immersive map
                    Button {
                        appModel.immersiveMapOpen.toggle()
                        if appModel.immersiveMapOpen {
                            Task {
                                await openImmersiveSpace(id: "ImmersiveNodeMapView")
                                // Call Push Window and hide main window
                                pushWindow(id: "ImmersiveMapToolbar")
                            }
                        } else {
                            Task {
                                await dismissImmersiveSpace()
                                dismissWindow(id: "ImmersiveMapToolbar")
                            }
                        }
                    } label: {
                        Label("Immersive Mode", systemImage: "graph.3d")
                    }
                        Divider()
#endif
                        
                        // outline
                        Button {
                            withAnimation {
                                #if os(visionOS)
                                
                                if appModel.outlineOpen {
                                    dismissWindow(id: "outline")
                                } else {
                                    openWindow(id: "outline")
                                }
                                #endif
                                appModel.outlineOpen.toggle()
                            }
                        } label: {
                            Label(appModel.outlineOpen ? "Hide Outline" : "Show Outline",
                                  systemImage: "list.bullet.indent"
                            )
                        }
                        
                        Button {
                            withAnimation {
                                showGrid.toggle()
                            }
                        } label: {
                            Label(showGrid ? "Hide Grid" : "Show Grid",
                                  systemImage: "squareshape.split.2x2.dotted.inside.and.outside"
                            )
                        }
                        
                        // tag filter
                        Menu {
                            ForEach(appModel.session.currentCanvas?.tags ?? [], id: \.name) { tag in
                                Button {
                                    appModel.toggleTag(tag)
                                } label: {
                                    let isSelected = appModel.session.selectedTags.contains(tag)
                                    if isSelected {
                                        Label(tag.name, systemImage: "checkmark")
                                    } else {
                                        Text(tag.name)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Button {
                                appModel.showAllTags()
                            } label: {
                                Text("Show All")
                            }
                        } label: {
                            Label("Tag Filter", systemImage: appModel.session.selectedTags.isEmpty ? "tag" : "tag.fill")
                        }
                        
                        // ai edit
                        if appModel.aiGenerationService.isAvailable {
                            
                            Toggle(isOn: Binding(
                                get: { appModel.aiEditorOpen },
                                set: { newValue in
                                    appModel.aiEditorOpen = newValue
                                }
                            ).animation()) {
                                Label("AI Editor", systemImage: "sparkles")
                            }
                        }
                    } label: {
                        Label("", systemImage: "ellipsis")
                    }
                    .menuStyle(.button)
                    .labelStyle(.iconOnly)
                }
                
                
                #if !os(visionOS)
                
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    
                    ToolbarItem(placement: .bottomBar) {
                        Button {
                            appModel.session.pendingNodePosition = visibleCenterPosition()
                            showNodeForm = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .keyboardShortcut("n", modifiers: [.command])
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .clipShape(Capsule())
                        .tint(themeStore.theme.canvasTheme.selection)
                    }
                }
                #endif
            }
            .background(Color("MapBackground"))
            .gesture(panGesture)
            .gesture(zoomGesture)
            
            // visible area center debug marker (DO NOT REMOVE!)
            Circle()
                .fill(Color.clear)
                .frame(width: 10, height: 10)
                .position(CGPoint(x: geo.size.width / 2, y: geo.size.height / 2))
                .opacity(0.5)
                .allowsHitTesting(false)
        }
        #if os(visionOS)
        .onChange(of: appModel.immersiveMapToolbarOpen) { _, new in
            if !new {
                Task {
                    await dismissImmersiveSpace()
                    appModel.immersiveMapOpen = new
                }
            }
        }
        #endif
        .onReceive(zoomIn, perform: { _ in
            applyZoom(multiplier: 1.2)
        })
        .onReceive(zoomOut, perform: { _ in
            applyZoom(multiplier: 0.8)
        })
        .onReceive(resetZoom, perform: { _ in
            setDefaultZoom()
        })
        #if !os(visionOS)
        .onReceive(outline, perform: { _ in
            withAnimation {
                appModel.outlineOpen.toggle()
            }
        })
        #endif
        .onReceive(toggleGrid, perform: { _ in
            withAnimation {
                showGrid.toggle()
            }
        })
        .onDisappear {
            appModel.reviewRequestService.handle(event: .canvasCompleted)
            generatePreview()
            appModel.aiGenerationService.cancelCurrentTask()
            appModel.switchToCanvas(nil)
        }
    }
}
