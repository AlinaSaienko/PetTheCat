import SwiftUI

// Shared by the app and the widget extension: the cat's look and how it is drawn.

// MARK: - Petting zones

enum Zone {
    case ears, forehead, cheeks, chin, back, belly, paws, tail

    /// places he doesn't like being touched — he says "Mew?!"
    var disliked: Bool { self == .belly || self == .paws || self == .tail }

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
        case .paws:     return ("Paws — not a fan 🙀", 0.3, 0.25, 125, 15, 0.9, 0.010)
        case .tail:     return ("Tail — he hates it 😾", 0.25, 0.2, 130, 14, 1.0, 0.012)
        }
    }
}

// MARK: - Breeds

enum Pattern { case solid, tabby, points, tuxedo, aurora }

struct Breed {
    let name: String
    let base: Color, light: Color, shade: Color, mark: Color
    /// outline colour, and colour for inner lines (legs, mouth, whiskers)
    let line: Color, detail: Color
    let eye: Color, nose: Color
    let pattern: Pattern
    /// stable id used by the collection, the store and the widget
    var id: String = ""
    /// outfit art from Outfits.swift (Christmas cats)
    var outfit: String? = nil
    /// inner-ear colour when it differs from the nose
    var inner: Color? = nil
    var isBoxed: Bool { outfit != nil }

    static let classic: [Breed] = [
        Breed(name: "British Blue", base: Color(hex: 0x9CA1B3), light: Color(hex: 0xD3D6E0), shade: Color(hex: 0x737A8F),
              mark: Color(hex: 0x7E8498), line: Color(hex: 0x3D4150), detail: Color(hex: 0x4A4F60),
              eye: Color(hex: 0xF2B53A), nose: Color(hex: 0xE7A1A6), pattern: .solid, id: "blue"),
        Breed(name: "Siamese", base: Color(hex: 0xF4E8D6), light: Color(hex: 0xFDF8F0), shade: Color(hex: 0xDCC8AA),
              mark: Color(hex: 0x6E5142), line: Color(hex: 0x4E3B30), detail: Color(hex: 0x5A4537),
              eye: Color(hex: 0x6CB4EE), nose: Color(hex: 0x8C6157), pattern: .points, id: "siamese"),
        Breed(name: "Ginger Tabby", base: Color(hex: 0xF2A65E), light: Color(hex: 0xFDE3C4), shade: Color(hex: 0xD07F38),
              mark: Color(hex: 0xD47833), line: Color(hex: 0x6E3A14), detail: Color(hex: 0x7A4218),
              eye: Color(hex: 0x8CC24F), nose: Color(hex: 0xF09AA0), pattern: .tabby, id: "ginger"),
        Breed(name: "Black", base: Color(hex: 0x34343B), light: Color(hex: 0x4D4D57), shade: Color(hex: 0x202026),
              mark: Color(hex: 0x34343B), line: Color(hex: 0x141417), detail: Color(hex: 0x8A8A96),
              eye: Color(hex: 0xF5C543), nose: Color(hex: 0x5A4A50), pattern: .solid, id: "black"),
        Breed(name: "White", base: Color(hex: 0xFBF8F4), light: Color(hex: 0xFFFFFF), shade: Color(hex: 0xE6DFD6),
              mark: Color(hex: 0xFBF8F4), line: Color(hex: 0x7D746B), detail: Color(hex: 0x8A8178),
              eye: Color(hex: 0x6CB0F0), nose: Color(hex: 0xF4A9B0), pattern: .solid, id: "white"),
        Breed(name: "Grey Tabby", base: Color(hex: 0xA9A49C), light: Color(hex: 0xDDD9D2), shade: Color(hex: 0x857F76),
              mark: Color(hex: 0x6B665E), line: Color(hex: 0x45413A), detail: Color(hex: 0x4E4A43),
              eye: Color(hex: 0xE9C04A), nose: Color(hex: 0xD99A98), pattern: .tabby, id: "greytabby")
    ]

    static let christmas: [Breed] = [
        Breed(name: "Gingerbread", base: Color(hex: 0xC98A4B), light: Color(hex: 0xEBC08E), shade: Color(hex: 0xA86A33),
              mark: Color(hex: 0xA86A33), line: Color(hex: 0x5E3415), detail: Color(hex: 0x5E3415),
              eye: Color(hex: 0x7FCFB0), nose: Color(hex: 0xE58A8A), pattern: .solid,
              id: "gingerbread", outfit: "gingerbread", inner: Color(hex: 0xF0A99B)),
        Breed(name: "Reindeer", base: Color(hex: 0x7A5238), light: Color(hex: 0xF3E3C8), shade: Color(hex: 0x5C3C28),
              mark: Color(hex: 0x5C3C28), line: Color(hex: 0x3A2416), detail: Color(hex: 0x3A2416),
              eye: Color(hex: 0xE8A33D), nose: Color(hex: 0xE0413A), pattern: .solid,
              id: "reindeer", outfit: "reindeer", inner: Color(hex: 0xD99A86)),
        Breed(name: "Elf", base: Color(hex: 0xFBF6EE), light: Color(hex: 0xFFFFFF), shade: Color(hex: 0xD9CDBD),
              mark: Color(hex: 0xD9CDBD), line: Color(hex: 0x7E756D), detail: Color(hex: 0x7E756D),
              eye: Color(hex: 0x7DBE5A), nose: Color(hex: 0xF0A3AE), pattern: .solid,
              id: "elf", outfit: "elf", inner: Color(hex: 0xF5B9BF)),
        Breed(name: "Frost", base: Color(hex: 0xB8B4D6), light: Color(hex: 0xE2E0F0), shade: Color(hex: 0x918CB8),
              mark: Color(hex: 0x918CB8), line: Color(hex: 0x4A4672), detail: Color(hex: 0x4A4672),
              eye: Color(hex: 0x8ED3F2), nose: Color(hex: 0xE5A0C0), pattern: .solid,
              id: "frost", outfit: "frost", inner: Color(hex: 0xE8B9D3)),
        Breed(name: "Cocoa", base: Color(hex: 0x2E2A2C), light: Color(hex: 0xFBF8F3), shade: Color(hex: 0x1A1718),
              mark: Color(hex: 0x1A1718), line: Color(hex: 0x141113), detail: Color(hex: 0x8A8A96),
              eye: Color(hex: 0xF2C14E), nose: Color(hex: 0xF0A3AE), pattern: .tuxedo,
              id: "cocoa", outfit: "cocoa", inner: Color(hex: 0xC98C9A)),
        Breed(name: "Midnight Star", base: Color(hex: 0x1E2547), light: Color(hex: 0x323C72), shade: Color(hex: 0x121733),
              mark: Color(hex: 0x121733), line: Color(hex: 0x6470B8), detail: Color(hex: 0x9AA4E0),
              eye: Color(hex: 0xFFD166), nose: Color(hex: 0xF2A7C3), pattern: .aurora,
              id: "midnight", outfit: "midnight", inner: Color(hex: 0x8A6FD0))
    ]

