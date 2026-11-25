import SwiftUI
import UIKit
import WidgetKit
import AppIntents

// MARK: - Poses (the widget can't animate, so it shows a few still frames)

extension CatArt {
    /// frame == nil → sitting calmly; frame 0...2 → purring, with slightly different details each time
    static func widgetPose(cat: Int, frame: Int?) -> CatArt {
        let breed = Breed.all[min(max(cat, 0), Breed.all.count - 1)]
        var art = CatArt(breed: breed, placement: .widget)
        if isLocked(breed) {          // a Christmas cat the player hasn't found yet
            art.silhouette = true
            return art
        }
        art.clock = 1.0            // eyes open, mid-breath
        art.tailPhase = 0.9
        guard let frame else { return art }

        art.intensity = 0.85       // eyes closed happily, zig-zag "happy vibes" around him
        art.squish = 0.7
        switch frame {
        case 0:
            art.clock = 1.0; art.phase = 0.5; art.tailPhase = 0.3
            art.words = [word("Purr", x: 0.42, y: -0.04, angle: 10)]
        case 1:
            art.clock = 1.4; art.phase = 1.5; art.tailPhase = 1.1
            art.words = [word("♥", x: -0.42, y: -0.10, angle: -12)]
        default:
            art.clock = 1.8; art.phase = 2.6; art.tailPhase = 1.9
            art.words = [word("Purrr", x: 0.40, y: -0.12, angle: 8),
                         word("♥", x: -0.44, y: 0.02, angle: -10)]
        }
        return art
    }

    /// true when the app's collection says this boxed cat isn't owned yet
    static func isLocked(_ breed: Breed) -> Bool {
        guard breed.isBoxed, let data = SharedCollection.load() else { return false }
        return !data.isOwned(breed.id)
    }

    private static func word(_ text: String, x: CGFloat, y: CGFloat, angle: Double) -> ComicWord {
        // age/life chosen so the word is fully faded in
        ComicWord(text: text, x: x, y: y, vx: 0, vy: 0, age: 0.6, life: 2.0, angle: angle, size: 0.12, angry: false)
    }
}

// MARK: - Turning a pose into a picture

/// Widgets are rendered in a separate process from archived views, so instead of a live Canvas
/// we hand them a finished bitmap of the cat.
@MainActor
enum CatRender {
    static func image(cat: Int, frame: Int?, side: CGFloat) -> UIImage? {
        let art = CatArt.widgetPose(cat: cat, frame: frame)
        let view = Canvas { ctx, size in art.drawCat(ctx, size) }
            .frame(width: side, height: side)
        let renderer = ImageRenderer(content: view)
        renderer.scale = min(3, 800 / side)       // stay well under WidgetKit's image size limit
        return renderer.uiImage
    }
}

// MARK: - Timeline

struct CatEntry: TimelineEntry {
    let date: Date
    let cat: Int
    let purring: Bool
    let image: UIImage?
}

struct CatProvider: AppIntentTimelineProvider {
    typealias Intent = SelectCatIntent
    typealias Entry = CatEntry

    private func side(_ context: Context) -> CGFloat {
        let s = min(context.displaySize.width, context.displaySize.height)
        return s > 0 ? s : 160
    }

    func placeholder(in context: Context) -> CatEntry {
        CatEntry(date: .now, cat: 0, purring: false, image: nil)
    }

    func snapshot(for configuration: SelectCatIntent, in context: Context) async -> CatEntry {
        let cat = configuration.cat.index
        let image = await CatRender.image(cat: cat, frame: nil, side: side(context))
        return CatEntry(date: .now, cat: cat, purring: false, image: image)
    }

    func timeline(for configuration: SelectCatIntent, in context: Context) async -> Timeline<CatEntry> {
        let cat = configuration.cat.index
        let side = side(context)
        let now = Date()
        let idle = await CatRender.image(cat: cat, frame: nil, side: side)

        // Not petted recently → just sit there.
        guard let started = PurrMemory.startDate(cat),
              now.timeIntervalSince(started) < PurrMemory.duration else {
            return Timeline(entries: [CatEntry(date: now, cat: cat, purring: false, image: idle)], policy: .never)
        }

        // Petted a moment ago → purr through a few frames, then calm down again.
        let remaining = started.addingTimeInterval(PurrMemory.duration).timeIntervalSince(now)
        var frames: [UIImage?] = []
        for f in 0..<3 { frames.append(await CatRender.image(cat: cat, frame: f, side: side)) }

        var entries: [CatEntry] = []
        var t = 0.0, k = 0
        while t < remaining {
            entries.append(CatEntry(date: now.addingTimeInterval(t), cat: cat, purring: true, image: frames[k % 3]))
            t += 1.2
            k += 1
        }
        entries.append(CatEntry(date: now.addingTimeInterval(remaining), cat: cat, purring: false, image: idle))
        return Timeline(entries: entries, policy: .never)
    }
}

// MARK: - View

struct CatWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CatEntry

    private let ink = Color(red: 0.28, green: 0.20, blue: 0.17)

    private var breed: Breed { Breed.all[min(max(entry.cat, 0), Breed.all.count - 1)] }
    private var breedName: String { CatArt.isLocked(breed) ? "Not found yet" : breed.name }

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 12) {
                catButton
                VStack(alignment: .leading, spacing: 4) {
                    Text(breedName)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(ink)
                    Text(CatArt.isLocked(breed) ? "Find it in a Christmas box" : entry.purring ? "Purrrr… ♥" : "Tap to pet")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(ink.opacity(0.6))
                }
                Spacer(minLength: 0)
            }
        default:
            catButton
        }
    }

    /// Tapping the cat runs PetCatIntent in place (the app does not open).
    private var catButton: some View {
        Button(intent: PetCatIntent(cat: entry.cat)) {
            if let image = entry.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("🐱").font(.system(size: 56))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Widget

struct PetTheCatWidget: Widget {
    let kind = "PetTheCatWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCatIntent.self, provider: CatProvider()) { entry in
            CatWidgetView(entry: entry)
                .containerBackground(Color(red: 0.98, green: 0.96, blue: 0.93), for: .widget)
        }
        .configurationDisplayName("Your cat")
        .description("Pick a cat for your Home Screen, then tap it to make it purr.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct PetTheCatWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetTheCatWidget()
    }
}
