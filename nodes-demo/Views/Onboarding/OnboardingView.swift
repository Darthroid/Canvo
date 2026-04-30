//
//  OnboardingView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 30.04.2026.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

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

                    VStack(alignment: .leading, spacing: 8) {

                        Text("Welcome to Canvo")
                            .font(.largeTitle.bold())
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 10)

                        Text("Visual thinking, structured ideas")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 10)
                    }
                }

                // FEATURES
                VStack(alignment: .leading, spacing: featureSpacing) {

                    FeatureRow(
                        icon: "sparkles",
                        title: "AI Generation",
                        detail: "Turn a single idea into a structured mind-map instantly"
                    )

                    FeatureRow(
                        icon: "point.topleft.down.curvedto.point.bottomright.up",
                        title: "Node-Based Editing",
                        detail: "Connect ideas freely and build non-linear structures"
                    )

                    FeatureRow(
                        icon: "rectangle.3.group",
                        title: "Visual Organization",
                        detail: "Keep complex ideas structured and easy to navigate"
                    )

                    FeatureRow(
                        icon: "star",
                        title: "Favorites",
                        detail: "Pin important canvases for quick access anytime"
                    )

                    FeatureRow(
                        icon: "clock",
                        title: "Recent Activity",
                        detail: "Your work is automatically tracked and organized"
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
            .controlSize(.large)
            .opacity(showCTA ? 1 : 0)
            .offset(y: showCTA ? 0 : 10)
            .animation(.easeOut(duration: 0.35), value: showCTA)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)

        }
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
        UIScreen.main.bounds.width < 380 ? 10 : 14
    }

    private var adaptiveSpacing: CGFloat {
        UIScreen.main.bounds.width < 380 ? 24 : 44
    }

    private var horizontalPadding: CGFloat {
        UIScreen.main.bounds.width < 380 ? 20 : 44
    }

    private var contentMaxWidth: CGFloat {
        UIScreen.main.bounds.width < 600 ? .infinity : 520
    }
}
