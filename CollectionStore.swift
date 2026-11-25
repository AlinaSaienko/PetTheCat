import SwiftUI
import WidgetKit

// MARK: - Weighted roll

/// SplitMix64, so tests and QA can replay exact rolls with a fixed seed.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum BoxRoller {
    /// Each basic cat 71/360 (19.72%), the secret cat 5/360 (1 in 72).
    /// With `after`, that cat is left out and its share goes to the other basic cats.
    static func roll<G: RandomNumberGenerator>(_ series: Series, after last: String? = nil, using rng: inout G) -> String {
        let weights = series.nextWeights(after: last)
        let total = weights.reduce(0) { $0 + $1.weight }
        var x = Int.random(in: 0..<total, using: &rng)
        for (id, w) in weights {
            x -= w
            if x < 0 { return id }
        }
        return weights.last { $0.weight > 0 }?.id ?? series.designs[0]
    }

    /// Uses the system's secure random generator (seeded by iOS; tap timing has no influence).
    static func roll(_ series: Series, after last: String? = nil) -> String {
        var rng = SystemRandomNumberGenerator()
        return roll(series, after: last, using: &rng)
    }
}

// MARK: - Free boxes

struct FreeBoxSchedule {
    /// unopened daily boxes stack up to this many (bonus boxes may go above it)
    static let stackLimit = 3

    var calendar: Calendar = .current
    let start: DateComponents
    let end: DateComponents

    func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private func day(_ key: String) -> Date? {
        let p = key.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))
    }

    private func day(_ c: DateComponents) -> Date? {
        calendar.date(from: DateComponents(year: c.year, month: c.month, day: c.day))
    }

    /// Is the drop window still open (or not started yet) on `now`?
    func seasonNotOver(_ now: Date) -> Bool {
        guard let last = day(end) else { return false }
        return calendar.startOfDay(for: now) <= last
    }

    /// Daily boxes earned after `lastDay` up to and including today, inside the window.
    /// Once the window has closed nothing more drops (no catch-up after Jan 6).
    /// Moving the clock back never takes boxes away and never grants any.
    func newDrops(lastDay: String?, now: Date) -> (count: Int, lastDay: String?) {
        guard let first = day(start), let last = day(end) else { return (0, lastDay) }
        let today = calendar.startOfDay(for: now)
        guard today <= last else { return (0, lastDay) }   // season over: nothing more drops
        let upTo = today
        var from = first
        if let lastDay, let prev = day(lastDay), let next = calendar.date(byAdding: .day, value: 1, to: prev) {
            from = max(from, next)
        }
        guard from <= upTo else { return (0, lastDay) }
        let n = (calendar.dateComponents([.day], from: from, to: upTo).day ?? 0) + 1
        return (n, dayKey(upTo))
    }
}

// MARK: - Box rules on the saved data (pure, so they can be unit-tested)

struct OpenedBox: Equatable {
    let id: String
    let isDuplicate: Bool
    let count: Int
    let bonusEarned: Bool
    let duplicateProgress: Int
}

extension CollectionData {
    /// First launch of 1.1: keep the cat picked in 1.0 ("breedIndex" indexed the classic cats).
    static func upgradingFromV1(breedIndex: Int) -> CollectionData {
        var d = CollectionData()
        d.selected = Breed.classic[min(max(breedIndex, 0), Breed.classic.count - 1)].id
        d.seen = Breed.classic.map(\.id)
        return d
    }

    /// Welcome box (once, until the season ends) plus daily boxes, stacking up to the limit.
    mutating func addFreeBoxes(_ schedule: FreeBoxSchedule, now: Date) {
        if !welcomeGiven && schedule.seasonNotOver(now) {
            welcomeGiven = true
            unopened += 1
        }
        let drop = schedule.newDrops(lastDay: lastDropDay, now: now)
        if drop.count > 0 {
            unopened = max(unopened, min(FreeBoxSchedule.stackLimit, unopened + drop.count))
            lastDropDay = drop.lastDay
        }
    }

    /// Records an opened box. Every 3rd duplicate gives a bonus box.
    mutating func recordOpened(_ id: String) -> OpenedBox {
        unopened = max(0, unopened - 1)
        opened += 1
        lastOpened = id
        let n = (owned[id] ?? 0) + 1
        owned[id] = n
        var bonus = false
        if n > 1 {
            duplicateProgress += 1
            if duplicateProgress >= 3 {
                duplicateProgress = 0
                unopened += 1
                bonus = true
            }
        }
        return OpenedBox(id: id, isDuplicate: n > 1, count: n, bonusEarned: bonus, duplicateProgress: duplicateProgress)
    }
}

