// GENERATED from the Pocket Purr Christmas design canvas (200×200 artboard units).
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
enum ArtAnchor { case head, body, pawL, pawR, box }
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
        case "gingerbread": return [
            ArtPart(.body, .body, .ellipse(100, 138, 4.5, 4.5), fill: 0xE0413A),
            ArtPart(.body, .body, .ellipse(100, 151, 4.5, 4.5), fill: 0xE0413A),
            ArtPart(.body, .body, .ellipse(98.6, 136.6, 1.4, 1.4), fill: 0xFFB3AE),
            ArtPart(.body, .body, .ellipse(98.6, 149.6, 1.4, 1.4), fill: 0xFFB3AE),
            ArtPart(.paw, .pawL, .path([.m(79, 180), .q(81, 177.5, 83, 180), .q(85, 182.5, 87, 180), .q(89, 177.5, 91, 180)]), stroke: 0xFFFFFF, width: 2),
            ArtPart(.paw, .pawR, .path([.m(105, 180), .q(107, 177.5, 109, 180), .q(111, 182.5, 113, 180), .q(115, 177.5, 117, 180)]), stroke: 0xFFFFFF, width: 2),
            ArtPart(.face, .head, .path([.m(50, 104), .q(52.5, 101, 55, 104), .q(57.5, 107, 60, 104), .q(62.5, 101, 65, 104)]), stroke: 0xFFFFFF, width: 2.2),
            ArtPart(.face, .head, .path([.m(135, 104), .q(137.5, 101, 140, 104), .q(142.5, 107, 145, 104), .q(147.5, 101, 150, 104)]), stroke: 0xFFFFFF, width: 2.2),
            ArtPart(.neck, .head, .path([.m(100, 121), .l(87, 114), .l(87, 128), .z]), fill: 0xFFFFFF, stroke: 0xD9C9B5, width: 2),
            ArtPart(.neck, .head, .path([.m(100, 121), .l(113, 114), .l(113, 128), .z]), fill: 0xFFFFFF, stroke: 0xD9C9B5, width: 2),
            ArtPart(.neck, .head, .ellipse(100, 121, 4, 4), fill: 0xFFFFFF, stroke: 0xD9C9B5, width: 2),
        ]
        case "reindeer": return [
            ArtPart(.neck, .head, .path([.m(72, 116), .q(100, 132, 128, 116)]), stroke: 0xC8323C, width: 6),
            ArtPart(.neck, .head, .ellipse(100, 128, 6, 6), fill: 0xE9B949, stroke: 0xB8902A, width: 2),
            ArtPart(.neck, .head, .path([.m(97.5, 130), .l(102.5, 130)]), stroke: 0x8A6A1E, width: 1.5),
            ArtPart(.top, .head, .path([.m(80, 42), .q(100, 30, 120, 42)]), stroke: 0x8A5A3B, width: 4),
            ArtPart(.top, .head, .path([.m(88, 37), .l(84, 14), .m(85, 23), .l(76, 17), .m(86, 30), .l(94, 22)]), stroke: 0xB9875A, width: 6),
            ArtPart(.top, .head, .path([.m(112, 37), .l(116, 14), .m(115, 23), .l(124, 17), .m(114, 30), .l(106, 22)]), stroke: 0xB9875A, width: 6),
        ]
        case "elf": return [
            ArtPart(.bodyPattern, .body, .path([.m(50, 146), .q(62, 122, 84, 128), .q(82, 156, 56, 168), .z]), fill: 0xE8964A, clip: .body),
            ArtPart(.bodyPattern, .body, .path([.m(122, 168), .q(138, 152, 150, 144), .q(152, 172, 134, 186), .z]), fill: 0x3A3438, clip: .body),
            ArtPart(.headPattern, .head, .path([.m(36, 60), .q(58, 32, 88, 42), .q(84, 70, 42, 82), .z]), fill: 0xE8964A, clip: .head),
            ArtPart(.headPattern, .head, .path([.m(114, 40), .q(150, 38, 164, 70), .q(140, 80, 116, 62), .z]), fill: 0x3A3438, clip: .head),
            ArtPart(.neck, .head, .path([.m(112, 124), .l(120, 152), .l(130, 148), .l(122, 122), .z]), fill: 0xD9433F, stroke: 0xB0302D, width: 1.5),
            ArtPart(.neck, .head, .path([.m(116, 138), .l(126, 135)]), stroke: 0xFFFFFF, width: 3),
            ArtPart(.neck, .head, .path([.m(70, 116), .q(100, 134, 130, 116)]), stroke: 0xD9433F, width: 9),
            ArtPart(.neck, .head, .path([.m(82, 121), .l(83, 129), .m(100, 124), .l(100, 132), .m(118, 121), .l(117, 129)]), stroke: 0xFFFFFF, width: 3),
            ArtPart(.top, .head, .path([.m(80, 40), .q(100, 30, 122, 38), .l(112, 2), .z]), fill: 0x3E8E4F, stroke: 0x2A5E37, width: 2.5),
            ArtPart(.top, .head, .path([.m(78, 42), .q(100, 32, 124, 40)]), stroke: 0xFFFFFF, width: 7),
            ArtPart(.top, .head, .ellipse(112, 3, 5, 5), fill: 0xE9B949, stroke: 0xB8902A, width: 2),
        ]
        case "frost": return [
            ArtPart(.face, .head, .path([.m(46, 72), .q(56, 46, 98, 39)]), stroke: 0xFFFFFF, width: 3.5, opacity: 0.8),
            ArtPart(.neck, .head, .path([.m(80, 124), .l(74, 152), .l(86, 154), .l(90, 126), .z]), fill: 0x8FD9C0, stroke: 0x5FAE95, width: 1.5),
            ArtPart(.neck, .head, .path([.m(76, 146), .l(86, 148)]), stroke: 0x5FAE95, width: 2),
            ArtPart(.neck, .head, .path([.m(70, 116), .q(100, 134, 130, 116)]), stroke: 0x8FD9C0, width: 10),
            ArtPart(.neck, .head, .path([.m(70, 116), .q(100, 134, 130, 116)]), stroke: 0x5FAE95, width: 2, dash: [3, 4], butt: true),
            ArtPart(.paw, .pawL, .ellipse(87, 182, 14, 9), fill: 0xFFFFFF, stroke: 0xC9D2E2, width: 2.5),
            ArtPart(.paw, .pawR, .ellipse(113, 182, 14, 9), fill: 0xFFFFFF, stroke: 0xC9D2E2, width: 2.5),
            ArtPart(.paw, .pawL, .path([.m(74, 177), .q(87, 170, 100, 177)]), stroke: 0x8FD9C0, width: 4.5),
            ArtPart(.paw, .pawR, .path([.m(100, 177), .q(113, 170, 126, 177)]), stroke: 0x8FD9C0, width: 4.5),
        ]
        case "cocoa": return [
            ArtPart(.body, .body, .path([.m(54, 150), .c(56, 130, 64, 118, 74, 113), .l(126, 113), .c(136, 118, 144, 130, 146, 150), .c(148, 166, 147, 176, 142, 178), .l(58, 178), .c(53, 176, 52, 166, 54, 150), .z]), fill: 0xC8323C, stroke: 0x8E1F29, width: 2.5, clip: .body),
            ArtPart(.body, .body, .path([.m(56, 152), .l(64, 146), .l(72, 152), .l(80, 146), .l(88, 152), .l(96, 146), .l(104, 152), .l(112, 146), .l(120, 152), .l(128, 146), .l(136, 152), .l(144, 147)]), stroke: 0xF3E3C8, width: 4, clip: .body),
            ArtPart(.body, .body, .ellipse(76, 166, 2.4, 2.4), fill: 0xF3E3C8),
            ArtPart(.body, .body, .ellipse(100, 168, 2.4, 2.4), fill: 0xF3E3C8),
            ArtPart(.body, .body, .ellipse(124, 166, 2.4, 2.4), fill: 0xF3E3C8),
            ArtPart(.neck, .head, .path([.m(74, 114), .q(100, 128, 126, 114)]), stroke: 0xF3E3C8, width: 6),
        ]
        case "midnight": return [
            ArtPart(.neck, .head, .path([.m(72, 116), .q(100, 132, 128, 116)]), stroke: 0xE9B949, width: 5),
            ArtPart(.neck, .head, .ellipse(100, 128, 6, 6), fill: 0xFFD166, stroke: 0xC99A2E, width: 2),
            ArtPart(.neck, .head, .path([.m(97.5, 130), .l(102.5, 130)]), stroke: 0x8A6A1E, width: 1.5),
            ArtPart(.top, .head, .path([.m(84, 40), .q(100, 33, 116, 40)]), stroke: 0xE9B949, width: 4),
            ArtPart(.top, .head, .path([.m(100, 15), .l(102.7, 22.3), .l(110.5, 22.6), .l(104.4, 27.4), .l(106.5, 34.9), .l(100, 30.6), .l(93.5, 34.9), .l(95.6, 27.4), .l(89.5, 22.6), .l(97.3, 22.3), .z]), fill: 0xFFD166, stroke: 0xE0A82E, width: 1.5),
        ]
        default: return []
        }
    }

    static let box: [ArtPart] = [
        ArtPart(.top, .box, .ellipse(100, 188, 66, 8), fill: 0x000000, opacity: 0.14),
        ArtPart(.top, .box, .rect(40, 90, 120, 92, radius: 12), fill: 0xC8323C, stroke: 0x9E2630, width: 3),
        ArtPart(.top, .box, .rect(92, 90, 16, 92, radius: 0), fill: 0xE9B949),
        ArtPart(.top, .box, .ellipse(66, 152, 9, 9), fill: 0xB12A34),
        ArtPart(.top, .box, .ellipse(56, 138, 4, 4), fill: 0xB12A34),
        ArtPart(.top, .box, .ellipse(64, 132, 4, 4), fill: 0xB12A34),
        ArtPart(.top, .box, .ellipse(73, 134, 4, 4), fill: 0xB12A34),
        ArtPart(.top, .box, .ellipse(78, 142, 3.6, 3.6), fill: 0xB12A34),
        ArtPart(.top, .box, .path([.m(44, 74), .l(52, 42), .q(54, 38, 58, 41), .l(80, 72), .z]), fill: 0xD63B45, stroke: 0x9E2630, width: 3),
        ArtPart(.top, .box, .path([.m(52, 70), .l(56, 50), .l(70, 70), .z]), fill: 0xF2A7B4),
        ArtPart(.top, .box, .path([.m(156, 74), .l(148, 42), .q(146, 38, 142, 41), .l(120, 72), .z]), fill: 0xD63B45, stroke: 0x9E2630, width: 3),
        ArtPart(.top, .box, .path([.m(148, 70), .l(144, 50), .l(130, 70), .z]), fill: 0xF2A7B4),
        ArtPart(.top, .box, .rect(32, 70, 136, 30, radius: 10), fill: 0xD63B45, stroke: 0x9E2630, width: 3),
        ArtPart(.top, .box, .rect(92, 70, 16, 30, radius: 0), fill: 0xE9B949),
        ArtPart(.top, .box, .path([.m(40, 74), .q(52, 66, 64, 73), .q(74, 66, 84, 73)]), stroke: 0xFFFFFF, width: 5, opacity: 0.85),
        ArtPart(.top, .box, .ellipse(86, 60, 15, 9, rotation: -25), fill: 0xF2C94C, stroke: 0xC99A2E, width: 2.5),
        ArtPart(.top, .box, .ellipse(114, 60, 15, 9, rotation: 25), fill: 0xF2C94C, stroke: 0xC99A2E, width: 2.5),
        ArtPart(.top, .box, .ellipse(100, 66, 7, 7), fill: 0xF2C94C, stroke: 0xC99A2E, width: 2.5),
        ArtPart(.top, .box, .path([.m(156, 100), .q(168, 104, 166, 114)]), stroke: 0xC99A2E, width: 2),
        ArtPart(.top, .box, .rect(140, 112, 54, 32, radius: 6), fill: 0xFFF8EC, stroke: 0xE9B949, width: 2),
        ArtPart(.top, .box, .ellipse(166, 117, 2, 2), fill: 0xE9B949),
    ]
}
