//
//  ExportService.swift
//  Canvo
//
//  Created by Олег Комаристый on 05.06.2026.
//

import Foundation
import ZIPFoundation

class ExportService {
    private weak var model: AppModel?
    
    public init() {
        
    }
    
    func set(model: AppModel) {
        self.model = model
    }
    
    func exportJSONCanvas(_ canvas: Canvas) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(canvas)
    }

    func exportMarkdownCanvas(_ canvas: Canvas) throws -> Data {
        let outline = OutlineService().buildOutline(
            nodes: canvas.nodes ?? [],
            connections: canvas.connections ?? []
        )

        var markdown = "# \(canvas.name)\n\n"

        for tree in outline {
            renderMarkdown(
                tree: tree,
                level: 1,
                into: &markdown
            )
        }

        guard let data = markdown.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }

        return data
    }

    func exportMarkdownPackage(_ canvas: Canvas) throws -> URL {
        let fileManager = FileManager.default

        let rootURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        let imagesURL = rootURL.appendingPathComponent("Images", isDirectory: true)

        try fileManager.createDirectory(
            at: imagesURL,
            withIntermediateDirectories: true
        )

        let markdownData = try exportMarkdownCanvas(canvas)

        try markdownData.write(
            to: rootURL.appendingPathComponent("Canvas.md")
        )

        let outline = OutlineService().buildOutline(
            nodes: canvas.nodes ?? [],
            connections: canvas.connections ?? []
        )

        try saveImages(
            from: outline,
            to: imagesURL
        )

        let zipURL = fileManager.temporaryDirectory
            .appendingPathComponent("\(canvas.name).zip")

        if fileManager.fileExists(atPath: zipURL.path) {
            try fileManager.removeItem(at: zipURL)
        }

        let archive = try Archive(
            url: zipURL,
            accessMode: .create
        )

        try archive.addEntry(
            with: "Canvas.md",
            relativeTo: rootURL
        )

        let imageFiles = try fileManager.contentsOfDirectory(
            at: imagesURL,
            includingPropertiesForKeys: nil
        )

        for file in imageFiles {
            try archive.addEntry(
                with: "Images/\(file.lastPathComponent)",
                relativeTo: rootURL
            )
        }

        try? fileManager.removeItem(at: rootURL)

        return zipURL
    }

    // MARK: - Private

    private func renderMarkdown(
        tree: NodeTree,
        level: Int,
        into markdown: inout String
    ) {
        let headingLevel = min(level + 1, 6)
        let heading = String(repeating: "#", count: headingLevel)

        markdown += "\(heading) \(tree.node.name)\n\n"
        
        for (index, _) in tree.node.images.enumerated() {
            let fileName = tree.node.images.count == 1
                ? "\(tree.node.id).png"
                : "\(tree.node.id)-\(index).png"

            markdown += "![](Images/\(fileName))\n\n"
        }

        let detail = tree.node.detail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !detail.isEmpty {
            markdown += "\(detail)\n\n"
        }

        let tags = tree.node.tagsRaw ?? ""
        if !tags.isEmpty {
            markdown += "**Tags:** \(tags)\n\n"
        }

        for child in tree.children {
            renderMarkdown(
                tree: child,
                level: level + 1,
                into: &markdown
            )
        }
    }

    private func saveImages(
        from trees: [NodeTree],
        to directory: URL
    ) throws {
        for tree in trees {
            try saveImages(
                from: tree,
                to: directory
            )
        }
    }

    private func saveImages(
        from tree: NodeTree,
        to directory: URL
    ) throws {
        for (index, imageData) in tree.node.images.enumerated() {
            let fileName = tree.node.images.count == 1
                ? "\(tree.node.id).png"
                : "\(tree.node.id)-\(index).png"

            try imageData.write(
                to: directory.appendingPathComponent(fileName)
            )
        }

        for child in tree.children {
            try saveImages(
                from: child,
                to: directory
            )
        }
    }
}
