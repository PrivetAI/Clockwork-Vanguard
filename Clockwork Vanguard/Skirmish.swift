import Foundation

// MARK: - Skirmish mode
//
// Procedurally assembles a fully-formed MissionDef from the existing enemy and
// hazard roster, so the live BattleEngine runs it unchanged. Two flavours:
//   • Daily Operation  — one fixed battle seeded from the calendar date.
//   • Endless Gauntlet — an escalating run; each cleared depth raises the stakes.
//
// Generation is fully deterministic for a given (seed, depth): the same day or
// the same depth always produces the identical board.

enum SkirmishMode: Equatable, Identifiable {
    case daily(dayKey: Int)
    case endless(depth: Int)

    var isDaily: Bool { if case .daily = self { return true }; return false }

    var id: String {
        switch self {
        case .daily(let k): return "daily-\(k)"
        case .endless(let d): return "endless-\(d)"
        }
    }
}

struct SkirmishBattle {
    let mission: MissionDef
    let depth: Int
    let baseCores: Int
    let isDaily: Bool
    let dayKey: Int
}

/// Which campaign-vs-skirmish flow a battle session is running under.
enum BattleContext {
    case campaign
    case skirmish(SkirmishBattle)
}

enum SkirmishGenerator {

    // Enemy pools widen as depth climbs. Bosses appear at milestone depths.
    private static let bossRotation: [EnemyKind] = [.foundryKing, .vaporTyrant, .cogColossus, .chronoArchon]

    private static func pool(forDepth d: Int) -> [EnemyKind] {
        var p: [EnemyKind] = [.scrapCrawler, .scrapCrawler, .boltSpitter]
        if d >= 2 { p += [.ironHusk, .springLeaper] }
        if d >= 3 { p += [.boilerTick, .aegisPlate] }
        if d >= 4 { p += [.beamSentry, .wireSpinner, .gearSplitter] }
        if d >= 6 { p += [.mortarHulk, .cogMender, .clockDrone] }
        if d >= 8 { p += [.rustBurrower, .foundrySpawner] }
        return p
    }

    /// Difficulty scaling routed through MissionDef.region, which the engine
    /// already uses to buff enemy HP/damage.
    private static func region(forDepth d: Int) -> Int { min(4, (d - 1) / 2) }

    static func dayKey(for date: Date, calendar: Calendar = .current) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return (c.year ?? 2000) * 10000 + (c.month ?? 1) * 100 + (c.day ?? 1)
    }

    static func make(_ mode: SkirmishMode) -> SkirmishBattle {
        let depth: Int
        let seed: UInt64
        let isDaily: Bool
        let dayKey: Int
        switch mode {
        case .daily(let key):
            depth = 4
            seed = UInt64(bitPattern: Int64(key)) &* 0x100000001B3
            isDaily = true
            dayKey = key
        case .endless(let d):
            depth = max(1, d)
            seed = UInt64(d) &* 0x9E3779B97F4A7C15 &+ 0xD1B54A32D192ED03
            isDaily = false
            dayKey = 0
        }

        var rng = SeededRNG(seed: seed)
        let reg = region(forDepth: depth)
        let size = Coord.boardSize

        // Player spawns: bottom row, three spread columns.
        let spawnCols = [1, 4, 6]
        let spawns = spawnCols.map { Coord(x: $0, y: size - 1) }
        var occupied = Set(spawns)

        // Enemy roster.
        var enemies: [(EnemyKind, Coord)] = []
        let wantBoss = depth >= 4 && depth % 4 == 0
        if wantBoss {
            let boss = bossRotation[(depth / 4 - 1) % bossRotation.count]
            if let c = freeCell(topRows: 3, occupied: occupied, rng: &rng) {
                enemies.append((boss, c)); occupied.insert(c)
            }
        }
        let baseCount = 3 + depth / 2
        let count = min(wantBoss ? 4 : 8, baseCount)
        let p = pool(forDepth: depth)
        var guardCount = 0
        while enemies.count < count + (wantBoss ? 1 : 0) && guardCount < 64 {
            guardCount += 1
            guard let kind = rng.pick(p) else { break }
            if kind.isBoss { continue }
            guard let c = freeCell(topRows: 4, occupied: occupied, rng: &rng) else { break }
            enemies.append((kind, c)); occupied.insert(c)
        }

        // Hazards: sprinkle onto unoccupied tiles only, keeping a clean spawn row.
        var grid = Array(repeating: Array(repeating: Character("."), count: size), count: size)
        let hazardChars: [Character] = ["P", "V", "O", ">", "<", "C"]
        let hazardBudget = 3 + depth   // grows with depth
        var placed = 0
        var hguard = 0
        while placed < hazardBudget && hguard < 200 {
            hguard += 1
            let x = Int(rng.next() % UInt64(size))
            let y = Int(rng.next() % UInt64(size - 2))   // never the bottom two rows
            let c = Coord(x: x, y: y)
            if occupied.contains(c) { continue }
            if grid[y][x] != "." { continue }
            guard let h = rng.pick(hazardChars) else { break }
            grid[y][x] = h
            placed += 1
        }

        let map = grid.map { String($0) }

        // Objective: mostly defeat-all, occasionally a survival stand.
        let survival = !wantBoss && depth >= 3 && (rng.next() % 5 == 0)
        let objective: ObjectiveKind = survival ? .survive(turns: 5 + depth / 2) : .defeatAll
        let bonusRoll = rng.next() % 3
        let bonus: BonusKind
        switch bonusRoll {
        case 0: bonus = .finishUnder(turns: 5 + depth / 2)
        case 1: bonus = .hazardKills(1)
        default: bonus = .noDamage
        }

        let name: String
        let intro: String
        if isDaily {
            name = "Daily Operation"
            intro = "A standing contract from the Vanguard war-room. Today's deployment is the same for every commander in the field — clear it for salvage."
        } else {
            name = "Gauntlet — Depth \(depth)"
            intro = depth == 1
                ? "An open skirmish against the wandering scrap. Survive deeper for richer salvage."
                : "The horde thickens. Depth \(depth): hold the line and press on."
        }

        let baseCores = isDaily ? 18 : (4 + depth * 2)

        let mission = MissionDef(
            id: 90000 + (isDaily ? dayKey % 10000 : depth),   // never collides with campaign ids (region*100+index)
            region: reg, index: 0,
            name: name, intro: intro,
            objective: objective, bonus: bonus, map: map,
            enemies: enemies,
            structures: [],
            playerSpawns: spawns,
            exitCell: nil,
            turnLimit: { if case .survive(let t) = objective { return t } else { return nil } }()
        )
        return SkirmishBattle(mission: mission, depth: depth, baseCores: baseCores,
                              isDaily: isDaily, dayKey: dayKey)
    }

    private static func freeCell(topRows: Int, occupied: Set<Coord>, rng: inout SeededRNG) -> Coord? {
        let size = Coord.boardSize
        for _ in 0..<40 {
            let x = Int(rng.next() % UInt64(size))
            let y = Int(rng.next() % UInt64(max(1, topRows)))
            let c = Coord(x: x, y: y)
            if !occupied.contains(c) { return c }
        }
        // deterministic fallback scan
        for y in 0..<topRows {
            for x in 0..<size {
                let c = Coord(x: x, y: y)
                if !occupied.contains(c) { return c }
            }
        }
        return nil
    }
}
