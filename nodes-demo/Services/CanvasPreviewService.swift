//
//  CanvasPreviewService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 25.12.2025.
//

import UIKit

class CanvasPreviewService {
    static let shared = CanvasPreviewService()
        
    private let fileManager = FileManager.default
    private let tempDirectory = FileManager.default.temporaryDirectory
    
    @discardableResult
    func generatePreview(image: UIImage, for canvasId: String) -> URL? {
        guard let data = image.pngData() else {
            return nil
        }

        let tmpURL = tempDirectory.appendingPathComponent("\(canvasId).png")

        do {
            try data.write(to: tmpURL, options: [.atomic])
            
            NotificationCenter.default.post(
                name: .canvasPreviewUpdated,
                object: nil,
                userInfo: ["canvasId": canvasId]
            )
            
            return tmpURL
        } catch {
            print("Snapshot save failed:", error)
            return nil
        }
    }
    
    func getPreviewURL(for canvas: Canvas) -> URL {
        return tempDirectory.appendingPathComponent("\(canvas.id).png")
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
