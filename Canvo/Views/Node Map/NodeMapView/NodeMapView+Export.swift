//
//  NodeMapView+Export.swift
//  Canvo
//
//  Created by Олег Комаристый on 27.05.2026.
//

import Foundation
import UIKit
import SwiftUI

extension NodeMapView {
    @MainActor
    func exportAsImage(format: ExportFormat) {
        guard let canvas = appModel.session.currentCanvas else { return }
        
        let watermark: UIImage?
        
        if applyThemeToExports {
            watermark = themeStore.theme.colorScheme == .dark ? CanvasPreviewService.watermarkWhiteImage : CanvasPreviewService.watermarkBlackImage
        } else {
            watermark = CanvasPreviewService.watermarkBlackImage
        }
        
        let image = appModel.previewService.previewImage(
            nodes: canvas.nodes ?? [],
            connections: canvas.connections ?? [],
            theme: applyThemeToExports ? themeStore.theme.canvasTheme : CanvasTheme.systemLight,
            removeBackground: false,
            watermark: watermark
        )
        self.generatedPreview = image
        self.selectedFormat = format
        
        showShareSheet.toggle()
    }
    
    @MainActor
    func exportJSON() {
        guard let canvas = appModel.session.currentCanvas else { return }
        
        do {
            let data = try appModel.exportService.exportJSONCanvas(canvas)
            self.generatedJSON = data
            self.selectedFormat = .json
            
            showShareSheet.toggle()
        } catch {
            print("error encoding json on export: \(error)")
        }
    }
    
    @MainActor
    func printCanvas() {
        guard let canvas = appModel.session.currentCanvas else { return }
        
        let watermark: UIImage?
        
        if applyThemeToExports {
            watermark = themeStore.theme.colorScheme == .dark ? CanvasPreviewService.watermarkWhiteImage : CanvasPreviewService.watermarkBlackImage
        } else {
            watermark = CanvasPreviewService.watermarkBlackImage
        }
        
        let image = appModel.previewService.previewImage(
            nodes: canvas.nodes ?? [],
            connections: canvas.connections ?? [],
            theme: applyThemeToExports ? themeStore.theme.canvasTheme : CanvasTheme.systemLight,
            removeBackground: false,
            watermark: watermark
        )
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = canvas.name
        
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.showsNumberOfCopies = true
        printController.printingItem = image
        
        printController.present(animated: true, completionHandler: nil)
    }
}
