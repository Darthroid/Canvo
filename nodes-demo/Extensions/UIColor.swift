//
//  UIColor.swift
//  nodes-demo
//
//  Created by Олег Комаристый on 17.11.2025.
//

import UIKit
import SwiftUI

extension UIColor {
    /// Initialize UIColor from a hex string
    /// - Parameter hex: Hex string in formats: "#RRGGBB", "#RRGGBBAA", "RRGGBB", "RRGGBBAA", "RGB", "RGBA"
    /// - Note: When using 3 or 4 character formats (RGB/RGBA), each character is duplicated (e.g., "F" becomes "FF")
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Remove # prefix if present
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        
        // Validate hex characters
        let allowedCharacters = CharacterSet(charactersIn: "0123456789ABCDEF")
        guard hexString.rangeOfCharacter(from: allowedCharacters.inverted) == nil else {
            return nil
        }
        
        var hexNumber: UInt64 = 0
        let scanner = Scanner(string: hexString)
        
        guard scanner.scanHexInt64(&hexNumber) else {
            return nil
        }
        
        let r, g, b, a: CGFloat
        
        switch hexString.count {
        case 3: // RGB (3-digit)
            r = CGFloat((hexNumber >> 8) & 0xF) / 15.0
            g = CGFloat((hexNumber >> 4) & 0xF) / 15.0
            b = CGFloat(hexNumber & 0xF) / 15.0
            a = 1.0
            
        case 4: // RGBA (4-digit)
            r = CGFloat((hexNumber >> 12) & 0xF) / 15.0
            g = CGFloat((hexNumber >> 8) & 0xF) / 15.0
            b = CGFloat((hexNumber >> 4) & 0xF) / 15.0
            a = CGFloat(hexNumber & 0xF) / 15.0
            
        case 6: // RRGGBB (6-digit)
            r = CGFloat((hexNumber >> 16) & 0xFF) / 255.0
            g = CGFloat((hexNumber >> 8) & 0xFF) / 255.0
            b = CGFloat(hexNumber & 0xFF) / 255.0
            a = 1.0
            
        case 8: // RRGGBBAA (8-digit)
            r = CGFloat((hexNumber >> 24) & 0xFF) / 255.0
            g = CGFloat((hexNumber >> 16) & 0xFF) / 255.0
            b = CGFloat((hexNumber >> 8) & 0xFF) / 255.0
            a = CGFloat(hexNumber & 0xFF) / 255.0
            
        default:
            return nil
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension Color {
    init?(hex: String) {
        guard let uiColor = UIColor(hex: hex) else { return nil }
        self.init(uiColor: uiColor)
    }
    
    func toHex(includeAlpha: Bool = false) -> String? {
        // Convert SwiftUI Color to UIColor
        let uiColor = UIColor(self)
        
        // Get the RGBA components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        // Convert components to 0-255 range
        let r = Int(red * 255.0)
        let g = Int(green * 255.0)
        let b = Int(blue * 255.0)
        let a = Int(alpha * 255.0)
        
        // Format the hex string
        if includeAlpha {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        } else {
            // Only include alpha if it's not fully opaque when not explicitly requested
            if a != 255 {
                return String(format: "#%02X%02X%02X%02X", r, g, b, a)
            }
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}

extension UIColor {

    /// Относительная яркость по WCAG
    var relativeLuminance: CGFloat {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        func adjust(_ c: CGFloat) -> CGFloat {
            return c <= 0.03928
            ? c / 12.92
            : pow((c + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * adjust(r)
             + 0.7152 * adjust(g)
             + 0.0722 * adjust(b)
    }

    /// Контрастный цвет текста
    func readableTextColor(isDarkMode: Bool) -> UIColor {
        let luminance = relativeLuminance

        // Порог можно тюнить
        if isDarkMode {
            return luminance < 0.35 ? .white : .black
        } else {
            return luminance < 0.55 ? .white : .black
        }
    }
}
