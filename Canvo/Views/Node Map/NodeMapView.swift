import SwiftUI
import SwiftData
import StoreKit

struct NodeMapView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.openWindow) private var openWindow
    
    var isCompact: Bool {
        return horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
#if os(visionOS)
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
#endif
    
    @State private var dragStartPositions: [String: SIMD3<Float>] = [:]
    @State private var draggedNodeIds: Set<String> = []
    
    @State private var scale: CGFloat = 1.0
    @State private var baseScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastPanTranslation: CGSize = .zero
    @State private var lastDragTranslation: CGSize = .zero
    
    @State private var showGrid = true
    
    @State private var showAIEditCanvas = false
    @State private var showNodeForm = false
    @State private var showtagsFilter: Bool = false
    @State private var showNodeSpace = false
    @State private var pendingNodePosition: SIMD3<Float>? = nil
    @State private var containerSize: CGSize = .zero
    
    @State private var searchText = ""
    @State private var showOutline = false
    @State private var searchResults: [Node] = []
    @State private var selectedSearchResultIndex = 0
    @FocusState private var isSearchFieldFocused: Bool
    
    @State private var showDetailNode: Node?
    @State private var showLinkToNode: Node?
    @State private var showDeleteNode: Node?
    
    @State private var showZoomLevel = false
    private let minScale: CGFloat = 0.1
    private let maxScale: CGFloat = 4.0
    private let zoomSensitivity: CGFloat = 0.35
    private let searchAnimationDuration: Double = 0.5
    
    @State private var generatedPreview: UIImage?
    @State private var generatedJSON: Data?
    @State private var showShareSheet = false
    @State private var selectedFormat: ExportFormat = .png
    
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
    
    private func applyZoom(multiplier: CGFloat) {
        let next = scale * multiplier
        let clamped = min(max(next, minScale), maxScale)
        scale = clamped
        baseScale = clamped
        showZoomLevel = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.showZoomLevel = false
        }
    }
    
    private func setDefaultZoom() {
        scale = 1.0
        baseScale = 1.0
        offset = .zero
    }
    
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
                deleteSelectedNodes()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .labelsHidden()
            
            Button {
                showAIEditCanvas.toggle()
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
                    duplicateSelectedNodes()
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
                        x: CGFloat(pendingNodePosition?.x ?? 0),
                        y: CGFloat(pendingNodePosition?.y ?? 0)
                    )
                    .opacity(pendingNodePosition == nil ? 0 : 0.7)
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
                        if showOutline && !isCompact {
                            let size = min(300, geo.size.width - 40)
                            HStack {
                                OutlineView(preferredWidth: size, style: .overlay)
                                    .environment(appModel)
                                    
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .leading))
                        }
                    }
                    
                    Spacer()
                    
                    if appModel.selectedNodeIds.count > 0 {
                        selectedNodesFloatingPanel
                    }
                    
                    #if os(visionOS)
                    HStack {
                        Spacer()
                        Button {
                            pendingNodePosition = visibleCenterPosition()
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
            .sheet(isPresented: Binding(
                get: { showOutline && isCompact },
                set: { newValue in
                    if !newValue {
                        showOutline = false
                    }
                }
            )) {
                OutlineView(preferredWidth: nil, style: .sheet)
                    .environment(appModel)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showNodeForm) {
                CreateNodeView(position: pendingNodePosition)
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
                }
            }
            .sheet(isPresented: $showAIEditCanvas) {
                if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                    NavigationStack {
                        AIEditCanvasView(showEditor: $showAIEditCanvas, visibleScopeIds: [])
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
                    let snapshot = appModel.makeNodeSnapshotWithConnections(node)
                    
                    let action = RemoveNodeAction(
                        node: snapshot.node,
                        connections: snapshot.connections
                    )
                    
                    appModel.actionService.perform(action)
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
                
                ToolbarItem(placement: .confirmationAction) {
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
                        showNodeSpace.toggle()
                        if showNodeSpace {
                            Task {
                                await openImmersiveSpace(id: "ImmersiveNodeMapView")
                            }
                        } else {
                            Task {
                                await dismissImmersiveSpace()
                            }
                        }
                    } label: {
                        Label(showNodeSpace ? "Hide Immersive Map" : "Show Immersive Map", systemImage: "graph.3d")
                    }
                        Divider()
#endif
                        
                        // outline
                        Button {
                            withAnimation {
                                #if os(visionOS)
                                openWindow(id: "outline")
                                #else
                                showOutline.toggle()
                                #endif
                            }
                        } label: {
                            Label(showOutline ? "Hide Outlie" : "Show Outline",
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
                        if AIGenerationService.shared.isAvailable {
                            
                            Toggle(isOn: $showAIEditCanvas.animation()) {
                                Label("AI Editor", systemImage: "sparkles")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
                
                #if !os(visionOS)
                ToolbarSpacer(.flexible, placement: .bottomBar)
                
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        pendingNodePosition = visibleCenterPosition()
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
        .onReceive(zoomIn, perform: { _ in
            applyZoom(multiplier: 1.2)
        })
        .onReceive(zoomOut, perform: { _ in
            applyZoom(multiplier: 0.8)
        })
        .onReceive(resetZoom, perform: { _ in
            setDefaultZoom()
        })
        .onReceive(outline, perform: { _ in
            withAnimation {
                showOutline.toggle()
            }
        })
        .onReceive(toggleGrid, perform: { _ in
            withAnimation {
                showGrid.toggle()
            }
        })
        .onDisappear {
            handleReviewRequest()
            generatePreview()
            AIGenerationService.shared.cancelCurrentTask()
            appModel.switchToCanvas(nil)
        }
    }
    
    private func handleReviewRequest() {
        screenDismissCount += 1

        if screenDismissCount.isMultiple(of: 5) {
            requestReview()
        }
    }
    
    private func deleteSelectedNodes() {
        guard !appModel.selectedNodeIds.isEmpty else { return }
        
        let snapshots = appModel.selectedNodeIds
            .compactMap { appModel.node(forId: $0) }
            .map { appModel.makeNodeSnapshotWithConnections($0) }
        
        appModel.actionService.beginBatch()
        snapshots.forEach {
            let action = RemoveNodeAction(node: $0.node, connections: $0.connections)
            appModel.actionService.perform(action)
        }
        appModel.actionService.endBatch()
        
        withAnimation {
            appModel.selectedNodeIds.removeAll()
        }
    }
    
    private func duplicateSelectedNodes() {
        guard !appModel.selectedNodeIds.isEmpty else { return }
        
        let snapshots = appModel.selectedNodeIds
            .compactMap { appModel.node(forId: $0) }
            .map {
                NodeSnapshot(
                    id: UUID().uuidString,
                    name: $0.name,
                    detail: $0.detail,
                    x: $0.x,
                    y: $0.y + 100,
                    z: $0.z, color: $0.colorRaw,
                    tagsRaw: $0.tagsRaw
                )
            }
        
        appModel.actionService.beginBatch()
        snapshots.forEach {
            let action = AddNodeAction(node: $0)
            appModel.actionService.perform(action)
        }
        appModel.actionService.endBatch()
        
        appModel.selectedNodeIds.removeAll()
        snapshots.forEach { appModel.selectedNodeIds.insert($0.id) }
    }
}

extension NodeMapView {
    @ViewBuilder
    private func previewCanvas(
        layout: PreviewLayout
    ) -> some View {
        ZStack {
            ForEach(appModel.connections) { c in
                if let a = appModel.node(forId: c.fromNodeId),
                   let b = appModel.node(forId: c.toNodeId) {
                    ConnectionView(
                        from: a.position.position2D,
                        to: b.position.position2D
                    )
                    .stroke(.secondary, lineWidth: 1.25)
                }
            }
            
            ForEach(appModel.nodes) { node in
                NodeView(
                    node: node,
                    isSelected: false,
                    isExpanded: false,
                    isMatchingSearch: false,
                    toolbarEnabled: true
                )
                .position(node.position.position2D)
            }
        }
        .scaleEffect(layout.scale, anchor: .topLeading)
        .offset(layout.offset)
    }
    
    
    private struct PreviewLayout {
        let scale: CGFloat
        let offset: CGSize
    }
    
    private func previewLayout(targetSize: CGSize) -> PreviewLayout? {
        let points = appModel.nodes.map { $0.position.position2D }
        guard !points.isEmpty else { return nil }
        
        let minX = points.map(\.x).min()!
        let maxX = points.map(\.x).max()!
        let minY = points.map(\.y).min()!
        let maxY = points.map(\.y).max()!
        
        let padding: CGFloat = 80
        
        let contentWidth = (maxX - minX) + padding * 2
        let contentHeight = (maxY - minY) + padding * 2
        
        let scale = min(
            targetSize.width / contentWidth,
            targetSize.height / contentHeight
        )
        
        let offsetX = targetSize.width / 2 - ((minX + maxX) / 2) * scale
        let offsetY = targetSize.height / 2 - ((minY + maxY) / 2) * scale
        
        return PreviewLayout(
            scale: scale,
            offset: CGSize(width: offsetX, height: offsetY)
        )
    }
    
    // MARK: - PAN
    
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { v in
                let dx = v.translation.width - lastPanTranslation.width
                let dy = v.translation.height - lastPanTranslation.height
                offset.width += dx
                offset.height += dy
                lastPanTranslation = v.translation
            }
            .onEnded { _ in
                lastPanTranslation = .zero
            }
    }
    
    // MARK: - ZOOM
    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = 1 + (value - 1) * zoomSensitivity
                scale = min(max(baseScale * delta, minScale), maxScale)
                
                showZoomLevel = true
            }
            .onEnded { _ in
                baseScale = scale
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showZoomLevel = false
                }
            }
    }
    
    // MARK: - NODE DRAG
    
    private func nodeDrag(_ node: Node) -> some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { value in
                // 1. Определяем, какие ноды будут перемещаться
                let isDraggedNodeSelected = appModel.selectedNodeIds.contains(node.id)
                let movingIds = isDraggedNodeSelected ? appModel.selectedNodeIds : [node.id]

                // 2. Сбрасываем выделение, если тащим невыделенную ноду
                if !isDraggedNodeSelected {
                    appModel.selectedNodeIds = [node.id]
                }

                // 3. Запоминаем стартовые позиции (один раз за жест)
                for id in movingIds {
                    if dragStartPositions[id] == nil,
                       let n = appModel.node(forId: id) {
                        dragStartPositions[id] = n.position
                    }
                }

                // 4. Добавляем все перемещаемые ноды в отслеживаемый набор
                draggedNodeIds.formUnion(movingIds)

                // 5. Вычисляем общее смещение (в координатах canvas)
                let dx = Float(value.translation.width) / Float(scale)
                let dy = Float(value.translation.height) / Float(scale)

                // 6. Применяем смещение ко всем нодам (только визуально, без сохранения)
                for id in movingIds {
                    guard let start = dragStartPositions[id],
                          let n = appModel.node(forId: id) else { continue }
                    n.x = start.x + dx
                    n.y = start.y + dy
                }
            }
            .onEnded { _ in
                // 1. Собираем данные для batch-действия
                var nodeIds: [String] = []
                var oldPositions: [SIMD3<Float>] = []
                var newPositions: [SIMD3<Float>] = []

                for id in draggedNodeIds {
                    guard let start = dragStartPositions[id],
                          let node = appModel.node(forId: id) else { continue }
                    let end = node.position
                    if start != end {
                        nodeIds.append(id)
                        oldPositions.append(start)
                        newPositions.append(end)
                    }
                }

                // 2. Выполняем batch-действие, если есть изменения
                if !nodeIds.isEmpty {
                    let action = MoveNodesBatchAction(
                        nodeIds: nodeIds,
                        oldPositions: oldPositions,
                        newPositions: newPositions
                    )
                    appModel.actionService.perform(action)
                }

                // 3. Очищаем временные данные
                for id in draggedNodeIds {
                    dragStartPositions.removeValue(forKey: id)
                }
                draggedNodeIds.removeAll()
            }
    }
    
    @MainActor
    private func exportAsImage(format: ExportFormat) {
        let image = previewImage(targetSize: .init(width: 2048, height: 1024), removeBackground: false)
        self.generatedPreview = image
        self.selectedFormat = format
        
        showShareSheet.toggle()
    }
    
    @MainActor func exportJSON() {
        guard let canvas = appModel.currentCanvas else { return }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(canvas)
//            let json = String(data: data, encoding: .utf8)
            self.generatedJSON = data
            self.selectedFormat = .json
            
            showShareSheet.toggle()
        } catch {
            print("error encoding json on export: \(error)")
        }
    }
    
    @MainActor
    private func previewImage(
        targetSize: CGSize = CGSize(width: 220, height: 160),
        removeBackground: Bool = true
    ) -> UIImage {

        let view: AnyView

        if let layout = previewLayout(targetSize: targetSize) {
            view = AnyView(
                previewCanvas(layout: layout)
                    .frame(
                        width: targetSize.width,
                        height: targetSize.height
                    )
            )
        } else {
            view = AnyView(
                GridLayer()
                    .frame(
                        width: targetSize.width,
                        height: targetSize.height
                    )
            )
        }

        return view.asImage(
            size: targetSize,
            scale: 2,
            removeBackground: removeBackground
        )
    }
    
    @MainActor
    private func generatePreview(targetSize: CGSize = CGSize(width: 220, height: 160)) {
        guard let canvas = appModel.currentCanvas else { return }
        let image = previewImage(targetSize: targetSize)

        CanvasPreviewService.shared.generatePreview(
            image: image,
            for: canvas.id
        )
    }
}
