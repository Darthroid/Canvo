//
//  NodeMapView+Preview.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import UIKit
import SwiftUI

extension NodeMapView {
    
    struct PreviewLayout {
        let scale: CGFloat
        let offset: CGSize
    }
    
    @ViewBuilder
    func previewCanvas(
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
    
    func previewLayout(targetSize: CGSize) -> PreviewLayout? {
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
    
    @MainActor
    func previewImage(
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
    func generatePreview(targetSize: CGSize = CGSize(width: 220, height: 160)) {
        guard let canvas = appModel.currentCanvas else { return }
        let image = previewImage(targetSize: targetSize)

        CanvasPreviewService.shared.generatePreview(
            image: image,
            for: canvas.id
        )
    }
    
}
