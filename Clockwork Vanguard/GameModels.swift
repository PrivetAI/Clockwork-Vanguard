import Foundation

// MARK: - Grid primitives

enum Dir: String, CaseIterable, Codable {
    case up, down, left, right

    var dx: Int { self == .left ? -1 : (self == .right ? 1 : 0) }
    var dy: Int { self == .up ? -1 : (self == .down ? 1 : 0) }

    var opposite: Dir {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }

    var angle: Double {
        switch self {
        case .up: return 0
        case .right: return 90
        case .down: return 180
        case .left: return 270
        }
    }
}

struct Coord: Hashable, Codable {
    var x: Int
    var y: Int

    static let boardSize = 8

    var inBounds: Bool { x >= 0 && x < Coord.boardSize && y >= 0 && y < Coord.boardSize }

    func step(_ d: Dir) -> Coord { Coord(x: x + d.dx, y: y + d.dy) }

    func manhattan(to other: Coord) -> Int { abs(x - other.x) + abs(y - other.y) }

    var neighbors: [Coord] { Dir.allCases.map { step($0) }.filter { $0.inBounds } }

    func dirTo(_ other: Coord) -> Dir? {
        if other.x == x && other.y < y { return .up }
        if other.x == x && other.y > y { return .down }
        if other.y == y && other.x < x { return .left }
        if other.y == y && other.x > x { return .right }
        return nil
    }
}

// MARK: - Tiles

enum TileKind: Equatable {
    case plain
    case pit
    case vent
    case conveyor(Dir)
    case oil
    case water
    case crumbling
}

struct Tile {
    var kind: TileKind
    var onFire: Bool = false
    var trapDamage: Int? = nil

    var isPit: Bool { kind == .pit }

    var walkable: Bool { kind != .pit }

    static func from(char c: Character) -> Tile {
        switch c {
        case "P": return Tile(kind: .pit)
        case "V": return Tile(kind: .vent)
        case ">": return Tile(kind: .conveyor(.right))
        case "<": return Tile(kind: .conveyor(.left))
        case "^": return Tile(kind: .conveyor(.up))
        case "v": return Tile(kind: .conveyor(.down))
        case "O": return Tile(kind: .oil)
        case "W": return Tile(kind: .water)
        case "C": return Tile(kind: .crumbling)
        default: return Tile(kind: .plain)
        }
    }
}

// MARK: - Player unit classes

enum UnitClassID: String, CaseIterable, Codable, Identifiable {
    case pistonKnight, cogArcher, steamBulwark, gearSapper, brassLancer, chronoTinker
    var id: String { rawValue }
}

struct UnitClassDef {
    let id: UnitClassID
    let name: String
    let role: String
    let baseHP: Int
    let move: Int
    let baseDamage: Int
    let attackName: String
    let attackDesc: String
    let abilityName: String
    let abilityDesc: String
    let abilityCooldown: Int
    let lore: String
}

struct UnitUpgrades: Codable, Equatable {
    var hpTier: Int = 0
    var dmgTier: Int = 0
    var abilityTier: Int = 0

    static let maxTier = 3
}

// MARK: - Enemies

enum EnemyKind: String, CaseIterable, Codable {
    case scrapCrawler, boltSpitter, beamSentry, foundrySpawner, rustBurrower
    case ironHusk, boilerTick, cogMender, springLeaper, wireSpinner
    case gearSplitter, scrapling, aegisPlate, mortarHulk, clockDrone
    case foundryKing, vaporTyrant, cogColossus, chronoArchon

    var isBoss: Bool {
        switch self {
        case .foundryKing, .vaporTyrant, .cogColossus, .chronoArchon: return true
        default: return false
        }
    }
}

enum EnemyBehavior {
    case melee(push: Int)
    case ranged(range: Int)
    case beam
    case spawner(EnemyKind, every: Int)
    case burrower
    case exploder
    case healer(amount: Int)
    case leaper(range: Int)
    case rooter(range: Int)
    case splitter
    case artillery
    case bossFoundryKing
    case bossVaporTyrant
    case bossCogColossus
    case bossChronoArchon
}

struct EnemyDef {
    let kind: EnemyKind
    let name: String
    let hp: Int
    let move: Int
    let damage: Int
    let armor: Int
    let shielded: Bool
    let behavior: EnemyBehavior
    let summary: String
    let lore: String
}

// MARK: - Structures

enum StructureKind: String, Codable {
    case boiler        // friendly: must survive
    case foundryCore   // enemy: destroy target
    case convoy        // escort: must reach exit

    var name: String {
        switch self {
        case .boiler: return "Pressure Boiler"
        case .foundryCore: return "Foundry Core"
        case .convoy: return "Supply Crawler"
        }
    }

    var hp: Int {
        switch self {
        case .boiler: return 4
        case .foundryCore: return 3
        case .convoy: return 3
        }
    }
}

// MARK: - Missions

enum ObjectiveKind: Equatable {
    case defeatAll
    case survive(turns: Int)
    case protectStructure
    case escort
    case destroyTargets

    var title: String {
        switch self {
        case .defeatAll: return "Destroy all enemies"
        case .survive(let t): return "Survive \(t) turns"
        case .protectStructure: return "Protect the boiler, destroy all enemies"
        case .escort: return "Escort the supply crawler to the exit"
        case .destroyTargets: return "Destroy every foundry core"
        }
    }
}

enum BonusKind: Equatable {
    case finishUnder(turns: Int)
    case hazardKills(Int)
    case noDamage

    var title: String {
        switch self {
        case .finishUnder(let t): return "Win in \(t) turns or fewer"
        case .hazardKills(let n): return n == 1 ? "Kill 1 enemy with hazards" : "Kill \(n) enemies with hazards"
        case .noDamage: return "Take no damage"
        }
    }
}

struct MissionDef: Identifiable {
    let id: Int          // region * 100 + index
    let region: Int      // 0..4
    let index: Int       // 0..7
    let name: String
    let intro: String
    let objective: ObjectiveKind
    let bonus: BonusKind
    let map: [String]    // 8 rows x 8 chars
    let enemies: [(EnemyKind, Coord)]
    let structures: [(StructureKind, Coord)]
    let playerSpawns: [Coord]
    let exitCell: Coord?
    let turnLimit: Int?

    var isBossMission: Bool { enemies.contains { $0.0.isBoss } }
}

struct RegionDef: Identifiable {
    let id: Int
    let name: String
    let tagline: String
    let starsRequired: Int
}

// MARK: - Achievements

struct AchievementDef: Identifiable {
    let id: String
    let name: String
    let detail: String
}

// MARK: - Stats

struct CampaignStats: Codable, Equatable {
    var battlesFought: Int = 0
    var missionsWon: Int = 0
    var enemiesDestroyed: Int = 0
    var bossesDestroyed: Int = 0
    var unitsLost: Int = 0
    var hazardKills: Int = 0
    var trapKills: Int = 0
    var redirectKills: Int = 0
    var pitKills: Int = 0
    var collisions: Int = 0
    var turnsPlayed: Int = 0
    var coresEarned: Int = 0
    var bonusObjectives: Int = 0
}

// MARK: - Deterministic RNG

struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func pick<T>(_ array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        return array[Int(next() % UInt64(array.count))]
    }
}
