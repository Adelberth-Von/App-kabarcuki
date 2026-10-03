import SwiftUI
import KabarCore

struct DayScene: View {
    var together = false
    var at = KabarState.now
    var zone = TimeZone.current
    var action = "idle"
    var body: some View {
        Canvas { context, size in
            let phase = LocalClock.phase(at,zone:zone)
            let sky = ["DCEBE3","D4E9F3","F6CEB3","293653"][phase]
            func color(_ hex: String) -> Color { let n = UInt32(hex,radix:16)!; return Color(red:Double((n>>16)&255)/255,green:Double((n>>8)&255)/255,blue:Double(n&255)/255) }
            context.fill(Path(CGRect(origin:.zero,size:size)),with:.color(color(sky)))
            let u = min(size.width/112,size.height/38)
            func r(_ x: Int,_ y: Int,_ w: Int,_ h: Int,_ hex: String) {
                context.fill(Path(CGRect(x:(size.width-112*u)/2+CGFloat(x)*u,y:(size.height-38*u)/2+CGFloat(y)*u,width:CGFloat(w)*u,height:CGFloat(h)*u)),with:.color(color(hex)))
            }
            if phase == 3 {
                r(84,5,7,7,"FFE5AA");r(87,4,5,6,sky)
                for x in [9,25,47,67,102] { r(x,4+x%9,1,3,"E2D7BB");r(x-1,5+x%9,3,1,"E2D7BB") }
            } else { r(83,phase == 2 ? 16:6,8,8,"EBA669");r(85,phase == 2 ? 14:4,4,12,"F6C97E");r(13,9,16,2,"FFFAE9");r(16,7,8,2,"FFFAE9");r(61,12,12,2,"FFFAE9") }
            r(0,31,112,7,phase == 3 ? "40584E" : together ? "B6BEA0":"AAC4A8");r(0,30,112,1,phase == 3 ? "6D8670":"8DA98E")
            let roof = together ? "A16B83":"657D76"
            r(16,19,21,12,"E6CCAC");r(13,17,27,3,roof);r(17,14,19,3,roof);r(21,11,11,3,roof);r(20,22,5,5,"FFE7A0");r(29,23,4,8,"58665A")
            r(91,24,2,8,"817462");r(87,17,10,8,phase == 3 ? "657B70":"7D9D7C");r(89,14,6,4,phase == 3 ? "657B70":"7D9D7C")
            func person(_ x: Int,_ shirt: String) { r(x,21,5,2,"4E4550");r(x,23,5,4,"EDC8AE");r(x-1,27,7,4,shirt);r(x,31,2,3,"4E4550");r(x+3,31,2,3,"4E4550") }
            let shirt=together ? "A76B8B":"7980A5"
            switch action {
            case "outside":person(55,shirt);r(52,26,3,5,"BC967C");if together {person(38,"9683AD");r(35,23,2,5,"EDC8AE")}
            case "meal":person(50,shirt);if together {person(68,"9683AD")};r(46,31,together ? 30:20,2,"B78C76");r(48,33,2,3,"886C67");r(together ? 72:62,33,2,3,"886C67");r(57,29,5,2,"E6D7B5");r(59,25,1,2,"FFFAE9");if together {r(67,29,5,2,"E6D7B5")}
            case "home":r(47,29,together ? 30:16,6,together ? "BD91AA":"98A0BF");person(52,shirt);r(51,28,4,3,"F4DCB6");r(55,28,3,3,"D1B3D7");r(29,23,4,8,"F8DEA5");if together {person(68,"9683AD")}
            default:person(53,shirt);if together {person(67,"9683AD")}
            }
            if together {r(61,14,2,2,"CA779A");r(64,14,2,2,"CA779A");r(61,16,5,1,"CA779A");r(62,17,3,1,"CA779A");r(63,18,1,1,"CA779A")}
            r(45,34,32,1,phase == 3 ? "68756B":"DADEC2")
            for x in [7,42,81,103] { r(x,30,1,3,"698E71");r(x-1,28,3,2,together ? "ECAAC0":"F5DC96") }
        }.accessibilityHidden(true)
    }
}
