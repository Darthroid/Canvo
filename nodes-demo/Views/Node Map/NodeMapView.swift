import SwiftUI
import SwiftData

struct NodeMapView: View {
    @Environment(AppModel.self) private var appModel
    
    #if os(visionOS)
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    #endif

    @State private var scale: CGFloat = 1.0
    @State private var baseScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastPanTranslation: CGSize = .zero
    @State private var lastDragTranslation: CGSize = .zero
    
    @State var showAIEditCanvas = false
    @State var showNodeForm = false
    @State var showNodeSpace = false
    @State var pendingNodePosition: SIMD3<Float>? = nil
    @State private var containerSize: CGSize = .zero
    
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var searchResults: [Node] = []
    @State private var selectedSearchResultIndex = 0
    @FocusState private var isSearchFieldFocused: Bool
    
    private let minScale: CGFloat = 0.1
    private let maxScale: CGFloat = 4.0
    private let zoomSensitivity: CGFloat = 0.35
    private let searchAnimationDuration: Double = 0.5
    
    private func applyZoom(multiplier: CGFloat) {
        let next = scale * multiplier
        let clamped = min(max(next, minScale), maxScale)
        scale = clamped
        baseScale = clamped
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
            node.name.lowercased().contains(query) ||
            node.detail.lowercased().contains(query)
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
                ForEach(appModel.connections) { c in
                    if let a = appModel.node(forId: c.fromNodeId),
                       let b = appModel.node(forId: c.toNodeId) {
                        ConnectionView(
                            from: a.position.position2D,
                            to: b.position.position2D
                        )
                        .stroke(.secondary, lineWidth: 2)
                    }
                }

                // Nodes
                ForEach(appModel.nodes) { node in
                    ZStack {
                        NodeView(
                            node: node,
                            isSelected: appModel.selectedNodeId == node.id,
                            isMatchingSearch: searchResults.contains(where: { $0.id == node.id })
                        )
                    }
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
    
    var searchView: some View {
        VStack(spacing: 0) {
            if showSearch {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search", text: $searchText)
                                .focused($isSearchFieldFocused)
                                .textFieldStyle(.plain)
                                .submitLabel(.search)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onSubmit { performSearch() }
                                .onChange(of: searchText) { _, _ in performSearch() }
                            
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                    showSearch = false
                                    searchText = ""
                                    searchResults = []
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                        )
                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    
                    if !searchResults.isEmpty {
                        HStack(spacing: 16) {
                            Text("\(selectedSearchResultIndex + 1) of \(searchResults.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button { goToPreviousSearchResult() } label: {
                                Image(systemName: "chevron.left")
                            }
                            .disabled(searchResults.count <= 1)
                            
                            Button { goToNextSearchResult() } label: {
                                Image(systemName: "chevron.right")
                            }
                            .disabled(searchResults.count <= 1)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .transition(.opacity)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                )
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    )
                )
            }
            
            Spacer()
        }
        .padding(16)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showSearch)
        .onChange(of: showSearch) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFieldFocused = true
                }
            } else {
                isSearchFieldFocused = false
            }
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                canvas
                
                searchView
            }
            .onAppear {
                containerSize = geo.size
            }
            .onChange(of: geo.size) { oldSize, newSize in
                containerSize = newSize
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
            .navigationTitle(appModel.currentCanvas?.name ?? "Nodes Demo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    // zoom out
                    Button {
                        applyZoom(multiplier: 0.8)
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    
                    // zoom in
                    Button {
                        applyZoom(multiplier: 1.2)
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    
                    // reset zoom
                    Button {
                        resetZoom()
                    } label: {
                        Image(systemName: "text.magnifyingglass")
                    }
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // search
                    if !showSearch {
                        Button {
                            withAnimation {
                                showSearch = true
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    
                    // new node
                    Button {
                        pendingNodePosition = visibleCenterPosition()
                        showNodeForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    
                    // ai edit
                    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *), AIGenerationService.shared.isAvailable {
                        Button {
                            showAIEditCanvas = true
                        } label: {
                            Image(systemName: "apple.intelligence")
                        }
                    }
                    
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
    
    // MARK: - PREVIEW FIT UTILS
    
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
            }
            .onEnded { _ in
                baseScale = scale
            }
    }

    // MARK: - NODE DRAG

    private func nodeDrag(_ node: Node) -> some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { v in
                let dx = (v.translation.width - lastDragTranslation.width) / scale
                let dy = (v.translation.height - lastDragTranslation.height) / scale
                
                node.x += Float(dx)
                node.y += Float(dy)
                
                lastDragTranslation = v.translation
            }
            .onEnded { _ in
                lastDragTranslation = .zero
                appModel.save()
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
