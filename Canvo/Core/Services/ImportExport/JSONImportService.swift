//
//  JSONImportService.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.07.2026.
//

import Foundation

final class JSONImportService {

    func importCanvas(from url: URL) throws -> Canvas {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Canvas.self, from: data)
    }
}
