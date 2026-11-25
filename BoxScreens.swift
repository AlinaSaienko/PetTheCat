import SwiftUI
import UIKit

// Colours from the Phase 2 design canvas. Each one has a light and a dark value and
// follows the phone's Light/Dark setting automatically (there's no setting in the app).
extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
    }
}

extension Color {
    static func dynamic(_ light: UInt32, _ dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark, alpha: darkAlpha) : UIColor(hex: light, alpha: lightAlpha) })
    }
}

enum Palette {
    static let cream = Color.dynamic(0xFAF5EE, 0x17131B)        // page background
    static let card = Color.dynamic(0xFFFFFF, 0x231D28)         // cards, sheets, pop-ups
    static let tile = Color.dynamic(0xFAF5EE, 0x2D2633)         // tiles inside cards
    static let ink = Color.dynamic(0x2B2430, 0xF4EEF3)          // main text
    static let muted = Color.dynamic(0x6E6475, 0xB6ACBD)        // secondary text
    static let body = Color.dynamic(0x4A4150, 0xD4CBD8)         // small body text
    static let hint = Color.dynamic(0x8C7F77, 0xB6ACBD)         // "Pet the cat …" hint, toolbar icons
    static let link = Color.dynamic(0xB02A34, 0xFF8E93)
    static let red = Color(hex: 0xC8323C)                        // red buttons stay the same
    static let giftIcon = Color.dynamic(0xB5342F, 0xFF8A8F)
    static let chip = Color.dynamic(0xF1EBE5, 0x2D2633)
    static let chipOn = Color.dynamic(0xE2DBD5, 0x40374A)
    static let chipInk = Color.dynamic(0x3E302B, 0xF4EEF3)
    static let gold = Color(hex: 0xFFD166)
    static let night = Color(hex: 0x1E2547)
    static let plum = Color(hex: 0x2A1E33)
    static let secretInk = Color.dynamic(0x5B4BA0, 0xC3B4FF)
    static let secretLabel = Color.dynamic(0x4B3D8F, 0xCFC3FF)
    static let secretBg = Color.dynamic(0xECE7F7, 0x2E2848)
    static let secretBorder = Color.dynamic(0xC9BEEA, 0x5E5290)
    static let slot = Color.dynamic(0xF3EEF2, 0x2D2633)
    static let pine = Color.dynamic(0x2F6B4F, 0x7DCFA4)
    static let track = Color.dynamic(0xF1E9EE, 0x3A3240)       // progress bar background
    static let divider = Color.dynamic(0xF0EAEF, 0x332B39)
    static let missingBg = Color.dynamic(0xF6F2F5, 0x2D2633)
    static let missingBorder = Color.dynamic(0xE2D9E0, 0x4A414F)
    static let outlineButton = Color.dynamic(0xD9D0DC, 0x4A414F)
    static let dim = Color.dynamic(0x201626, 0x000000, lightAlpha: 0.55, darkAlpha: 0.62)
    static let snowScene = Color.dynamic(0xE7EFF6, 0x22304A)
    static let snow = Color.dynamic(0xFFFFFF, 0xC9D6E8)
    static let revealSnow = Color.dynamic(0xECE4EC, 0x2A232F)
}

// MARK: - Small building blocks

/// A still picture of a cat (or its silhouette) for lists and cards.
struct CatThumb: View {
    let breed: Breed
    var silhouette = false
    var side: CGFloat

