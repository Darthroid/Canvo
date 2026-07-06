//
//  NodeMapView+Gestures.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import SwiftUI

extension NodeMapView {
    
    var minScale: CGFloat { 0.1 }
    var maxScale: CGFloat { 4.0 }
    var zoomSensitivity: CGFloat { 0.35 }
    
    // MARK: - PAN
    
    var panGesture: some Gesture {
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
    
    var zoomGesture: some Gesture {
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
    
    func applyZoom(multiplier: CGFloat) {
        let next = scale * multiplier
        let clamped = min(max(next, minScale), maxScale)
        scale = clamped
        baseScale = clamped
        showZoomLevel = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.showZoomLevel = false
        }
    }
    
    func setDefaultZoom() {
        scale = 1.0
        baseScale = 1.0
//        offset = .zero
    }
    
    // MARK: - NODE DRAG
    
    
}
