//
//  OnboardingView.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 30.04.2026.
//

import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

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

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to Canvo")
                            .font(.largeTitle.bold())

                        Text("Visual thinking, structured ideas")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                // FEATURES (NO SCROLL)
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
            .frame(maxWidth: .infinity)
            .padding(.horizontal, horizontalPadding)

//            Spacer(minLength: 16)
        }
    }

    // MARK: - Adaptive layout tuning

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
