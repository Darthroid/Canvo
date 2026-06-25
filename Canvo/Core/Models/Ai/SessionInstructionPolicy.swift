//
//  SessionInstructionPolicy.swift
//  Canvo
//
//  Created by Олег Комаристый on 25.06.2026.
//


struct SessionInstructionPolicy {

    enum Mode {
        case graphGeneration
        case graphExpansion
        case summarization
        case qa
        case rewriting
    }

    static func instructions(for mode: Mode) -> String {
        switch mode {

        case .graphGeneration:
            return """
            You generate structured knowledge graphs.
            Follow strict node consistency rules.
            Avoid duplication across the graph.
            """

        case .graphExpansion:
            return """
            You expand existing graph structures.
            You must stay local to provided node context.
            Do not introduce unrelated global concepts.
            """

        case .summarization:
            return """
            You compress semantic structures into abstractions.
            Focus on shared meaning.
            """

        case .qa:
            return """
            You explain graph structures clearly.
            Prefer synthesis over listing.
            """

        case .rewriting:
            return """
            You rewrite provided content only.
            Do not introduce new semantic entities.
            """
        }
    }
}