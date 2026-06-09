//
//  String.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 22.01.2026.
//

import Foundation

extension String {
    func parseTags() -> [String] {
        self
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }
}
