//
//  ShareSheet.swift
//  Canvo
//
//  Created by Олег Комаристый on 21.05.2026.
//

import UIKit
import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let item: ShareImageItem

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [item],
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}
