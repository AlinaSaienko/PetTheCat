import AppIntents
import WidgetKit

// MARK: - Which cat does this widget show? (long-press the widget → Edit Widget)

enum CatBreed: String, AppEnum, CaseIterable {
    // keep the same order as Breed.all in CatArt.swift
    case britishBlue, siamese, gingerTabby, black, white, greyTabby
    // Christmas Series (shown as a silhouette until found in a box)
    case gingerbread, reindeer, elf, frost, cocoa, midnightStar

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Cat"
    static let caseDisplayRepresentations: [CatBreed: DisplayRepresentation] = [
        .britishBlue: "British Blue",
        .siamese: "Siamese",
        .gingerTabby: "Ginger Tabby",
        .black: "Black",
        .white: "White",
        .greyTabby: "Grey Tabby",
        .gingerbread: "Gingerbread",
        .reindeer: "Reindeer",
        .elf: "Elf",
        .frost: "Frost",
        .cocoa: "Cocoa",
        .midnightStar: "Midnight Star"
    ]

    /// index into Breed.all
    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

struct SelectCatIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choose your cat"
    static let description = IntentDescription("Pick which cat lives on your Home Screen.")

    @Parameter(title: "Cat", default: .britishBlue)
    var cat: CatBreed
}

// MARK: - Tapping the cat in the widget

/// Remembers when each cat was last petted, so the timeline can show it purring for a few seconds.
enum PurrMemory {
    static let duration: TimeInterval = 6

    private static func key(_ cat: Int) -> String { "purrStart.\(cat)" }

    static func start(_ cat: Int) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: key(cat))
    }

    static func startDate(_ cat: Int) -> Date? {
        let t = UserDefaults.standard.double(forKey: key(cat))
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }
}

struct PetCatIntent: AppIntent {
    static let title: LocalizedStringResource = "Pet the cat"
    static let isDiscoverable = false

    @Parameter(title: "Cat")
    var cat: Int

    init() {}
    init(cat: Int) { self.cat = cat }

    func perform() async throws -> some IntentResult {
        PurrMemory.start(cat)
        return .result()      // WidgetKit reloads the timeline right after this
    }
}
