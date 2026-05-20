//
//  OutlineView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 16.04.2026.
//

import SwiftUI

struct OutlineView: View {
    
    enum SidebarPresentationStyle {
        case overlay
        case sheet
    }
    
    let preferredWidth: CGFloat?
    let style: SidebarPresentationStyle
    
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        let outline = appModel.buildOutline()
        
        let isSheet = style == .sheet
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Outline")
                .font(.headline)
                .padding(.top, 20)
                .padding(.horizontal, isSheet ? 16 : 0)
            
            List {
                ForEach(outline) { tree in
                    NodeTreeView(tree: tree)
                        .listRowBackground(Color.clear)
                        .environment(appModel)
                }
            }
            .listStyle(.plain)
            .background(.clear)
            .transaction { tx in
                tx.animation = nil
            }
        }
        .frame(
            width: style == .sheet ? nil : preferredWidth
        )
        .background(
            Color.clear
        )
        .clipShape(
            isSheet
            ? AnyShape(Rectangle())
            : AnyShape(RoundedRectangle(cornerRadius: 20))
        )
        .shadow(
            color: isSheet ? .clear : .black.opacity(0.15),
            radius: isSheet ? 0 : 8,
            y: isSheet ? 0 : 4
        )
        .padding(.horizontal, isSheet ? 0 : 20)
        #if !os(visionOS)
        .glassEffect(isSheet ? .identity : .regular, in: isSheet
                     ? AnyShape(Rectangle())
                     : AnyShape(RoundedRectangle(cornerRadius: 20)))
        #endif
    }
}
