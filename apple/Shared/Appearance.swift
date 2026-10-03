import SwiftUI

struct KabarPalette {
    let together: Bool
    let dark: Bool
    var background: Color { color(dark ? (together ? "211B28":"18231F") : (together ? "FFF5F6":"F8F6F0")) }
    var surface: Color { color(dark ? (together ? "302736":"24342D") : "FFFFFF") }
    var ink: Color { color(dark ? "F5EEE6" : (together ? "492F42":"24352E")) }
    var muted: Color { color(dark ? "C1BCB5" : (together ? "795F73":"657265")) }
    var accent: Color { color(dark ? (together ? "F5B6CE":"B5D7AC") : (together ? "954965":"496651")) }
    var tint: Color { color(dark ? (together ? "493346":"334A3D") : (together ? "F5DFE8":"DEE6D8")) }
    private func color(_ hex: String) -> Color { let n = UInt32(hex,radix:16)!; return Color(red:Double((n>>16)&255)/255,green:Double((n>>8)&255)/255,blue:Double(n&255)/255) }
}
