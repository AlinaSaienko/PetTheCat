import SwiftUI

// MARK: - 4 · Collection ("My cats")

struct CollectionView: View {
    @ObservedObject var store: CollectionStore
    var onPet: (String) -> Void
    var onClose: () -> Void

    @State private var showOdds = false
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    private var ownedCount: Int { store.ownedBreeds.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                classicSection
                christmasSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(Palette.cream.ignoresSafeArea())
        .foregroundColor(Palette.ink)
        .sheet(isPresented: $showOdds) { OddsSheet(store: store) }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Palette.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white).shadow(color: Palette.ink.opacity(0.08), radius: 5, y: 3))
            }
            .accessibilityLabel("Back to petting")
            VStack(alignment: .leading, spacing: 0) {
                Text("My cats")
                    .font(.system(size: 30, weight: .heavy))
                    .accessibilityAddTraits(.isHeader)
                Text("\(ownedCount) cats in 2 series")
                    .font(.system(size: 14))
                    .foregroundColor(Palette.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
    }

    private var classicSection: some View {
        card {
            HStack(alignment: .firstTextBaseline) {
                Text("Classic").font(.system(size: 18, weight: .heavy)).accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(Breed.classic.count) of \(Breed.classic.count)")
                    .font(.system(size: 14, weight: .bold)).foregroundColor(Palette.muted)
            }
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Breed.classic, id: \.id) { b in ownedTile(b, count: 1) }
            }
        }
    }

    private var christmasSection: some View {
        let s = store.series
        let found = store.foundInSeries
        return card {
            HStack {
                HStack(spacing: 6) {
                    SnowflakeMark(size: 15)
                    Text(s.name).font(.system(size: 18, weight: .heavy))
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Odds") { showOdds = true }
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Palette.link)
                    .frame(minHeight: 44)
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(found) of \(s.designs.count) found").font(.system(size: 14, weight: .heavy))
                    Spacer()
                    Text("Free boxes until Jan 6").font(.system(size: 14, weight: .bold)).foregroundColor(Palette.muted)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0xF1E9EE))
                        Capsule().fill(Palette.red)
                            .frame(width: geo.size.width * CGFloat(found) / CGFloat(max(1, s.designs.count)))
                    }
                }
                .frame(height: 10)
                .accessibilityElement()
                .accessibilityLabel("Christmas Series progress")
                .accessibilityValue("\(found) of \(s.designs.count)")
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i < store.data.duplicateProgress ? Color(hex: 0xE9B949) : Color(hex: 0xF1E9EE))
                                .overlay(RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color(hex: 0xD9C9A0), style: StrokeStyle(lineWidth: i < store.data.duplicateProgress ? 0 : 2, dash: [3, 2])))
                                .frame(width: 14, height: 14)
                        }
                    }
                    .accessibilityHidden(true)
                    (Text("Bonus box: ").bold() + Text("\(store.data.duplicateProgress) of 3 duplicates"))
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x4A4150))
                }
            }
            .padding(.top, -6)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(s.designs, id: \.self) { id in
                    if let b = Catalog.breed(id) {
                        let n = store.count(id)
                        if n > 0 {
                            ownedTile(b, count: n)
                        } else if id == s.secret {
                            secretTile
                        } else {
                            missingTile(b)
                        }
                    }
                }
            }
        }
    }

    private func ownedTile(_ b: Breed, count: Int) -> some View {
        Button { onPet(b.id) } label: {
            VStack(spacing: 4) {
                CatThumb(breed: b, side: 78)
                Text(b.name)
                    .font(.system(size: 13, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(EdgeInsets(top: 8, leading: 4, bottom: 10, trailing: 4))
            .background(RoundedRectangle(cornerRadius: 18).fill(Palette.cream))
            .overlay(alignment: .topTrailing) {
                if count > 1 {
                    Text("×\(count)")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7).padding(.vertical, 2)
                        .background(Capsule().fill(Palette.ink))
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .foregroundColor(Palette.ink)
        .accessibilityLabel("Pet \(b.name)" + (count > 1 ? ", you have \(count)" : ""))
    }

    private func missingTile(_ b: Breed) -> some View {
        VStack(spacing: 4) {
            CatThumb(breed: b, silhouette: true, side: 74)
            Text(b.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 8, leading: 4, bottom: 10, trailing: 4))
        .background(RoundedRectangle(cornerRadius: 18).fill(Color(hex: 0xF6F2F5)))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color(hex: 0xE2D9E0), style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(b.name), not found yet")
    }

    private var secretTile: some View {
        VStack(spacing: 4) {
            Text("?")
                .font(.system(size: 46, weight: .heavy))
                .foregroundColor(Palette.secretInk)
                .frame(height: 74)
            Text("Secret · 1/72")
                .font(.system(size: 13, weight: .heavy))
                .foregroundColor(Color(hex: 0x4B3D8F))
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 8, leading: 4, bottom: 10, trailing: 4))
        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.secretBg))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color(hex: 0xC9BEEA), style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Secret cat, 1 in 72, not found yet")
    }
}
