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

        // rewrite
        case improveStyle
        case makeShorter
        case makeLonger
        case explain
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

        case .improveStyle:
            return "You improve written content while preserving meaning."

        case .makeShorter:
            return "You rewrite content in a shorter form."

        case .makeLonger:
            return "You expand content with additional useful details."

        case .explain:
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
            return """
            TASK:
            Read the provided context and generate the best title for the entire mind map.
            The title should represent the overall topic, not an individual node.
            """

        case .mainNode:
            return """
            TASK:
            Read the user input and create the single central concept that everything else in the mind map should branch from.
            """

        case .branchNodes:
            return """
            TASK:
            Read the MAIN NODE and generate its primary first-level branches.
            Each branch should represent a different major aspect of the main concept.
            """

        case .leafNodes:
            return """
            TASK:
            Read the PARENT NODE and generate direct child topics.
            These should refine the parent, not introduce unrelated or sibling concepts.
            """

        case .childNodes:
            return """
            TASK:
            Read the PARENT NODE and generate a diverse set of direct child concepts.
            Every generated node should naturally belong under the provided parent.
            """

        case .extendNode:
            return """
            TASK:
            Read the PARENT NODE and generate new child nodes that meaningfully extend it.
            Add missing concepts instead of rewording or repeating existing ones.
            """

        case .summarize:
            return """
            TASK:
            Read all provided nodes and identify the single concept that best represents them together.
            Produce one node summarizing their shared meaning.
            """

        case .askQuestions:
            return """
            TASK:
            Answer the user's question using the provided graph.
            Base the answer on the supplied information whenever possible.
            """

        case .improveStyle:
            return """
            TASK:
            Rewrite NODE CONTENT to improve clarity, flow and writing quality.
            Rephrase the text using different wording and sentence structure.
            Preserve the original meaning.
            Use NODE TITLE only as context.
            Return only the rewritten NODE CONTENT.
            """

        case .makeShorter:
            return """
            TASK:
            Rewrite NODE CONTENT into a significantly shorter version, max 2-3 sentences.
            Remove repetition and unnecessary details while preserving essential information.
            Use NODE TITLE only as context.
            Return only the rewritten NODE CONTENT.
            """

        case .makeLonger:
            return """
            TASK:
            Rewrite NODE CONTENT into a more detailed version.
            Add useful explanations without changing the original meaning.
            Use NODE TITLE only as context.
            Return only the rewritten NODE CONTENT.
            """

        case .explain:
            return """
            TASK:
            Rewrite NODE CONTENT as an explanation for someone unfamiliar with the topic.
            Assume no prior knowledge.
            Introduce brief clarifications when they improve understanding.
            Use NODE TITLE only as context.
            Return only the rewritten NODE CONTENT.
            """

        case .simplify:
            return """
            TASK:
            Rewrite NODE CONTENT using simple everyday language.
            Replace difficult words and complex sentences with simpler alternatives.
            Preserve the original meaning.
            Use NODE TITLE only as context.
            Return only the rewritten NODE CONTENT.
            """

        case .professionalTone:
            return """
            TASK:
            Rewrite NODE CONTENT using a professional and polished tone.
            Improve precision and wording while preserving the original meaning.
            Use NODE TITLE only as context.
            Return only the rewritten NODE CONTENT.
            """

        case .customRewrite:
            return """
            TASK:
            Rewrite NODE CONTENT according to the user's instruction.
            Follow the instruction as closely as possible while preserving information that was not requested to change.
            Use NODE TITLE only as context.
            Return only the rewritten NODE CONTENT.
            """

        case .generateTags:
            return """
            TASK:
            Read NODE TITLE and NODE CONTENT and generate relevant discovery tags describing the topic.
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

        case .improveStyle,
             .makeShorter,
             .makeLonger,
             .explain,
             .simplify,
             .professionalTone,
             .customRewrite:
            return """
            RULES:
            - Rewrite only NODE CONTENT
            - Rewrite the text completely instead of making minor edits
            - Use different wording and sentence structure
            - Preserve the original meaning unless explicitly instructed otherwise
            - Use NODE TITLE only as context
            - Do not include NODE TITLE in the response
            - No labels, headings or markdown
            - Preserve the original language
            - Return only the rewritten text
            """

        case .generateTags:
            return """
            RULES:
            - EXACTLY 5 tags
            - each tag MUST be ONE word only (no spaces allowed)
            - output format: tag1, tag2, tag3, tag4, tag5
            - no explanations, no punctuation except commas
            - tags must represent key concepts of the topic
            - avoid multi-word phrases under any circumstances
            """
        }
    }
}
