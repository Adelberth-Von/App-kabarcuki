import SwiftUI

struct PixelScene: View {
    var outside = false
    var body: some View {
        DayScene(action: outside ? "outside" : "idle")
            .accessibilityLabel(outside ? "Ilustrasi pixel: di luar" : "Ilustrasi pixel: rumah dan makanan")
    }
}
