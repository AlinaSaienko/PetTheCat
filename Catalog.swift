import SwiftUI

// MARK: - Series and odds (shared by the app and the widget)

enum Rarity { case basic, secret }

struct Series {
    let id: String
    let name: String
    /// cat ids in slot order (the secret one last)
    let designs: [String]
    let secret: String?
    let isFree: Bool
    /// free boxes drop once per local calendar day from `dropStart` to `dropEnd` (inclusive)
    let dropStart: DateComponents?
    let dropEnd: DateComponents?

    /// Weights out of 360: every basic cat 71, the secret cat 5 (= 1 in 72).
    func weight(_ id: String) -> Int { id == secret ? 5 : 71 }
    var totalWeight: Int { designs.reduce(0) { $0 + weight($1) } }
    var basics: [String] { designs.filter { $0 != secret } }

    func rarity(_ id: String) -> Rarity { id == secret ? .secret : .basic }

    /// "19.72%" / "1.39%"
    func percent(_ id: String) -> String {
        String(format: "%.2f%%", Double(weight(id)) / Double(totalWeight) * 100)
    }

    /// Weights for the next box, out of 1440 (= 4 × 360), when `last` was the previous cat:
    /// that cat can't come twice in a row; the secret cat keeps exactly 1 in 72 (20/1440)
    /// unless it was the previous cat itself, and the basic cats share the rest equally.
    func nextWeights(after last: String?) -> [(id: String, weight: Int)] {
        let scale = 4
        guard let last, designs.contains(last) else {
            return designs.map { ($0, weight($0) * scale) }
        }
        let total = totalWeight * scale
        if last == secret {
            let each = total / basics.count                          // 288 each
            return designs.map { ($0, $0 == secret ? 0 : each) }
        }
        let secretWeight = secret.map { weight($0) * scale } ?? 0   // 20
        let each = (total - secretWeight) / (basics.count - 1)       // 355 each
        return designs.map { ($0, $0 == last ? 0 : $0 == secret ? secretWeight : each) }
    }

    /// share of the other basic cats right after you got a basic cat ("24.65%")
    var afterRepeatPercent: String {
        let w = nextWeights(after: basics.first)
        let total = w.reduce(0) { $0 + $1.weight }
        return String(format: "%.2f%%", Double(w[1].weight) / Double(total) * 100)
    }
}

enum Catalog {
    static let classic = Series(id: "classic", name: "Classic", designs: Breed.classic.map(\.id),
                                secret: nil, isFree: true, dropStart: nil, dropEnd: nil)

    static let christmas = Series(id: "christmas", name: "Christmas Series",
                                  designs: ["gingerbread", "reindeer", "elf", "frost", "cocoa", "midnight"],
                                  secret: "midnight", isFree: true,
                                  dropStart: DateComponents(year: 2026, month: 12, day: 1),
                                  dropEnd: DateComponents(year: 2027, month: 1, day: 6))

    /// the series that free boxes come from right now
    static let boxSeries = christmas

    static func breed(_ id: String) -> Breed? { Breed.all.first { $0.id == id } }

    static func isClassic(_ id: String) -> Bool { classic.designs.contains(id) }

    /// Extra comic words a cat says while it is happy (on top of "Purr", "♥" …).
    static func specialWords(_ id: String) -> [String] {
        switch id {
        case "gingerbread": return ["Crunch!", "Purr"]
        case "reindeer": return ["Glow~"]
        case "elf": return ["Jingle!"]
        case "frost": return ["Brrr", "❄︎"]
        case "cocoa": return ["Mallow!"]
        case "midnight": return ["Twinkle purr!", "✦"]
        default: return []
        }
    }

    /// short name for the series card ("Midnight Star" → "Midnight")
    static func shortName(_ id: String) -> String {
        id == "midnight" ? "Midnight" : (breed(id)?.name ?? id)
    }
}

// MARK: - What the player owns (a small JSON file the widget can read too)

struct CollectionData: Codable, Equatable {
    /// how many of each boxed cat the player has (classic cats are always owned)
    var owned: [String: Int] = [:]
    var unopened = 0
    var welcomeGiven = false
    /// the last calendar day ("yyyy-MM-dd") whose free box has been handed out
    var lastDropDay: String?
    /// duplicates collected towards the next bonus box (0…2)
    var duplicateProgress = 0
    var selected = "blue"
    /// cats that have been petted at least once (others show a "new" dot)
    var seen: [String] = []
    var lastPopupDay: String?
    var opened = 0
    /// the cat from the last box (never the same one twice in a row)
    var lastOpened: String?

    func count(_ id: String) -> Int { Catalog.isClassic(id) ? 1 : (owned[id] ?? 0) }
    func isOwned(_ id: String) -> Bool { count(id) > 0 }
}

enum SharedCollection {
    static let appGroup = "group.com.alinasaienko.PetTheCat"

    /// nil when the App Group isn't available (then the widget shows every cat)
    static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("collection.json")
    }

    static func load() -> CollectionData? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CollectionData.self, from: data)
    }
}
