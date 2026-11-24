import SwiftUI
import Combine

// MARK: - Screen

struct ContentView: View {
    @State private var intensity: CGFloat = 0
    @State private var irritation: CGFloat = 0
    @State private var squish: CGFloat = 0
    @State private var lean = CGPoint.zero
    @State private var leanTarget = CGPoint.zero
    @State private var touching = false
    @GestureState private var fingerDown = false
    @State private var zone: Zone?
    @State private var lastPoint: CGPoint?
    @State private var phase: Double = 0
    @State private var tailPhase: Double = 0
    @State private var clock: Double = 0
    @State private var pitch: Float = 100
    @State private var rate: Float = 24
    @State private var rough: Float = 0.2
    @State private var purr = Purr()
    @State private var words: [ComicWord] = []
    @State private var wordTimer: Double = 0
    @AppStorage("breedIndex") private var breedIndex = 0

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let bg = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let ink = Color(red: 0.28, green: 0.20, blue: 0.17)

    private var breed: Breed { Breed.all[min(max(breedIndex, 0), Breed.all.count - 1)] }

    /// the cat as it looks right now (drawing + hit-testing live in CatArt.swift)
    private var art: CatArt {
        CatArt(breed: breed, intensity: intensity, irritation: irritation, squish: squish, lean: lean,
               touching: touching, zone: zone, phase: phase, tailPhase: tailPhase, clock: clock, words: words)
    }

    private var label: String {
        if touching, let z = zone { return irritation > 0.5 ? "Enough! 😾" : z.profile.title }
        return intensity > 0.05 ? "" : "Pet the cat with your finger"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                bg.ignoresSafeArea()
                Canvas { ctx, size in art.drawCat(ctx, size) }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let p = value.location
                                let z = art.zoneAt(p, art.makeGeo(geo.size))
                                if let z, z.disliked, zone != z { wordTimer = 0 }
                                zone = z
                                touching = (z != nil)
                                guard let z else { lastPoint = nil; return }
                                if let last = lastPoint {
                                    let dx = p.x - last.x, dy = p.y - last.y
                                    intensity = min(z.profile.cap, intensity + hypot(dx, dy) / 600 * z.profile.gain)
                                }
                                lastPoint = p
                                let nx = (p.x - geo.size.width / 2) / (geo.size.width / 2)
                                let ny = (p.y - geo.size.height / 2) / (geo.size.height / 2)
                                leanTarget = CGPoint(x: max(-1, min(1, nx)), y: max(-1, min(1, ny)))
                            }
                            .updating($fingerDown) { _, state, _ in state = true }
                            .onEnded { _ in releaseFinger() }
                    )
                    // onEnded is not called when the system cancels the gesture
                    // (e.g. a long hold), so also react to the finger going up.
                    .onChange(of: fingerDown) { down in
                        if !down { releaseFinger() }
                    }

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

    private func releaseFinger() {
        touching = false
        zone = nil
        lastPoint = nil
    }

    private func tick() {
        clock += 1.0 / 60.0
        phase += 0.04 + Double(intensity) * 0.1 + Double(irritation) * 0.1
        // the tail has its own slow, smooth clock so it sways instead of rattling
        tailPhase += 0.03 + Double(intensity) * 0.015 + Double(irritation) * 0.10
        updateWords()
        if touching, let z = zone {
            let p = z.profile
            intensity = intensity > p.cap ? max(p.cap, intensity - 0.01)
                                          : min(p.cap, intensity + 0.004 * p.gain)
            irritation = p.irr > 0 ? min(1, irritation + p.irr) : max(0, irritation - 0.012)
            pitch += (p.pitch - pitch) * 0.04
            rate += (p.rate - rate) * 0.04
            rough += (p.rough - rough) * 0.04
        } else {
            intensity = max(0, intensity - 0.007)
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

    private func updateWords() {
        let dt = 1.0 / 60.0
        for i in words.indices {
            words[i].age += dt
            words[i].x += words[i].vx * CGFloat(dt)
            words[i].y += words[i].vy * CGFloat(dt)
        }
        words.removeAll { $0.age >= $0.life }

        wordTimer -= dt
        guard wordTimer <= 0, words.count < 14 else { return }
        let annoyed = (touching && zone?.disliked == true) || irritation > 0.4
        if touching && annoyed {
            addWord(["Mew?!", "Mew!", "Mrrow!", "Hss!", "Mew?!", "😾", "🙀"].randomElement()!, angry: true)
            wordTimer = 0.75
        } else if intensity > 0.2 && (touching || intensity > 0.5) {
            addWord(["Purr", "Purrr", "Prrr", "Purr~", "Mrrr", "Purr", "♥", "😻", "😽", "😺"].randomElement()!, angry: false)
            wordTimer = max(0.2, 0.6 - 0.4 * Double(intensity))
        }
    }

    private func addWord(_ text: String, angry: Bool) {
        let side: CGFloat = Bool.random() ? 1 : -1
        let w = ComicWord(text: text,
                          x: side * CGFloat.random(in: 0.22...0.50),
                          y: CGFloat.random(in: -0.08...0.12),
                          vx: side * CGFloat.random(in: 0.02...0.06),
                          vy: -CGFloat.random(in: 0.10...0.16),
                          life: angry ? 1.3 : 1.7,
                          angle: Double(side) * Double.random(in: 4...14),
                          size: angry ? 0.085 : CGFloat.random(in: 0.060...0.078),
                          angry: angry)
        words.append(w)
    }
}

#Preview {
    ContentView()
}
