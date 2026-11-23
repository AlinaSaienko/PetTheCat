import SwiftUI
import Combine

// MARK: - Petting zones

enum Zone {
    case ears, forehead, cheeks, chin, back, belly, tail

    /// title, gain (how fast purring builds), cap (max purr),
    /// pitch/rate/rough (sound character), irr (how fast he gets annoyed)
    var profile: (title: String, gain: CGFloat, cap: CGFloat, pitch: Float, rate: Float, rough: Float, irr: CGFloat) {
        switch self {
        case .chin:     return ("Chin — his favorite spot 😻", 1.5, 1.0, 90, 26, 0.0, 0)
        case .cheeks:   return ("Cheeks 😽", 1.2, 0.9, 100, 25, 0.1, 0)
        case .forehead: return ("Forehead 😺", 1.0, 0.85, 115, 23, 0.2, 0)
        case .back:     return ("Back 😌", 0.9, 0.75, 85, 21, 0.3, 0)
        case .ears:     return ("Ears 😸", 0.7, 0.55, 145, 19, 0.4, 0)
        case .belly:    return ("Belly… careful 😼", 0.6, 0.5, 80, 16, 0.8, 0.007)
        case .tail:     return ("Tail — he hates it 😾", 0.25, 0.2, 130, 14, 1.0, 0.012)
        }
    }
}

// MARK: - Breeds

enum Pattern { case solid, tabby, points }

struct Breed {
    let name: String
    let base: Color, light: Color, shade: Color, mark: Color
    let eye: Color, nose: Color, whisker: Color
    let pattern: Pattern
    let folded: Bool

    static let all: [Breed] = [
        Breed(name: "Scottish Fold", base: Color(hex: 0x8E96A3), light: Color(hex: 0xB8BEC8), shade: Color(hex: 0x555C68),
              mark: Color(hex: 0x6E7581), eye: Color(hex: 0xE8A838), nose: Color(hex: 0xC98C8C),
              whisker: .white, pattern: .solid, folded: true),
        Breed(name: "Siamese", base: Color(hex: 0xEADBC3), light: Color(hex: 0xF6EDE0), shade: Color(hex: 0xBFAA8A),
              mark: Color(hex: 0x4A372E), eye: Color(hex: 0x5BA7E0), nose: Color(hex: 0x6B4A44),
              whisker: .white, pattern: .points, folded: false),
        Breed(name: "Ginger Tabby", base: Color(hex: 0xE0883A), light: Color(hex: 0xF3C18A), shade: Color(hex: 0x9A5219),
              mark: Color(hex: 0xA9561A), eye: Color(hex: 0xC7A93A), nose: Color(hex: 0xE08C8C),
              whisker: .white, pattern: .tabby, folded: false),
        Breed(name: "Black", base: Color(hex: 0x2A2A2E), light: Color(hex: 0x45454B), shade: Color(hex: 0x0E0E10),
              mark: Color(hex: 0x2A2A2E), eye: Color(hex: 0xE3B73A), nose: Color(hex: 0x3A2E30),
              whisker: .white, pattern: .solid, folded: false),
        Breed(name: "White", base: Color(hex: 0xF3F1EE), light: Color(hex: 0xFFFFFF), shade: Color(hex: 0xC4BFB8),
              mark: Color(hex: 0xF3F1EE), eye: Color(hex: 0x62A8E8), nose: Color(hex: 0xF0A8A8),
              whisker: Color(hex: 0x9A9590), pattern: .solid, folded: false),
        Breed(name: "Grey Tabby", base: Color(hex: 0x9A9488), light: Color(hex: 0xC9C3B6), shade: Color(hex: 0x57524A),
              mark: Color(hex: 0x4B473F), eye: Color(hex: 0xD9B341), nose: Color(hex: 0xC48B86),
              whisker: .white, pattern: .tabby, folded: false)
    ]
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Cat geometry (shared by drawing and touch handling)

struct Geo {
    var u: CGFloat, floorY: CGFloat
    var bodyC: CGPoint, bodyRX: CGFloat, bodyRY: CGFloat
    var hx: CGFloat, hy: CGFloat, r: CGFloat
    var t0: CGPoint, t1: CGPoint, t2: CGPoint
}

private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

private func oval(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2))
}

