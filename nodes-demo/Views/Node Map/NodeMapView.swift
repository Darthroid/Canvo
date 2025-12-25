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
    
    @State var showNodeForm = false
    @State var showNodeSpace = false
    @State var pendingNodePosition: SIMD3<Float>? = nil
    
    private let minScale: CGFloat = 0.1
    private let maxScale: CGFloat = 4.0
    private let zoomSensitivity: CGFloat = 0.35
    
    private func applyZoom(multiplier: CGFloat) {
        let next = scale * multiplier
        let clamped = min(max(next, minScale), maxScale)
        scale = clamped
        baseScale = clamped
    }
    
    private func resetZoom() {
        scale = 1.0
        baseScale = 1.0
    }
    
    private func visibleCenterPosition(in geo: GeometryProxy) -> SIMD3<Float> {
        let screenCenter = CGPoint(
            x: geo.size.width / 2,
            y: geo.size.height / 2
        )
        
        let canvasX = (screenCenter.x - offset.width) / scale
        let canvasY = (screenCenter.y - offset.height) / scale
        
        return SIMD3(Float(canvasX), Float(canvasY), 0)
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
                    NodeView(
                        node: node,
                        isSelected: appModel.selectedNodeId == node.id
                    )
                    .position(node.position.position2D)
                    .gesture(nodeDrag(node))
                    .onTapGesture {
                        appModel.selectedNodeId = appModel.selectedNodeId == node.id ? nil : node.id
                    }
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .coordinateSpace(name: "canvas")
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            canvas
                .sheet(isPresented: $showNodeForm) {
                    CreateNodeView(position: pendingNodePosition)
                        .environment(appModel)
                }
                .navigationTitle(appModel.currentCanvas?.name ?? "Nodes Demo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button {
                            applyZoom(multiplier: 0.8)
                        } label: {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        
                        Button {
                            applyZoom(multiplier: 1.2)
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        
                        Button {
                            resetZoom()
                        } label: {
                            Image(systemName: "text.magnifyingglass")
                        }
                    }
                    
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            pendingNodePosition = visibleCenterPosition(in: geo)
                            showNodeForm = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        #if os(visionOS)
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
        }
        .onAppear {
            generatePreview()
        }
        .onDisappear {
            generatePreview()
        }
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
        let image = self.canvas.asImage().resizedWithAspect(targetSize: .init(width: 220, height: 160))
        
        CanvasPreviewService.shared.generatePreview(image: image, for: canvas.id)
    }
}

// MARK: - GRID

struct GridLayer: View {
    private let spacing: CGFloat = 60
    private let dotSize: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            Path { p in
                for x in stride(from: -geo.size.width,
                                to: geo.size.width * 2,
                                by: spacing) {
                    for y in stride(from: -geo.size.height,
                                    to: geo.size.height * 2,
                                    by: spacing) {
                        p.addEllipse(
                            in: CGRect(x: x, y: y, width: dotSize, height: dotSize)
                        )
                    }
                }
            }
            .fill(Color.gray.opacity(0.6))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - NODE VIEW

struct NodeView: View {
    let node: Node
    let isSelected: Bool
    @State var showDetail: Bool = false
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                Text(node.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.init(uiColor: .darkGray))
                    .multilineTextAlignment(.center)
                
                if isSelected {
                    Text(node.detail.isEmpty ? "No description" : node.detail)
                        .font(.system(size: 14))
                        .foregroundColor(.init(uiColor: .darkGray).opacity(node.detail.isEmpty ? 0.6 : 0.9))
                        .multilineTextAlignment(.center)
                }
            }
            
            if isSelected {
                Button {
                    showDetail.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.init(uiColor: .darkGray))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .stroke(.gray, lineWidth: 1)
                .fill(node.color ?? .white)
                .shadow(
                    color: .black.opacity(isSelected ? 0.5 : 0.3),
                    radius: isSelected ? 10 : 6,
                    x: 0, y: isSelected ? 5 : 3
                )
        )
        .frame(maxWidth: 400)
        .transition(.scale.combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .sheet(isPresented: $showDetail) {
            NavigationStack {
                NodeDetailView(node: node)
            }
        }
    }
}

// MARK: - CONNECTION

struct ConnectionView: Shape {
    let from: CGPoint
    let to: CGPoint

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: from)
        p.addLine(to: to)
        return p
    }
}
