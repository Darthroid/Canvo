//
//  NodeMapView+Preview.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import UIKit
import SwiftUI

extension NodeMapView {
    
    @MainActor
    func generatePreview(targetSize: CGSize = CGSize(width: 220, height: 160)) {
        guard let canvas = appModel.currentCanvas else { return }

        appModel.previewService.generatePreview(
            for: canvas,
            nodes: canvas.nodes ?? [],
            connections: canvas.connections ?? [],
            targetSize: targetSize
        )
    }
    
}
