import SwiftUI
import Combine

// MARK: - Screen

struct ContentView: View {
    @ObservedObject private var store = CollectionStore.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

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
    private let purr = Purr.shared
    @State private var words: [ComicWord] = []
    @State private var wordTimer: Double = 0
    @State private var chimeTimer: Double = 0

    // Phase 2 screens
    @State private var showPopup = false
    @State private var opening = false
    @State private var showCollection = false
    @State private var showOdds = false
    @AppStorage(ThemeMode.key) private var themeRaw = ThemeMode.system.rawValue

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let ink = Color(red: 0.28, green: 0.20, blue: 0.17)

    private var breed: Breed { store.selectedBreed }

    /// the cat as it looks right now (drawing + hit-testing live in CatArt.swift)
    private var art: CatArt {
        CatArt(breed: breed, intensity: intensity, irritation: irritation, squish: squish, lean: lean,
               touching: touching, zone: zone, phase: phase, tailPhase: tailPhase, clock: clock, words: words,
               onDark: colorScheme == .dark)
    }

    private var label: String {
        if touching, let z = zone { return irritation > 0.5 ? "Enough! 😾" : z.profile.title }
        return intensity > 0.05 ? "" : "Pet the cat with your finger"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.cream.ignoresSafeArea()
                if colorScheme == .dark {
                    // a faint warm glow behind the cat, so dark cats don't disappear into the background
                    RadialGradient(colors: [Color(red: 1, green: 0.84, blue: 0.67).opacity(0.13), .clear],
                                   center: UnitPoint(x: 0.5, y: 0.5), startRadius: 0, endRadius: geo.size.width * 0.55)
                        .frame(width: geo.size.width * 0.92, height: geo.size.height * 0.5)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.52)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                Canvas { ctx, size in art.drawCat(ctx, size) }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let p = value.location
                                let z = art.zoneAt(p, art.makeGeo(geo.size))
                                if let z, z.disliked, zone != z { wordTimer = 0 }
                                if z == .ears, zone != .ears, breed.id == "elf" || breed.id == "midnight" {
                                    purr.play(.jingle)
                                    addWord("Jingle!", angry: false)
                                }
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
                    .accessibilityLabel("\(breed.name) cat. Drag on the cat to pet it.")

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    breedPicker
                }