    /// classic first, then the boxed series; the widget relies on this order
    static let all: [Breed] = classic + christmas
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Comic words ("Purr", "Mew?!") that pop up and float away

struct ComicWord {
    var text: String
    var x: CGFloat, y: CGFloat        // in units of u, relative to the top of the head
    var vx: CGFloat, vy: CGFloat
    var age: Double = 0
    var life: Double
    var angle: Double
    var size: CGFloat
    var angry: Bool
}

// MARK: - Cat geometry (shared by drawing and touch handling)

struct Geo {
    var u: CGFloat, floorY: CGFloat
    var bx: CGFloat, by: CGFloat, bRX: CGFloat, bRY: CGFloat
    var hx: CGFloat, hy: CGFloat, r: CGFloat, ryT: CGFloat, ryB: CGFloat
    var t0: CGPoint, t1: CGPoint, t2: CGPoint
}

private func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

private func oval(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2))
}

private func poly(_ p: [CGPoint], closed: Bool = true) -> Path {
    var path = Path()
    path.addLines(p)
    if closed { path.closeSubpath() }
    return path
}

/// sign(v) * |v|^p
private func spow(_ v: CGFloat, _ p: CGFloat) -> CGFloat {
    v < 0 ? -pow(-v, p) : pow(v, p)
}

/// point on a quadratic Bézier
private func qb(_ a: CGPoint, _ c: CGPoint, _ e: CGPoint, _ t: CGFloat) -> CGPoint {
    let m = 1 - t
    return pt(m * m * a.x + 2 * m * t * c.x + t * t * e.x, m * m * a.y + 2 * m * t * c.y + t * t * e.y)
}

private func curve(_ a: CGPoint, _ c: CGPoint, _ e: CGPoint, _ n: Int = 12) -> [CGPoint] {
    (0...n).map { qb(a, c, e, CGFloat($0) / CGFloat(n)) }
}

/// triangle wave 0…1…0 repeated `count` times over t in 0…1 — used for fluffy tufts
private func tufts(_ t: CGFloat, _ count: CGFloat) -> CGFloat {
    let f = (t * count).truncatingRemainder(dividingBy: 1)
    return 1 - abs(2 * f - 1)
}

/// A stripe that tapers to a point.
private func taper(_ a: CGPoint, _ c: CGPoint, _ e: CGPoint, _ w0: CGFloat) -> Path {
    let n = 16
    var left: [CGPoint] = [], right: [CGPoint] = []
    for i in 0...n {
        let t = CGFloat(i) / CGFloat(n), m = 1 - t
        let p = qb(a, c, e, t)
        let dx = 2 * m * (c.x - a.x) + 2 * t * (e.x - c.x)
        let dy = 2 * m * (c.y - a.y) + 2 * t * (e.y - c.y)
        let l = max(0.001, hypot(dx, dy))
        let hw = w0 * (1 - t) * 0.5 * (1 + 0.3 * sin(t * .pi))
        left.append(pt(p.x - dy / l * hw, p.y + dx / l * hw))
        right.append(pt(p.x + dy / l * hw, p.y - dx / l * hw))
    }
    return poly(left + right.reversed())
}

// MARK: - The cat, as one drawable value

/// Everything needed to draw (or hit-test) the cat for a single frame.
/// The app builds one from its @State every frame; the widget builds fixed poses.
struct CatArt {
    enum Placement { case screen, widget, thumb }

    var breed: Breed
    var placement: Placement = .screen
    var intensity: CGFloat = 0
    var irritation: CGFloat = 0
    var squish: CGFloat = 0
    var lean = CGPoint.zero
    var touching = false
    var zone: Zone?
    var phase: Double = 0
    var tailPhase: Double = 0
    var clock: Double = 0
    var words: [ComicWord] = []
    /// a flat grey shape for cats the player hasn't found yet
    var silhouette = false
    var silhouetteColor = Color(hex: 0xD6CFD0)
    /// drawn on a dark background: comic words and zig-zags switch to light colours
    var onDark = false

