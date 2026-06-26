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

        case improveWriting
        case makeShorter
        case makeLonger
        case explainBetter
        case simplify
        case professionalTone
        case generateTags
        case customRewrite
    }

    struct Context {
        var canvasName: String?
        var mainNode: NodeSchema?
        var parentNode: NodeSchema?
        var userInput: String?

        var semanticGuard: String?

        var nodeTitle: String?
        var nodeContent: String?
    }

    func instructions(for task: Task) -> String {
        [
            role(task),
            rules(task),
        ]
        .compactMap { $0 }
        .joined(separator: "\n\n")
    }
    
    func build(
        sessionInstructions: String,
        task: Task,
        context: Context
    ) -> String {

        [
            sessionInstructions,
            instructions(for: task),
            intent(task),
            contextBlock(context)
        ]
        .compactMap { $0 }
        .joined(separator: "\n\n")
    }

    // MARK: Role

    private func role(_ task: Task) -> String {
        switch task {

        case .canvasTitle:
            return "You create concise titles for mind maps."

        case .mainNode:
            return "You create the central idea of a mind map."

        case .branchNodes, .leafNodes, .childNodes:
            return "You create useful mind map nodes. Focus on content, not structure."

        case .extendNode:
            return "You extend ideas with relevant related topics."

        case .summarize:
            return "You identify common themes between ideas."

        case .askQuestions:
            return "You explain ideas and answer questions about theme."

        case .improveWriting:
            return "You improve written content while preserving meaning."

        case .makeShorter:
            return "You rewrite content in a shorter form."

        case .makeLonger:
            return "You expand content with additional useful details."

        case .explainBetter:
            return "You rewrite content to make it easier to understand."

        case .simplify:
            return "You simplify content using plain language."

        case .professionalTone:
            return "You rewrite content using a professional tone."

        case .generateTags:
            return "You generate useful tags from content."

        case .customRewrite:
            return "You rewrite content according to user instructions."
        }
    }

    // MARK: Intent

    private func intent(_ task: Task) -> String {
        switch task {

        case .canvasTitle:
            return "TASK: Generate a short title for the mind map."

        case .mainNode:
            return "TASK: Create the central idea of the mind map."

        case .branchNodes:
            return "TASK: Generate 4 major aspects of the main idea."

        case .leafNodes:
            return "TASK: Generate 2 subtopics of the parent node."

        case .childNodes:
            return "TASK: Generate 10 concepts that belong under the provided topic."

        case .extendNode:
            return "TASK: Generate EXACTLY 2-4 new nodes that expand the parent node."

        case .summarize:
            return "TASK: Create one node summarizing the provided nodes."

        case .askQuestions:
            return "TASK: Explain the provided information by breaking down the structure."

        case .improveWriting:
            return """
            TASK: Improve NODE CONTENT.
            Use NODE TITLE only as context.
            DO NOT include NODE TITLE in your response.
            """

        case .makeShorter:
            return """
            TASK: Shorten NODE CONTENT.
            Use NODE TITLE only as context.
            DO NOT include NODE TITLE in your response.
            """

        case .makeLonger:
            return """
            TASK: Expand NODE CONTENT.
            Use NODE TITLE only as context.
            DO NOT include NODE TITLE in your response.
            """

        case .explainBetter:
            return """
            TASK: Clarify NODE CONTENT.
            Use NODE TITLE only as context.
            DO NOT include NODE TITLE in your response.
            """

        case .simplify:
            return """
            TASK: Simplify NODE CONTENT.
            Use NODE TITLE only as context.
            DO NOT include NODE TITLE in your response.
            """

        case .professionalTone:
            return """
            TASK: Make NODE CONTENT professional.
            Use NODE TITLE only as context.
            DO NOT include NODE TITLE in your response.
            """

        case .customRewrite:
            return """
            TASK: Rewrite NODE CONTENT according to instruction.
            Use NODE TITLE only as context.
            DO NOT include NODE TITLE in your response.
            """

        case .generateTags:
            return """
            TASK: Generate tags from NODE TITLE and NODE CONTENT.
            """
        }
    }

    // MARK: Context

    private func contextBlock(_ c: Context) -> String? {
        var blocks: [String] = []

        if let canvasName = c.canvasName {
            blocks.append("CANVAS:\n\(canvasName)")
        }

        if let mainNode = c.mainNode {
//            blocks.append("MAIN NODE:\n\(mainNode.name)\n\(mainNode.detail)")
            blocks.append(
                """
                MAIN NODE:
                - Title: \(mainNode.name)
                - Detail: \(mainNode.detail)
                """
            )
        }

        if let parent = c.parentNode {
//            blocks.append("PARENT NODE:\n\(parent.name)\n\(parent.detail)")
            blocks.append(
                """
                PARENT NODE:
                - Title: \(parent.name)
                - Detail: \(parent.detail)
                """
            )
        }

        if let userInput = c.userInput, !userInput.isEmpty {
            blocks.append("INPUT:\n\(userInput)")
        }

        if let guardText = c.semanticGuard {
            blocks.append(guardText)
        }

        if let nodeTitle = c.nodeTitle {
            blocks.append("NODE TITLE:\n\(nodeTitle)")
        }

        if let nodeContent = c.nodeContent {
            blocks.append("NODE CONTENT:\n\(nodeContent)")
        }

        return blocks.isEmpty ? nil : blocks.joined(separator: "\n\n")
    }

    // MARK: Rules

    private func rules(_ task: Task) -> String {
        switch task {

        case .canvasTitle:
            return """
            RULES:
            - Max 6 words
            - Title only
            - No punctuation
            """

        case .mainNode:
            return """
            RULES:
            - Return single main concept
            - No explanations
            """

        case .branchNodes:
            return """
            RULES:
            - Exactly 4 nodes
            - Mutually distinct aspects
            - Avoid overlap between nodes
            """

        case .leafNodes:
            return """
            RULES:
            - Exactly 2 nodes
            - Direct subtopics only
            - Do not repeat parent concept
            """

        case .childNodes:
            return """
            RULES:
            - Exactly 10 nodes
            - Diverse ideas
            """

        case .extendNode:
            return """
            RULES:
            - EXACTLY 2-4 nodes
            - AVOID DUPLICATING PARENT NODE (INCLUDING TITLE AND DETAIL)
            - Do not repeat existing topics or obvious variations of them
            - Each node should extend concepts of PARENT NODE (read PARENT NODE field)
            - Each one must be unique and not repeating any of presented concepts
            """

        case .summarize:
            return """
            RULES:
            - Exactly 1 node
            - Capture the shared concept behind the provided nodes
            - Title should reflect common theme
            - Detail should provide brief description of common theme
            """

        case .askQuestions:
            return """
            RULES:
            - Answer clearly
            - No extra formatting
            """

        case .improveWriting,
             .makeShorter,
             .makeLonger,
             .explainBetter,
             .simplify,
             .professionalTone,
             .customRewrite:
            return """
            RULES:
            - Rewrite only NODE CONTENT
            - Do not repeat or include NODE TITLE in your response
            - No labels, headers, markdown
            - Preserve language
            - Return raw text only
            """

        case .generateTags:
            return """
            RULES:
            - EXACTLY 5 tags
            - comma separated
            - no explanations
            - should clearly be related to topic
            - Prefer broad discovery keywords
            """
        }
    }
}
