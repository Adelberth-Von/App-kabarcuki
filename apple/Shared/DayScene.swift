import SwiftUI
import KabarCore

/// Static Canvas snapshots allow WidgetKit to animate data transitions safely.
struct DayScene: View {
    var together = false
    var at = KabarState.now
    var zone = TimeZone.current
    var action = "idle"
    var body: some View {
        Canvas { context, size in
            let world = PixelWorld(context: context, size: size, phase: LocalClock.phase(at, zone: zone), pair: together, action: action)
            world.draw()
        }.accessibilityHidden(true)
    }
}

private final class PixelWorld {
    var context: GraphicsContext
    let size: CGSize
    let phase: Int
    let pair: Bool
    let action: String
    let frame = 0
    let cycle = 0.0
    var night: Bool { phase == 3 }
    var sky: Int { [0xB7D7D4,0xAAD6E3,0xC799B8,0x172A45][phase] }
    var horizon: Int { [0xF7DDB5,0xE5F1DA,0xF6BD94,0x385275][phase] }
    var leaf: Int { [0x6C9F85,0x65A17A,0x926D81,0x355E60][phase] }
    var leafLight: Int { [0xA6C79B,0xA7CE8A,0xC99897,0x537875][phase] }
    var ground: Int { [0xA7BA91,0xA3BD85,0xB6988D,0x486565][phase] }
    var accent: Int { pair ? 0xC7829E : 0x6B8DA9 }
    var wood: Int { night ? 0x735B6B : 0x9D7680 }
    var wall: Int { [0xF5DDBE,0xF6E5C9,0xECC8AD,0xC5ACB1][phase] }
    var window: Int { night ? 0xFFE2A3 : 0xF8ECD0 }
    init(context: GraphicsContext, size: CGSize, phase: Int, pair: Bool, action: String) {
        self.context = context; self.size = size; self.phase = phase; self.pair = pair; self.action = action
    }
    func wave(_ offset: Double, _ amount: Int) -> Int { Int((sin(cycle + offset) * Double(amount)).rounded()) }
    func mix(_ a: Int, _ b: Int, _ amount: Double) -> Int {
        let red = Int((Double((a >> 16) & 255) * (1 - amount) + Double((b >> 16) & 255) * amount).rounded())
        let green = Int((Double((a >> 8) & 255) * (1 - amount) + Double((b >> 8) & 255) * amount).rounded())
        let blue = Int((Double(a & 255) * (1 - amount) + Double(b & 255) * amount).rounded())
        return (red << 16) | (green << 8) | blue
    }
    func color(_ hex: Int) -> Color { Color(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255) }
    func r(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ hex: Int) {
        context.fill(Path(CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h))), with: .color(color(hex)))
    }
  func draw() {
    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(color(sky)))
    let u = max(size.width / 160, size.height / 64)

    context.translateBy(x: (size.width - 160 * u) / 2, y: size.height - 64 * u)
    context.scaleBy(x: u, y: u)
    // Eight broad colour bands keep the sky soft without blurring pixel edges.
    for i in 0..<8 {
      r(0, i * 5, 160, 5, mix(sky, horizon, Double(i) / 9));
    }
    celestial();
    cloud(9 + wave(0.0, 3), 12, night ? 0x52617C : 0xFFF1DA);
    cloud(99 + wave(2.0, 2), 8, night ? 0x465C78 : 0xFBEEDC);
    // Distant city lights and two stepped ridgelines give the world depth.
    let far = [0xA3BAB2, 0xA2C5BA, 0xB597AD, 0x405777][phase];
    for i in 0..<14 {
      let x = i * 13 - 4, h = 4 + (i * 7) % 9;
      r(x, 40 - h, 9, h, far);
      if night && i % 2 == 0 { r(x + 2, 35 - h, 1, 2, 0xDCC598); }
    }
    for i in 0..<16 {
      r(i * 10, 36 + (i * 3) % 7, 10, 14, night ? 0x355460 : 0x88AC99);
      r(i * 10, 41 + (i * 5) % 4, 10, 11, leaf);
    }
    r(0, 47, 160, 17, ground);
    r(0, 49, 160, 2, night ? 0x698077 : 0xCDD0A1);
    r(0, 57, 160, 7, night ? 0x345657 : 0x8EA983);
    for i in 0..<20 {
      r(i * 9 + 1, 59 + i % 4, 3, 1, night ? 0x4C6C65 : 0xB8C49A);
    }
    tree(5, 28, false); tree(143, 30, true);
    switch action {
      case "home": room(false)
      case "meal": room(true)
      default: garden();
    }
    foreground();

  }
  func cloud(_ x: Int, _ y: Int, _ color: Int) {
    r(x, y + 3, 25, 2, color); r(x + 4, y, 10, 3, color);
    r(x + 13, y + 1, 8, 2, color);
  }
  func celestial() {
    if night {
      r(124, 5, 10, 10, 0x67768A); r(123, 4, 10, 10, 0xFFE8B6);
      r(126, 2, 9, 10, sky); r(123, 8, 2, 4, 0xFFF4D4);
      for i in 0..<24 {
        let x = 6 + (i * 37) % 149, y = 3 + (i * 11) % 22;
        let bright = (frame / 8 + i * 2) % 7 < 3;
        r(x, y, 1, 1, bright ? 0xF8E7C6 : 0x778FA7);
        if bright && i % 5 == 0 { r(x - 1, y, 3, 1, 0xB4C7CC); r(x, y - 1, 1, 3, 0xB4C7CC); }
      }
      // A shooting star appears briefly, entering and leaving the visible sky.
      if frame >= 76 && frame < 88 {
        let x = 24 + (frame - 76) * 5;
        r(x, 8 + (frame - 76) / 3, 3, 1, 0xF9EAC8);
        r(x - 5, 7 + (frame - 76) / 3, 5, 1, 0x8EACC0);
      }
    } else {
      let y = phase == 2 ? 26 : phase == 0 ? 20 : 7;
      r(121, y - 2, 16, 16, phase == 2 ? 0xEBAB9B : 0xF4DFB5);
      r(124, y, 10, 12, 0xFFE4A4); r(122, y + 3, 14, 6, 0xFFEAB5);
      if phase == 0 {
        let x = frame * 2 - 16;
        bird(x, 12 + wave(0.0, 2)); bird(x - 12, 15 + wave(1.0, 2));
      }
    }
  }
  func bird(_ x: Int, _ y: Int) {
    let up = frame / 3 % 2;
    r(x, y, 1, 1, 0x63787E); r(x - 2, y - up, 2, 1, 0x63787E); r(x + 1, y - up, 2, 1, 0x63787E);
  }
  func tree(_ x: Int, _ y: Int, _ blossom: Bool) {
    r(x + 7, y + 8, 4, 22, night ? 0x6C6070 : 0x977A78);
    r(x + 4, y + 14, 5, 2, wood); r(x + 10, y + 11, 4, 2, wood);
    let base = blossom && pair ? (night ? 0x88657F : 0xCC9AAC) : leaf;
    let top = blossom && pair ? (night ? 0xAF8A9D : 0xF0BAC5) : leafLight;
    r(x + 1, y + 3, 16, 11, base); r(x - 1, y + 6, 20, 5, base);
    r(x + 4, y, 10, 4, top); r(x + 1, y + 4, 5, 4, top);
    r(x + 12, y + 3, 4, 3, top); r(x + 8, y + 8, 3, 2, top);
    r(x + 3, y + 10, 3, 2, night ? 0x3C5761 : 0x759782);
  }
  func cottage(_ x: Int, _ y: Int) {
    r(x, y + 9, 33, 23, 0x6E6475); r(x + 1, y + 10, 31, 21, wall);
    for i in 0..<5 { r(x - 3 + i * 3, y + 8 - i * 2, 39 - i * 6, 2, accent); }
    r(x + 6, y + 3, 22, 1, pair ? 0xEDB4BF : 0xACC2CC);
    r(x + 25, y - 1, 4, 7, wood); r(x + 24, y - 2, 6, 2, 0xC3A39B);
    r(x + 5, y + 14, 11, 10, wood); r(x + 6, y + 15, 9, 8, window);
    r(x + 10, y + 15, 1, 8, wall); r(x + 6, y + 19, 9, 1, wall);
    r(x + 21, y + 17, 8, 14, wood); r(x + 22, y + 18, 6, 12, 0x748E8D);
    r(x + 26, y + 24, 1, 1, 0xFFE4AB);
    r(x - 2, y + 31, 37, 2, 0xB3978B);
    planter(x + 2, y + 25, true); r(x + 19, y + 30, 12, 1, 0xD9BFA9);
    if night { r(x + 3, y + 32, 16, 1, 0xCCBA91); r(x + 6, y + 33, 9, 1, 0xAEA48A); }
  }
  func garden() {
    cottage(24, 20);
    // A winding path and fence make walking belong to the scene.
    r(57, 53, 69, 4, night ? 0x78888A : 0xE0D4B7);
    r(61, 57, 65, 3, night ? 0x657E80 : 0xC8C5A5);
    for i in 0..<6 { r(66 + i * 9, 54 + i % 2, 5, 1, night ? 0xA4A792 : 0xF4E7C5); }
    for i in 0..<4 { r(113 + i * 7, 42, 3, 12, 0xDFC6B0); r(115 + i * 7, 44, 2, 11, 0xB09A98); }
    r(113, 46, 24, 2, 0xC6ADA1); r(113, 50, 24, 2, 0xC6ADA1);
    r(132, 38, 2, 15, wood); r(127, 35, 12, 6, accent); r(128, 36, 10, 3, 0xE5C9B6);
    r(131, 37, 3, 1, 0x9E7B89);
    let walking = action == "outside";
    let x = walking ? 78 + wave(0.0, 14) : 84;
    person(x, 33, 0, walking ? "walk" : "wave");
    if pair { person(62, 33, 1, walking ? "wave" : "wave"); heart(74, 23 + wave(2.0, 1)); }
    if walking {
      let puff = frame / 5 % 3;
      r(x - 7, 54, 3 + puff, 1, night ? 0x7D9290 : 0xD7D3B7);
    }
    // A tiny resident cat grounds the quiet idle world.
    r(108, 49, 8, 4, 0xE7CDA8); r(113, 46, 5, 5, 0xE7CDA8);
    r(113, 45, 1, 2, 0xAF8C87); r(117, 45, 1, 2, 0xAF8C87);
    r(116, 48, 1, 1, 0x695864); r(105, 48 + wave(1.0, 1), 4, 2, 0xE7CDA8);
  }
  func room(_ eating: Bool) {
    // A dollhouse cutaway is a different world from the outdoor path.
    r(38, 17, 88, 39, 0x766578); r(40, 19, 84, 36, wall);
    r(40, 19, 84, 2, 0xE3C0AF); r(40, 43, 84, 12, night ? 0xAD919B : 0xDABAA0);
    for i in 0..<6 { r(41, 44 + i * 2, 82, 1, night ? 0x937C91 : 0xC9A78F); }
    for i in 0..<4 { r(35 + i * 8, 17 - i * 2, 94 - i * 16, 2, accent); }
    r(43, 16, 76, 1, pair ? 0xE9ADB8 : 0x9DB7C7);
    // Light spills onto floor without an expensive glow shader.
    if night { r(63, 47, 33, 3, 0xEBD1B0); r(66, 50, 29, 2, 0xD5B8A4); }
    r(65, 24, 29, 18, wood); r(67, 26, 25, 13, sky);
    r(67, 32, 25, 7, horizon); r(67, 35, 9, 4, leaf); r(80, 34, 12, 5, leafLight);
    r(78, 25, 2, 16, wall); r(66, 31, 28, 2, wall);
    r(63, 23, 4, 19, pair ? 0xBF8C9F : 0x8AA5AD);
    r(91, 23, 4, 19, pair ? 0xBF8C9F : 0x8AA5AD);
    r(64, 23, 1, 18, 0xF1D1B7); r(93, 23, 1, 18, 0xF1D1B7);
    r(49, 49, 58, 6, pair ? 0xAE7F96 : 0x7D98A5);
    r(52, 50, 52, 1, pair ? 0xDAB0B4 : 0xB0C0BE); r(52, 53, 52, 1, pair ? 0xDAB0B4 : 0xB0C0BE);
    if eating { dining() } else { living() }
    planter(115, 43, false); planter(42, 45, true);
    r(47, 22, 9, 9, wood); r(48, 23, 7, 7, 0xFAE8C8);
    r(50, 25, 3, 3, 0xDBA886); r(52, 24, 2, 2, leafLight);
    if pair { heart(77, 19 + wave(1.0, 1)); }
  }
  func living() {
    r(50, 40, 57, 12, wood); r(51, 39, 55, 10, accent);
    r(49, 43, 5, 9, accent); r(104, 43, 5, 9, accent);
    r(55, 44, 48, 5, pair ? 0xE0AAB3 : 0xA8BDC1);
    r(54, 49, 50, 2, pair ? 0xAA758F : 0x66849A);
    r(55, 51, 3, 3, wood); r(102, 51, 3, 3, wood);
    r(53, 40, 9, 7, window); r(96, 40, 8, 7, 0xDBC2B3);
    person(pair ? 66 : 76, 28, 0, "read");
    if pair { person(87, 28, 1, "read"); }
    // Bookshelf and a shaded lamp add room-specific quiet motion.
    r(108, 24, 10, 16, wood); r(109, 25, 8, 14, 0xDCC1AC);
    for i in 0..<4 { r(110 + i * 2, 26 + i % 2, 1, 6 - i % 2, i % 2 == 0 ? accent : 0x8FAD99); }
    r(108, 33, 10, 1, wood); r(110, 36, 6, 1, 0xBD8E8F);
    r(59, 27, 1, 16, wood); r(54, 27, 11, 3, window); r(56, 24, 7, 3, 0xF3CD9F);
    r(55, 42, 9, 2, wood);
    r(74, 51, 12, 3, 0xB08C80); r(75, 50, 10, 1, 0xE1C9AD);
    r(82, 48, 3, 3, window); r(85, 49, 1, 1, window);
    steam(82, 45, 0);
  }
  func dining() {
    r(43, 32, 17, 15, wood); r(44, 32, 15, 3, 0xEFE0BF);
    r(45, 36, 13, 10, accent); r(47, 37, 9, 6, 0x526879);
    r(48, 38, 7, 1, 0xF3D7A3); r(50, 44, 3, 1, 0xD9C6B0);
    r(45, 29, 10, 2, 0x8D7078); r(47, 27, 6, 2, 0xE0C8A7);
    r(115, 20, 1, 11, wood); r(111, 30, 9, 3, window); r(113, 28, 5, 2, 0xE7BF97);
    person(pair ? 68 : 78, 29, 0, "eat");
    if pair { person(91, 29, 1, "eat"); }
    r(64, 45, 46, 4, wood); r(63, 44, 48, 2, 0xE4C4A0);
    r(67, 49, 3, 6, wood); r(104, 49, 3, 6, wood);
    bowl(pair ? 72 : 82, 41, 0);
    if pair { bowl(95, 41, 3); }
    r(63, 41, 4, 3, 0xF6E4C3); r(64, 40, 2, 1, 0xC3A38E);
    r(104, 40, 4, 4, accent); r(105, 38, 2, 2, 0x8EAA92);
    r(83, 22, 1, 7, wood); r(79, 28, 9, 2, 0xF8D3A0);
  }
  func bowl(_ x: Int, _ y: Int, _ offset: Int) {
    r(x, y, 9, 2, 0xF9EBCB); r(x + 1, y + 2, 7, 2, pair ? 0xB8879E : 0x7595A5);
    r(x + 3, y + 4, 3, 1, wood); r(x + 2, y - 1, 5, 1, 0xB9C28D);
    r(x + 5, y - 2, 2, 2, 0xDC9A75); steam(x + 3, y - 4, offset);
  }
  func steam(_ x: Int, _ y: Int, _ offset: Int) {
    let a = (frame / 3 + offset) % 10;
    r(x + wave(Double(offset), 1), y - a / 3, 1, 2, night ? 0xE0D4C3 : 0xFFF2DA);
    r(x + 3 - wave(Double(offset) + 1, 1), y - 3 - a / 4, 1, 2, night ? 0xC8C7B9 : 0xEEDBC7);
  }
  func planter(_ x: Int, _ y: Int, _ flowers: Bool) {
    r(x, y, 7, 4, night ? 0xA17B88 : 0xC09585); r(x + 1, y + 4, 5, 1, wood);
    r(x + 3, y - 7, 1, 7, leaf); r(x, y - 5, 3, 3, leafLight); r(x + 4, y - 8, 3, 3, leafLight);
    if flowers { r(x - 1, y - 5 + wave(0.0, 1), 3, 2, pair ? 0xEAB4BD : 0xF4D9A5); r(x + 4, y - 9, 3, 2, pair ? 0xF7D0CC : 0xFAE6B9); }
  }
  func heart(_ x: Int, _ y: Int) {
    r(x, y, 2, 2, 0xF0AEBB); r(x + 3, y, 2, 2, 0xF0AEBB);
    r(x, y + 2, 5, 1, 0xD78DAB); r(x + 1, y + 3, 3, 1, 0xD78DAB); r(x + 2, y + 4, 1, 1, 0xB97296);
  }
  func person(_ x: Int, _ initialY: Int, _ identity: Int, _ pose: String) {
    var y = initialY
    let walk = pose == "walk", sitting = pose == "read" || pose == "eat";
    let step = frame / 3 % 4;
    let bob = walk && step % 2 == 1 ? 1 : 0;
    y -= bob;
    let hair = identity == 0 ? 0x514959 : 0x71546A;
    let skin = identity == 0 ? 0xEDBE9D : 0xE9B9A1;
    let shirt = identity == 0 ? accent : 0x9C9DC2;
    // Outlined hair, cheek highlights and a two-frame blink keep faces legible.
    r(x + 1, y, 7, 2, hair); r(x, y + 2, 9, 5, hair);
    r(x + 1, y + 3, 7, 6, skin); r(x + 2, y + 2, 3, 2, hair);
    r(x - 1, y + 5, 2, 2, skin); r(x + 8, y + 5, 1, 2, skin);
    if identity == 1 { r(x - 1, y + 3, 2, 7, hair); r(x + 7, y + 2, 2, 8, hair); }
    let blink = (frame + identity * 11) % 120 > 112;
    r(x + 2, y + 6, 1, blink ? 1 : 2, hair); r(x + 6, y + 6, 1, blink ? 1 : 2, hair);
    r(x + 1, y + 8, 2, 1, 0xDB9B94); r(x + 6, y + 8, 2, 1, 0xDB9B94);
    r(x + 4, y + 8, 1, 1, 0xAE7880);
    r(x + 3, y + 9, 3, 1, skin); r(x, y + 10, 9, 8, shirt);
    r(x + 1, y + 10, 7, 1, identity == 0 ? 0xCBD7D2 : 0xD5C8D3);
    r(x + 4, y + 12, 1, 4, identity == 0 ? 0xABC0C1 : 0xC4BDD2);
    r(x, y + 17, 9, 1, 0x6F708A);
    if walk {
      r(x - 3, y + 10, 3, 7, 0xBB8C7C); r(x - 2, y + 9, 2, 2, 0xDBC3A1);
      r(x + 9, y + 12 + step % 2, 2, 5, shirt); r(x + 9, y + 17 + step % 2, 2, 1, skin);
      let leg = [0, 1, 0, -1][step];
      r(x + 1 + leg, y + 18, 3, 4, hair); r(x + 6 - leg, y + 18, 3, 4, hair);
      r(x + leg, y + 21, 4, 1, 0xF1DDC3); r(x + 6 - leg, y + 21, 4, 1, 0xF1DDC3);
    } else if sitting {
      r(x, y + 18, 9, 2, hair); r(x + 1, y + 19, 3, 3, hair); r(x + 6, y + 19, 3, 3, hair);
      if pose == "read" {
        r(x - 1, y + 14, 11, 2, skin); r(x, y + 15, 5, 4, 0xF4E1BA);
        r(x + 5, y + 15, 5, 4, 0xDBB9AA); r(x + 5, y + 14, 1, 5, wood);
        r(x + 1, y + 16, 3, 1, 0xBBA297);
        if frame / 15 % 2 == 0 { r(x + 6, y + 16, 3, 1, 0xFFF0CF); }
      } else {
        let reach = wave(Double(identity) * 1.7, 2);
        r(x - 2, y + 12, 2, 6, shirt); r(x - 2, y + 17, 3, 1, skin);
        r(x + 8, y + 13 - reach, 3, 2, skin); r(x + 10, y + 10 - reach, 1, 4, 0xEEE5CC);
      }
    } else {
      r(x + 1, y + 18, 3, 4, hair); r(x + 6, y + 18, 3, 4, hair);
      r(x, y + 21, 4, 1, 0xF1DDC3); r(x + 6, y + 21, 4, 1, 0xF1DDC3);
      r(x - 2, y + 11, 2, 6, shirt); r(x - 2, y + 17, 2, 1, skin);
      let greeting = frame / 8 % 3;
      r(x + 9, y + 9, 2, 6, shirt); r(x + 9 + greeting % 2, y + 6, 2, 4, skin);
    }
  }
  func foreground() {
    // Flowers, swaying blades and light motes provide foreground parallax.
    for x in [9, 18, 133, 143, 152] {
      r(x, 53, 1, 6, leaf); r(x - 2, 56, 2, 1, leafLight);
      r(x + 1 + wave(Double(x) / 9, 1), 52, 2, 3, leafLight);
      if x % 2 == 1 { r(x - 1, 52, 3, 2, pair ? 0xECB5BE : 0xEEDDAD); r(x, 53, 1, 1, 0xCD9C85); }
    }
    if night {
      for i in 0..<7 {
        let x = 15 + i * 21 + wave(Double(i), 2), y = 39 + i % 4 * 3 + wave(Double(i) + 1, 2);
        r(x, y, 1, 1, (frame / 6 + i) % 4 < 2 ? 0xFAE5A8 : 0xA4BB9E);
      }
    } else if phase == 1 {
      let x = 128 + wave(0.0, 6), y = 38 + wave(2.0, 3), wing = frame / 2 % 2;
      r(x, y, 1, 3, 0x7B6B81); r(x - 2, y - wing, 2, 2 + wing, 0xE9BD91); r(x + 1, y - wing, 2, 2 + wing, 0xF1D4A9);
    } else if phase == 2 || pair {
      for i in 0..<4 {
        let t = (frame + i * 29) % 120;
        r(19 + i * 39 + Int((Double(t) / 18).rounded()), -6 + t * 2 / 3, 2, 1, pair ? 0xE6ADBD : 0xE5B099);
      }
    }
    r(0, 63, 160, 1, night ? 0x2A4A51 : 0x74937A);
  }
}
