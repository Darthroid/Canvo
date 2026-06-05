//
//  CanvasPreviewService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 25.12.2025.
//

import UIKit
import SwiftUI

final class CanvasPreviewService {
    private weak var model: AppModel?
    
    private let fileManager = FileManager.default
    private let tempDirectory = FileManager.default.temporaryDirectory

    /// Serial queue — важен порядок и отсутствие гонок
    private let renderQueue = DispatchQueue(
        label: "canvas.preview.render.queue",
        qos: .utility
    )

    /// Чтобы не генерировать превью одного канваса параллельно
    private var pendingCanvasIds = Set<String>()
    private let lock = NSLock()

    // MARK: - Public API
    
    public init() {
        
    }
    
    func set(model: AppModel) {
        self.model = model
    }

    /// Асинхронная генерация превью
    public func generatePreview(
        image: UIImage,
        for canvasId: String
    ) {
        lock.lock()
        if pendingCanvasIds.contains(canvasId) {
            lock.unlock()
            return
        }
        pendingCanvasIds.insert(canvasId)
        lock.unlock()

        renderQueue.async { [weak self] in
            guard let self else { return }

            defer {
                self.lock.lock()
                self.pendingCanvasIds.remove(canvasId)
                self.lock.unlock()
            }

            guard let data = image.pngData(), !data.isEmpty else {
                return
            }

            let url = self.tempDirectory
                .appendingPathComponent("\(canvasId).png")

            do {
                try data.write(to: url, options: [.atomic])

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .canvasPreviewUpdated,
                        object: nil,
                        userInfo: ["canvasId": canvasId]
                    )
                }
            } catch {
                print("Preview save failed:", error)
            }
        }
    }

    // MARK: - Utilities

    func getPreviewURL(for canvas: Canvas) -> URL {
        tempDirectory.appendingPathComponent("\(canvas.id).png")
    }

    func hasPreview(for canvas: Canvas) -> Bool {
        let url = getPreviewURL(for: canvas)
        return fileManager.fileExists(atPath: url.path())
    }

    func removePreview(for canvas: Canvas) {
        let url = getPreviewURL(for: canvas)
        try? fileManager.removeItem(at: url)
    }
}

extension CanvasPreviewService {

    struct PreviewLayout {
        let scale: CGFloat
        let offset: CGSize
    }

    func previewLayout(
        nodes: [Node],
        targetSize: CGSize
    ) -> PreviewLayout? {

        let points = nodes.map(\.position.position2D)

        guard !points.isEmpty else {
            return nil
        }

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
}

extension CanvasPreviewService {

    func generatePreview(
        for canvas: Canvas,
        nodes: [Node],
        connections: [NodeConnection],
        targetSize: CGSize = CGSize(width: 220, height: 160)
    ) {

        let image = previewImage(
            nodes: nodes,
            connections: connections,
            targetSize: targetSize
        )

        generatePreview(
            image: image,
            for: canvas.id
        )
    }
}

extension CanvasPreviewService {

    func previewImage(
        nodes: [Node],
        connections: [NodeConnection],
        targetSize: CGSize = CGSize(width: 220, height: 160),
        removeBackground: Bool = true
    ) -> UIImage {

        let view: AnyView

        if let layout = previewLayout(
            nodes: nodes,
            targetSize: targetSize
        ) {

            view = AnyView(
                CanvasPreviewView(
                    nodes: nodes,
                    connections: connections,
                    layout: layout
                )
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
}

private struct CanvasPreviewView: View {

    let nodes: [Node]
    let connections: [NodeConnection]
    let layout: CanvasPreviewService.PreviewLayout

    var body: some View {
        ZStack {

            ForEach(connections) { connection in
                if let from = nodes.first(where: { $0.id == connection.fromNodeId }),
                   let to = nodes.first(where: { $0.id == connection.toNodeId }) {

                    ConnectionView(
                        from: from.position.position2D,
                        to: to.position.position2D
                    )
                    .stroke(.secondary, lineWidth: 1.25)
                }
            }

            ForEach(nodes) { node in
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
}
