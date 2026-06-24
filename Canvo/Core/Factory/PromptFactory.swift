//
//  PromptFactory.swift
//  Canvo
//
//  Created by Олег Комаристый on 24.06.2026.
//


struct PromptFactory {

    enum Task {
        case canvasTitle
        case mainNode
        case branchNodes
        case leafNodes
        case childNodes
        case summarize
        case extendNode
        case askQuestions
    }

    struct Context {
        var canvasName: String?
        var mainNode: NodeSchema?
        var parentNode: NodeSchema?
        var userInput: String?

        var graphMemory: String?
        var semanticGuard: String?
    }

    func build(task: Task, context: Context) -> String {

        [
            role(task),
            intent(task),
            contextBlock(context),
            rules(task)
        ]
        .compactMap { $0 }
        .joined(separator: "\n\n")
    }

    // MARK: Role

    private func role(_ task: Task) -> String {
        switch task {

        case .canvasTitle:
            return """
            You create concise titles for mind maps.
            """

        case .branchNodes, .leafNodes, .childNodes:
            return """
            You create useful mind map nodes.
            Focus on content, not on explaining structure.
            """

        case .extendNode:
            return """
            You extend ideas with relevant related topics.
            """

        case .summarize:
            return """
            You identify common themes between ideas.
            """

        case .askQuestions:
            return """
            You explain ideas and answer questions about them.
            """

        default:
            return """
            You create mind map nodes.
            """
        }
    }

    // MARK: Intent
    
    private func intent(_ task: Task) -> String {
        switch task {

        case .canvasTitle:
            return """
            TASK:
            Generate a short title for the mind map.
            """

        case .mainNode:
            return """
            TASK:
            Create the central idea of the mind map.
            """

        case .branchNodes:
            return """
            TASK:
            Generate 4 major aspects of the main idea.
            """

        case .leafNodes:
            return """
            TASK:
            Generate 2 subtopics of the parent node.
            """

        case .childNodes:
            return """
            TASK:
            Generate 10 related ideas connected to the main topic.
            """

        case .extendNode:
            return """
            TASK:
            Generate 2-3 new nodes that expand the parent node.
            """

        case .summarize:
            return """
            TASK:
            Create one node summarizing the provided nodes.
            """

        case .askQuestions:
            return """
            TASK:
            Explain the provided information.
            """
        }
    }
    
    // MARK: Context injection

    private func contextBlock(_ c: Context) -> String? {

        var blocks: [String] = []

        if let canvasName = c.canvasName {
            blocks.append("CANVAS: \(canvasName)")
        }

        if let mainNode = c.mainNode {
            blocks.append("MAIN: \(mainNode.name) - \(mainNode.detail)")
        }

        if let parent = c.parentNode {
            blocks.append("PARENT: \(parent.name) - \(parent.detail)")
        }

        if let userInput = c.userInput, !userInput.isEmpty {
            blocks.append("INPUT: \(userInput)")
        }

        if let memory = c.graphMemory {
            blocks.append(memory)
        }

        if let guardText = c.semanticGuard {
            blocks.append(guardText)
        }

        return blocks.joined(separator: "\n\n")
    }

    // MARK: Rules

    private func rules(_ task: Task) -> String {
        switch task {
            
        case .canvasTitle:
            return """
            RULES:
            - Maximum 6 words
            - Return title only
            - No quotes
            - No punctuation
            - No explanations
            """

        case .branchNodes:
            return """
            RULES:
            - Generate exactly 4 nodes
            - Each node should represent a different aspect of the topic
            - Use concise names
            - Avoid duplicate ideas
            """

        case .extendNode:
            return """
            RULES:
            - Generate 2-3 nodes
            - Each node must directly relate to the parent node
            - Expand the topic with useful new ideas
            - Avoid repeating existing concepts
            """

        case .childNodes:
            return """
            RULES:
            - Generate exactly 10 nodes
            - Each node should explore a different idea related to the topic
            - Use practical and meaningful concepts
            - Avoid duplicates
            """

        case .summarize:
            return """
            RULES:
            - Generate exactly 1 node
            - Find the common theme shared by the provided nodes
            - Use a concise title
            """

        default:
            return """
            - produce clean structured node output
            """
        }
    }
}
