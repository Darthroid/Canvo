//
//  MarkdownImportService.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.07.2026.
//


import Foundation

final class MarkdownImportService {
    
    private var headingStack: [(level: Int, node: Node)] = []
    private var nodes: [Node] = []
    private var connections: [NodeConnection] = []
    private var currentNode: Node?
    
    private func reset() {
        nodes.removeAll(keepingCapacity: true)
        connections.removeAll(keepingCapacity: true)
        headingStack.removeAll(keepingCapacity: true)
        currentNode = nil
    }

    func importCanvas(from url: URL) throws -> Canvas {
        let markdown = try String(contentsOf: url, encoding: .utf8)
        return try importCanvas(from: markdown)
    }

    func importCanvas(from markdown: String) throws -> Canvas {
        reset()

        let lines = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: .newlines)

        let canvas = createCanvas(from: lines)

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !line.isEmpty else {
                continue
            }

            if let heading = parseHeading(line) {
                // Первый H1 используется как название Canvas
                if heading.level == 1 {
                    continue
                }

                handleHeading(
                    level: heading.level,
                    title: heading.title,
                    canvas: canvas
                )

                continue
            }

            if handleTags(line) {
                continue
            }

            appendDetail(line)
        }

        canvas.nodes = nodes
        canvas.connections = connections

        
        performLayout(for: canvas)

        return canvas
    }
    
    private func parseHeading(_ line: String) -> (level: Int, title: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        guard trimmed.hasPrefix("#") else {
            return nil
        }

        var level = 0

        for character in trimmed {
            guard character == "#" else {
                break
            }
            level += 1
        }

        guard (1...6).contains(level) else {
            return nil
        }

        let title = trimmed
            .dropFirst(level)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return nil
        }

        return (level, title)
    }
    
    private func handleHeading(
        level: Int,
        title: String,
        canvas: Canvas
    ) {
        while let last = headingStack.last,
              last.level >= level {
            headingStack.removeLast()
        }

        let node = Node(
            name: title,
            detail: "",
            x: 0,
            y: 0,
            z: 0,
            canvas: canvas
        )

        nodes.append(node)

        if let parent = headingStack.last?.node {
            connections.append(
                NodeConnection(
                    fromNodeId: parent.id,
                    toNodeId: node.id,
                    canvas: canvas
                )
            )
        }

        headingStack.append((level, node))
        currentNode = node
    }
    
    private func appendDetail(_ line: String) {
        guard let currentNode else {
            return
        }

        if currentNode.detail.isEmpty {
            currentNode.detail = line
        } else {
            currentNode.detail += "\n" + line
        }
    }
    
    private func handleTags(_ line: String) -> Bool {
        guard let currentNode else {
            return false
        }

        let prefix = "**Tags:**"

        guard line.hasPrefix(prefix) else {
            return false
        }

        currentNode.tagsRaw = line
            .dropFirst(prefix.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return true
    }
    
    private func createCanvas(from lines: [String]) -> Canvas {
        for line in lines {
            guard let heading = parseHeading(line), heading.level == 1 else {
                continue
            }

            return Canvas(name: heading.title)
        }

        return Canvas(name: "Imported Markdown")
    }
    
    private func performLayout(for canvas: Canvas) {
        guard
            var nodes = canvas.nodes,
            let connections = canvas.connections,
            !nodes.isEmpty
        else {
            return
        }

        CanvasLayoutService().layoutTree(
            nodes: &nodes,
            connections: connections
        )

        canvas.nodes = nodes
    }
}

enum MarkdownImportError: LocalizedError {
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Markdown import is not implemented."
        }
    }
}
