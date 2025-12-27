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
        
        // locate far out of screen
        controller.view.frame = CGRect(x: 0, y: CGFloat(Int.max), width: 1, height: 1)
        UIApplication.shared.windows.first!.rootViewController?.view.addSubview(controller.view)
        
        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.sizeToFit()
        if removeBackground {
            controller.view.backgroundColor = .clear
        }
        
        let image = controller.view.asImage()
        controller.view.removeFromSuperview()
        return image
    }
}
