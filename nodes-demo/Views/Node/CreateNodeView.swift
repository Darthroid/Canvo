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

    let position: SIMD3<Float>?

    @State var name: String = ""
    @State var detail: String = ""
    @State var color = Color.white
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Name")
                    .font(.title)
                    .padding(.bottom)

                TextField("Enter name", text: $name)
                    .textFieldStyle(.roundedBorder)

                Text("Description")
                    .font(.title)
                    .padding(.vertical)

                TextField("Optional description", text: $detail, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)

                Text("Color")
                    .font(.title)
                    .padding(.vertical)

                ColorPicker("Choose color", selection: $color)

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
                            position: position.map {
                                (x: $0.x, y: $0.y, z: $0.z)
                            },
                            color: color.toHex(includeAlpha: true)
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .padding()
            .navigationTitle("Create Node")
        }
    }
}