    var body: some View {
        Canvas { ctx, size in
            CatArt(breed: breed, placement: .thumb, tailPhase: 0.9, clock: 1.0, silhouette: silhouette).drawCat(ctx, size)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

struct BoxArtView: View {
    var side: CGFloat
    var body: some View {
        Canvas { ctx, size in
            ArtRender.drawBox(in: ctx, origin: .zero, side: min(size.width, size.height))
        }
        .frame(width: side, height: side)
        .accessibilityLabel("Christmas Series surprise box")
    }
}

struct SnowflakeMark: View {
    var size: CGFloat = 13
    var body: some View {
        Image(systemName: "snowflake")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(Palette.pine)
            .accessibilityHidden(true)
    }
}

/// 6 slots: found cats in colour, missing ones as silhouettes, the secret one as "?".
struct SeriesCardView: View {
    @ObservedObject var store: CollectionStore

    var body: some View {
        HStack(spacing: 0) {
            ForEach(store.series.designs, id: \.self) { id in
                let has = store.isOwned(id)
                let hidden = id == store.series.secret && !has
                VStack(spacing: 4) {
                    ZStack {
                        Circle().fill(hidden ? Palette.secretBg : Palette.slot)
                        if hidden {
                            Text("?").font(.system(size: 26, weight: .heavy)).foregroundColor(Palette.secretInk)
                        } else if let b = Catalog.breed(id) {
                            CatThumb(breed: b, silhouette: !has, side: 46)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    Text(hidden ? "Secret 1/72" : Catalog.shortName(id))
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(has ? Palette.ink : Palette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(hidden ? "Secret cat, 1 in 72, not found yet"
                                    : Catalog.shortName(id) + (has ? ", found" : ", not found yet"))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Christmas Series: 6 cats")
    }
}

/// Slow side-to-side wobble (stops with Reduce Motion).
struct Wobble: ViewModifier {
    var degrees: Double
    var period: Double
    var shift: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion || degrees == 0 {
            content
        } else {
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                let s = sin(t / period * 2 * .pi)
                content
                    .rotationEffect(.degrees(degrees * s), anchor: UnitPoint(x: 0.5, y: 0.92))
                    .offset(x: shift * CGFloat(s))
            }
        }
    }
}

// MARK: - 2 · Box arrived pop-up

struct BoxPopupView: View {
    @ObservedObject var store: CollectionStore
    var title: String? = nil
    var subtitle = "1 of 6 Christmas cats inside"
    var onOpen: () -> Void
    var onLater: () -> Void
    var onOdds: () -> Void

    var body: some View {
        ZStack {
            Palette.dim
                .ignoresSafeArea()
                .onTapGesture(perform: onLater)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 20).fill(Palette.snowScene)
                    Canvas { ctx, size in
                        let k = size.width / 330
                        for (x, y, r) in [(30.0, 30.0, 4.0), (80, 70, 3), (290, 40, 5), (250, 96, 3), (150, 22, 2.5), (40, 120, 2.5), (306, 140, 3)] {
                            ctx.fill(Path(ellipseIn: CGRect(x: (x - r) * k, y: (y - r) * k, width: 2 * r * k, height: 2 * r * k)), with: .color(Palette.snow))
                        }
                        var hill = Path()
                        hill.move(to: CGPoint(x: 0, y: size.height - 32))
                        hill.addQuadCurve(to: CGPoint(x: size.width / 2, y: size.height - 38), control: CGPoint(x: size.width * 0.24, y: size.height - 52))
                        hill.addQuadCurve(to: CGPoint(x: size.width, y: size.height - 44), control: CGPoint(x: size.width * 0.76, y: size.height - 24))
                        hill.addLine(to: CGPoint(x: size.width, y: size.height))
                        hill.addLine(to: CGPoint(x: 0, y: size.height))
                        hill.closeSubpath()
                        ctx.fill(hill, with: .color(Palette.snow))
                    }
                    BoxArtView(side: 180)
                        .modifier(Wobble(degrees: 4, period: 1.6))
                        .padding(.bottom, 10)
                }
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Text(title ?? (store.unopened > 1 ? "\(store.unopened) Christmas boxes arrived" : "A Christmas box arrived"))
                    .font(.system(size: 27, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Palette.ink)
                    .padding(.top, 4)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.system(size: 15))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Palette.muted)
                    .padding(.top, -6)

                SeriesCardView(store: store)
                    .padding(.vertical, 4)

                Button(action: onOpen) {
                    Text("Open now")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(Capsule().fill(Palette.red))
                }
                HStack {
                    Button(action: onLater) {
                        Text("Later").font(.system(size: 16, weight: .heavy)).foregroundColor(Palette.body)
                            .frame(minHeight: 44).padding(.horizontal, 10)
                    }
                    Spacer()
                    Button(action: onOdds) {
                        Text("Odds").font(.system(size: 14, weight: .bold)).foregroundColor(Palette.link)
                            .frame(minHeight: 44).padding(.horizontal, 10)
                    }
                }
                .padding(.horizontal, 6)
            }
            .padding(EdgeInsets(top: 14, leading: 14, bottom: 16, trailing: 14))
            .background(RoundedRectangle(cornerRadius: 28).fill(Palette.card).shadow(color: Color.black.opacity(0.35), radius: 25, y: 20))
            .padding(.horizontal, 16)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }
}

// MARK: - 3 · Opening the box, then the reveal

struct BoxOpeningView: View {
    @ObservedObject var store: CollectionStore
    var onPet: (String) -> Void
    var onCollection: () -> Void
    var onClose: () -> Void

    @State private var taps = 0
    @State private var result: CollectionStore.Opened?
    @State private var pop: CGFloat = 0.4
    @State private var showBonus = false
    @State private var showOdds = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let purr = Purr.shared

    private var secret: Bool { result.map { store.series.rarity($0.id) == .secret } ?? false }
    private var name: String { result.flatMap { Catalog.breed($0.id)?.name } ?? "" }

    private var background: Color { result == nil ? Palette.plum : secret ? Palette.night : Palette.cream }
    private var snow: Color { result == nil ? Color(hex: 0x4A3B57) : secret ? Color(hex: 0x38427A) : Palette.revealSnow }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            Canvas { ctx, size in
                let k = size.width / 390
                for (x, y, r) in [(40.0, 110.0, 3.0), (340, 160, 4), (90, 260, 2.5), (300, 300, 2.5), (30, 520, 3.5), (360, 580, 3), (200, 80, 2), (120, 700, 2.5), (280, 740, 3)] {
                    ctx.fill(Path(ellipseIn: CGRect(x: (x - r) * k, y: (y - r) * k, width: 2 * r * k, height: 2 * r * k)), with: .color(snow))
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)

            if let result {
                reveal(result)
                    .transition(.opacity)
            } else {
                tapStage
            }
        }
        .overlay {
            if showBonus {
                BoxPopupView(store: store,
                             title: "Bonus box!",
                             subtitle: "That's your 3rd \(name) — here's a free box",
                             onOpen: {
                                 showBonus = false
                                 taps = 0
                                 pop = 0.4
                                 result = nil
                             },
                             onLater: { showBonus = false },
                             onOdds: { showOdds = true })
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: reduceMotion ? 0.4 : 0.25), value: result == nil)
        .animation(.easeInOut(duration: 0.25), value: showBonus)
        .sheet(isPresented: $showOdds) { OddsSheet(store: store) }
    }

    // MARK: Tap 3×

    private var tapStage: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: 0xBFB3CC))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close, open the box later")
            }
            .padding(.horizontal, 12)

