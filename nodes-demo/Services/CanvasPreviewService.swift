//
//  CanvasPreviewService.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 25.12.2025.
//

import UIKit

final class CanvasPreviewService {
    static let shared = CanvasPreviewService()

    private let fileManager = FileManager.default
    private let tempDirectory = FileManager.default.temporaryDirectory

    /// Serial queue — важен порядок и отсутствие гонок
    private let renderQueue = DispatchQueue(
        label: "canvas.preview.render.queue",
        qos: .utility
    )

    /// Чтобы не генерировать превью одного канваса параллельно
    private var pendingCanvasIds = Set<String>()
    private let lock = NSLock()

    // MARK: - Public API

    /// Асинхронная генерация превью
    public func generatePreview(
        image: UIImage,
        for canvasId: String
    ) {
        lock.lock()
        if pendingCanvasIds.contains(canvasId) {
            lock.unlock()
            return
        }
        pendingCanvasIds.insert(canvasId)
        lock.unlock()

        renderQueue.async { [weak self] in
            guard let self else { return }

            defer {
                self.lock.lock()
                self.pendingCanvasIds.remove(canvasId)
                self.lock.unlock()
            }

            guard let data = image.pngData(), !data.isEmpty else {
                return
            }

            let url = self.tempDirectory
                .appendingPathComponent("\(canvasId).png")

            do {
                try data.write(to: url, options: [.atomic])

                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .canvasPreviewUpdated,
                        object: nil,
                        userInfo: ["canvasId": canvasId]
                    )
                }
            } catch {
                print("Preview save failed:", error)
            }
        }
    }

    // MARK: - Utilities

    func getPreviewURL(for canvas: Canvas) -> URL {
        tempDirectory.appendingPathComponent("\(canvas.id).png")
    }

    func hasPreview(for canvas: Canvas) -> Bool {
        let url = getPreviewURL(for: canvas)
        return fileManager.fileExists(atPath: url.path())
    }

    func removePreview(for canvas: Canvas) {
        let url = getPreviewURL(for: canvas)
        try? fileManager.removeItem(at: url)
    }
}

