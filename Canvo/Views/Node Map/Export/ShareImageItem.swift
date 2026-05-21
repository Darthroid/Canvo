//
//  ShareImageItem.swift
//  Canvo
//
//  Created by Олег Комаристый on 21.05.2026.
//


import SwiftUI
import LinkPresentation

final class ShareImageItem: NSObject, UIActivityItemSource {

    enum ImageFormat: String {
        case jpeg, png
    }
    
    let image: UIImage
    let title: String
    let format: ImageFormat

    init(image: UIImage, title: String, format: ImageFormat) {
        self.image = image
        self.title = title
        self.format = format
    }

    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        image
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(title).\(format.rawValue)")

        switch format {
        case .jpeg:
            if let data = image.jpegData(compressionQuality: 1) {
                try? data.write(to: url)
            }
        case .png:
            if let data = image.pngData() {
                try? data.write(to: url)
            }
        }

        return url
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        title
    }

    func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {

        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.imageProvider = NSItemProvider(object: image)

        return metadata
    }
}