// MARK: - The player's collection

/// Owned cats, unopened boxes and progress. Saved as JSON in the App Group (so the widget can read it)
/// and mirrored to iCloud key-value storage, so cats survive a reinstall and appear on other devices.
@MainActor
final class CollectionStore: ObservableObject {
    static let shared = CollectionStore()

    @Published private(set) var data = CollectionData()

    let series = Catalog.boxSeries
    private let cloud = NSUbiquitousKeyValueStore.default
    private let cloudKey = "collection.v1"
    private var schedule: FreeBoxSchedule {
        FreeBoxSchedule(start: series.dropStart ?? DateComponents(), end: series.dropEnd ?? DateComponents())
    }

    private var fileURL: URL {
        if let url = SharedCollection.fileURL { return url }
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("collection.json")
    }

    private init() {
        if let d = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder().decode(CollectionData.self, from: d) {
            data = saved
        } else {
            data = .upgradingFromV1(breedIndex: UserDefaults.standard.integer(forKey: "breedIndex"))
        }
        mergeFromCloud()
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: cloud, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.mergeFromCloud() }
        }
        cloud.synchronize()
    }

    // MARK: Reading

    var unopened: Int { data.unopened }
    func count(_ id: String) -> Int { data.count(id) }
    func isOwned(_ id: String) -> Bool { data.isOwned(id) }
    func isNew(_ id: String) -> Bool { isOwned(id) && !data.seen.contains(id) }

    var selectedBreed: Breed { Catalog.breed(data.selected) ?? Breed.classic[0] }

    /// classic first, then boxed cats the player owns, in series order
    var ownedBreeds: [Breed] { Breed.all.filter { isOwned($0.id) } }

    var foundInSeries: Int { series.designs.filter { isOwned($0) }.count }

    // MARK: Free boxes

    /// Hands out the welcome box and any daily boxes earned since last time.
    func refreshFreeBoxes(now: Date = Date()) {
        var d = data
        d.addFreeBoxes(schedule, now: now)
        update(d)
    }

    /// The pop-up shows by itself at most once per day.
    func shouldShowPopupToday(now: Date = Date()) -> Bool {
        data.unopened > 0 && data.lastPopupDay != schedule.dayKey(now)
    }

    func markPopupShown(now: Date = Date()) {
        var d = data
        d.lastPopupDay = schedule.dayKey(now)
        update(d)
    }

    typealias Opened = OpenedBox

    /// Opens one box: rolls, records the cat and handles duplicates (every 3rd one gives a bonus box).
    func openBox(forcing forced: String? = nil) -> Opened? {
        guard data.unopened > 0 else { return nil }
        let id = forced ?? BoxRoller.roll(series, after: data.lastOpened)
        var d = data
        let result = d.recordOpened(id)
        update(d)
        return result
    }

    /// For App Review and QA: grants a box outside the season (long-press the gift button).
    func grantBox() {
        var d = data
        d.unopened += 1
        update(d)
    }

    // MARK: Selection

    func select(_ id: String) {
        guard isOwned(id), data.selected != id else { return }
        var d = data
        d.selected = id
        update(d)
    }

    func markSeen(_ id: String) {
        guard !data.seen.contains(id) else { return }
        var d = data
        d.seen.append(id)
        update(d)
    }

    // MARK: Saving

    private func update(_ d: CollectionData) {
        guard d != data else { return }
        let ownedChanged = d.owned != data.owned || d.selected != data.selected
        data = d
        save()
        if ownedChanged { WidgetCenter.shared.reloadAllTimelines() }
    }

    private func save() {
        guard let json = try? JSONEncoder().encode(data) else { return }
        try? json.write(to: fileURL, options: .atomic)
        cloud.set(json, forKey: cloudKey)
    }

    /// Combines the iCloud copy with the local one without ever losing a cat.
    private func mergeFromCloud() {
        guard let json = cloud.data(forKey: cloudKey),
              let remote = try? JSONDecoder().decode(CollectionData.self, from: json) else { return }
        var d = data
        for (id, n) in remote.owned { d.owned[id] = max(d.owned[id] ?? 0, n) }
        d.welcomeGiven = d.welcomeGiven || remote.welcomeGiven
        if let r = remote.lastDropDay, r > (d.lastDropDay ?? "") {
            // the other device already handed out these days' boxes; take its unopened count
            d.lastDropDay = r
            d.unopened = max(d.unopened, remote.unopened)
        }
        d.duplicateProgress = max(d.duplicateProgress, remote.duplicateProgress)
        d.opened = max(d.opened, remote.opened)
        d.seen = Array(Set(d.seen).union(remote.seen)).sorted()
        update(d)
    }
}