    func makeGeo(_ size: CGSize) -> Geo {
        let w = size.width, h = size.height
        let u: CGFloat = placement == .widget ? min(w, h) * 0.78
            : placement == .thumb ? min(w, h) * 0.74 : min(w * 0.88, h * 0.55)
        // thumbnails leave room on the right for the tail and above for hats
        let cx = placement == .thumb ? w / 2 - u * 0.10 : w / 2
        let sq = squish
        let breathe = 1 + 0.015 * CGFloat(sin(clock * 2 * .pi / 3.2))
        let floorY = placement == .widget ? h * 0.92 : placement == .thumb ? h * 0.95 : h * 0.72
        let bRX = u * 0.36 * (1 + 0.10 * sq)
        let bRY = u * 0.30 * (1 - 0.10 * sq) * breathe
        let bx = cx + lean.x * u * 0.03
        let by = floorY - bRY * 0.94
        let r = u * 0.33
        let ryT = r * 0.80, ryB = r * 0.78
        let bodyTop = by - bRY
        let hx = cx + lean.x * u * 0.07
        let hy = bodyTop + bRY * 0.42 - ryB + sq * u * 0.03 + lean.y * u * 0.015

        // tail: starts behind the right haunch and sways around its base
        let ang = CGFloat(sin(tailPhase)) * (0.10 + 0.10 * intensity)
                + CGFloat(sin(tailPhase * 2)) * 0.22 * irritation
        let base = pt(bx + bRX * 0.62, floorY - u * 0.06)
        func rot(_ p: CGPoint) -> CGPoint {
            let dx = p.x - base.x, dy = p.y - base.y
            return pt(base.x + dx * cos(ang) - dy * sin(ang), base.y + dx * sin(ang) + dy * cos(ang))
        }
        let t1 = rot(pt(bx + bRX * 1.60, floorY - u * 0.04))
        let t2 = rot(pt(bx + bRX * 1.18, floorY - u * 0.42))
        return Geo(u: u, floorY: floorY, bx: bx, by: by, bRX: bRX, bRY: bRY,
                   hx: hx, hy: hy, r: r, ryT: ryT, ryB: ryB, t0: base, t1: t1, t2: t2)
    }

    // MARK: - Shapes

    /// Head: round on top, wide cheeks with fluffy tufts at the bottom sides.
    private func headPoints(_ g: Geo) -> [CGPoint] {
        let n = 160
        var pts: [CGPoint] = []
        for i in 0..<n {
            let th = CGFloat(i) / CGFloat(n) * 2 * .pi
            let c = cos(th), s = sin(th)
            let ry = s > 0 ? g.ryB : g.ryT
            let e: CGFloat = s < 0 ? 2 / 2.15 : 2 / 2.6
            var x = g.hx + g.r * spow(c, e)
            var y = g.hy + ry * spow(s, e)
            if s > 0 {
                let a = atan2(s, abs(c))
                if a > 0.12 && a < 0.80 {
                    let t = (a - 0.12) / 0.68
                    let bump = g.r * 0.07 * tufts(t, 3) * sin(.pi * t)
                    x += (c < 0 ? -bump : bump) * 0.9
                    y += bump * 0.55
                }
            }
            pts.append(pt(x, y))
        }
        return pts
    }

    let headExpTop: CGFloat = 2.15, headExpBottom: CGFloat = 2.6, bodyExp: CGFloat = 2.6

    /// Body: a soft pear, wider at the bottom, with fluffy tufts on the shoulders.
    private func bodyPoints(_ g: Geo) -> [CGPoint] {
        let n = 140
        var pts: [CGPoint] = []
        for i in 0..<n {
            let th = CGFloat(i) / CGFloat(n) * 2 * .pi
            let c = cos(th), s = sin(th)
            var x = g.bx + g.bRX * spow(c, 2 / bodyExp) * (0.80 + 0.20 * s)
            let y = g.by + g.bRY * spow(s, 2 / bodyExp)
            let a = atan2(s, abs(c))
            if a > -0.75 && a < 0.05 {
                let t = (a + 0.75) / 0.80
                let bump = g.u * 0.016 * tufts(t, 3) * sin(.pi * t)
                x += c < 0 ? -bump : bump
            }
            pts.append(pt(x, y))
        }
        return pts
    }

    private func tailCenter(_ g: Geo) -> [CGPoint] {
        let n = 30
        return (0...n).map { i in
            let t = CGFloat(i) / CGFloat(n)
            let p = qb(g.t0, g.t1, g.t2, t)
            let wave = CGFloat(sin(tailPhase - Double(t) * 2.2)) * g.u * 0.010 * t
            return pt(p.x + wave, p.y)
        }
    }

    /// Thick tail that gets fluffier towards a round, scalloped tip.
    private func tailOutline(_ g: Geo, _ c: [CGPoint]) -> [CGPoint] {
        let n = c.count - 1
        var left: [CGPoint] = [], right: [CGPoint] = []
        var lastN = CGPoint.zero, lastW: CGFloat = 0
        for i in 0...n {
            let t = CGFloat(i) / CGFloat(n)
            let hw = g.u * (0.050 + 0.022 * t * t)
            let a = c[max(0, i - 1)], b = c[min(n, i + 1)]
            let dx = b.x - a.x, dy = b.y - a.y
            let l = max(0.001, hypot(dx, dy))
            let nn = pt(-dy / l, dx / l)
            left.append(pt(c[i].x + nn.x * hw, c[i].y + nn.y * hw))
            right.append(pt(c[i].x - nn.x * hw, c[i].y - nn.y * hw))
            lastN = nn; lastW = hw
        }
        let fwd = pt(lastN.y, -lastN.x)
        var tip: [CGPoint] = []
        for k in 1..<24 {
            let a = CGFloat(k) / 24 * .pi
            let fl = 1 + 0.12 * max(0, sin(a * 4))
            let dx = lastN.x * cos(a) + fwd.x * sin(a)
            let dy = lastN.y * cos(a) + fwd.y * sin(a)
            tip.append(pt(c[n].x + dx * lastW * fl, c[n].y + dy * lastW * fl))
        }
        return left + tip + right.reversed()
    }

