import XCTest
@testable import PetTheCat

// MARK: - Helpers

func calendar(_ tz: String = "Europe/Madrid") -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: tz)!
    return c
}

func christmasSchedule(_ tz: String = "Europe/Madrid") -> FreeBoxSchedule {
    FreeBoxSchedule(calendar: calendar(tz), start: Catalog.christmas.dropStart!, end: Catalog.christmas.dropEnd!)
}

func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0, tz: String = "Europe/Madrid") -> Date {
    calendar(tz).date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

// MARK: - Odds

final class BoxRollerTests: XCTestCase {
    let series = Catalog.christmas

    func testWeightsMatchPublishedOdds() {
        XCTAssertEqual(series.totalWeight, 360)
        XCTAssertEqual(series.basics.count, 5)
        for id in series.basics {
            XCTAssertEqual(series.weight(id), 71)
            XCTAssertEqual(series.percent(id), "19.72%")
        }
        XCTAssertEqual(series.secret, "midnight")
        XCTAssertEqual(series.weight("midnight"), 5)          // 5 / 360 = 1 in 72
        XCTAssertEqual(series.percent("midnight"), "1.39%")
    }

    func testEveryDesignExistsAsACat() {
        for id in series.designs { XCTAssertNotNil(Catalog.breed(id), id) }
        XCTAssertEqual(Breed.all.count, 12)
        XCTAssertEqual(Set(Breed.all.map(\.id)).count, 12, "ids must be unique")
    }

    /// 1 million seeded rolls land within 0.1 percentage points of the published odds.
    func testMillionRollsMatchOdds() {
        var rng = SeededGenerator(seed: 2026)
        let n = 1_000_000
        var counts: [String: Int] = [:]
        for _ in 0..<n { counts[BoxRoller.roll(series, using: &rng), default: 0] += 1 }
        for id in series.designs {
            let expected = Double(series.weight(id)) / Double(series.totalWeight) * 100
            let actual = Double(counts[id] ?? 0) / Double(n) * 100
            XCTAssertEqual(actual, expected, accuracy: 0.1, "\(id): \(actual)% vs \(expected)%")
        }
    }

    func testSameSeedGivesSameRolls() {
        var a = SeededGenerator(seed: 42), b = SeededGenerator(seed: 42)
        let first = (0..<50).map { _ in BoxRoller.roll(series, using: &a) }
        let second = (0..<50).map { _ in BoxRoller.roll(series, using: &b) }
        XCTAssertEqual(first, second)
    }
}

// MARK: - Free-box schedule

final class FreeBoxScheduleTests: XCTestCase {
    func schedule(_ tz: String = "Europe/Madrid") -> FreeBoxSchedule { christmasSchedule(tz) }

    func testNothingBeforeTheSeason() {
        let r = schedule().newDrops(lastDay: nil, now: date(2026, 11, 30))
        XCTAssertEqual(r.count, 0)
        XCTAssertNil(r.lastDay)
    }

    func testFirstDay() {
        let r = schedule().newDrops(lastDay: nil, now: date(2026, 12, 1, 0, 1))
        XCTAssertEqual(r.count, 1)
        XCTAssertEqual(r.lastDay, "2026-12-01")
    }

    func testSameDayGivesNothingTwice() {
        let r = schedule().newDrops(lastDay: "2026-12-05", now: date(2026, 12, 5, 23, 59))
        XCTAssertEqual(r.count, 0)
        XCTAssertEqual(r.lastDay, "2026-12-05")
    }

    func testMidnightRollover() {
        let s = schedule()
        XCTAssertEqual(s.newDrops(lastDay: "2026-12-05", now: date(2026, 12, 5, 23, 59)).count, 0)
        XCTAssertEqual(s.newDrops(lastDay: "2026-12-05", now: date(2026, 12, 6, 0, 0)).count, 1)
    }

    func testMissedDaysAreCounted() {
        // last box Dec 3, back on Dec 8 → Dec 4…8 = 5 days (the stack limit is applied by the collection)
        let r = schedule().newDrops(lastDay: "2026-12-03", now: date(2026, 12, 8))
        XCTAssertEqual(r.count, 5)
        XCTAssertEqual(r.lastDay, "2026-12-08")
    }

    func testLateInstallStillGetsBoxesSinceDecemberFirst() {
        let r = schedule().newDrops(lastDay: nil, now: date(2026, 12, 9))
        XCTAssertEqual(r.count, 9)
    }

    func testClockMovedBackGivesNothingAndKeepsProgress() {
        let r = schedule().newDrops(lastDay: "2026-12-10", now: date(2026, 12, 7))
        XCTAssertEqual(r.count, 0)
        XCTAssertEqual(r.lastDay, "2026-12-10")
    }

    func testNothingDropsAfterTheSeasonEnds() {
        // also covers the clock being moved past Jan 6, and a first launch in February
        let r = schedule().newDrops(lastDay: "2027-01-04", now: date(2027, 3, 1))
        XCTAssertEqual(r.count, 0)
        XCTAssertEqual(r.lastDay, "2027-01-04")
        XCTAssertEqual(schedule().newDrops(lastDay: nil, now: date(2027, 2, 1)).count, 0)
    }

    func testCatchUpInsideTheSeasonStopsAtToday() {
        let r = schedule().newDrops(lastDay: "2027-01-02", now: date(2027, 1, 6, 8, 0))
        XCTAssertEqual(r.count, 4)                      // Jan 3…6
        XCTAssertEqual(r.lastDay, "2027-01-06")
    }

    func testJanuarySixthIsLastDay() {
        let s = schedule()
        XCTAssertEqual(s.newDrops(lastDay: "2027-01-05", now: date(2027, 1, 6, 23, 0)).count, 1)
        XCTAssertEqual(s.newDrops(lastDay: "2027-01-06", now: date(2027, 1, 7, 9, 0)).count, 0)
        XCTAssertTrue(s.seasonNotOver(date(2027, 1, 6, 23, 59)))
        XCTAssertFalse(s.seasonNotOver(date(2027, 1, 7, 0, 1)))
    }

    func testDaysFollowTheLocalTimeZone() {
        // 23:30 on Nov 30 in Los Angeles is already Dec 1 in Madrid
        let instant = date(2026, 11, 30, 23, 30, tz: "America/Los_Angeles")
        XCTAssertEqual(schedule("America/Los_Angeles").newDrops(lastDay: nil, now: instant).count, 0)
        XCTAssertEqual(schedule("Europe/Madrid").newDrops(lastDay: nil, now: instant).count, 1)
    }
}

// MARK: - Collection rules

final class CollectionRulesTests: XCTestCase {
    let s = christmasSchedule()

    func testWelcomeBoxOnceBeforeTheSeason() {
        var d = CollectionData()
        d.addFreeBoxes(s, now: date(2026, 11, 26))
        XCTAssertEqual(d.unopened, 1)
        d.addFreeBoxes(s, now: date(2026, 11, 27))
        XCTAssertEqual(d.unopened, 1, "welcome box is given only once")
    }

    func testNoWelcomeBoxAfterTheSeason() {
        var d = CollectionData()
        d.addFreeBoxes(s, now: date(2027, 2, 1))
        XCTAssertEqual(d.unopened, 0)
    }

    func testUnopenedBoxesStackUpToThree() {
        var d = CollectionData()
        d.welcomeGiven = true
        d.addFreeBoxes(s, now: date(2026, 12, 9))     // 9 days owed
        XCTAssertEqual(d.unopened, FreeBoxSchedule.stackLimit)
        XCTAssertEqual(d.lastDropDay, "2026-12-09")
        d.addFreeBoxes(s, now: date(2026, 12, 10))
        XCTAssertEqual(d.unopened, 3, "a full stack doesn't grow")
    }

    func testBonusBoxesAboveTheLimitAreKept() {
        var d = CollectionData()
        d.welcomeGiven = true
        d.unopened = 4
        d.lastDropDay = "2026-12-09"
        d.addFreeBoxes(s, now: date(2026, 12, 10))
        XCTAssertEqual(d.unopened, 4)
    }

    func testEveryThirdDuplicateGivesABonusBox() {
        var d = CollectionData()
        d.unopened = 10
        XCTAssertFalse(d.recordOpened("elf").isDuplicate)
        var r = d.recordOpened("elf")
        XCTAssertTrue(r.isDuplicate)
        XCTAssertEqual(r.count, 2)
        XCTAssertEqual(r.duplicateProgress, 1)
        r = d.recordOpened("frost")                     // new cat: no progress
        XCTAssertEqual(r.duplicateProgress, 1)
        _ = d.recordOpened("elf")
        let before = d.unopened
        r = d.recordOpened("frost")                     // 3rd duplicate
        XCTAssertTrue(r.bonusEarned)
        XCTAssertEqual(r.duplicateProgress, 0)
        XCTAssertEqual(d.unopened, before)              // one spent, one bonus
        XCTAssertEqual(d.count("elf"), 3)
        XCTAssertEqual(d.opened, 5)
    }

    func testClassicCatsAreAlwaysOwned() {
        let d = CollectionData()
        for b in Breed.classic { XCTAssertTrue(d.isOwned(b.id)) }
        for id in Catalog.christmas.designs { XCTAssertFalse(d.isOwned(id)) }
    }

    func testUpgradeFromV1KeepsSelectedCat() {
        for (i, b) in Breed.classic.enumerated() {
            let d = CollectionData.upgradingFromV1(breedIndex: i)
            XCTAssertEqual(d.selected, b.id)
            XCTAssertEqual(d.unopened, 0)
        }
        XCTAssertEqual(CollectionData.upgradingFromV1(breedIndex: 99).selected, Breed.classic.last!.id)
        XCTAssertTrue(CollectionData.upgradingFromV1(breedIndex: 0).seen.contains("ginger"), "classic cats show no 'new' dot")
    }

    func testSavedDataRoundTrips() throws {
        var d = CollectionData()
        d.owned = ["elf": 2, "midnight": 1]
        d.unopened = 2
        d.lastDropDay = "2026-12-12"
        let back = try JSONDecoder().decode(CollectionData.self, from: JSONEncoder().encode(d))
        XCTAssertEqual(back, d)
    }
}
