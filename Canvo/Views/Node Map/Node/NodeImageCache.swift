//
//  NodeImageCache.swift
//  Canvo
//
//  Created by Олег Комаристый on 18.06.2026.
//

import Foundation
import UIKit

final class NodeImageCache {
    static let shared = NSCache<NSString, UIImage>()
}

func decodeCover(_ data: Data) -> UIImage? {
    let key = NSString(string: "\(data.hashValue)")

    if let cached = NodeImageCache.shared.object(forKey: key) {
        return cached
    }

    guard let image = UIImage(data: data) else {
        return nil
    }

    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256))

    let thumbnail = renderer.image { _ in
        image.draw(in: CGRect(x: 0, y: 0, width: 256, height: 256))
    }

    NodeImageCache.shared.setObject(thumbnail, forKey: key)

    return thumbnail
}
