//
//  OnboardingView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 30.04.2026.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    
    @EnvironmentObject private var themeStore: ThemeStore

    @State private var showLogo = false
    @State private var showTitle = false
    @State private var showFeatures = false
    @State private var showCTA = false

    var body: some View {
        VStack(spacing: 24) {

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: adaptiveSpacing) {

                // LOGO + TITLE
                VStack(alignment: .leading, spacing: 12) {
                    
                    Image("appIcon")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(12)
                        .opacity(showLogo ? 1 : 0)
                        .offset(y: showLogo ? 0 : 8)
                    
                    Text("Welcome to Canvo")
                        .font(.largeTitle.bold())
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 10)
                }

                // FEATURES
                VStack(alignment: .leading, spacing: featureSpacing) {

                    FeatureRow(
                        icon: "sparkles",
                        title: String(localized: "Start with an Idea"),
                        detail: String(localized: "AI turns a single thought into a structured mind map in seconds")
                    )

                    FeatureRow(
                        icon: "point.3.connected.trianglepath.dotted",
                        title: String(localized: "Think Visually"),
                        detail: String(localized: "Explore ideas through connections instead of endless notes")
                    )

                    FeatureRow(
                        icon: "rectangle.3.group",
                        title: String(localized: "Bring Order to Complexity"),
                        detail: String(localized: "Transform scattered information into clear structure")
                    )
                }
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 12)
            }
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity)

            Spacer()
            
            Button {
                onFinish()
            } label: {
                Text("Continue")
                    .frame(maxWidth: contentMaxWidth)
            }
            .buttonStyle(.borderedProminent)
            .tint(themeStore.theme.canvasTheme.selection)
            .controlSize(.large)
            .opacity(showCTA ? 1 : 0)
            .offset(y: showCTA ? 0 : 10)
            .animation(.easeOut(duration: 0.35), value: showCTA)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)

        }
        .safeAreaPadding(.bottom)
        .onAppear {
            runAnimationSequence()
        }
    }

    // MARK: - Animation sequence

    private func runAnimationSequence() {
        withAnimation(.easeOut(duration: 0.35)) {
            showLogo = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.35)) {
                showTitle = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.35)) {
                showFeatures = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.35)) {
                showCTA = true
            }
        }
    }

    // MARK: - Layout tuning

    private var featureSpacing: CGFloat {
    #if os(visionOS)
        14
    #else
        UIScreen.main.bounds.width < 380 ? 10 : 14
    #endif
    }

    private var adaptiveSpacing: CGFloat {
    #if os(visionOS)
        44
    #else
        UIScreen.main.bounds.width < 380 ? 24 : 44
    #endif
        
    }

    private var horizontalPadding: CGFloat {
    #if os(visionOS)
        44
    #else
        UIScreen.main.bounds.width < 380 ? 20 : 44
    #endif
    }

    private var contentMaxWidth: CGFloat {
    #if os(visionOS)
        520
    #else
        UIScreen.main.bounds.width < 600 ? .infinity : 520
    #endif
    }
}
