//
//  UIView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 24.12.2025.
//

import UIKit

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            // [!!] Uncomment to clip resulting image
            //             rendererContext.cgContext.addPath(
            //                UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath)
            //            rendererContext.cgContext.clip()
            
            // As commented by @MaxIsom below in some cases might be needed
            // to make this asynchronously, so uncomment below DispatchQueue
            // if you'd same met crash
            //            DispatchQueue.main.async {
            layer.render(in: rendererContext.cgContext)
            //            }
        }
    }
}

extension UIImage {
    func resizedWithAspect(targetSize: CGSize) -> UIImage {
        let image = self
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Determine the smaller ratio to ensure the image fits
        let scaleFactor = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: image.size.width * scaleFactor,
                             height: image.size.height * scaleFactor)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
