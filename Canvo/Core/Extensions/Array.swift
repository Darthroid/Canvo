//
//  Array.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 18.01.2026.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
