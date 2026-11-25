import SwiftUI

// Draws the design-canvas shapes from Outfits.swift onto the live, squishy cat.
// Each part is pinned to the head, the body or a paw, so outfits move with him.

enum ArtRender {
    typealias Mapper = (CGFloat, CGFloat) -> CGPoint

    /// Maps design units (200×200 artboard) to screen points for one anchor.
    static func mapper(_ g: Geo, _ anchor: ArtAnchor) -> (map: Mapper, kx: CGFloat, ky: CGFloat) {
        switch anchor {
        case .head:
            // design head: x 40…160, y 36…122
            let kx = g.r / 60, ky = (g.ryT + g.ryB) / 86
            let top = g.hy - g.ryT
            return ({ x, y in CGPoint(x: g.hx + (x - 100) * kx, y: top + (y - 36) * ky) }, kx, ky)
        case .body:
            // design body: x 52…148, y 113…186
            let kx = g.bRX / 48, ky = 2 * g.bRY / 73
            let top = g.by - g.bRY
            return ({ x, y in CGPoint(x: g.bx + (x - 100) * kx, y: top + (y - 113) * ky) }, kx, ky)
        case .pawL, .pawR:
            let s: CGFloat = anchor == .pawL ? -1 : 1
            let designX: CGFloat = anchor == .pawL ? 87 : 113
            let pc = CGPoint(x: g.bx + s * g.bRX * 0.17, y: g.floorY - g.u * 0.032)
            let kx = g.u * 0.068 / 12, ky = g.u * 0.040 / 7
            return ({ x, y in CGPoint(x: pc.x + (x - designX) * kx, y: pc.y + (y - 183) * ky) }, kx, ky)
        case .box:
            return ({ x, y in CGPoint(x: x, y: y) }, 1, 1)
        }
    }

    static func path(_ shape: ArtShape, _ map: Mapper, _ kx: CGFloat, _ ky: CGFloat) -> Path {
        switch shape {
        case .path(let ops):
            var p = Path()
            for op in ops {
                switch op {
                case let .m(x, y): p.move(to: map(x, y))
                case let .l(x, y): p.addLine(to: map(x, y))
                case let .q(cx, cy, x, y): p.addQuadCurve(to: map(x, y), control: map(cx, cy))
                case let .c(ax, ay, bx, by, x, y): p.addCurve(to: map(x, y), control1: map(ax, ay), control2: map(bx, by))
                case .z: p.closeSubpath()
                }
            }
            return p
        case let .ellipse(cx, cy, rx, ry, rotation):
            let c = map(cx, cy)
            let e = Path(ellipseIn: CGRect(x: -rx * kx, y: -ry * ky, width: 2 * rx * kx, height: 2 * ry * ky))
            let t = CGAffineTransform(rotationAngle: rotation * .pi / 180).concatenating(CGAffineTransform(translationX: c.x, y: c.y))
            return e.applying(t)
        case let .rect(x, y, w, h, radius):
            let o = map(x, y)
            return Path(roundedRect: CGRect(x: o.x, y: o.y, width: w * kx, height: h * ky), cornerRadius: radius * kx)
        }
    }

    static func draw(_ part: ArtPart, in ctx: GraphicsContext, map: Mapper, kx: CGFloat, ky: CGFloat, clip: Path?) {
        let p = path(part.shape, map, kx, ky)
        let k = (kx + ky) / 2
        func paint(_ c: GraphicsContext) {
            if let fill = part.fill {
                c.fill(p, with: .color(Color(hex: fill).opacity(part.opacity)))
            }
            if let stroke = part.stroke {
                let style = StrokeStyle(lineWidth: part.width * k, lineCap: part.butt ? .butt : .round, lineJoin: .round,
                                        dash: (part.dash ?? []).map { $0 * k })
                c.stroke(p, with: .color(Color(hex: stroke).opacity(part.opacity)), style: style)
            }
        }
        if let clip {
            ctx.drawLayer { l in
                l.clip(to: clip)
                paint(l)
            }
        } else {
            paint(ctx)
        }
    }

    /// Draws one layer of a cat's outfit.
    static func drawOutfit(_ outfit: String?, layer: ArtLayer, in ctx: GraphicsContext, geo g: Geo, head: Path?, body: Path?) {
        for part in OutfitArt.parts(outfit) where part.layer == layer {
            let m = mapper(g, part.anchor)
            let clip: Path? = part.clip == .head ? head : part.clip == .body ? body : nil
            draw(part, in: ctx, map: m.map, kx: m.kx, ky: m.ky, clip: clip)
        }
    }

    static func hasLayer(_ outfit: String?, _ layer: ArtLayer) -> Bool {
        OutfitArt.parts(outfit).contains { $0.layer == layer }
    }

    /// A four-point twinkle star.
    static func sparkle(_ c: CGPoint, _ size: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - size))
        p.addQuadCurve(to: CGPoint(x: c.x + size, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + size), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x - size, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - size), control: c)
        p.closeSubpath()
        return p
    }

    // MARK: - The Christmas box

    /// Draws the box art (design units 0…200) into a square of side `side` at `origin`.
    static func drawBox(in ctx: GraphicsContext, origin: CGPoint, side: CGFloat) {
        let k = side / 200
        let map: Mapper = { x, y in CGPoint(x: origin.x + x * k, y: origin.y + y * k) }
        for part in OutfitArt.box {
            draw(part, in: ctx, map: map, kx: k, ky: k, clip: nil)
        }
        let ink = Color(hex: 0x24563F)
        let font = Font.system(size: 9.5 * k, weight: .heavy)
        ctx.draw(Text("Christmas").font(font).foregroundColor(ink), at: map(167, 125.5))
        ctx.draw(Text("Series").font(font).foregroundColor(ink), at: map(167, 136.5))
    }
}
