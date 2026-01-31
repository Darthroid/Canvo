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
    @Attribute(.unique) var name: String

    // optional, на будущее
    var colorRaw: String?

    init(name: String) {
        self.name = name.lowercased()
    }
}
