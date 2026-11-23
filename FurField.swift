import CoreGraphics

/// Сітка "пам'яті шерсті": де пройшов палець, там шерсть відхиляється
/// у напрямку руху й потім плавно повертається назад.
final class FurField {
    private let cols = 36
    private let rows = 54
    private var vx: [CGFloat]
    private var vy: [CGFloat]

    init() {
        vx = Array(repeating: 0, count: 36 * 54)
        vy = Array(repeating: 0, count: 36 * 54)
    }

    func push(at p: CGPoint, velocity v: CGPoint, in size: CGSize, radius: CGFloat) {
        guard size.width > 0, size.height > 0 else { return }
        let cw = size.width / CGFloat(cols)
        let ch = size.height / CGFloat(rows)
        let ci = min(cols - 1, max(0, Int(p.x / cw)))
        let ri = min(rows - 1, max(0, Int(p.y / ch)))
        let rc = Int(radius / min(cw, ch)) + 1
        for r in max(0, ri - rc)...min(rows - 1, ri + rc) {
            for c in max(0, ci - rc)...min(cols - 1, ci + rc) {
                let dx = (CGFloat(c) + 0.5) * cw - p.x
                let dy = (CGFloat(r) + 0.5) * ch - p.y
                let w = exp(-(dx * dx + dy * dy) / (radius * radius))
                let i = r * cols + c
                vx[i] += v.x * w * 0.5
                vy[i] += v.y * w * 0.5
                let m = hypot(vx[i], vy[i])
                if m > 40 {
                    vx[i] *= 40 / m
                    vy[i] *= 40 / m
                }
            }
        }
    }

    func decay() {
        for i in 0..<vx.count {
            vx[i] *= 0.97
            vy[i] *= 0.97
        }
    }

    func sample(_ p: CGPoint, in size: CGSize) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return .zero }
        let c = min(cols - 1, max(0, Int(p.x / (size.width / CGFloat(cols)))))
        let r = min(rows - 1, max(0, Int(p.y / (size.height / CGFloat(rows)))))
        return CGPoint(x: vx[r * cols + c], y: vy[r * cols + c])
    }
}
