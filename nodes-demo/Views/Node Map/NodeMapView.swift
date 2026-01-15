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
                .sheet(isPresented: $showAIEditCanvas) {
                    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
                        AIEditCanvasView()
                    }
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
                        if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *), AIGenerationService.shared.isAvailable {
                            Button {
                                showAIEditCanvas = true
                            } label: {
                                Image(systemName: "apple.intelligence")
                            }
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
                    isSelected: false
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

        /// ❗️ВАЖНО:
        /// Сначала сдвигаем bounding в (0,0),
        /// потом центрируем в targetSize
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

    @Environment(\.colorScheme) private var colorScheme
    @State var showDetail: Bool = false

    private var backgroundUIColor: UIColor {
        node.color ?? UIColor.systemBackground
    }

    private var titleColor: Color {
        Color(
            uiColor: backgroundUIColor.readableTextColor(
                isDarkMode: colorScheme == .dark
            )
        )
    }

    private var secondaryColor: Color {
        titleColor.opacity(0.75)
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(spacing: 8) {
                Text(node.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)

                if isSelected {
                    Text(node.detail.isEmpty ? "No description" : node.detail)
                        .font(.system(size: 14))
                        .foregroundColor(secondaryColor)
                        .multilineTextAlignment(.center)
                }
            }

            if isSelected {
                Button {
                    showDetail.toggle()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(titleColor.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(uiColor: backgroundUIColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(titleColor.opacity(0.2), lineWidth: 1)
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

public extension CGSize {
    static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
}