            Text(taps == 0 ? "Tap the box" : taps == 1 ? "Again!" : "One more!")
                .font(.system(size: 34, weight: .heavy))
                .foregroundColor(.white)
                .padding(.top, 60)
            Text(3 - taps == 1 ? "1 more tap to open" : "\(3 - taps) taps to open")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0xD8CDE2))
                .padding(.top, 8)

            ZStack {
                if taps > 0 {
                    Canvas { ctx, _ in
                        var p = Path()
                        for (a, b, c) in [(22.0, 10.0, 22.0), (8, 0, 8)] {
                            p.move(to: CGPoint(x: a, y: 30 + (a == 8 ? 10 : 0)))
                            p.addQuadCurve(to: CGPoint(x: c, y: 90 - (a == 8 ? 10 : 0)), control: CGPoint(x: b, y: 60))
                            p.move(to: CGPoint(x: 320 - a, y: 30 + (a == 8 ? 10 : 0)))
                            p.addQuadCurve(to: CGPoint(x: 320 - c, y: 90 - (a == 8 ? 10 : 0)), control: CGPoint(x: 320 - b, y: 60))
                        }
                        ctx.stroke(p, with: .color(Palette.gold), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    }
                    .frame(width: 320, height: 120)
                    .offset(y: 30)
                    .accessibilityHidden(true)
                }
                Button(action: tap) {
                    BoxArtView(side: 240)
                        .modifier(shake)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tap the box, \(3 - taps) taps left")
            }
            .padding(.top, 70)

            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < taps ? Palette.gold : Color.clear)
                        .overlay(Circle().stroke(Palette.gold, lineWidth: 2))
                        .frame(width: 14, height: 14)
                }
            }
            .padding(.top, 40)
            .accessibilityHidden(true)

            Spacer()
            Text("Odds: each basic cat \(store.series.percent(store.series.basics[0])) · secret 1 in 72 · no repeats in a row")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0xBFB3CC))
                .padding(.bottom, 24)
        }
    }

    private func ordinal(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        return f.string(from: NSNumber(value: n)) ?? "\(n)th"
    }

    private var shake: Wobble {
        switch taps {
        case 0: return Wobble(degrees: 4, period: 1.4)
        case 1: return Wobble(degrees: 6, period: 0.7, shift: 6)
        default: return Wobble(degrees: 6, period: 0.32, shift: 4)
        }
    }

    private func tap() {
        guard result == nil else { return }
        taps += 1
        purr.play(.tap)
        purr.tapHaptic(0.45 + 0.2 * Float(taps))
        guard taps >= 3 else { return }
        guard let opened = store.openBox() else { onClose(); return }
        let isSecret = store.series.rarity(opened.id) == .secret
        purr.play(isSecret ? .secretChime : .chime)
        purr.revealHaptic(secret: isSecret)
        pop = reduceMotion ? 1 : 0.4
        result = opened
        if !reduceMotion {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.1)) { pop = 1 }
        }
        let n = Catalog.breed(opened.id)?.name ?? ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            UIAccessibility.post(notification: .announcement,
                                 argument: isSecret ? "Secret cat! You found \(n)" : "You got \(n)")
        }
        if opened.bonusEarned {
            // let the reveal land first, then offer the bonus box
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                guard result?.id == opened.id else { return }
                purr.play(.jingle)
                showBonus = true
            }
        }
    }

    // MARK: Reveal

    private func reveal(_ r: CollectionStore.Opened) -> some View {
        let ink: Color = secret ? .white : Palette.ink
        let muted: Color = secret ? Color(hex: 0xC9C3EE) : Palette.muted
        return ZStack {
            // the rays are bigger than the screen, so they hang in an overlay that doesn't affect layout
            Color.clear
                .overlay(
                    Rays(color: secret ? Color(hex: 0x9B7BFF) : Color(hex: 0xE9B949), opacity: secret ? 0.22 : 0.2)
                        .frame(width: 800, height: 800)
                        .offset(y: -70)
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            if secret {
                Canvas { ctx, size in
                    let k = size.width / 390
                    for (x, y, s, c) in [(60.0, 180.0, 1.8, 0xFFD166), (330, 220, 1.4, 0x5FE0C8), (40, 420, 1.2, 0x9B7BFF),
                                         (348, 440, 1.9, 0xFFD166), (300, 120, 1.0, 0xFFD166), (96, 520, 1.0, 0x5FE0C8)] as [(CGFloat, CGFloat, CGFloat, UInt32)] {
                        ctx.fill(ArtRender.sparkle(CGPoint(x: x * k, y: y * k), 6 * s * k), with: .color(Color(hex: c)))
                    }
                }
                .accessibilityHidden(true)
            }
            VStack(spacing: 0) {
                Text(r.isDuplicate ? "Duplicate ×\(r.count)" : secret ? "Secret cat!" : "New cat!")
                    .font(.system(size: 18, weight: .heavy))
                    .kerning(0.4)
                    .padding(.horizontal, 18).padding(.vertical, 8)
                    .background(Capsule().fill(secret ? Palette.gold : Palette.red))
                    .foregroundColor(secret ? Palette.night : .white)
                    .padding(.top, 44)
                if let b = Catalog.breed(r.id) {
                    CatThumb(breed: b, side: UIScreen.main.bounds.height < 700 ? 260 : 350)   // smaller on iPhone SE
                        .scaleEffect(pop)
                        .opacity(Double(min(1, pop * 1.6)))
                        .padding(.top, 16)
                }
                Text(name)
                    .font(.system(size: 54, weight: .heavy))
                    .foregroundColor(ink)
                    .padding(.top, 14)
                    .accessibilityAddTraits(.isHeader)
                Text(secret ? "Secret · 1 in 72 · Christmas Series" : "Basic · Christmas Series")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(muted)
                    .padding(.top, 6)
                Text(r.bonusEarned ? "Your \(ordinal(r.count)) \(name) — bonus box earned! 🎁"
                     : r.isDuplicate ? "You have ×\(r.count) · get \(3 - r.duplicateProgress) more for a bonus box"
                     : "Added to My cats")
                    .font(.system(size: 17))
                    .foregroundColor(muted)
                    .padding(.top, 6)
                Spacer()
                VStack(spacing: 10) {
                    Button { onPet(r.id) } label: {
                        Text("Pet \(name)")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(secret ? Palette.night : .white)
                            .frame(maxWidth: .infinity, minHeight: 54)
                            .background(Capsule().fill(secret ? Palette.gold : Palette.red))
                    }
                    Button(action: onCollection) {
                        Text("See collection")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(ink)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .overlay(Capsule().stroke(secret ? Color(hex: 0x5A64A8) : Palette.outlineButton, lineWidth: 2))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

/// Slowly turning light rays behind a revealed cat.
struct Rays: View {
    var color: Color
    var opacity: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            let turn = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 24) / 24 * 360
            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let R = max(size.width, size.height) * 0.54
                var p = Path()
                for i in 0..<12 {
                    let a1 = (Double(i) * 30 + turn) * .pi / 180
                    let a2 = (Double(i) * 30 + 14 + turn) * .pi / 180
                    p.move(to: c)
                    p.addLine(to: CGPoint(x: c.x + R * CGFloat(cos(a1)), y: c.y + R * CGFloat(sin(a1))))
                    p.addLine(to: CGPoint(x: c.x + R * CGFloat(cos(a2)), y: c.y + R * CGFloat(sin(a2))))
                    p.closeSubpath()
                }
                ctx.fill(p, with: .color(color.opacity(opacity)))
            }
        }
    }
}

// MARK: - 5 · Odds sheet

struct OddsSheet: View {
    @ObservedObject var store: CollectionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let s = store.series
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(s.name) odds")
                    .font(.system(size: 26, weight: .heavy))
                    .accessibilityAddTraits(.isHeader)
                Text("Each box holds 1 of these 6 cats.")
                    .font(.system(size: 14)).foregroundColor(Palette.muted)
            }
            .padding(.top, 20)

            VStack(spacing: 0) {
                ForEach(s.designs, id: \.self) { id in
                    let isSecret = id == s.secret
                    let found = store.isOwned(id)
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(isSecret ? Palette.secretBg : Palette.slot)
                            if isSecret && !found {
                                Text("?").font(.system(size: 24, weight: .heavy)).foregroundColor(Palette.secretInk)
                            } else if let b = Catalog.breed(id) {
                                CatThumb(breed: b, side: 42)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 1) {
                            Text(isSecret && !found ? "Secret cat" : Catalog.breed(id)?.name ?? id)
                                .font(.system(size: 15, weight: .heavy))
                            Text(isSecret ? "Revealed when found · 1 in 72" : "Basic · \(s.weight(id)) in \(s.totalWeight)")
                                .font(.system(size: 12)).foregroundColor(Palette.muted)
                        }
                        Spacer()
                        Text(s.percent(id))
                            .font(.system(size: 16, weight: .heavy).monospacedDigit())
                    }
                    .padding(.vertical, 7)
                    .overlay(alignment: .bottom) { Rectangle().fill(Palette.divider).frame(height: 1) }
                    .accessibilityElement(children: .combine)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Free boxes").font(.system(size: 15, weight: .heavy))
                ForEach(["1 welcome box with the update", "1 box a day, Dec 1 – Jan 6",
                         "Unopened boxes stack up to 3", "Get the same cat 3 times = 1 bonus box",
                         "Never the same cat twice in a row: right after a basic cat, the other 4 are \(s.afterRepeatPercent) each and the secret cat stays 1.39%"],
                        id: \.self) { rule in
                    HStack(spacing: 10) {
                        Circle().fill(Palette.red).frame(width: 8, height: 8).accessibilityHidden(true)
                        Text(rule).font(.system(size: 14)).foregroundColor(Palette.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(Palette.tile))

            Spacer(minLength: 0)
            Button { dismiss() } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Palette.cream)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Capsule().fill(Palette.ink))
            }
        }
        .foregroundColor(Palette.ink)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .background(Palette.card.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
