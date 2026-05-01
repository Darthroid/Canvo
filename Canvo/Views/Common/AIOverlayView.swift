//
//  ThinkingDotsView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 09.01.2026.
//


import SwiftUI
import Combine

struct IntelligenceEdgeGlow: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Основной градиент
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.7, blue: 1.0), // blue
                            Color(red: 0.6, green: 0.5, blue: 1.0), // purple
                            Color(red: 1.0, green: 0.5, blue: 0.8), // pink
                            Color(red: 1.0, green: 0.6, blue: 0.4), // orange
                            Color(red: 0.4, green: 0.7, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 30
                )
                .blur(radius: 30)

            // Мягкое внутреннее свечение
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .stroke(
                    Color.white.opacity(0.12),
                    lineWidth: 1
                )
                .blur(radius: 6)
        }
        .padding(6)
        .opacity(0.6 + phase * 0.4)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1)
                    .repeatForever(autoreverses: true)
            ) {
                phase = 1
            }
        }
        .ignoresSafeArea(.all)
    }
}

struct IntelligenceThinkingView: View {
    @State private var pulse = false
    @Binding var title: String

    var body: some View {
        VStack(spacing: 14) {
            Text(title)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach(0..<3) { i in
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundStyle(.white)
                        .scaleEffect(pulse ? 1 : 0.4)
                        .opacity(pulse ? 1 : 0.3)
                        .animation(
                            .easeInOut(duration: 1.1)
                                .repeatForever()
                                .delay(Double(i) * 0.2),
                            value: pulse
                        )
                }
            }
        }
        .onAppear { pulse = true }
    }
}

struct AIOverlayView: View {
    @Binding var title: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            IntelligenceEdgeGlow()

            IntelligenceThinkingView(title: $title)
        }
        .transition(.opacity)
    }
}

#Preview {
    VStack {
        Spacer()
        Text("Test overlay")
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay {
        AIOverlayView(title: .constant("Thinking"))
    }
}
