from outfits import OUTFITS, parse
def f(v): 
    s = ('%.2f' % v).rstrip('0').rstrip('.'); return s if s not in ('-0', '') else '0'
def ops(o):
    out = []
    for op in o:
        if op[0] == 'Z': out.append('.z')
        else: out.append('.%s(%s)' % (op[0].lower(), ', '.join(f(x) for x in op[1:])))
    return '[' + ', '.join(out) + ']'
def col(c): return 'nil' if c is None else '0x%06X' % c
LAY = dict(bodypat='bodyPattern', body='body', paw='paw', headpat='headPattern', face='face', neck='neck', top='top')
lines = []
for name, parts in OUTFITS.items():
    lines.append('        case "%s": return [' % name)
    for lay, p in parts:
        if p['kind'] == 'ellipse':
            shape = '.ellipse(%s, %s, %s, %s)' % (f(p['c'][0]), f(p['c'][1]), f(p['r'][0]), f(p['r'][1]))
        else:
            shape = '.path(%s)' % ops(p['ops'])
        extra = []
        if p['fill'] is not None: extra.append('fill: %s' % col(p['fill']))
        if p['stroke'] is not None: extra.append('stroke: %s, width: %s' % (col(p['stroke']), f(p['w'])))
        if p.get('dash'): extra.append('dash: [%s, %s]' % (f(p['dash'][0]), f(p['dash'][1])))
        if p['op'] != 1: extra.append('opacity: %s' % f(p['op']))
        if p.get('clip'): extra.append('clip: .%s' % p['clip'])
        if p.get('cap') == 'butt': extra.append('butt: true')
        lines.append('            ArtPart(.%s, .%s, %s, %s),' % (LAY[lay], p['anchor'], shape, ', '.join(extra)))
    lines.append('        ]')
outfit_cases = '\n'.join(lines)

# box art (200x200 viewBox, uniform scale)
B = []
def bp(shape, **kw):
    extra = []
    if 'fill' in kw: extra.append('fill: 0x%06X' % kw['fill'])
    if 'stroke' in kw: extra.append('stroke: 0x%06X, width: %s' % (kw['stroke'], f(kw['w'])))
    if 'op' in kw: extra.append('opacity: %s' % f(kw['op']))
    B.append('        ArtPart(.top, .box, %s, %s),' % (shape, ', '.join(extra)))
E = lambda cx, cy, rx, ry, rot=0: '.ellipse(%s, %s, %s, %s%s)' % (f(cx), f(cy), f(rx), f(ry), ', rotation: %s' % f(rot) if rot else '')
Rr = lambda x, y, w, h, r=0: '.rect(%s, %s, %s, %s, radius: %s)' % (f(x), f(y), f(w), f(h), f(r))
Pp = lambda d: '.path(%s)' % ops(parse(d))
bp(E(100, 188, 66, 8), fill=0x000000, op=0.14)
bp(Rr(40, 90, 120, 92, 12), fill=0xC8323C, stroke=0x9E2630, w=3)
bp(Rr(92, 90, 16, 92), fill=0xE9B949)
for (x, y, r) in [(66, 152, 9), (56, 138, 4), (64, 132, 4), (73, 134, 4), (78, 142, 3.6)]: bp(E(x, y, r, r), fill=0xB12A34)
bp(Pp('M44 74 L52 42 Q54 38 58 41 L80 72 Z'), fill=0xD63B45, stroke=0x9E2630, w=3)
bp(Pp('M52 70 L56 50 L70 70 Z'), fill=0xF2A7B4)
bp(Pp('M156 74 L148 42 Q146 38 142 41 L120 72 Z'), fill=0xD63B45, stroke=0x9E2630, w=3)
bp(Pp('M148 70 L144 50 L130 70 Z'), fill=0xF2A7B4)
bp(Rr(32, 70, 136, 30, 10), fill=0xD63B45, stroke=0x9E2630, w=3)
bp(Rr(92, 70, 16, 30), fill=0xE9B949)
bp(Pp('M40 74 Q52 66 64 73 Q74 66 84 73'), stroke=0xFFFFFF, w=5, op=0.85)
bp(E(86, 60, 15, 9, -25), fill=0xF2C94C, stroke=0xC99A2E, w=2.5)
bp(E(114, 60, 15, 9, 25), fill=0xF2C94C, stroke=0xC99A2E, w=2.5)
bp(E(100, 66, 7, 7), fill=0xF2C94C, stroke=0xC99A2E, w=2.5)
bp(Pp('M156 100 Q168 104 166 114'), stroke=0xC99A2E, w=2)
bp(Rr(140, 112, 54, 32, 6), fill=0xFFF8EC, stroke=0xE9B949, w=2)
bp(E(166, 117, 2, 2), fill=0xE9B949)
box = '\n'.join(B)

src = '''// GENERATED from the Pocket Purr Christmas design canvas (200×200 artboard units).
// Outfit, pattern and box shapes are taken from the design so the app matches it.
import SwiftUI

enum PathOp {
    case m(CGFloat, CGFloat), l(CGFloat, CGFloat)
    case q(CGFloat, CGFloat, CGFloat, CGFloat)
    case c(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
    case z
}

enum ArtShape {
    case path([PathOp])
    case ellipse(CGFloat, CGFloat, CGFloat, CGFloat, rotation: CGFloat = 0)
    case rect(CGFloat, CGFloat, CGFloat, CGFloat, radius: CGFloat)
}

/// Where a part is drawn in the cat's layer order.
enum ArtLayer { case bodyPattern, body, paw, headPattern, face, neck, top }
/// Which part of the cat the design coordinates are pinned to (so outfits squish and lean with him).
/// `neck` follows the body (not the bobbing head), for collars and scarves.
enum ArtAnchor { case head, neck, body, pawL, pawR, box }
enum ArtClip { case head, body }

struct ArtPart {
    var layer: ArtLayer
    var anchor: ArtAnchor
    var shape: ArtShape
    var fill: UInt32? = nil
    var stroke: UInt32? = nil
    var width: CGFloat = 0
    var dash: [CGFloat]? = nil
    var opacity: Double = 1
    var clip: ArtClip? = nil
    var butt = false

    init(_ layer: ArtLayer, _ anchor: ArtAnchor, _ shape: ArtShape, fill: UInt32? = nil, stroke: UInt32? = nil,
         width: CGFloat = 0, dash: [CGFloat]? = nil, opacity: Double = 1, clip: ArtClip? = nil, butt: Bool = false) {
        self.layer = layer; self.anchor = anchor; self.shape = shape; self.fill = fill; self.stroke = stroke
        self.width = width; self.dash = dash; self.opacity = opacity; self.clip = clip; self.butt = butt
    }
}

enum OutfitArt {
    static func parts(_ outfit: String?) -> [ArtPart] {
        switch outfit {
%s
        default: return []
        }
    }

    static let box: [ArtPart] = [
%s
    ]
}
''' % (outfit_cases, box)
open(__import__('os').path.join(__import__('os').path.dirname(__file__), '..', 'Outfits.swift'), 'w').write(src)
print(len(src))
