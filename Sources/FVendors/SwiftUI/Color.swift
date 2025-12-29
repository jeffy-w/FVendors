//
//  UIColor.swift
//  FVendors
//
//  (\(\
//  ( -.-)
//  o_(")(")
//  -----------------------
//  Created by jeffy on 4/17/25.
//

import SwiftUI

extension Color {
    public var f: FWrapper<Color> { FWrapper(self) }
    public static var f: FWrapper<Color>.Type { FWrapper<Color>.self }
}

extension FWrapper where Base == Color {

    // 创建动态颜色，根据系统外观自动切换
    /// - Parameters:
    ///   - light: 日间模式颜色的十六进制字符串
    ///   - dark: 夜间模式颜色的十六进制字符串
#if canImport(UIKit)
    public static func system(light: String, dark: String) -> Color {
        Color.init(
            uiColor: UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.f.hexString(dark) ?? .black
                default:
                    return UIColor.f.hexString(light) ?? .white
                }
            })
    }
#endif

    public static func hex(_ hexString: String, alpha: Double = 1) -> Color {
        let hex = hexString.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r: UInt64
        let g: UInt64
        let b: UInt64
        var a: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (
                255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17
            )
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (
                int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF
            )
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        if a == 255 {
            a = UInt64(alpha * 255)
        }
        return Color.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
