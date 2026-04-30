//
//  Tag.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 22.01.2026.
//

import SwiftData
import Foundation

@Model
final class Tag: Identifiable {
//    @Attribute(.unique) 
    var name: String = ""

    var canvas: Canvas?
    
    // optional, на будущее
    var colorRaw: String?

    init(name: String, canvas: Canvas? = nil) {
        self.name = name.lowercased()
        self.canvas = canvas
    }
}
