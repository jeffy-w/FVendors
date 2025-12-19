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
#if canImport(UIKit)

import UIKit

extension UIColor {
    public var f: FWrapper<UIColor> { FWrapper(self) }
    public static var f: FWrapper<UIColor>.Type { FWrapper<UIColor>.self }
}

extension FWrapper where Base: UIColor {

    public static func hexString(_ hexString: String) -> UIColor? {
        let hex = hexString.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else { return nil }

        var r: UInt64
        var g: UInt64
        var b: UInt64
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
            return nil // 对于无效长度，返回 nil
        }
        // 直接返回创建的 UIColor 实例
        return UIColor(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }

}

#endif
