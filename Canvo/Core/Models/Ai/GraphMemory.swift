//
//  GraphMemory.swift
//  Canvo
//
//  Created by Олег Комаристый on 24.06.2026.
//


struct GraphMemory {

    static func build(_ state: GraphState) -> String {

        let names = state.nodes
            .map(\.name)
            .prefix(20)

        return """
        CURRENT TOPICS:
        \(names.map { "- \($0)" }.joined(separator: "\n"))
        """
    }
}
