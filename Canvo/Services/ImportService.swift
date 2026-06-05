//
//  ImportService.swift
//  Canvo
//
//  Created by Олег Комаристый on 05.06.2026.
//

import Foundation

class ImportService {
    private weak var model: AppModel?
    
    init() {
        
    }
    
    func set(model: AppModel) {
        self.model = model
    }
    
    func processImport(from urls: [URL]) async throws -> [Canvas] {
        var canvases = [Canvas]()
        
        try urls.forEach { file in
            // gain access to the directory
            let gotAccess = file.startAccessingSecurityScopedResource()
            if !gotAccess { return }
            
            // access the directory URL
            let canvas = try handleCanvas(from: file)
            canvases.append(canvas)
            
            // release access
            file.stopAccessingSecurityScopedResource()
        }
        
        return canvases
    }
    
    private func handleCanvas(from url: URL) throws -> Canvas {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Canvas.self, from: data)
    }
}
