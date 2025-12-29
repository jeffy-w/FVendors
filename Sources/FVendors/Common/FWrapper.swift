// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A wrapper for a generic type that can be used to create code like `aObject.f.bProperty`.
///
/// Example usage 1:
/// ```swift
///// SwiftUI
///extension View {
///    public var f: FWrapper<Self> { FWrapper(self) }
///    public static var f: FWrapper<Self>.Type { FWrapper<Self>.self }
///}
///
///extension FWrapper where Base: View {
///    public func xxxx() -> some View{
///        content.YYYY()
///    }
///}
///// Usage
///Text("xx").f.xxxx
/// ```
///
/// Example usage 2:
/// ```swift
///// UIKit
///extension UIView {
///    public var f: FWrapper<UIView> { FWrapper(self) }
///    public static var f: FWrapper<UIView>.Type { FWrapper<UIView>.self }
///}
///extension FWrapper where Base: UIView {
///    public func xxxx() -> some UIView{
///        base.YYYY()
///    }
///}
///// Usage
///UIView().f.shadowStyle1()
/// ```
public struct FWrapper<Base> {
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}
