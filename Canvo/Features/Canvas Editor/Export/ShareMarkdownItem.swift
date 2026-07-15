//
//  ShareMarkdownItem.swift
//  Canvo
//
//  Created by Олег Комаристый on 10.07.2026.
//

import UIKit
import SwiftUI
import LinkPresentation

final class ShareMarkdownItem: NSObject, UIActivityItemSource {

    let markdownData: Data
    let filename: String

    init(markdownData: Data, filename: String) {
        self.markdownData = markdownData
        self.filename = filename
    }

    private var fileURL: URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(filename).md")

        try? markdownData.write(to: url)

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
