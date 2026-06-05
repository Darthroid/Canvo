//
//  NodeMapView+Export.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import Foundation

extension NodeMapView {
    @MainActor
    func exportAsImage(format: ExportFormat) {
        guard let canvas = appModel.currentCanvas else { return }
        
        let image = appModel.previewService.previewImage(
            nodes: canvas.nodes ?? [],
            connections: canvas.connections ?? [],
            targetSize: .init(width: 2048, height: 1024),
            removeBackground: false
        )
        self.generatedPreview = image
        self.selectedFormat = format
        
        showShareSheet.toggle()
    }
    
    @MainActor
    func exportJSON() {
        guard let canvas = appModel.currentCanvas else { return }
        
        do {
            let data = try appModel.exportService.exportJSONCanvas(canvas)
            self.generatedJSON = data
            self.selectedFormat = .json
            
            showShareSheet.toggle()
        } catch {
            print("error encoding json on export: \(error)")
        }
    }
}
