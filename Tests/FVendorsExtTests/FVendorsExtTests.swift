import FVendorsExt
import SwiftUI
import Testing

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

@Suite("FVendorsExt Tests")
struct FVendorsExtTests {
    @Test("FWrapper preserves wrapped base value")
    func wrapperPreservesBaseValue() {
        let wrapper = FWrapper("value")

        #expect(wrapper.base == "value")
    }

    #if canImport(AppKit)
    @Test("Color hex parses six digit RGB on macOS")
    func colorHexParsesSixDigitRGBOnMacOS() throws {
        let color = Color.f.hex("#3366FF")
        let nsColor = try #require(NSColor(color).usingColorSpace(.sRGB))

        #expect(abs(nsColor.redComponent - 0x33 / 255) < 0.001)
        #expect(abs(nsColor.greenComponent - 0x66 / 255) < 0.001)
        #expect(abs(nsColor.blueComponent - 1.0) < 0.001)
        #expect(abs(nsColor.alphaComponent - 1.0) < 0.001)
    }
    #endif

    #if canImport(UIKit)
    @Test("UIColor hexString parses six digit RGB")
    func uiColorHexStringParsesSixDigitRGB() throws {
        let color = try #require(UIColor.f.hexString("#3366FF"))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        #expect(color.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
        #expect(abs(red - 0x33 / 255) < 0.001)
        #expect(abs(green - 0x66 / 255) < 0.001)
        #expect(abs(blue - 1.0) < 0.001)
        #expect(abs(alpha - 1.0) < 0.001)
    }

    @Test("UIColor hexString rejects invalid input")
    func uiColorHexStringRejectsInvalidInput() {
        #expect(UIColor.f.hexString("not-a-color") == nil)
    }
    #endif
}
