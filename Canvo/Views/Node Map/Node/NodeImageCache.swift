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

    guard let image = UIImage(data: data) else { return nil }

    NodeImageCache.shared.setObject(image, forKey: key)
    return image
}
