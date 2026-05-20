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
        HStack(spacing: 12) {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
            }
            .foregroundStyle(Color.primary)
            .frame(width: 25, height: 25)
            .padding(8)
            #if !os(visionOS)
            .glassEffect()
            #endif
            
            Text("\(index + 1) of \(total)")
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                #if !os(visionOS)
                .glassEffect()
                #endif
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(Color.primary)
            .frame(width: 25, height: 25)
            .padding(8)
            #if !os(visionOS)
            .glassEffect()
            #endif
            
            Spacer()
        }
        .padding(12)
        .padding(.horizontal)
    }
}
