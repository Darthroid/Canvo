//
//  AIGenerationSnackbar.swift
//  Canvo
//
//  Created by Олег Комаристый on 14.05.2026.
//

import SwiftUI

struct AIGenerationSnackbar: View {
    let title: String
    let onCancel: () -> Void
    
    @State private var animatedGradient = false
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(borderGradient, lineWidth: 1.5)
                        .blur(radius: 0.3)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(glowGradient, lineWidth: 4)
                        .blur(radius: 12)
                        .opacity(0.9)
                        .padding(-1)
                }
            
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(borderGradient)
                    .shadow(radius: 8)
                
                Text(title)
                    .font(.headline)
//                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
                
                Button(role: .cancel) {
                    onCancel()
                }
                #if !os(visionOS)
                .buttonStyle(.glass)
                #endif
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: 420)
        .frame(height: 60)
        .shadow(radius: 20)
        .onAppear {
            withAnimation(
                .linear(duration: 4)
                .repeatForever(autoreverses: false)
            ) {
                animatedGradient.toggle()
            }
        }
    }
    
    private var borderGradient: AngularGradient {
        AngularGradient(
            colors: [
                .blue,
                .purple,
                .cyan,
                .mint,
                .blue
            ],
            center: .center,
            angle: .degrees(animatedGradient ? 360 : 0)
        )
    }
    
    private var glowGradient: AngularGradient {
        AngularGradient(
            colors: [
                .blue.opacity(0.9),
                .purple.opacity(0.9),
                .cyan.opacity(0.9),
                .mint.opacity(0.9),
                .blue.opacity(0.9)
            ],
            center: .center,
            angle: .degrees(animatedGradient ? 360 : 0)
        )
    }
}

#Preview {
    VStack {
        Spacer()
        Text("Some action")
        Spacer()
    }
    .frame(maxWidth: .infinity)
    .overlay(alignment: .bottom) {
        AIGenerationSnackbar(
            title: "Generating Canvas",
            onCancel: {
                //
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .transition(
            .move(edge: .bottom)
            .combined(with: .opacity)
        )
    }
}
