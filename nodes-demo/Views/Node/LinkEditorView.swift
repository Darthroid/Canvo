//
//  LinkEditorView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 07.12.2025.
//

import SwiftUI

struct LinkEditorView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismiss) var dismiss

    @State var fromNode: Node
    
    @State var selectedNodeId: String?
    
    @State var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedNodeId) {
                ForEach(
                    appModel.nodes
                        .filter { $0.id != fromNode.id }
                        .filter {
                            guard !searchText.isEmpty else { return true }
                            return $0.name.localizedCaseInsensitiveContains(searchText)
                        }
                ) { node in
                    VStack(alignment: .leading) {
                        Text(node.name)
                            .font(.headline)
                        Text(node.positionDescription)
                            .font(.footnote)
                    }
                }
            }
            .searchable(text: $searchText)
            .padding()
            .navigationTitle(Text("Add Link To \(fromNode.name)"))
            .toolbar {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .onChange(of: selectedNodeId) { oldValue, newValue in
            guard let toNodeId = newValue else { return }
            appModel.addConnection(from: fromNode.id, to: toNodeId)
            dismiss()
        }
    }
}
