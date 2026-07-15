//
//  OutlineView.swift
//  Canvo
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
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        let outline = appModel.buildOutline()
        
        let isSheet = style == .sheet
        
        return VStack(alignment: .leading, spacing: 16) {
            Text(appModel.session.currentCanvas?.name ?? "Outline")
                .font(.headline)
                .padding(.top, 20)
                #if os(visionOS)
                .padding(.horizontal, 16)
                #else
                .padding(.horizontal, isSheet ? 16 : 0)
                #endif
            
            List {
                ForEach(outline) { tree in
                    NodeTreeView(
                        tree: tree,
                        level: 0
                    )
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
        .adaptiveGlass(isSheet: isSheet, in: isSheet
                       ? AnyShape(Rectangle())
                       : AnyShape(RoundedRectangle(cornerRadius: 20))
        )
        #else
        .glassBackgroundEffect()
        .onChange(of: scenePhase, initial: true) {
            switch scenePhase {
            case .inactive, .background:
                appModel.outlineOpen = false
            case .active:
                appModel.outlineOpen = true
            @unknown default:
                appModel.outlineOpen = false
            }
        }
        #endif
    }
}
