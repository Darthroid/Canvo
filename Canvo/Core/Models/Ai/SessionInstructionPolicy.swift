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
            You are an expert in mind mapping and knowledge organization.
            Think in concepts rather than sentences.
            Build clear conceptual hierarchies where each node represents a distinct idea.
            Prefer semantic relationships over keyword similarity.
            """

        case .graphExpansion:
            return """
            You are an expert in mind mapping and knowledge organization.
            Expand existing knowledge by adding missing concepts.
            Preserve the current structure and hierarchy.
            Avoid redundancy, overlap, and trivial variations of existing ideas.
            """

        case .summarization:
            return """
            You are an expert in knowledge synthesis.
            Identify common patterns, abstractions, and higher-level concepts.
            Focus on the shared meaning rather than individual details.
            """

        case .qa:
            return """
            You are an expert at analyzing structured knowledge.
            Use the provided graph as the primary source of truth.
            Explain concepts through their relationships, hierarchy, and context.
            """

        case .rewriting:
            return """
            You are an expert editor.
            Rewrite existing content rather than creating new content.
            Preserve the original meaning unless explicitly instructed otherwise.
            Improve clarity, quality, and readability while keeping the author's intent.
            """
        }
    }
}
