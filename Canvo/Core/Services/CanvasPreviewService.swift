//
//  CanvasPreviewService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 25.12.2025.
//

import UIKit
import SwiftUI

final class CanvasPreviewService {

    public static var watermarkImage: UIImage? {
        UIImage(named: "watermark")
    }

    private weak var model: AppModel?

    private let fileManager = FileManager.default
    private let tempDirectory = FileManager.default.temporaryDirectory

    private let renderQueue = DispatchQueue(
        label: "canvas.preview.render.queue",
        qos: .utility
    )

    private var pendingCanvasIds = Set<String>()
    private let lock = NSLock()

    public init() {}

    func set(model: AppModel) {
        self.model = model
    }

    func generatePreview(
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

            guard let data = image.pngData(), !data.isEmpty else { return }

            let url = self.tempDirectory.appendingPathComponent("\(canvasId).png")

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

    func generatePreview(
        for canvas: Canvas,
        nodes: [Node],
        connections: [NodeConnection],
        theme: CanvasTheme,
        removeBackground: Bool
    ) {
        let image = previewImage(
            nodes: nodes,
            connections: connections,
            theme: theme,
            removeBackground: removeBackground
        )

        generatePreview(
            image: image,
            for: canvas.id
        )
    }

    func getPreviewURL(for canvas: Canvas) -> URL {
        tempDirectory.appendingPathComponent("\(canvas.id).png")
    }

    func hasPreview(for canvas: Canvas) -> Bool {
        let url = getPreviewURL(for: canvas)
        return fileManager.fileExists(atPath: url.path)
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
        let size: CGSize
    }

    func previewLayout(nodes: [Node]) -> PreviewLayout? {
        let padding: CGFloat = 100
        let points = nodes.map(\.position.position2D)
        guard !points.isEmpty else { return nil }

        let minX = points.map(\.x).min()!
        let maxX = points.map(\.x).max()!
        let minY = points.map(\.y).min()!
        let maxY = points.map(\.y).max()!

        let width = maxX - minX
        let height = maxY - minY

        let size = CGSize(
            width: width + padding * 2,
            height: height + padding * 2
        )

        return PreviewLayout(
            scale: 1.0,
            offset: CGSize(width: -minX + padding, height: -minY + padding),
            size: size
        )
    }
}

extension CanvasPreviewService {

    func previewImage(
        nodes: [Node],
        connections: [NodeConnection],
        theme: CanvasTheme,
        removeBackground: Bool = true,
        watermark: UIImage? = nil
    ) -> UIImage {

        guard let layout = previewLayout(nodes: nodes) else {
            let fallback = AnyView(GridLayer(offset: .zero, scale: .zero))
            return fallback.asImage(
                size: CGSize(width: 200, height: 200),
                scale: 2,
                removeBackground: removeBackground
            )
        }

        let view = AnyView(
            CanvasPreviewView(
                nodes: nodes,
                connections: connections,
                layout: layout,
                theme: theme
            )
            .frame(width: layout.size.width, height: layout.size.height)
            .background(removeBackground ? .clear : theme.background)
        )

        let image = view.asImage(
            size: layout.size,
            scale: 2,
            removeBackground: removeBackground
        )

        guard let watermark else { return image }

        return addWatermark(watermark, to: image)
    }

    private func addWatermark(_ watermark: UIImage, to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))

            let margin: CGFloat = 24
            let targetWidth = image.size.width * 0.15
            let aspect = watermark.size.height / watermark.size.width

            let size = CGSize(width: targetWidth, height: targetWidth * aspect)

            let rect = CGRect(
                x: image.size.width - size.width - margin,
                y: image.size.height - size.height - margin,
                width: size.width,
                height: size.height
            )

            watermark.draw(in: rect, blendMode: .normal, alpha: 0.9)
        }
    }
}

private struct CanvasPreviewView: View {

    let nodes: [Node]
    let connections: [NodeConnection]
    let layout: CanvasPreviewService.PreviewLayout
    let theme: CanvasTheme

    var body: some View {
        ZStack {

            ForEach(connections) { connection in
                if let from = nodes.first(where: { $0.id == connection.fromNodeId }),
                   let to = nodes.first(where: { $0.id == connection.toNodeId }) {

                    ConnectionView(
                        from: from.position.position2D,
                        to: to.position.position2D
                    )
                    .stroke(theme.connector, lineWidth: 3)
                }
            }

            ForEach(nodes) { node in
                previewNode(node)
                    .position(node.position.position2D)
            }
        }
        .offset(layout.offset)
    }

    @ViewBuilder
    private func previewNode(_ node: Node) -> some View {
        let bg: Color = {
            if let color = node.color {
                return Color(uiColor: color)
            }
            return theme.nodeBackground
        }()

        let text: Color = {
            let ui = UIColor(bg)
            return Color(uiColor: ui.readableTextColor())
        }()

        VStack(spacing: 6) {

            if let data = node.coverImageData,
               let uiImage = UIImage(data: data) {

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .clipped()
            }

            Text(node.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(text)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(theme.nodeBorder, lineWidth: 1)
        )
    }
}
