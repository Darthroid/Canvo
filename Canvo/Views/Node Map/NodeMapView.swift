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
    
    @State private var dragStartPositions: [String: SIMD3<Float>] = [:]
    @State private var draggedNodeIds: Set<String> = []
    
    @State private var scale: CGFloat = 1.0
    @State private var baseScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastPanTranslation: CGSize = .zero
    @State private var lastDragTranslation: CGSize = .zero
    
    @State var showAIEditCanvas = false
    @State var showNodeForm = false
    @State var showtagsFilter: Bool = false
    @State var showNodeSpace = false
    @State var pendingNodePosition: SIMD3<Float>? = nil
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
    
    private func resetZoom() {
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
        appModel.selectedNodeId = node.id
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
    
    var canvas: some View {
        ZStack {
            
            ZStack {
                GridLayer()
                
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
                        isSelected: appModel.selectedNodeId == node.id,
                        isMatchingSearch: searchResults.contains(where: { $0.id == node.id })
                    )
                    .position(node.position.position2D)
                    .gesture(nodeDrag(node))
                    .onTapGesture {
                        appModel.selectedNodeId = appModel.selectedNodeId == node.id ? nil : node.id
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
                            .glassEffect()
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
            .sheet(isPresented: $showNodeForm) {
                CreateNodeView(position: pendingNodePosition)
                    .environment(appModel)
            }
            .sheet(isPresented: $showAIEditCanvas) {
                if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                    AIEditCanvasView()
                }
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
                        appModel.actionService.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.left")
                    }
                    .disabled(!appModel.actionService.canUndo)

                    Button {
                        appModel.actionService.redo()
                    } label: {
                        Image(systemName: "arrow.uturn.right")
                    }
                    .disabled(!appModel.actionService.canRedo)
                }

                
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
                
                ToolbarItemGroup(placement: .bottomBar) {
                    
                    // outline
                    Button {
                        withAnimation {
                            showOutline.toggle()
                        }
                    } label: {
                        Image(systemName: "list.bullet.indent")
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
                        Image(systemName: appModel.selectedTags.isEmpty ? "tag" : "tag.fill")
                    }
                    
                    // ai edit
                    if AIGenerationService.shared.isAvailable {
                        
                        
                        Menu {
                            Button {
                                showAIEditCanvas = true
                            } label: {
                                Text("Extend")
                            }
                            
                            Button {
                                showAIEditCanvas = true
                            } label: {
                                Text("Summarize")
                            }
                            
                            Divider()
                            
                            Button {
                                showAIEditCanvas = true
                            } label: {
                                Text("Enter your question")
                            }
                        } label: {
                            Image(systemName: "sparkles")
                        }

                        
//                        Button {
//                            showAIEditCanvas = true
//                        } label: {
//                            Image(systemName: "sparkles")
//                        }
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
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .clipShape(Capsule())
                    .tint(.accent)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    
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
                        Image(systemName: "graph.3d")
                    }
#endif
                }
            }
            .background(Color(uiColor: .systemBackground))
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
        .onDisappear {
            generatePreview()
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
            .onChanged { v in
                
                // 1. init snapshot once
                if dragStartPositions[node.id] == nil {
                    dragStartPositions[node.id] = SIMD3(node.x, node.y, node.z)
                }
                
                draggedNodeIds.insert(node.id)
                
                let dx = Float(v.translation.width) / Float(scale)
                let dy = Float(v.translation.height) / Float(scale)
                
                let start = dragStartPositions[node.id] ?? SIMD3(node.x, node.y, node.z)
                
                // UI-only preview (NO persistence)
                node.x = start.x + dx
                node.y = start.y + dy
            }
            .onEnded { _ in
                
                guard let start = dragStartPositions[node.id] else { return }
                
                let end = SIMD3(node.x, node.y, node.z)
                
                let action = MoveNodeAction(
                    nodeId: node.id,
                    oldPosition: start,
                    newPosition: end
                )
                
                appModel.actionService.perform(action)
                
                dragStartPositions.removeValue(forKey: node.id)
                draggedNodeIds.remove(node.id)
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
