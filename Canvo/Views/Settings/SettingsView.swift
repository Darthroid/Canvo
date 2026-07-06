//
//  SettingsView.swift
//  Canvo
//
//  Created by Олег Комаристый on 16.06.2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeStore: ThemeStore
    
    @AppStorage("applyThemeToExports")
    private var applyThemeToExports = true

    @AppStorage("libraryViewStyle")
    private var viewStyle: LibraryViewStyle = .grid
    
    @AppStorage("hasSeenOnboarding")
    private var hasSeenOnboarding: Bool = false
    
    @AppStorage("hasSeenCanvasOnboarding")
    private var hasSeenCanvasOnboarding: Bool = false

    private var language: String {
        (Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "") ?? "").capitalized
    }

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themeStore.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName)
                            .tag(theme)
                    }
                }
                Toggle(
                    "Apply theme to exports",
                    isOn: $applyThemeToExports
                )
            }
            
            Section("Library") {
                Picker("View Style", selection: $viewStyle) {
                    ForEach(LibraryViewStyle.allCases) { style in
                        Text(style.displayName)
                            .tag(style)
                    }
                }
            }
            
            Section("Language") {
                HStack {
                    Text("App Language")

                    Spacer()
                    
                    Button {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else {
                            return
                        }

                        UIApplication.shared.open(url)
                    } label: {
                        HStack {
                            Text(language)
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }
            }

            Section("About & Support") {
                Link(
                    destination: URL(string: "https://raw.githubusercontent.com/Darthroid/Canvo-documentation/refs/heads/main/privacy.md")!
                ) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }

                Link(
                    destination: URL(string: "https://github.com/Darthroid/Canvo-documentation/issues/new")!
                ) {
                    Label("Report an Issue", systemImage: "exclamationmark.bubble")
                }

                Link(
                    destination: URL(string: "https://apps.apple.com/app/id6761765531?action=write-review")!
                ) {
                    Label("Review on the App Store", systemImage: "star.bubble")
                }

                Button {
                    hasSeenOnboarding = false
                    hasSeenCanvasOnboarding = false
                } label: {
                    Label("Show Onboarding", systemImage: "sparkles.rectangle.stack")
                }
            }

            Section {
                VStack(spacing: 4) {
                    Text("Canvo")
                        .font(.footnote.weight(.semibold))

                    Text(versionString)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.clear)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .close) {
                        dismiss()
                    }
                } else {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }

    private var versionString: String {
        let version =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"

        let build =
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"

        return String(localized: "Version \(version) (\(build))")
    }
}
