//
//  View.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 24.12.2025.
//

import UIKit
import SwiftUI

extension View {
    func asImage(removeBackground: Bool) -> UIImage {
        let controller = UIHostingController(rootView: self)

        #if os(visionOS)

        let targetSize = controller.sizeThatFits(
            in: CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        )

        controller.view.bounds = CGRect(origin: .zero, size: targetSize)

        #else

        controller.view.frame = CGRect(
            x: 0,
            y: CGFloat(Int.max),
            width: 1,
            height: 1
        )

        guard
            let window = UIApplication.shared
                .connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first
        else {
            return UIImage()
        }

        window.rootViewController?.view.addSubview(controller.view)

        let size = controller.sizeThatFits(
            in: UIScreen.main.bounds.size
        )

        controller.view.bounds = CGRect(origin: .zero, size: size)

        #endif

        controller.view.sizeToFit()

        if removeBackground {
            controller.view.backgroundColor = .clear
        }

        let image = controller.view.asImage()

        #if !os(visionOS)
        controller.view.removeFromSuperview()
        #endif

        return image
    }
}

