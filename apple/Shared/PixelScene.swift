import SwiftUI
struct PixelScene: View {
    var outside = false
    var body: some View {
        Canvas { context, size in
            let unit = min(size.width/32,size.height/24)
            func rect(_ x: Int,_ y: Int,_ w: Int,_ h: Int,_ color: Color) {
                context.fill(Path(CGRect(x: (size.width-32*unit)/2+CGFloat(x)*unit, y: CGFloat(y)*unit, width: CGFloat(w)*unit, height: CGFloat(h)*unit)), with: .color(color))
            }
            let sage = Color(red: 0.45, green: 0.57, blue: 0.44), peach = Color(red: 0.91, green: 0.66, blue: 0.48), ink = Color(red: 0.2, green: 0.29, blue: 0.22)
            rect(2,21,28,2,sage); rect(4,13,14,8,Color(red:0.85,green:0.83,blue:0.7))
            for i in 0..<5 { rect(3+i,12-i,16-2*i,1,peach) }
            rect(7,15,3,3,.white);rect(13,15,3,6,ink);rect(25,6,3,3,peach)
            let x = outside ? 23 : 12
            rect(x,13,3,3,peach);rect(x-1,16,5,4,sage);rect(x,20,1,2,ink);rect(x+2,20,1,2,ink)
            rect(22,18,7,1,ink);rect(23,19,5,2,peach);rect(24,17,1,1,sage);rect(27,16,1,2,sage)
        }.accessibilityLabel(outside ? "Ilustrasi pixel: di luar" : "Ilustrasi pixel: rumah dan makanan")
    }
}
