//
//  CreateNodeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 20.11.2025.
//

import SwiftUI
import RichTextKit

struct CreateNodeView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let position: SIMD3<Float>?

    @State private var name: String = ""
//    @State private var detail: String = ""
    @State private var color: Color = .white
    @State private var tagsRaw: String = ""
    
    @State private var attributedDetail = NSAttributedString()
    
    @StateObject private var context = RichTextContext()

    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .focused($isNameFocused)
                        .textInputAutocapitalization(.sentences)
                }

                Section {
//                    TextField(
//                        "Description",
//                        text: $detail,
//                        axis: .vertical
//                    )
//                    .lineLimit(3...6)
                    
                    RichTextEditor(
                        text: $attributedDetail,
                        context: context
                    )
                    .frame(minHeight: 200)
                }

                Section {
                    ColorPicker("Color", selection: $color, supportsOpacity: true)
                }
                
                Section {
                    TextField(
                        "Tags (separate with commas)",
                        text: $tagsRaw,
                        axis: .horizontal
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                }
            }
            .navigationTitle("Create Node")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm) {
                        createNode()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isNameFocused = true
                }
            }
        }
    }
    
    private func createNode() {        
        let id = UUID().uuidString
        
        let positionValue = position ?? SIMD3<Float>(0, 1.0, -1.5)
        
        
        let richTextData = try? attributedDetail.data(
            from: NSRange(location: 0, length: attributedDetail.length),
            documentAttributes: [
                .documentType: NSAttributedString.DocumentType.rtf
            ]
        )
        
        let snapshot = NodeSnapshot(
            id: id,
            name: name,
            detail: "",
            detailRichText: richTextData,
            x: positionValue.x,
            y: positionValue.y,
            z: positionValue.z,
            color: color.toHex(includeAlpha: true),
            tagsRaw: tagsRaw
        )
        
        let action = AddNodeAction(node: snapshot)
        
        appModel.actionService.perform(action)
    }
}