                if showPopup {
                    BoxPopupView(store: store,
                                 onOpen: { showPopup = false; opening = true },
                                 onLater: { showPopup = false },
                                 onOdds: { showOdds = true })
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showPopup)
        }
        .onReceive(timer) { _ in tick() }
        .onAppear { checkBoxes() }
        .onChange(of: scenePhase) { p in
            if p == .active { checkBoxes() }
        }
        .fullScreenCover(isPresented: $opening) {
            BoxOpeningView(store: store,
                           onPet: { id in store.select(id); opening = false },
                           onCollection: {
                               opening = false
                               DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { showCollection = true }
                           },
                           onClose: { opening = false })
        }
        .fullScreenCover(isPresented: $showCollection) {
            CollectionView(store: store,
                           onPet: { id in store.select(id); showCollection = false },
                           onClose: { showCollection = false })
        }
        .sheet(isPresented: $showOdds) { OddsSheet(store: store) }
    }

    // MARK: - Top bar: collection, hint, gift

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(spacing: 12) {
                Button { showCollection = true } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(Palette.hint)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(Palette.chip))
                }
                .accessibilityLabel("My cats")

                themeButton
            }

            Spacer()
            Text(label)
                .font(.system(.title3, design: .rounded))
                .foregroundColor(Palette.hint)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .animation(.easeInOut(duration: 0.25), value: label)
            Spacer()

            giftButton
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    /// Light / Dark / System, remembered between launches
    private var themeButton: some View {
        Menu {
            Picker("Appearance", selection: $themeRaw) {
                ForEach(ThemeMode.allCases) { m in
                    Label(m.title, systemImage: m.icon).tag(m.rawValue)
                }
            }
        } label: {
            Image(systemName: (ThemeMode(rawValue: themeRaw) ?? .system).icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(Palette.hint)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Palette.chip))
        }
        .accessibilityLabel("Appearance: " + (ThemeMode(rawValue: themeRaw) ?? .system).title)
    }

    private var giftButton: some View {
        Button {
            if store.unopened > 0 { showPopup = true } else { showCollection = true }
        } label: {
            Image(systemName: "gift")
                .font(.system(size: 21, weight: .semibold))
                .foregroundColor(Palette.giftIcon)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Palette.chip))
                .overlay(alignment: .topTrailing) {
                    if store.unopened > 0 {
                        Text("\(store.unopened)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Capsule().fill(Palette.red))
                            .overlay(Capsule().stroke(Palette.cream, lineWidth: 2))
                            .offset(x: 3, y: -3)
                    }
                }
        }
        // Hold for 2 seconds to get a box outside the season (for App Review and testing).
        .simultaneousGesture(LongPressGesture(minimumDuration: 2).onEnded { _ in
            store.grantBox()
            purr.tapHaptic(0.8)
        })
        .accessibilityLabel(store.unopened > 0 ? "Surprise boxes: \(store.unopened) unopened" : "Surprise boxes: none right now")
    }

    // MARK: - Picker: owned cats only

    private var breedPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.ownedBreeds, id: \.id) { b in
                        let selected = b.id == breed.id
                        let isNew = store.isNew(b.id)
                        Button { store.select(b.id) } label: {
                            HStack(spacing: 9) {
                                Circle()
                                    .fill(chipFill(b))
                                    .frame(width: 22, height: 22)
                                    .overlay(Circle().stroke(Palette.chipInk.opacity(0.15), lineWidth: 1))
                                Text(b.name).font(.system(size: 16))
                                if b.isBoxed { SnowflakeMark() }
                            }
                            .padding(.leading, 14)
                            .padding(.trailing, 18)
                            .frame(height: 46)
                            .background(Capsule().fill(selected ? Palette.chipOn : Palette.chip))
                            .overlay(alignment: .topTrailing) {
                                if isNew {
                                    Circle().fill(Palette.red)
                                        .frame(width: 10, height: 10)
                                        .overlay(Circle().stroke(Palette.cream, lineWidth: 2))
                                        .offset(x: -3, y: 1)
                                }
                            }
                            .foregroundColor(Palette.chipInk)
                        }
                        .id(b.id)
                        .accessibilityLabel(b.name + (b.isBoxed ? ", Christmas" : "") + (isNew ? ", new" : ""))
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 20)
            }
            .onAppear { proxy.scrollTo(breed.id, anchor: .center) }
            .onChange(of: breed.id) { id in
                withAnimation { proxy.scrollTo(id, anchor: .center) }
            }
        }
        .padding(.bottom, 12)
    }

    private func chipFill(_ b: Breed) -> AnyShapeStyle {
        switch b.id {
        case "elf":
            return AnyShapeStyle(AngularGradient(gradient: Gradient(stops: [
                .init(color: Color(hex: 0xFBF6EE), location: 0), .init(color: Color(hex: 0xFBF6EE), location: 0.5),
                .init(color: Color(hex: 0xE8964A), location: 0.5), .init(color: Color(hex: 0xE8964A), location: 0.75),
                .init(color: Color(hex: 0x3A3438), location: 0.75), .init(color: Color(hex: 0x3A3438), location: 1)]),
                center: .center))
        case "midnight":
            return AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x1E2547), Color(hex: 0x9B7BFF)], startPoint: .top, endPoint: .bottom))
        default:
            let two = b.pattern == .tabby || b.pattern == .points
            return AnyShapeStyle(LinearGradient(colors: [b.base, two ? b.mark : b.base], startPoint: .top, endPoint: .bottom))
        }
    }

    // MARK: - Boxes

    private func checkBoxes() {
        store.refreshFreeBoxes()
        if store.shouldShowPopupToday() && !opening && !showCollection {
            store.markPopupShown()
            showPopup = true
        }
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
            if intensity > 0.3 { store.markSeen(breed.id) }   // petted once: the "new" dot goes away
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

        // Midnight Star: a soft bell chime layered on the purr
        chimeTimer -= 1.0 / 60.0
        if breed.id == "midnight", level > 0.5, chimeTimer <= 0 {
            purr.play(.chime)
            chimeTimer = 3.2
        }
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
            let special = Catalog.specialWords(breed.id)
            let text = !special.isEmpty && Double.random(in: 0...1) < 0.3
                ? special.randomElement()!
                : ["Purr", "Purrr", "Prrr", "Purr~", "Mrrr", "Purr", "♥", "😻", "😽", "😺"].randomElement()!
            addWord(text, angry: false)
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
