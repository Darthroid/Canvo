import SwiftUI
import SwiftData
import StoreKit

struct NodeMapView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.openWindow) private var openWindow
    #if os(visionOS)
    @Environment(\.pushWindow) private var pushWindow
    #endif
    @Environment(\.dismissWindow) private var dismissWindow
    
    var isCompact: Bool {
        return horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
#if os(visionOS)
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
#endif
    
    @State var dragStartPositions: [String: SIMD3<Float>] = [:]
    @State var draggedNodeIds: Set<String> = []
    
    @State var scale: CGFloat = 1.0
    @State var baseScale: CGFloat = 1.0
    @State var offset: CGSize = .zero
    @State var lastPanTranslation: CGSize = .zero
    @State var lastDragTranslation: CGSize = .zero
    
    @State private var showGrid = true
    
    @State private var showNodeForm = false
    @State private var showtagsFilter: Bool = false
    
    @State private var containerSize: CGSize = .zero
    
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
    @State var showShareSheet = false
    @State var selectedFormat: ExportFormat = .png
    
    @Environment(\.requestReview) private var requestReview

    @AppStorage("screenDismissCount")
    private var screenDismissCount = 0
    
    private var updatedAt: String? {
        guard let date = appModel.currentCanvas?.updatedAt else { return nil }
        
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
        appModel.selectedNodeIds = [node.id]
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
    
    var selectedNodesFloatingPanel: some View {
        HStack(spacing: 24) {
            Text(String(format: appModel.selectedNodeIds.count > 1 ? "%d items" : "%d item", appModel.selectedNodeIds.count))
            
            Button {
                appModel.deleteSelectedNodes()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .labelsHidden()
            
            Button {
                appModel.aiEditorOpen.toggle()
            } label: {
                Image(systemName: "sparkles")
            }
            .buttonStyle(.plain)
            .labelsHidden()
            
            Menu {
                Button {
                    appModel.nodes
                        .map(\.id)
                        .forEach { appModel.selectedNodeIds.insert($0) }
                } label: {
                    Text("Select All")
                }
                
                Button {
                    appModel.duplicateSelectedNodes()
                } label: {
                    Text("Duplicate")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .buttonStyle(.plain)
            .labelsHidden()
            
            Button {
                withAnimation {
                    appModel.selectedNodeIds.removeAll()
                }
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical)
        #if !os(visionOS)
        .glassEffect()
        #else
        .glassBackgroundEffect()
        #endif
    }
    
    var canvas: some View {
        ZStack {
            
            ZStack {
                // Canvas grid
                if showGrid {
                    GridLayer()
                }
                
                // Connections
                ForEach(appModel.visibleConnections) { c in
                    if let a = appModel.node(forId: c.fromNodeId),
                       let b = appModel.node(forId: c.toNodeId),
                       !a.isHidden && !b.isHidden {
                        ConnectionView(
                            from: a.position.position2D,
                            to: b.position.position2D
                        )
                        .stroke(.secondary, lineWidth: 2)
                    }
                }
                
                // Nodes
                ForEach(appModel.visibleNodes) { node in
                    NodeView(
                        node: node,
                        isSelected: appModel.selectedNodeIds.contains(node.id),
                        isExpanded: appModel.expandedNodeIds.contains(node.id),
                        isMatchingSearch: searchResults.contains(where: { $0.id == node.id }),
                        toolbarEnabled: true,
                        onDetail: { showDetailNode = node },
                        onLink: { showLinkToNode = node },
                        onDelete: { showDeleteNode = node }
                    )
                    .position(node.position.position2D)
                    .gesture(nodeDrag(node))
                    .onTapGesture(count: 1) {
                        withAnimation {
                            if appModel.selectedNodeIds.contains(node.id) {
                                appModel.selectedNodeIds.remove(node.id)
                            } else {
                                appModel.selectedNodeIds.insert(node.id)
                            }
                        }
                        
                    }
                    .onTapGesture(count: 2) {
                        withAnimation(.bouncy(duration: 0.2)) {
                            if appModel.expandedNodeIds.contains(node.id) {
                                appModel.expandedNodeIds.remove(node.id)
                            } else {
                                appModel.expandedNodeIds.insert(node.id)
                            }
                        }
                    }
                }
                
                // Debug marker for node creation (DO NOT REMOVE!)
                Circle()
                    .fill(Color.clear)
                    .frame(width: 12, height: 12)
                    .position(
                        x: CGFloat(appModel.pendingNodePosition?.x ?? 0),
                        y: CGFloat(appModel.pendingNodePosition?.y ?? 0)
                    )
                    .opacity(appModel.pendingNodePosition == nil ? 0 : 0.7)
            }
            .scaleEffect(scale)
            .offset(offset)
            .coordinateSpace(name: "canvas")
        }
        .background(Color(uiColor: .secondarySystemFill))
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // CANVAS
                canvas
                    .ignoresSafeArea()
                
                // UI LAYER
                VStack(spacing: 0) {
                    
                    if showZoomLevel {
                        Text(String(format: "%.0f %%", scale * 100))
                            .frame(width: 60)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            #if !os(visionOS)
                            .glassEffect()
                            #else
                            .glassBackgroundEffect()
                            #endif
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
                    
                    if appModel.selectedNodeIds.count > 0 {
                        SelectedNodesPanel {
                            appModel.deleteSelectedNodes()
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
                            appModel.pendingNodePosition = visibleCenterPosition()
                            showNodeForm = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .keyboardShortcut("n", modifiers: [.command])
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .clipShape(Circle())
                        .tint(.accent)
                    }
                    .safeAreaPadding()
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
            .onChange(of: appModel.centerOnNodeId, { _, _ in
                guard let node = appModel.visibleNodes.first(where: {
                    $0.id == appModel.centerOnNodeId
                }) else { return }
                centerOnNode(node, animated: true)
            })
            .sheet(isPresented: Binding(
                get: { showShareSheet && (generatedPreview != nil || generatedJSON != nil) },
                set: { newValue in
                    if !newValue {
                        showShareSheet = false
                        generatedPreview = nil
                        generatedJSON = nil
                    }
                }
            )) {
                if let generatedPreview {
                    ShareSheet(
                        item: ShareImageItem(
                            image: generatedPreview,
                            title: appModel.currentCanvas?.name ?? "Map Export",
                            format: selectedFormat
                        )
                    )
                } else if let generatedJSON {
                    ShareSheet(
                        item: ShareJSONItem(
                            jsonData: generatedJSON,
                            filename: appModel.currentCanvas?.name ?? "Map Export"
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
                CreateNodeView(position: appModel.pendingNodePosition)
                    .environment(appModel)
            }
            .sheet(item: $showDetailNode) { node in
                NavigationStack {
                    NodeDetailView(node: node)
                }
            }
            .sheet(item: $showLinkToNode) { node in
                NavigationStack {
                    LinkEditorView(fromNode: node)
                        .interactiveDismissDisabled()
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
                        ), visibleScopeIds: [])
                            .environment(appModel)
                            .presentationBackground(Color(.secondarySystemBackground))
                    }
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
                Button(role: .cancel) {}
            } message: { _ in
                Text("Are you sure you want to delete this node?")
            }
//            .navigationTitle(appModel.currentCanvas?.name ?? "Canvo")
//            .navigationSubtitle("Last Edit: \(updatedAt ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
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

                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    
                    Menu {
                        Text(appModel.currentCanvas?.name ?? "Canvo")
                            .font(.headline)
                        Divider()

                        Menu {
                            Button {
                                exportAsImage(format: .jpeg)
                            } label: {
                                Text("JPEG image")
                            }
                            
                            Button {
                                exportAsImage(format: .png)
                            } label: {
                                Text("PNG image")
                            }
                            
                            Button {
                                exportJSON()
                            } label: {
                                Text("JSON")
                            }
                            
                            
                        } label: {
                            Label("Export As", systemImage: "square.and.arrow.up")
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
                            ForEach(appModel.currentCanvas?.tags ?? [], id: \.name) { tag in
                                Button {
                                    appModel.toggleTag(tag)
                                } label: {
                                    let isSelected = appModel.selectedTags.contains(tag)
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
                            Label("Tag Filter", systemImage: appModel.selectedTags.isEmpty ? "tag" : "tag.fill")
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
                ToolbarSpacer(.flexible, placement: .bottomBar)
                
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        appModel.pendingNodePosition = visibleCenterPosition()
                        showNodeForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .keyboardShortcut("n", modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .clipShape(Capsule())
                    .tint(.accent)
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
            handleReviewRequest()
            generatePreview()
            appModel.aiGenerationService.cancelCurrentTask()
            appModel.switchToCanvas(nil)
        }
    }
    
    private func handleReviewRequest() {
        screenDismissCount += 1

        if screenDismissCount.isMultiple(of: 5) {
            requestReview()
        }
    }
}
