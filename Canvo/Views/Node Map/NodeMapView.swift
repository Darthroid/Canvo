import SwiftUI
import SwiftData

struct NodeMapView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isCompact: Bool {
        return horizontalSizeClass == .compact || verticalSizeClass == .compact
    }
    
#if os(visionOS)
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
#endif
    
    @GestureState private var isNodeDragActive = false
    @State private var dragStartPositions: [String: SIMD3<Float>] = [:]
    @State private var draggedNodeIds: Set<String> = []
    
    @State private var scale: CGFloat = 1.0
    @State private var baseScale: CGFloat = 1.0
    @State private var cameraOffset: CGSize = .zero
    @State private var lastPanTranslation: CGSize = .zero
    
    @State private var showGrid = true
    
    @State private var showAIEditCanvas = false
    @State private var showNodeForm = false
    @State private var showNodeSpace = false
    @State private var pendingNodePosition: SIMD3<Float>? = nil
    @State private var containerSize: CGSize = .zero
    
    @State private var searchText = ""
    @State private var showOutline = false
    @State private var searchResults: [Node] = []
    @State private var selectedSearchResultIndex = 0
    @FocusState private var isSearchFieldFocused: Bool
    
    @State private var showZoomLevel = false
    private let minScale: CGFloat = 0.1
    private let maxScale: CGFloat = 4.0
    private let zoomSensitivity: CGFloat = 0.35
    private let searchAnimationDuration: Double = 0.5
    
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
        cameraOffset = .zero
    }
    
    private func visibleCenterPosition() -> SIMD3<Float> {
        let screenCenterX = containerSize.width / 2
        let screenCenterY = containerSize.height / 2
        
        let canvasX = (screenCenterX - cameraOffset.width) / scale
        let canvasY = (screenCenterY - cameraOffset.height) / scale
        
        return SIMD3(Float(canvasX), Float(canvasY), 0)
    }
    
    // Функция для центрирования ноды
    private func centerOnNode(_ node: Node, animated: Bool = true) {
        let p = node.position.position2D
        let center = CGPoint(x: containerSize.width / 2,
                             y: containerSize.height / 2)

        let target = CGSize(
            width: center.x - p.x * scale,
            height: center.y - p.y * scale
        )

        if animated {
            withAnimation(.easeInOut(duration: searchAnimationDuration)) {
                cameraOffset = target
            }
        } else {
            cameraOffset = target
        }
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
    
    var connections: some View {
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
    }
    
    var nodes: some View {
        ForEach(appModel.visibleNodes) { node in
            NodeView(
                node: node,
                isSelected: appModel.selectedNodeIds.contains(node.id),
                isExpanded: appModel.expandedNodeIds.contains(node.id),
                isMatchingSearch: searchResults.contains(where: { $0.id == node.id })
            )
            .position(node.position.position2D)
            .highPriorityGesture(nodeDrag(node))
            .onTapGesture(count: 2, perform: {
                withAnimation(.bouncy(duration: 0.2), {
                    if appModel.expandedNodeIds.contains(node.id) {
                        appModel.expandedNodeIds.remove(node.id)
                    } else {
                        appModel.expandedNodeIds.insert(node.id)
                    }
                })
            })
            .onTapGesture(count: 1) {
                withAnimation {
                    if appModel.selectedNodeIds.contains(node.id) {
                        appModel.selectedNodeIds.remove(node.id)
                    } else {
                        appModel.selectedNodeIds.insert(node.id)
                    }
                }
            }
        }
    }
    
    var debugMarker: some View {
        Circle()
            .fill(Color.clear)
            .frame(width: 12, height: 12)
            .position(
                x: CGFloat(pendingNodePosition?.x ?? 0),
                y: CGFloat(pendingNodePosition?.y ?? 0)
            )
            .opacity(pendingNodePosition == nil ? 0 : 0.7)
    }
    
    var canvas: some View {
        ZStack {
            
            ZStack {
                // Canvas grid
                if showGrid {
                    GridLayer()
                }
                
                // Connections
                connections
                
                // Nodes
                nodes
                
                // Debug marker for node creation (DO NOT REMOVE!)
                debugMarker
            }
            .coordinateSpace(name: "canvas")
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // CANVAS
                canvas
                    .scaleEffect(scale)
                    .offset(cameraOffset)
                    .position(x: geo.size.width / 2,
                              y: geo.size.height / 2)
                    .ignoresSafeArea()
                
                // UI LAYER
                VStack(spacing: 0) {
                    
                    if showZoomLevel {
                        Text(String(format: "%.0f %%", scale * 100))
                            .frame(width: 60)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .glassEffect()
                    }
                    
                    // This spacer pushes content below nav bar
                    if !isCompact {
                        Color.clear
                            .frame(height: 40)
                    }
                    
                    
                    ZStack(alignment: .topLeading) {
                        
                        // sidebar
                        VStack {
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
//                            if showAIEditCanvas && !isCompact {
//                                if !showOutline {
//                                    Spacer()
//                                }
//                                HStack {
//                                    AIEditCanvasView(showEditor: $showAIEditCanvas)
//                                        .frame(maxWidth: isCompact ? .greatestFiniteMagnitude : 500,  maxHeight: 800)
//                                        .padding(.horizontal)
////                                    Rectangle()
////                                        .backgroundStyle(.red)
////                                        .frame(width: 400, height: 400)
//                                    Spacer()
//                                }
//                            }
                        }
                        
                    }
                    
                    Spacer()
                }
                
                
            }
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(panGesture)
            )
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
                guard let node = appModel.nodes.first(where: {
                    $0.id == appModel.centerOnNodeId
                }) else { return }
                centerOnNode(node, animated: true)
            })
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
            
            .sheet(isPresented: $showAIEditCanvas) {
                AIEditCanvasView(showEditor: $showAIEditCanvas)
                    .background(Color(.secondarySystemBackground))
                    .environment(appModel)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showNodeForm) {
                CreateNodeView(position: pendingNodePosition)
                    .environment(appModel)
            }
