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
        let image = previewImage(targetSize: .init(width: 2048, height: 1024), removeBackground: false)
        self.generatedPreview = image
        self.selectedFormat = format
        
        showShareSheet.toggle()
    }
    
    @MainActor
    func exportJSON() {
        guard let canvas = appModel.currentCanvas else { return }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(canvas)
//            let json = String(data: data, encoding: .utf8)
            self.generatedJSON = data
            self.selectedFormat = .json
            
            showShareSheet.toggle()
        } catch {
            print("error encoding json on export: \(error)")
        }
    }
}
