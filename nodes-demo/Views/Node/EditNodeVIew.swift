//
//  EditNodeVIew.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 04.12.2025.
//


import SwiftUI

struct EditNodeView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismiss) var dismiss
    
    var nodeId: String
    @State var name: String
    @State var detail: String
    @State var color: Color
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading){
                Text("Name:")
                    .font(.title)
                    .padding(.bottom)
                TextField(text: $name, axis: .vertical) {
                    Text("Enter Name")
                }
                .lineLimit(2...3)
                .textFieldStyle(.roundedBorder)
                
                Text("Description:")
                    .font(.title)
                    .padding(.vertical)
                TextField(text: $detail, axis: .vertical) {
                    Text("Enter Description (optional)")
                }
                .lineLimit(5...10)
                .textFieldStyle(.roundedBorder)
                
                Text("Color:")
                    .font(.title)
                    .padding(.vertical)
                ColorPicker("Choose a color", selection: $color)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Button("Save") {
                        appModel.updateNode(
                            id: nodeId,
                            name: name,
                            detail: detail,
                            color: color.toHex()
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty && detail.isEmpty)
                }
            }
            .padding()
            .navigationTitle(Text("Edit Node"))
        }
    }
}
