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
    func generatePreview() {
        guard let canvas = appModel.session.currentCanvas else { return }

        appModel.previewService.generatePreview(
            for: canvas,
            nodes: canvas.nodes ?? [],
            connections: canvas.connections ?? [],
        )
    }
    
}
