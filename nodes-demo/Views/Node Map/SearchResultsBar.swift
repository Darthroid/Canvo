//
//  SearchResultsBar.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 20.04.2026.
//

import SwiftUI

struct SearchResultsBar: View {
    let index: Int
    let total: Int
    let onNext: () -> Void
    let onPrev: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(index + 1) of \(total)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
            }
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
        }
        .padding(12)
        .glassEffect()
        .padding(.horizontal)
    }
}
