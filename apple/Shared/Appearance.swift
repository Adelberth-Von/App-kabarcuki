import SwiftUI

struct KabarPalette {
    let together: Bool
    let dark: Bool
    var background: Color { color(dark ? (together ? "211A24":"161B26") : (together ? "FFF5F7":"F7F7FC")) }
    var surface: Color { color(dark ? (together ? "312532":"232A3B") : "FFFFFF") }
    var ink: Color { color(dark ? "F6F3FC" : (together ? "4C3044":"292D45")) }
    var muted: Color { color(dark ? "C1BCCD" : (together ? "795C71":"666B84")) }
    var accent: Color { color(dark ? (together ? "F5B1CA":"C2B8FF") : (together ? "AF4B76":"6552BC")) }
    var tint: Color { color(dark ? (together ? "4C3347":"383455") : (together ? "F8DFE9":"EBE7FC")) }
    private func color(_ hex: String) -> Color { let n = UInt32(hex,radix:16)!; return Color(red:Double((n>>16)&255)/255,green:Double((n>>8)&255)/255,blue:Double(n&255)/255) }
}
