//
//  AIResponseView.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//

import SwiftUI
import MarkdownUI

struct AIResponseView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var response: String
        
    var body: some View {
        VStack(alignment: .leading) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Markdown(response)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Невидимый якорь в самом низу
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                }
                .onChange(of: response) { _, _ in
                    // Прокручиваем к низу при каждом обновлении текста
                    withAnimation(.none) {   // без анимации для плавности
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        .navigationTitle("AI Explanation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .close) {
                    AIGenerationService.shared.cancelCurrentTask()
                    response = ""
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Copy to Clipboard", systemImage: "document.on.document") {
                    UIPasteboard.general.string = response
                }
                .buttonStyle(.glass)
                .labelsHidden()
            }
        }
    }
}
