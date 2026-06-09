//
//  Image.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 25.12.2025.
//

import SwiftUI
import UIKit

extension Image {
    init(contentsOfFile: String) {
        // You could force unwrap here if you are 100% sure the image exists
        // but it is better to handle it gracefully
        if let image = UIImage(contentsOfFile: contentsOfFile) {
            self.init(uiImage: image)
        } else {
            // You need to handle the option if the image doesn't exist at the file path
            // let's just initialize with a SF Symbol as that will exist
            // you could pass a default name or otherwise if you like
            self.init(systemName: "xmark.octagon")
        }
    }
}
