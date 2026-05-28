//
//  Notification.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 25.12.2025.
//

import Foundation

extension Notification.Name {
    static let canvasPreviewUpdated = Notification.Name("canvasPreviewUpdated")
    static let pinchInWithNode = Notification.Name("pinchInWithNode")
    static let pinchOutWithNode = Notification.Name("pinchOutWithNode")
    static let linkWithNode = Notification.Name("linkWithNode")
}
