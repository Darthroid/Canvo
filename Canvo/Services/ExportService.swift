//
//  ExportService.swift
//  Canvo
//
//  Created by Олег Комаристый on 05.06.2026.
//

import Foundation

class ExportService {
    private weak var model: AppModel?
    
    public init() {
        
    }
    
    func set(model: AppModel) {
        self.model = model
    }
    
    func exportJSONCanvas(_ canvas: Canvas) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(canvas)
        return data
    }
}
