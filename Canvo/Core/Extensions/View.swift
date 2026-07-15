//
//  View.swift
//  Canvo
//
//  Created by Олег Комаристый on 24.12.2025.
//

import UIKit
import SwiftUI

extension View {
    @MainActor
    func asImage(
        size: CGSize,
        scale: CGFloat = 2,
        removeBackground: Bool = true
    ) -> UIImage {

        let content: AnyView

        if removeBackground {
            content = AnyView(
                self
                    .frame(width: size.width, height: size.height)
                    .background(.clear)
            )
        } else {
            content = AnyView(
                self.frame(width: size.width, height: size.height)
                    .background(.background)
            )
        }

        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = .init(size)
        renderer.scale = scale

        return renderer.uiImage ?? UIImage()
    }
}
