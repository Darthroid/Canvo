//
//  ShareJSONItem.swift
//  Canvo
//
//  Created by Олег Комаристый on 22.05.2026.
//

import UIKit
import SwiftUI
import LinkPresentation

final class ShareJSONItem: NSObject, UIActivityItemSource {

    let jsonData: Data
    let filename: String

    init(jsonData: Data, filename: String) {
        self.jsonData = jsonData
        self.filename = filename
    }

    private var fileURL: URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filename).json")

        try? jsonData.write(to: url)

        return url
    }

    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        fileURL
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        fileURL
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        filename
    }

    func activityViewControllerLinkMetadata(
        _ activityViewController: UIActivityViewController
    ) -> LPLinkMetadata? {

        let metadata = LPLinkMetadata()

        metadata.title = filename

        if let image = UIImage(systemName: "doc.text") {
            metadata.iconProvider = NSItemProvider(object: image)
        }

        return metadata
    }
}
