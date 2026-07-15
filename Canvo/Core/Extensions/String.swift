//
//  String.swift
//  Canvo
//
//  Created by Олег Комаристый on 22.01.2026.
//

import Foundation

extension String {
    func parseTags() -> [String] {
        self
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }
}

extension String {
    /// Returns the localized version of the string using the main bundle.
    var localized: String {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return String(localized: String.LocalizationValue(self))
        } else {
            return NSLocalizedString(self, comment: "")
        }
    }
    
    /// Returns the localized version of the string from a specific bundle.
    /// Useful for Swift Packages, frameworks, or multi-target apps.
    func localized(bundle: Bundle) -> String {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return String(localized: String.LocalizationValue(self), bundle: bundle)
        } else {
            return NSLocalizedString(self, bundle: bundle, comment: "")
        }
    }
    
    /// Returns a formatted localized string with dynamic arguments.
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
