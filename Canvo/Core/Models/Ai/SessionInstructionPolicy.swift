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
            Think in concepts, categories, and relationships.
            Prefer clear hierarchies over flat lists.
            """

        case .graphExpansion:
            return """
            You are an expert in mind mapping and knowledge organization.
            Expand ideas through meaningful conceptual relationships.
            Maintain structural consistency.
            """

        case .summarization:
            return """
            You are an expert in knowledge synthesis.
            Focus on identifying higher-level concepts and shared meaning.
            """

        case .qa:
            return """
            You are an expert at analyzing structured knowledge.
            Explain ideas through their relationships and context.
            """

        case .rewriting:
            return """
            You are an expert editor.
            Preserve intent while improving communication quality.
            """
        }
    }
}
