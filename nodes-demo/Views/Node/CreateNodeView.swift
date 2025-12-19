//
//  CreateNodeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 20.11.2025.
//

import SwiftUI

struct CreateNodeView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismiss) var dismiss
    
    @State var name: String = ""
    @State var detail: String = ""
    @State var color = Color.white
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
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
                    
                    Button("Create") {
                        appModel.addNode(
                            name: name,
                            detail: detail,
                            position: nil,
                            color: color.toHex(includeAlpha: true)
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .padding()
            .navigationTitle(Text("Create Node"))
        }
    }
}