    /// Ear with a rounded tip. k < 1 gives the smaller inner ear.
    private func earPoints(_ g: Geo, _ s: CGFloat, _ irr: CGFloat, _ twitch: CGFloat, k: CGFloat = 1) -> [CGPoint] {
        let r = g.r
        var tip = pt(g.hx + s * (r * 0.70 + irr * r * 0.25), g.hy - r * 1.12 + irr * r * 0.30 + twitch)
        var bin = pt(g.hx + s * r * 0.12, g.hy - r * 0.70)
        var bout = pt(g.hx + s * r * 0.98, g.hy - r * 0.28)
        if k != 1 {
            let cc = pt((tip.x + bin.x + bout.x) / 3, (tip.y + bin.y + bout.y) / 3 + r * 0.06)
            func f(_ p: CGPoint) -> CGPoint { pt(cc.x + (p.x - cc.x) * k, cc.y + (p.y - cc.y) * k) }
            tip = f(tip); bin = f(bin); bout = f(bout)
        }
        let a1 = pt(tip.x + (bin.x - tip.x) * 0.22, tip.y + (bin.y - tip.y) * 0.22)
        let a2 = pt(tip.x + (bout.x - tip.x) * 0.22, tip.y + (bout.y - tip.y) * 0.22)
        let m1 = pt((bin.x + a1.x) / 2 - s * r * 0.03, (bin.y + a1.y) / 2 - r * 0.03)
        let m2 = pt((bout.x + a2.x) / 2 + s * r * 0.05, (bout.y + a2.y) / 2 - r * 0.02)
        return curve(bin, m1, a1, 14) + curve(a1, tip, a2, 14).dropFirst() + curve(a2, m2, bout, 14).dropFirst()
    }

    // MARK: - Touch zones

    func zoneAt(_ p: CGPoint, _ g: Geo) -> Zone? {
        // tail (skip the base hidden behind the body)
        let tc = tailCenter(g)
        for i in stride(from: 5, to: tc.count, by: 2) where hypot(p.x - tc[i].x, p.y - tc[i].y) < g.u * 0.08 {
            return .tail
        }
        // ears
        for s in [CGFloat(-1), CGFloat(1)] {
            let e = pt(g.hx + s * g.r * 0.62, g.hy - g.r * 0.80)
            if hypot(p.x - e.x, p.y - e.y) < g.r * 0.30 { return .ears }
        }
        // paws (they stick out a little below the body)
        for s in [CGFloat(-1), CGFloat(1)] {
            let pc = pt(g.bx + s * g.bRX * 0.17, g.floorY - g.u * 0.032)
            if hypot(p.x - pc.x, p.y - pc.y) < g.u * 0.08 { return .paws }
        }
        // head
        let dx = (p.x - g.hx) / (g.r * 1.08)
        let dyRaw = p.y - g.hy
        let dy = dyRaw / (dyRaw < 0 ? g.ryT : g.ryB * 1.1)
        let e = dyRaw < 0 ? headExpTop : headExpBottom
        if pow(abs(dx), e) + pow(abs(dy), e) <= 1 {
            let ny = dyRaw / g.r
            if ny > 0.40 { return .chin }
            if ny < -0.35 { return .forehead }
            return .cheeks
        }
        // body
        let yn = (p.y - g.by) / g.bRY
        if abs(yn) <= 1 {
            let s = spow(yn, bodyExp / 2)
            let xn = (p.x - g.bx) / (g.bRX * (0.80 + 0.20 * s) * 1.05)
            if pow(abs(xn), bodyExp) + pow(abs(yn), bodyExp) <= 1 {
                if abs(p.x - g.bx) < g.bRX * 0.42 && p.y > g.floorY - g.bRY * 0.65 { return .paws }
                if abs(p.x - g.bx) < g.bRX * 0.45 && yn > -0.2 { return .belly }
                return .back
            }
        }
        return nil
    }

    // MARK: - Cat

    func drawCat(_ ctx: GraphicsContext, _ size: CGSize) {
        let g = makeGeo(size)
        let b = breed
        let u = g.u, r = g.r, hx = g.hx, hy = g.hy
        let it = intensity, irr = irritation
        let points = (b.pattern == .points)
        let limb = points ? b.mark : b.base
        let signs: [CGFloat] = [-1, 1]
        let lw = u * 0.013
        let outline = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
        func line(_ w: CGFloat) -> StrokeStyle { StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round) }

        if silhouette {
            let sil = GraphicsContext.Shading.color(silhouetteColor)
            ctx.fill(poly(tailOutline(g, tailCenter(g))), with: sil)
            ctx.fill(poly(bodyPoints(g)), with: sil)
            for s in signs { ctx.fill(poly(earPoints(g, s, 0, 0)), with: sil) }
            ctx.fill(poly(headPoints(g)), with: sil)
            return
        }

