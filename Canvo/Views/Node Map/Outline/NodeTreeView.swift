//
//  NodeTreeView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 15.04.2026.
//

import SwiftUI

struct NodeTreeView: View {
    let tree: NodeTree
    var level: Int = 0

    @State private var isExpanded = true
    @Environment(AppModel.self) private var appModel

    var isSelected: Bool {
        appModel.session.selectedNodeIds.contains(tree.node.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {

            HStack(alignment: .top, spacing: 8) {

                if !tree.children.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .foregroundStyle(Color(isSelected ? .accent : .label))
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(width: 16)
                }

                VStack(alignment: .leading, spacing: 6) {

                    Text(tree.node.name)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(isSelected ? .accent : .label))

                    if let imageData = tree.node.coverImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if !tree.node.richText.characters.isEmpty {
                        Text(tree.node.richText)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    appModel.session.selectedNodeIds = [tree.node.id]
                    appModel.session.centerOnNodeId = tree.node.id
                }
            }
            .padding(.vertical, 8)

            if isExpanded {
                ForEach(tree.children) { child in
                    NodeTreeView(
                        tree: child,
                        level: level + 1
                    )
                    .padding(.leading, 12)
                    .environment(appModel)
                }
            }
        }
        .padding(.leading, 12)
        .overlay(alignment: .leading) {
            HStack(spacing: 12) {
//                ForEach(0..<level, id: \.self) { _ in
                    Rectangle()
                        .fill(.separator.opacity(0.5))
                        .frame(width: 1)
//                }
            }
            .padding(.leading, 6)
        }
    }
}