private func rnd(_ i: Int) -> CGFloat {
    let x = sin(Double(i) * 12.9898) * 43758.5453
    return CGFloat(x - floor(x))
}

// MARK: - Screen

struct ContentView: View {
    @State private var intensity: CGFloat = 0
    @State private var irritation: CGFloat = 0
    @State private var squish: CGFloat = 0
    @State private var lean = CGPoint.zero
    @State private var leanTarget = CGPoint.zero
    @State private var touching = false
    @State private var zone: Zone?
    @State private var lastPoint: CGPoint?
    @State private var phase: Double = 0
    @State private var pitch: Float = 100
    @State private var rate: Float = 24
    @State private var rough: Float = 0.2
    @State private var purr = Purr()
    @State private var field = FurField()
    @AppStorage("breedIndex") private var breedIndex = 0

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let bg = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let ink = Color(red: 0.28, green: 0.20, blue: 0.17)

    private var breed: Breed { Breed.all[min(max(breedIndex, 0), Breed.all.count - 1)] }

    private var label: String {
        if touching, let z = zone { return irritation > 0.5 ? "Enough! 😾" : z.profile.title }
        return intensity > 0.05 ? "" : "Pet the cat with your finger"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                bg.ignoresSafeArea()
                Canvas { ctx, size in drawCat(ctx, size) }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let p = value.location
                                let z = zoneAt(p, makeGeo(geo.size))
                                zone = z
                                touching = (z != nil)
                                guard let z else { lastPoint = nil; return }
                                if let last = lastPoint {
                                    let dx = p.x - last.x, dy = p.y - last.y
                                    intensity = min(z.profile.cap, intensity + hypot(dx, dy) / 600 * z.profile.gain)
                                    field.push(at: p, velocity: pt(dx, dy), in: geo.size, radius: 46)
                                }
                                lastPoint = p
                                let nx = (p.x - geo.size.width / 2) / (geo.size.width / 2)
                                let ny = (p.y - geo.size.height / 2) / (geo.size.height / 2)
                                leanTarget = CGPoint(x: max(-1, min(1, nx)), y: max(-1, min(1, ny)))
                            }
                            .onEnded { _ in
                                touching = false
                                zone = nil
                                lastPoint = nil
                            }
                    )

                VStack {
                    Text(label)
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(ink.opacity(0.6))
                        .padding(.top, 24)
                        .animation(.easeInOut(duration: 0.25), value: label)
                    Spacer()
                    breedPicker
                }
            }
        }
        .onReceive(timer) { _ in tick() }
    }

    private var breedPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(Breed.all.enumerated()), id: \.offset) { i, b in
                    Button { breedIndex = i } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(LinearGradient(colors: [b.base, b.pattern == .solid ? b.base : b.mark],
                                                     startPoint: .top, endPoint: .bottom))
                                .frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color.black.opacity(0.15)))
                            Text(b.name).font(.system(.subheadline, design: .rounded))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(i == breedIndex ? 0.12 : 0.04)))
                        .foregroundColor(ink)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Logic

    private func tick() {
        phase += 0.04 + Double(intensity) * 0.1 + Double(irritation) * 0.1
        field.decay()
        if touching, let z = zone {
            let p = z.profile
            intensity = intensity > p.cap ? max(p.cap, intensity - 0.01)
                                          : min(p.cap, intensity + 0.004 * p.gain)
            irritation = p.irr > 0 ? min(1, irritation + p.irr) : max(0, irritation - 0.012)
            pitch += (p.pitch - pitch) * 0.04
            rate += (p.rate - rate) * 0.04
            rough += (p.rough - rough) * 0.04
        } else {
            intensity = max(0, intensity - 0.010)
            irritation = max(0, irritation - 0.012)
            leanTarget = .zero
        }
        let target: CGFloat = touching ? (0.3 + 0.7 * intensity) * (1 - irritation * 0.8) : 0
        squish += (target - squish) * 0.10
        lean.x += (leanTarget.x - lean.x) * 0.12
        lean.y += (leanTarget.y - lean.y) * 0.12
        let level = intensity * max(0, 1 - irritation * 1.3)
        purr.update(level: Float(level), pitch: pitch, rate: rate, rough: rough)
    }

    private func makeGeo(_ size: CGSize) -> Geo {
        let w = size.width, h = size.height
        let u: CGFloat = min(w * 0.88, h * 0.55)
        let cx = w / 2, cy = h * 0.47
        let sq = squish
        let bodyRX = u * 0.42 * (1 + 0.20 * sq)
        let bodyRY = u * 0.27 * (1 - 0.25 * sq)
        let floorY = cy + u * 0.42
        let bodyC = pt(cx + lean.x * u * 0.08, floorY - bodyRY)
        let r = u * 0.23 * (1 + 0.05 * sq)
        let hx = cx + lean.x * u * 0.14
        let hy = bodyC.y - bodyRY * 0.8 - r * 0.3 + sq * u * 0.02 + lean.y * u * 0.03
        let sway = CGFloat(sin(phase))
        let wag = CGFloat(sin(phase * 6))
        let t0 = pt(bodyC.x + bodyRX * 0.85, bodyC.y + bodyRY * 0.2)
        let t1 = pt(bodyC.x + bodyRX * 1.45, bodyC.y + bodyRY * 0.1)
        let t2 = pt(bodyC.x + bodyRX * 1.15 + sway * u * 0.03 * (0.4 + intensity) + wag * u * 0.07 * irritation,
                    bodyC.y - u * 0.30 - intensity * u * 0.03)
        return Geo(u: u, floorY: floorY, bodyC: bodyC, bodyRX: bodyRX, bodyRY: bodyRY,
                   hx: hx, hy: hy, r: r, t0: t0, t1: t1, t2: t2)
    }

    private func zoneAt(_ p: CGPoint, _ g: Geo) -> Zone? {
        // tail
        for i in 0...8 {
            let t = CGFloat(i) / 8
            let a = (1 - t) * (1 - t), b = 2 * (1 - t) * t, c = t * t
            let q = pt(a * g.t0.x + b * g.t1.x + c * g.t2.x, a * g.t0.y + b * g.t1.y + c * g.t2.y)
            if hypot(p.x - q.x, p.y - q.y) < g.u * 0.06 { return .tail }
        }
        // ears
        let earY: CGFloat = breed.folded ? -0.72 : -1.0
        for s in [CGFloat(-1), CGFloat(1)] {
            let e = pt(g.hx + s * g.r * 0.78, g.hy + earY * g.r)
            if hypot(p.x - e.x, p.y - e.y) < g.r * 0.30 { return .ears }
        }
        // head
        let dx = (p.x - g.hx) / (g.r * 1.08)
        let dy = (p.y - g.hy) / (g.r * 0.92)
        if dx * dx + dy * dy <= 1 {
            let ny = (p.y - g.hy) / g.r
            if ny > 0.42 { return .chin }
            if ny < -0.38 { return .forehead }
            return .cheeks
        }
        // body
        let bx = (p.x - g.bodyC.x) / (g.bodyRX * 1.05)
        let by = (p.y - g.bodyC.y) / g.bodyRY
        if bx * bx + by * by <= 1 {
            if abs(bx) > 0.72 || p.y < g.bodyC.y + g.bodyRY * 0.30 { return .back }
            return .belly
        }
        return nil
    }

    // MARK: - Drawing helpers

    private func shaded(_ ctx: GraphicsContext, _ path: Path, _ c: CGPoint, _ radius: CGFloat, _ base: Color, _ shade: Color) {
        ctx.fill(path, with: .color(base))
        ctx.fill(path, with: .radialGradient(Gradient(colors: [Color.white.opacity(0.14), .clear]),
                                             center: pt(c.x, c.y - radius * 0.35), startRadius: 0, endRadius: radius * 0.9))
        ctx.fill(path, with: .radialGradient(Gradient(colors: [.clear, shade.opacity(0.6)]),
                                             center: c, startRadius: radius * 0.55, endRadius: radius * 1.15))
    }

    /// Fur inside a shape. Hairs near the finger's trail bend in the direction of the stroke,
    /// lengthen and show the lighter undercoat, then slowly spring back.
    private func fur(_ ctx: GraphicsContext, _ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ size: CGSize,
                     _ b: Breed, count: Int, seed: Int, len: CGFloat) {
        var pl = Path(), pd = Path(), pu = Path()
        let wave = CGFloat(phase)
        for i in 0..<count {
            let a = rnd(seed + i * 3) * 2 * CGFloat.pi
            let d = rnd(seed + i * 3 + 1).squareRoot()
            var x = c.x + cos(a) * d * rx
            var y = c.y + sin(a) * d * ry
            let f = field.sample(pt(x, y), in: size)
            let mag = hypot(f.x, f.y)
            x += f.x * 0.25
            y += f.y * 0.25
            let grow = 1 + min(mag, 20) / 20 * 0.8
            let flutter = sin(wave * 2 + CGFloat(i)) * intensity * len * 0.25
            var bx = f.x * 0.8, by = f.y * 0.8
            let bm = hypot(bx, by)
            let lim = len * 2.2
            if bm > lim { bx *= lim / bm; by *= lim / bm }
            let ex = x + cos(a) * len * 0.5 * grow + flutter + bx
            let ey = y + sin(a) * len * 0.5 * grow + len * 0.6 + by
            if mag > 6 { pu.move(to: pt(x, y)); pu.addLine(to: pt(ex, ey)) }
            else if i % 2 == 0 { pl.move(to: pt(x, y)); pl.addLine(to: pt(ex, ey)) }
            else { pd.move(to: pt(x, y)); pd.addLine(to: pt(ex, ey)) }
        }
        ctx.stroke(pl, with: .color(b.light.opacity(0.35)), lineWidth: 0.9)
        ctx.stroke(pd, with: .color(b.shade.opacity(0.35)), lineWidth: 0.9)
        ctx.stroke(pu, with: .color(b.light.opacity(0.6)), lineWidth: 1.2)
    }

    /// Fuzzy silhouette: short hairs sticking out around the outline.
    private func edgeFur(_ ctx: GraphicsContext, _ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ size: CGSize,
                         color: Color, count: Int, seed: Int, len: CGFloat, skipBottom: Bool) {
        var p = Path()
        for i in 0..<count {
            let a = CGFloat(i) / CGFloat(count) * 2 * CGFloat.pi + rnd(seed + i) * 0.1
            if skipBottom && sin(a) > 0.75 { continue }
            let x = c.x + cos(a) * rx * 0.97
            let y = c.y + sin(a) * ry * 0.97
            let f = field.sample(pt(x, y), in: size)
            let l = len * (0.7 + rnd(seed + i + 7) * 0.8)
            p.move(to: pt(x, y))
            p.addLine(to: pt(x + cos(a) * l + f.x * 0.6, y + sin(a) * l + f.y * 0.6 + l * 0.2))
        }
        ctx.stroke(p, with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
    }

    // MARK: - Cat

    private func drawCat(_ ctx: GraphicsContext, _ size: CGSize) {
        let g = makeGeo(size)
        let b = breed
        let u = g.u, r = g.r, hx = g.hx, hy = g.hy
        let bodyC = g.bodyC, bRX = g.bodyRX, bRY = g.bodyRY
        let it = intensity, irr = irritation
        let sway = CGFloat(sin(phase))
        let points = (b.pattern == .points)
        let limb = points ? b.mark : b.base
        let signs: [CGFloat] = [-1, 1]

        // Shadow
        ctx.drawLayer { l in
            l.addFilter(.blur(radius: u * 0.02))
            l.fill(oval(pt(bodyC.x, g.floorY), bRX, u * 0.035), with: .color(Color.black.opacity(0.22)))
        }

        // Tail
        var tail = Path()
        tail.move(to: g.t0)
        tail.addQuadCurve(to: g.t2, control: g.t1)
        ctx.stroke(tail, with: .color(limb), style: StrokeStyle(lineWidth: u * 0.07, lineCap: .round))
        if b.pattern == .tabby {
            ctx.stroke(tail, with: .color(b.mark.opacity(0.8)),
                       style: StrokeStyle(lineWidth: u * 0.07, lineCap: .butt, dash: [u * 0.025, u * 0.05]))
        }
        ctx.stroke(tail, with: .color(Color.white.opacity(0.15)),
                   style: StrokeStyle(lineWidth: u * 0.02, lineCap: .round))

        // Body (with haunches so he looks seated)
        var body = Path()
        body.addEllipse(in: CGRect(x: bodyC.x - bRX, y: bodyC.y - bRY, width: bRX * 2, height: bRY * 2))
        for s in signs {
            body.addEllipse(in: CGRect(x: bodyC.x + s * bRX * 0.55 - bRX * 0.5, y: bodyC.y + bRY * 0.25 - bRY * 0.75,
                                       width: bRX, height: bRY * 1.5))
        }
        shaded(ctx, body, bodyC, bRX, b.base, b.shade)
        ctx.drawLayer { l in
            l.clip(to: body)
            l.fill(oval(pt(bodyC.x, bodyC.y + bRY * 0.45), bRX * 0.55, bRY * 0.6),
                   with: .radialGradient(Gradient(colors: [b.light.opacity(0.9), b.light.opacity(0)]),
                                         center: pt(bodyC.x, bodyC.y + bRY * 0.45), startRadius: 0, endRadius: bRX * 0.6))
            if b.pattern == .tabby {
                var st = Path()
                for k in -4...4 {
                    let kk = CGFloat(k)
                    let x = bodyC.x + kk * bRX * 0.24
                    st.move(to: pt(x, bodyC.y - bRY * 0.9))
                    st.addQuadCurve(to: pt(x + kk * bRX * 0.04, bodyC.y + bRY * 0.3),
                                    control: pt(x - kk * bRX * 0.06, bodyC.y - bRY * 0.3))
                }
                l.stroke(st, with: .color(b.mark.opacity(0.55)),
                         style: StrokeStyle(lineWidth: u * 0.03, lineCap: .round))
            }
            fur(l, bodyC, bRX, bRY, size, b, count: 450, seed: 1000, len: u * 0.045)
        }
        edgeFur(ctx, bodyC, bRX, bRY, size, color: b.base, count: 160, seed: 2000, len: u * 0.03, skipBottom: true)

        // Front paws
        for s in signs {
            let pc = pt(bodyC.x + s * bRX * 0.36, g.floorY - u * 0.035)
            shaded(ctx, oval(pc, u * 0.075, u * 0.045), pc, u * 0.075, points ? b.mark : b.light, b.shade)
            var toes = Path()
            for k in [-1, 1] {
                toes.move(to: pt(pc.x + CGFloat(k) * u * 0.02, pc.y + u * 0.005))
                toes.addLine(to: pt(pc.x + CGFloat(k) * u * 0.02, pc.y + u * 0.04))
            }
            ctx.stroke(toes, with: .color(b.shade.opacity(0.5)), lineWidth: 1)
        }

        // Pointed ears (behind the head)
        if !b.folded {
            for s in signs {
                let twitch: CGFloat = (zone == .ears && touching) ? CGFloat(sin(phase * 9 + Double(s))) * r * 0.05 : 0
                let tipX = hx + s * (r * 0.80 + irr * r * 0.3)
                let tipY = hy - r * 1.42 + irr * r * 0.55 + twitch
                var ear = Path()
                ear.move(to: pt(hx + s * r * 0.95, hy - r * 0.15))
                ear.addQuadCurve(to: pt(tipX, tipY), control: pt(hx + s * r * 1.0, hy - r * 0.95))
                ear.addQuadCurve(to: pt(hx + s * r * 0.12, hy - r * 0.88), control: pt(hx + s * r * 0.45, hy - r * 1.2))
                ear.closeSubpath()
                shaded(ctx, ear, pt(hx + s * r * 0.6, hy - r * 0.8), r * 0.6, points ? b.mark : b.base, b.shade)

                var inner = Path()
                inner.move(to: pt(hx + s * r * 0.80, hy - r * 0.30))
                inner.addQuadCurve(to: pt(hx + s * (r * 0.78 + irr * r * 0.25), hy - r * 1.18 + irr * r * 0.45 + twitch),
                                   control: pt(hx + s * r * 0.86, hy - r * 0.85))
                inner.addQuadCurve(to: pt(hx + s * r * 0.32, hy - r * 0.85),
                                   control: pt(hx + s * r * 0.5, hy - r * 1.02))
                inner.closeSubpath()
                ctx.fill(inner, with: .color(b.nose.opacity(0.55)))
            }
        }

        // Head (round, with cheeks and whisker pads)
        var head = Path()
        let headRX = r * (b.folded ? 1.10 : 1.0)
        head.addEllipse(in: CGRect(x: hx - headRX, y: hy - r * 0.88, width: headRX * 2, height: r * 1.76))
        let cheekW: CGFloat = b.folded ? 1.08 : 0.96
        for s in signs {
            head.addEllipse(in: CGRect(x: hx + s * r * 0.62 - r * 0.48 * cheekW / 0.96, y: hy + r * 0.28 - r * 0.42,
                                       width: r * cheekW, height: r * 0.84))
        }
        shaded(ctx, head, pt(hx, hy), r, b.base, b.shade)
        ctx.drawLayer { l in
            l.clip(to: head)
            l.fill(oval(pt(hx, hy + r * 0.40), r * 0.45, r * 0.32),
                   with: .radialGradient(Gradient(colors: [b.light, b.light.opacity(0)]),
                                         center: pt(hx, hy + r * 0.40), startRadius: 0, endRadius: r * 0.45))
            for s in signs {
                let pc = pt(hx + s * r * 0.26, hy + r * 0.40)
                l.fill(oval(pc, r * 0.24, r * 0.17),
                       with: .radialGradient(Gradient(colors: [b.light.opacity(0.8), b.light.opacity(0)]),
                                             center: pc, startRadius: 0, endRadius: r * 0.24))
            }
            if b.pattern == .tabby {
                var m = Path()
                for k in -1...1 {
                    let x = hx + CGFloat(k) * r * 0.18
                    m.move(to: pt(x, hy - r * 0.88))
                    m.addLine(to: pt(x, hy - r * 0.42))
                }
                for s in signs {
                    m.move(to: pt(hx + s * r * 1.0, hy + r * 0.02))
                    m.addQuadCurve(to: pt(hx + s * r * 0.58, hy + r * 0.10), control: pt(hx + s * r * 0.8, hy + r * 0.0))
                    m.move(to: pt(hx + s * r * 1.02, hy + r * 0.22))
                    m.addQuadCurve(to: pt(hx + s * r * 0.62, hy + r * 0.26), control: pt(hx + s * r * 0.82, hy + r * 0.18))
                }
                l.stroke(m, with: .color(b.mark.opacity(0.65)),
                         style: StrokeStyle(lineWidth: r * 0.07, lineCap: .round))
            }
            fur(l, pt(hx, hy), headRX, r * 0.88, size, b, count: 320, seed: 5000, len: r * 0.14)
            if points {
                l.fill(oval(pt(hx, hy + r * 0.3), r * 0.95, r * 0.8),
                       with: .radialGradient(Gradient(colors: [b.mark.opacity(0.9), b.mark.opacity(0)]),
                                             center: pt(hx, hy + r * 0.3), startRadius: r * 0.15, endRadius: r * 0.85))
            }
        }
        edgeFur(ctx, pt(hx, hy), headRX * 1.03, r * 0.88, size, color: b.base, count: 120, seed: 8000, len: r * 0.12, skipBottom: false)

        // Folded ears: small caps lying flat on the skull, tip pointing forward/down
        if b.folded {
            for s in signs {
                var fe = Path()
                fe.move(to: pt(hx + s * r * 0.30, hy - r * 0.86))
                fe.addQuadCurve(to: pt(hx + s * r * 1.02, hy - r * 0.58), control: pt(hx + s * r * 0.80, hy - r * 1.08))
                fe.addQuadCurve(to: pt(hx + s * r * 0.84, hy - r * 0.34), control: pt(hx + s * r * 1.10, hy - r * 0.40))
                fe.addQuadCurve(to: pt(hx + s * r * 0.30, hy - r * 0.86), control: pt(hx + s * r * 0.52, hy - r * 0.50))
                fe.closeSubpath()
                shaded(ctx, fe, pt(hx + s * r * 0.7, hy - r * 0.70), r * 0.5, b.base, b.shade)
                var crease = Path()
                crease.move(to: pt(hx + s * r * 0.45, hy - r * 0.80))
                crease.addQuadCurve(to: pt(hx + s * r * 0.92, hy - r * 0.50), control: pt(hx + s * r * 0.62, hy - r * 0.50))
                ctx.stroke(crease, with: .color(b.shade.opacity(0.6)),
                           style: StrokeStyle(lineWidth: r * 0.035, lineCap: .round))
                ctx.stroke(fe, with: .color(b.shade.opacity(0.5)), lineWidth: 1.2)
            }
        }

        // Eyes
        let open: CGFloat = irr > 0.5 ? 1.1 : max(0, 1 - it * 1.5)
        let eyeScale: CGFloat = b.folded ? 1.14 : 1.0
        let eyeX: CGFloat = b.folded ? 0.47 : 0.44
        for s in signs {
            let ex = hx + s * r * eyeX, ey = hy - r * 0.02
            let ew = r * 0.27 * eyeScale
            let eh = r * 0.15 * open * eyeScale
            if open < 0.16 {
                var arc = Path()
                arc.move(to: pt(ex - ew * 0.8, ey + r * 0.03))
                arc.addQuadCurve(to: pt(ex + ew * 0.8, ey + r * 0.03), control: pt(ex, ey - r * 0.22))
                ctx.stroke(arc, with: .color(Color.black.opacity(0.75)),
                           style: StrokeStyle(lineWidth: r * 0.05, lineCap: .round))
            } else {
                var upper = Path()
                upper.move(to: pt(ex - ew, ey + ew * 0.05))
                upper.addQuadCurve(to: pt(ex + ew, ey - ew * 0.05), control: pt(ex, ey - eh * 2))
                var eye = upper
                eye.addQuadCurve(to: pt(ex - ew, ey + ew * 0.05), control: pt(ex, ey + eh * 2))
                ctx.fill(eye, with: .radialGradient(Gradient(colors: [b.eye, b.eye, Color.black.opacity(0.6)]),
                                                    center: pt(ex, ey), startRadius: ew * 0.3, endRadius: ew * 1.1))
                ctx.drawLayer { l in
                    l.clip(to: eye)
                    let pw = ew * (irr > 0.5 ? 0.10 : 0.16 + 0.30 * it)
                    l.fill(oval(pt(ex, ey), pw, eh * 1.9), with: .color(Color.black))
                    l.fill(oval(pt(ex + ew * 0.22, ey - eh * 0.35), ew * 0.12, ew * 0.12),
                           with: .color(Color.white.opacity(0.9)))
                }
                ctx.stroke(upper, with: .color(Color.black.opacity(0.7)),
                           style: StrokeStyle(lineWidth: r * 0.035, lineCap: .round))
            }
        }

        // Nose and mouth
        let noseY = hy + r * 0.24
        var nose = Path()
        nose.move(to: pt(hx - r * 0.09, noseY))
        nose.addQuadCurve(to: pt(hx + r * 0.09, noseY), control: pt(hx, noseY - r * 0.04))
        nose.addQuadCurve(to: pt(hx, noseY + r * 0.09), control: pt(hx + r * 0.09, noseY + r * 0.06))
        nose.addQuadCurve(to: pt(hx - r * 0.09, noseY), control: pt(hx - r * 0.09, noseY + r * 0.06))
        ctx.fill(nose, with: .color(b.nose))
        ctx.fill(oval(pt(hx - r * 0.02, noseY + r * 0.01), r * 0.03, r * 0.015), with: .color(Color.white.opacity(0.35)))

        var mouth = Path()
        mouth.move(to: pt(hx, noseY + r * 0.09))
        mouth.addLine(to: pt(hx, noseY + r * 0.15))
        for s in signs {
            mouth.move(to: pt(hx, noseY + r * 0.15))
            mouth.addQuadCurve(to: pt(hx + s * r * 0.15, noseY + r * 0.14),
                               control: pt(hx + s * r * 0.07, noseY + r * 0.24))
        }
        ctx.stroke(mouth, with: .color(Color.black.opacity(0.5)),
                   style: StrokeStyle(lineWidth: r * 0.03, lineCap: .round))

        // Whiskers
        var wh = Path()
        for s in signs {
            for k in 0..<4 {
                let off = CGFloat(k) - 1.5
                wh.move(to: pt(hx + s * r * 0.30, noseY + r * 0.12 + off * r * 0.05))
                wh.addQuadCurve(to: pt(hx + s * r * 1.2, noseY + r * 0.10 + off * r * 0.17 + sway * r * 0.02),
                                control: pt(hx + s * r * 0.75, noseY + off * r * 0.10))
            }
        }
        ctx.stroke(wh, with: .color(b.whisker.opacity(0.7)), lineWidth: 1.1)
    }
}

#Preview {
    ContentView()
}