        // Frost: slow snow behind him
        if b.outfit == "frost" {
            for i in 0..<14 {
                let fx = CGFloat((sin(Double(i) * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)).magnitude
                let fy = CGFloat((sin(Double(i) * 78.233) * 12345.678).truncatingRemainder(dividingBy: 1)).magnitude
                let fall = (fy * 1.3 + CGFloat(clock) * 0.05).truncatingRemainder(dividingBy: 1.3) - 0.15
                let drift = CGFloat(sin(clock * 0.8 + Double(i))) * u * 0.015
                let c = pt(g.bx + (fx - 0.5) * u * 1.3 + drift, g.floorY - u * 1.15 + fall * u * 1.15)
                let rr = u * 0.014 * (1 + fx)
                ctx.fill(oval(c, rr, rr), with: .color(Color(hex: 0xC9E4F5).opacity(0.9)))
            }
        }
        // Midnight Star: twinkling sparkles, brighter while petted
        if b.outfit == "midnight" {
            let stars: [(CGFloat, CGFloat, CGFloat, UInt32)] = [(-0.62, -0.78, 1.4, 0xFFD166), (0.62, -0.62, 1.1, 0x9B7BFF),
                                                               (-0.66, -0.18, 0.9, 0x5FE0C8), (-0.38, -1.05, 0.8, 0x5FE0C8),
                                                               (0.48, -1.0, 0.9, 0xFFD166), (0.70, -0.25, 0.8, 0xFFD166)]
            for (i, st) in stars.enumerated() {
                let tw = 0.7 + 0.3 * CGFloat(sin(clock * (3 + 4 * Double(it)) + Double(i) * 1.7))
                let size = u * 0.035 * st.2 * tw * (1 + 0.4 * it)
                ctx.fill(ArtRender.sparkle(pt(g.bx + st.0 * u, g.floorY + st.1 * u), size), with: .color(Color(hex: st.3)))
            }
        }

        // Ground shadow
        ctx.drawLayer { l in
            l.addFilter(.blur(radius: u * 0.015))
            l.fill(oval(pt(g.bx, g.floorY + u * 0.005), g.bRX * 1.25, u * 0.03), with: .color(Color.black.opacity(0.16)))
        }

        // Tail (behind the body)
        let tc = tailCenter(g)
        let tail = poly(tailOutline(g, tc))
        ctx.fill(tail, with: .color(limb))
        if b.pattern == .aurora {
            ctx.fill(tail, with: .linearGradient(Gradient(colors: [Color(hex: 0x5FE0C8), Color(hex: 0x9B7BFF)]),
                                                 startPoint: tc[0], endPoint: tc[tc.count - 1]))
        }
        if b.pattern == .tabby {
            ctx.drawLayer { l in
                l.clip(to: tail)
                let n = tc.count - 1
                for j in 0..<4 {
                    let i0 = Int((0.30 + CGFloat(j) * 0.17) * CGFloat(n))
                    let i1 = min(n, i0 + 2)
                    l.stroke(poly([tc[i0], tc[i1]], closed: false), with: .color(b.mark.opacity(0.67)),
                             style: StrokeStyle(lineWidth: u * 0.16, lineCap: .butt))
                }
                l.fill(oval(tc[n], u * 0.075, u * 0.075), with: .color(b.mark.opacity(0.8)))
            }
        }
        ctx.stroke(tail, with: .color(b.line), style: outline)

        // Body
        let body = poly(bodyPoints(g))
        ctx.fill(body, with: .color(b.base))
        ctx.drawLayer { l in
            l.clip(to: body)
            l.drawLayer { s1 in
                s1.addFilter(.blur(radius: u * 0.02))
                for s in signs {
                    s1.fill(oval(pt(g.bx + s * g.bRX * 0.95, g.by + g.bRY * 0.35), g.bRX * 0.40, g.bRY * 0.9),
                            with: .color(b.shade.opacity(0.22)))
                }
                // shadow under the chin
                s1.fill(oval(pt(hx, hy + g.ryB * 0.95), r * 0.75, r * 0.22), with: .color(b.shade.opacity(0.43)))
            }
            l.drawLayer { s2 in
                s2.addFilter(.blur(radius: u * 0.012))
                s2.fill(oval(pt(g.bx, g.by + g.bRY * 0.10), g.bRX * 0.42, g.bRY * 0.75), with: .color(b.light.opacity(0.86)))
            }
            if b.pattern == .tuxedo {   // crisp white bib
                l.drawLayer { s3 in
                    s3.addFilter(.blur(radius: u * 0.004))
                    s3.fill(oval(pt(g.bx, g.by + g.bRY * 0.05), g.bRX * 0.40, g.bRY * 0.85), with: .color(b.light))
                }
            }
            if b.pattern == .tabby {
                for s in signs {
                    for k in 0..<3 {
                        let kk = CGFloat(k)
                        let y = g.by - g.bRY * 0.35 + kk * g.bRY * 0.30
                        let x0 = g.bx + s * g.bRX * (0.98 - 0.02 * kk)
                        l.fill(taper(pt(x0, y), pt(x0 - s * g.bRX * 0.16, y + g.bRY * 0.05),
                                     pt(x0 - s * g.bRX * 0.30, y + g.bRY * 0.12), u * 0.035),
                               with: .color(b.mark.opacity(0.67)))
                    }
                }
            }
        }
        ArtRender.drawOutfit(b.outfit, layer: .bodyPattern, in: ctx, geo: g, head: nil, body: body)
        ctx.stroke(body, with: .color(b.line), style: outline)

        // Legs: inner leg lines and haunch curves (kept inside the body outline)
        ctx.drawLayer { ctx in
        ctx.clip(to: body)
        for s in signs {
            let lx = g.bx + s * g.bRX * 0.30
            ctx.stroke(poly(curve(pt(lx - s * g.bRX * 0.04, g.by + g.bRY * 0.10),
                                  pt(lx + s * g.bRX * 0.02, g.by + g.bRY * 0.5),
                                  pt(lx + s * g.bRX * 0.02, g.floorY - u * 0.035)), closed: false),
                       with: .color(b.detail), style: line(lw * 0.85))
            ctx.stroke(poly(curve(pt(g.bx + s * g.bRX * 0.50, g.floorY - u * 0.02),
                                  pt(g.bx + s * g.bRX * 0.62, g.by),
                                  pt(g.bx + s * g.bRX * 0.86, g.by - g.bRY * 0.05)), closed: false),
                       with: .color(b.detail.opacity(0.6)), style: line(lw * 0.75))
        }
        }

        // Outfit on the body (sweater, buttons), then the outline again on top of it
        if ArtRender.hasLayer(b.outfit, .body) {
            ArtRender.drawOutfit(b.outfit, layer: .body, in: ctx, geo: g, head: nil, body: body)
            ctx.stroke(body, with: .color(b.line), style: outline)
        }

        // Paws
        for s in signs {
            let pc = pt(g.bx + s * g.bRX * 0.17, g.floorY - u * 0.032)
            let paw = oval(pc, u * 0.068, u * 0.040)
            ctx.fill(paw, with: .color(points ? b.mark : b.light))
            ctx.stroke(paw, with: .color(b.line), style: outline)
            var toes = Path()
            for k in [CGFloat(-1), CGFloat(1)] {
                toes.move(to: pt(pc.x + k * u * 0.020, pc.y + u * 0.005))
                toes.addLine(to: pt(pc.x + k * u * 0.020, pc.y + u * 0.030))
            }
            ctx.stroke(toes, with: .color(b.detail), style: line(lw * 0.7))
        }

        ArtRender.drawOutfit(b.outfit, layer: .paw, in: ctx, geo: g, head: nil, body: body)

        // Ears (behind the head)
        for s in signs {
            let twitch: CGFloat = (zone == .ears && touching) ? CGFloat(sin(phase * 9 + Double(s))) * r * 0.05 : 0
            let ear = poly(earPoints(g, s, irr, twitch))
            ctx.fill(ear, with: .color(points ? b.mark : b.base))
            if b.pattern == .aurora {   // aurora-tipped ears
                let tip = pt(hx + s * r * 0.70, hy - r * 1.12)
                ctx.drawLayer { l in
                    l.clip(to: ear)
                    l.fill(oval(tip, r * 0.42, r * 0.42),
                           with: .linearGradient(Gradient(colors: [Color(hex: 0x5FE0C8), Color(hex: 0x9B7BFF)]),
                                                 startPoint: pt(tip.x - s * r * 0.3, tip.y), endPoint: pt(tip.x + s * r * 0.1, tip.y + r * 0.4)))
                }
            }
            ctx.stroke(ear, with: .color(b.line), style: outline)
            let innerPts = earPoints(g, s, irr, twitch, k: 0.58)
            ctx.fill(poly(innerPts), with: .color((b.inner ?? b.nose).opacity(0.8)))
            // fluffy tuft inside the ear
            let ic = pt(innerPts.map(\.x).reduce(0, +) / CGFloat(innerPts.count),
                        innerPts.map(\.y).reduce(0, +) / CGFloat(innerPts.count))
            var tuft = Path()
            for k in 0..<3 {
                let kk = CGFloat(k)
                let a = pt(ic.x - s * r * 0.02 + kk * s * r * 0.05, ic.y + r * 0.12)
                tuft.move(to: a)
                tuft.addLine(to: pt(a.x + s * r * 0.02 - kk * s * r * 0.03, a.y - r * 0.16 + kk * r * 0.03))
            }
            ctx.stroke(tuft, with: .color(b.light.opacity(0.9)), style: line(lw * 0.8))
        }

        // Collars and scarves sit on the body, under the head
        ArtRender.drawOutfit(b.outfit, layer: .neck, in: ctx, geo: g, head: nil, body: body)

        // Head
        let head = poly(headPoints(g))
        ctx.fill(head, with: .color(b.base))
        ctx.drawLayer { l in
            l.clip(to: head)
            l.drawLayer { m in
                m.addFilter(.blur(radius: u * 0.02))
                m.fill(oval(pt(hx, hy + r * 0.38), r * 0.55, r * 0.32), with: .color(b.light.opacity(0.9)))
            }
            if points {
                l.drawLayer { m in
                    m.addFilter(.blur(radius: u * 0.05))
                    m.fill(oval(pt(hx, hy + r * 0.25), r * 0.62, r * 0.52), with: .color(b.mark.opacity(0.67)))
                }
            }
            if b.pattern == .tabby {
                let mk = b.mark.opacity(0.72)
                let top = hy - g.ryT
                l.fill(taper(pt(hx, top - r * 0.02), pt(hx, top + r * 0.18), pt(hx, top + r * 0.38), r * 0.085), with: .color(mk))
                for s in signs {
                    l.fill(taper(pt(hx + s * r * 0.22, top), pt(hx + s * r * 0.25, top + r * 0.16),
                                 pt(hx + s * r * 0.19, top + r * 0.32), r * 0.075), with: .color(mk))
                    for k in 0..<2 {
                        let y = hy + r * (0.10 + 0.16 * CGFloat(k))
                        l.fill(taper(pt(hx + s * r * 1.05, y), pt(hx + s * r * 0.92, y + r * 0.02),
                                     pt(hx + s * r * 0.78, y + r * 0.05), r * 0.07), with: .color(mk))
                    }
                }
            }
        }
        if b.pattern == .tuxedo {   // crisp white muzzle
            ctx.drawLayer { l in
                l.clip(to: head)
                l.addFilter(.blur(radius: u * 0.004))
                l.fill(oval(pt(hx, hy + r * 0.40), r * 0.50, r * 0.30), with: .color(b.light))
            }
        }
        ArtRender.drawOutfit(b.outfit, layer: .headPattern, in: ctx, geo: g, head: head, body: body)
        ctx.stroke(head, with: .color(b.line), style: outline)

        // Chest ruff mark and a little tuft on the crown
        let chestY = hy + g.ryB + r * 0.16
        let zz = (0..<5).map { i in pt(hx - r * 0.16 + CGFloat(i) * r * 0.08, chestY + (i % 2 == 1 ? r * 0.05 : 0)) }
        ctx.stroke(poly(zz, closed: false), with: .color(b.detail.opacity(0.67)), style: line(lw * 0.8))
        let crown = hy - g.ryT
        let crownTuft: [CGFloat] = ArtRender.hasLayer(b.outfit, .top) ? [] : [-1, 0, 1]   // hidden under hats
        for k in crownTuft {
            ctx.stroke(poly(curve(pt(hx + k * r * 0.05, crown + r * 0.01), pt(hx + k * r * 0.07, crown - r * 0.06),
                                  pt(hx + k * r * 0.12 + r * 0.02, crown - r * 0.09), 8), closed: false),
                       with: .color(b.line), style: line(lw * 0.8))
        }

        ArtRender.drawOutfit(b.outfit, layer: .face, in: ctx, geo: g, head: head, body: body)

        // Blush
        ctx.drawLayer { l in
            l.addFilter(.blur(radius: u * 0.012))
            for s in signs {
                l.fill(oval(pt(hx + s * r * 0.58, hy + r * 0.30), r * 0.16, r * 0.09),
                       with: .color(Color(hex: 0xF0828C).opacity(0.43 * Double(1 - irr))))
            }
        }

        // Eyes: big, shiny; close happily when purring, blink now and then, squint when annoyed
        let blinkT = clock.truncatingRemainder(dividingBy: 4.3)
        let blink: CGFloat = blinkT < 0.14 ? CGFloat(abs(blinkT - 0.07) / 0.07) : 1
        let openBase: CGFloat = irr > 0.5 ? 0.6 : max(0, 1 - it * 1.4)
        let open = openBase * blink
        for s in signs {
            let ex = hx + s * r * 0.42, ey = hy + r * 0.02
            let erx = r * 0.20, ery = r * 0.235
            if open < 0.15 {
                let c = it > 0.4 ? -r * 0.20 : r * 0.06   // ^ when content, ‿ when blinking
                ctx.stroke(poly(curve(pt(ex - erx * 0.9, ey + r * 0.04), pt(ex, ey + c), pt(ex + erx * 0.9, ey + r * 0.04)), closed: false),
                           with: .color(b.line), style: line(lw * 1.6))
                continue
            }
            let eye = oval(pt(ex, ey), erx, ery)
            let lidOuter = ey - ery + (1 - open) * ery * 2
            let lidInner = irr > 0.4 ? lidOuter + irr * ery * 0.45 : lidOuter
            let inner = pt(ex - s * erx * 1.3, lidInner), outer = pt(ex + s * erx * 1.3, lidOuter)
            let belowLid = poly([inner, outer, pt(outer.x, ey + ery * 2), pt(inner.x, ey + ery * 2)])
            ctx.drawLayer { l in
                l.clip(to: eye)
                l.clip(to: belowLid)
                l.fill(eye, with: .color(Color(hex: 0x2A1B18)))
                let iris = Path(ellipseIn: CGRect(x: ex - erx * 0.82, y: ey - ery * 0.55, width: erx * 1.64, height: ery * 1.45))
                l.fill(iris, with: .color(b.eye))
                l.drawLayer { d in
                    d.clip(to: iris)
                    d.fill(Path(CGRect(x: ex - erx, y: ey - ery, width: erx * 2, height: ery * 0.75)),
                           with: .color(Color.black.opacity(0.25)))
                }
                let pw = irr < 0.5 ? erx * (0.30 + 0.25 * it) : erx * 0.18
                l.fill(oval(pt(ex, ey), pw, ery * 0.55), with: .color(Color(hex: 0x1A100E)))
                l.fill(Path(ellipseIn: CGRect(x: ex + erx * 0.05, y: ey - ery * 0.62, width: erx * 0.57, height: ery * 0.52)),
                       with: .color(Color.white.opacity(0.96)))
                l.fill(Path(ellipseIn: CGRect(x: ex - erx * 0.55, y: ey + ery * 0.30, width: erx * 0.25, height: ery * 0.22)),
                       with: .color(Color.white.opacity(0.78)))
            }
            if open > 0.9 && irr < 0.4 {
                let arc = (0...16).map { i -> CGPoint in
                    let a = CGFloat.pi + CGFloat(i) / 16 * .pi
                    return pt(ex + erx * cos(a) * 1.02, ey + ery * sin(a) * 1.02)
                }
                ctx.stroke(poly(arc, closed: false), with: .color(b.line), style: line(lw * 1.9))
                let oc = pt(ex + s * erx, ey - ery * 0.15)
                ctx.stroke(poly([oc, pt(oc.x + s * erx * 0.30, oc.y - ery * 0.25)], closed: false),
                           with: .color(b.line), style: line(lw * 1.4))
            } else {
                ctx.drawLayer { l in
                    l.clip(to: Path(CGRect(x: ex - erx * 1.15, y: ey - ery * 1.5, width: erx * 2.3, height: ery * 3)))
                    l.stroke(poly([inner, outer], closed: false), with: .color(b.line), style: line(lw * 1.9))
                }
                let bottom = (0...16).map { i -> CGPoint in
                    let a = CGFloat(i) / 16 * .pi
                    return pt(ex + erx * cos(a), ey + ery * sin(a))
                }
                ctx.stroke(poly(bottom, closed: false), with: .color(b.line.opacity(0.47)), style: line(lw * 0.8))
            }
        }

        // Nose and mouth
        let ny = hy + r * 0.30
        let nose = curve(pt(hx - r * 0.065, ny), pt(hx, ny - r * 0.035), pt(hx + r * 0.065, ny), 6)
            + curve(pt(hx + r * 0.065, ny), pt(hx + r * 0.04, ny + r * 0.05), pt(hx, ny + r * 0.065), 6).dropFirst()
            + curve(pt(hx, ny + r * 0.065), pt(hx - r * 0.04, ny + r * 0.05), pt(hx - r * 0.065, ny), 6).dropFirst()
        ctx.fill(poly(nose), with: .color(b.nose))
        let my = ny + r * 0.065
        if irr > 0.5 {
            ctx.stroke(poly(curve(pt(hx - r * 0.10, my + r * 0.10), pt(hx, my + r * 0.02), pt(hx + r * 0.10, my + r * 0.10)), closed: false),
                       with: .color(b.detail), style: line(lw))
        } else {
            for s in signs {
                ctx.stroke(poly(curve(pt(hx, my), pt(hx + s * r * 0.01, my + r * 0.10), pt(hx + s * r * 0.075, my + r * 0.07)), closed: false),
                           with: .color(b.detail), style: line(lw))
            }
        }

        // Whiskers
        var wh = Path()
        let sway = CGFloat(sin(phase)) * r * 0.01
        for s in signs {
            for k in 0..<2 {
                let kk = CGFloat(k)
                let y0 = hy + r * (0.22 + 0.10 * kk)
                let x0 = hx + s * r * 0.97
                wh.move(to: pt(x0, y0))
                wh.addLine(to: pt(x0 + s * r * 0.22, y0 - r * 0.05 + kk * r * 0.10 + sway))
            }
        }
        ctx.stroke(wh, with: .color(b.detail), style: line(lw * 0.7))

        // Reindeer: the nose glows, more while he purrs
        if b.outfit == "reindeer" {
            let glow = 0.35 + 0.65 * Double(it)
            ctx.drawLayer { l in
                l.addFilter(.blur(radius: u * 0.02))
                l.fill(oval(pt(hx, hy + r * 0.32), r * 0.22, r * 0.22), with: .color(Color(hex: 0xFF6B5E).opacity(0.45 * glow)))
            }
        }

        // Outfit around the neck and on top of the head
        ArtRender.drawOutfit(b.outfit, layer: .top, in: ctx, geo: g, head: head, body: body)

        // Cartoon "happy vibes": zig-zags around him when he's really satisfied
        let joy = max(0, (it - 0.6) / 0.4) * (1 - irr)
        if joy > 0.01 {
            let top = hy - r * 1.15
            let cc = pt(g.bx, (top + g.floorY) / 2)
            let rx = g.bRX * 1.75, ry = (g.floorY - top) / 2 * 1.02
            let angles: [CGFloat] = [160, 195, 228, 258, 282, 312, 345, 20]
            let tick = Int(clock * 9)
            var zz = Path()
            for (k, deg) in angles.enumerated() where (tick + k) % 3 != 0 {   // flicker like a comic
                let a = deg * .pi / 180
                let dir = pt(cos(a), sin(a))
                let side = pt(-dir.y, dir.x)
                let jitter = CGFloat(sin(clock * 30 + Double(k))) * u * 0.008
                let start = pt(cc.x + dir.x * (rx + jitter), cc.y + dir.y * (ry + jitter))
                let len = u * 0.075, amp = u * 0.014
                zz.move(to: start)
                for j in 1...4 {
                    let t = CGFloat(j) / 4
                    let off = (j % 2 == 1 ? amp : -amp) * (j == 4 ? 0 : 1)
                    zz.addLine(to: pt(start.x + dir.x * len * t + side.x * off, start.y + dir.y * len * t + side.y * off))
                }
            }
            let vibe = onDark ? Color(hex: 0xF4EEF3) : b.line
            ctx.stroke(zz, with: .color(vibe.opacity(0.85 * Double(min(1, joy * 1.5)))), style: line(lw * 1.1))
        }

        // Comic words
        let headTop = hy - r
        for w in words {
            let pop = min(1, w.age / 0.15)
            let alpha = min(1, (w.life - w.age) / 0.45) * pop
            let scale = 0.6 + 0.4 * pop
            ctx.drawLayer { l in
                l.opacity = alpha
                l.translateBy(x: hx + w.x * u, y: headTop + w.y * u)
                l.rotate(by: .degrees(w.angle))
                l.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
                let ink = w.angry ? Color(hex: onDark ? 0xFF8E93 : 0xC2412F)
                                  : onDark ? Color(hex: 0xF4EEF3).opacity(0.92) : b.line.opacity(0.9)
                l.draw(Text(w.text).font(.custom("ChalkboardSE-Bold", size: w.size * u)).foregroundColor(ink), at: .zero)
            }
        }
    }
}
