//
//  SemanticGuard.swift
//  Canvo
//
//  Created by Олег Комаристый on 24.06.2026.
//

@available(iOS 26.0, *)
struct SemanticGuard {

    static func build(_ nodes: [NodeSchema]) -> String {

        guard !nodes.isEmpty else {
            return ""
        }

        let topics = nodes.map(\.name)

        return """
        EXISTING TOPICS:

        \(topics.map { "- \($0)" }.joined(separator: "\n"))

        Do not generate:
        - identical topics
        - near-duplicates
        - synonyms
        - minor rewordings of existing topics
        """
    }
}
