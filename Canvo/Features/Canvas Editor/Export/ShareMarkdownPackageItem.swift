//
//  ShareMarkdownPackageItem.swift
//  Canvo
//
//  Created by Олег Комаристый on 10.07.2026.
//

import UIKit
import SwiftUI
import LinkPresentation

final class ShareMarkdownPackageItem: NSObject, UIActivityItemSource {

    let archiveURL: URL
    let filename: String

    init(archiveURL: URL, filename: String) {
        self.archiveURL = archiveURL
        self.filename = filename
    }

    func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        archiveURL
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        archiveURL
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

        if let image = UIImage(systemName: "doc.zipper") {
            metadata.iconProvider = NSItemProvider(object: image)
        }

        return metadata
    }
}
