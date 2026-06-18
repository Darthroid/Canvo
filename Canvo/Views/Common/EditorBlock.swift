//
//  EditorBlock.swift
//  Canvo
//
//  Created by Олег Комаристый on 17.06.2026.
//

import SwiftUI

struct EditorBlock<Content: View, Actions: View>: View {
    let title: String
    let content: Content
    let actions: Actions

    init(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.content = content()
        self.actions = actions()
    }

    init(
        title: String,
        @ViewBuilder content: () -> Content
    ) where Actions == EmptyView {
        self.title = title
        self.content = content()
        self.actions = EmptyView()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(alignment: .firstTextBaseline) {

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                actions
            }

            content
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
