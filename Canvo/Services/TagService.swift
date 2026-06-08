//
//  TagService.swift
//  Canvo
//
//  Created by Олег Комаристый on 06.06.2026.
//

import Foundation

@MainActor
public class TagService {

    private let repository: CanvasRepository

    init(repository: CanvasRepository) {
        self.repository = repository
    }

    func resolveTags(
        from rawText: String,
        canvas: Canvas
    ) -> [Tag] {

        let names = Set(rawText.parseTags())

        guard !names.isEmpty else {
            return []
        }

        let existing = canvas.tags ?? []

        var result = existing

        let existingNames = Set(
            existing.map(\.name)
        )

        let missing = names.subtracting(
            existingNames
        )

        for name in missing {
            let tag = Tag(
                name: name,
                canvas: canvas
            )
            repository.createTag(name: name, canvas: canvas)

            result.append(tag)
        }

        return result
    }

    func recomputeCanvasTags(
        canvasId: String
    ) {

        guard let canvas = repository.canvas(id: canvasId) else {
            return
        }

        let nodes = canvas.nodes ?? []

        let allTags = Set(
            nodes.flatMap {
                ($0.tagsRaw ?? "").parseTags()
            }
        )

        for tag in canvas.tags ?? [] {
            repository.deleteTag(tag)
        }

        for name in allTags {
            repository.createTag(name: name, canvas: canvas)
        }

        repository.save()
    }

    func updateNodeTags(
        nodeId: String,
        raw: String
    ) {

        guard let node = repository.node(id: nodeId),
              let canvas = node.canvas
        else {
            return
        }

        let tags = resolveTags(
            from: raw,
            canvas: canvas
        )

        node.tagsRaw = tags
            .map { $0.name }
            .joined(separator: ",")
    }

    func createTag(
        name: String,
        canvas: Canvas?
    ) {

        guard let canvas else {
            return
        }

        let exists = canvas.tags?
            .contains {
                $0.name == name
            } ?? false

        guard !exists else {
            return
        }

        repository.createTag(name: name, canvas: canvas)
    }

    func deleteTag(
        name: String,
        canvas: Canvas?
    ) {

        guard let canvas else {
            return
        }

        guard let tag = canvas.tags?
            .first(where: {
                $0.name == name
            }) else {
            return
        }

        repository.deleteTag(tag)

        for node in canvas.nodes ?? [] {

            let tags = (node.tagsRaw ?? "")
                .components(separatedBy: ",")
                .filter {
                    $0 != name
                }

            node.tagsRaw = tags.joined(
                separator: ","
            )
        }

        repository.save()
    }
}
