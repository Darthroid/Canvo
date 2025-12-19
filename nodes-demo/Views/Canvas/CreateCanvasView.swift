//
//  CreateCanvasView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 19.12.2025.
//

import SwiftUI

struct CreateCanvasView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismiss) var dismiss
    
    @State var name: String = ""
    
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
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Button("Create") {
                        appModel.createCanvas(name: name)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .padding()
            .navigationTitle(Text("Create Canvas"))
        }
    }
}
