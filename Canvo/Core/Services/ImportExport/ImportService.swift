//
//  ImportService.swift
//  Canvo
//
//  Created by Олег Комаристый on 05.06.2026.
//

import Foundation
import UniformTypeIdentifiers

final class ImportService {
    public static var supportedFormats: [UTType] = [
        .json,
        UTType(filenameExtension: "md") ?? UTType(importedAs: "net.daringfireball.markdown")
    ]
    
    private weak var model: AppModel?

    private let jsonImporter = JSONImportService()
    private let markdownImporter = MarkdownImportService()

    init() {

    }

    func set(model: AppModel) {
        self.model = model
    }

    func processImport(from url: URL) async throws -> Canvas? {
        let gotAccess = url.startAccessingSecurityScopedResource()
        guard gotAccess else { return nil }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        return try handleCanvas(from: url)
    }

    func processImport(from urls: [URL]) async throws -> [Canvas] {
        var canvases: [Canvas] = []

        for url in urls {
            let gotAccess = url.startAccessingSecurityScopedResource()
            guard gotAccess else { continue }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            canvases.append(try handleCanvas(from: url))
        }

        return canvases
    }

    private func handleCanvas(from url: URL) throws -> Canvas {
        switch url.pathExtension.lowercased() {
        case "json":
            return try jsonImporter.importCanvas(from: url)

        case "md", "markdown":
            return try markdownImporter.importCanvas(from: url)

        default:
            throw ImportError.unsupportedFileType(url.pathExtension)
        }
    }
}

enum ImportError: LocalizedError {
    case unsupportedFileType(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let ext):
            if ext.isEmpty {
                return "Unsupported file type."
            } else {
                return "Unsupported file type: .\(ext)"
            }
        }
    }
}