//            .sheet(isPresented: $showAIEditCanvas) {
//                if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
//                    AIEditCanvasView()
//                }
//            }
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
                ToolbarItem(placement: .title) {
                    VStack {
                        Text(appModel.currentCanvas?.name ?? "Canvo")
                            .font(.headline)
                        Text("Last Edit: \(updatedAt ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .glassEffect()
                }
                
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
                
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        // undo/redo
                        Button {
                            appModel.actionService.undo()
                        } label: {
                            Label("Undo", systemImage: "arrow.uturn.left")
                        }
                        .disabled(!appModel.actionService.canUndo)

                        Button {
                            appModel.actionService.redo()
                        } label: {
                            Label("Redo", systemImage: "arrow.uturn.right")
                        }
                        .disabled(!appModel.actionService.canRedo)
                        
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
                        Toggle(isOn: $showOutline.animation()) {
                            Label("Outline", systemImage: "list.bullet.indent")
                        }
                        
                        Toggle(isOn: $showGrid.animation()) {
                            Label("Canvas Grid", systemImage: "squareshape.split.2x2.dotted.inside.and.outside")
                        }
                        
                        // tag filter
                        Menu {
                            ForEach(appModel.currentCanvas?.tags ?? [], id: \.name) { tag in
                                Button {
                                    appModel.toggleTag(tag)
                                } label: {
                                    Label(tag.name, systemImage: (appModel.selectedTags.contains(tag) ? "checkmark" : ""))
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
            }
            .background(Color(uiColor: .systemBackground))
            .simultaneousGesture(zoomGesture)
            
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
            generatePreview()
            appModel.switchToCanvas(nil)
        }
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
                    isMatchingSearch: false
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
                guard !isNodeDragActive else { return }

                cameraOffset.width += v.translation.width - lastPanTranslation.width
                cameraOffset.height += v.translation.height - lastPanTranslation.height

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
        DragGesture()
            .updating($isNodeDragActive) { _, state, _ in
                state = true
            }
            .onChanged { v in
                
                // если это первый drag — снимаем snapshot
                if dragStartPositions[node.id] == nil {
                    let selected = appModel.selectedNodeIds
                    
                    // если группа — фиксируем ВСЕ
                    if selected.contains(node.id), selected.count > 1 {
                        for id in selected {
                            if let n = appModel.node(forId: id) {
                                dragStartPositions[id] = SIMD3(n.x, n.y, n.z)
                            }
                        }
                    } else {
                        dragStartPositions[node.id] = SIMD3(node.x, node.y, node.z)
                    }
                }
                
                draggedNodeIds.insert(node.id)
                
                let dx = Float(v.translation.width)
                let dy = Float(v.translation.height)
                
                let selected = appModel.selectedNodeIds
                
                // GROUP DRAG
                if selected.contains(node.id), selected.count > 1 {
                    
                    for id in selected {
                        guard let start = dragStartPositions[id],
                              let n = appModel.node(forId: id) else { continue }
                        
                        n.x = start.x + dx
                        n.y = start.y + dy
                    }
                    
                } else {
                    // SINGLE DRAG
                    let start = dragStartPositions[node.id] ?? SIMD3(node.x, node.y, node.z)
                    
                    node.x = start.x + dx
                    node.y = start.y + dy
                }
            }
            .onEnded { _ in
                let selected = appModel.selectedNodeIds
                
                // commit actions for all moved nodes
                if selected.contains(node.id), selected.count > 1 {
                    
                    for id in selected {
                        guard let start = dragStartPositions[id],
                              let n = appModel.node(forId: id) else { continue }
                        
                        let end = SIMD3(n.x, n.y, n.z)
                        
                        let action = MoveNodeAction(
                            nodeId: id,
                            oldPosition: start,
                            newPosition: end
                        )
                        
                        appModel.actionService.perform(action)
                    }
                    
                } else {
                    guard let start = dragStartPositions[node.id] else { return }
                    
                    let end = SIMD3(node.x, node.y, node.z)
                    
                    let action = MoveNodeAction(
                        nodeId: node.id,
                        oldPosition: start,
                        newPosition: end
                    )
                    
                    appModel.actionService.perform(action)
                }
                
                dragStartPositions.removeAll()
                draggedNodeIds.removeAll()
            }
    }
    
    @MainActor
    private func generatePreview() {
        guard let canvas = appModel.currentCanvas else { return }
        
        let targetSize = CGSize(width: 220, height: 160)
#if os(visionOS)
        let scaleFactor: CGFloat = 1.0
#else
        let scaleFactor: CGFloat = UIScreen.main.scale
#endif
        
        let renderSize = CGSize(
            width: targetSize.width * scaleFactor,
            height: targetSize.height * scaleFactor
        )
        
        let view: AnyView
        
        if let layout = previewLayout(targetSize: targetSize) {
            let scaledLayout = PreviewLayout(
                scale: layout.scale * scaleFactor,
                offset: layout.offset * scaleFactor
            )
            
            view = AnyView(
                previewCanvas(layout: scaledLayout)
                    .frame(width: renderSize.width, height: renderSize.height)
            )
        } else {
            view = AnyView(
                GridLayer()
                    .frame(width: renderSize.width, height: renderSize.height)
            )
        }
        
        let image = view
            .asImage(removeBackground: true)
            .resizedWithAspect(targetSize: targetSize)
        
        CanvasPreviewService.shared.generatePreview(
            image: image,
            for: canvas.id
        )
    }
}
