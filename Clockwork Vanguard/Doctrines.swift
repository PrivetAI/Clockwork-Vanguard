import Foundation

// MARK: - Battle modifiers
//
// A tiny, engine-safe bundle of additive stat boosts applied to the player
// squad at battle start. Threaded into BattleEngine.init with a neutral
// default so existing call sites keep compiling. Everything here is a pure
// additive tweak to values the engine already reads at spawn time.

struct BattleModifiers: Equatable {
    var bonusHP: Int = 0
    var bonusMove: Int = 0
    var bonusDamage: Int = 0
    var abilityCooldownReduction: Int = 0   // abilities recharge faster (min cooldown 1)

    static let none = BattleModifiers()

    var isNeutral: Bool { self == .none }
}

// MARK: - Vanguard Doctrines (meta-progression)
//
// Permanent passive perks bought once with cores, then equipped into a
// limited loadout. Owning many but only equipping a few makes loadout a real
// decision instead of a strict power creep.

enum DoctrineID: String, CaseIterable, Codable, Identifiable {
    case reinforcedPlating     // +1 max HP to every unit
    case overclockedServos     // +1 move to every unit
    case honedStrikers         // +1 damage to every unit
    case primedMechanisms      // abilities start off cooldown
    case scrapBounty           // +30% cores from every battle
    case fieldSalvage          // flat +3 cores on any victory

    var id: String { rawValue }
}

struct DoctrineDef: Identifiable {
    let id: DoctrineID
    let name: String
    let blurb: String
    let cost: Int
    var identifier: DoctrineID { id }
}

enum DoctrineCatalog {

    /// How many doctrines can be equipped at once.
    static let loadoutSlots = 3

    static let all: [DoctrineDef] = [
        DoctrineDef(id: .reinforcedPlating, name: "Reinforced Plating",
                    blurb: "Field-welded boilerplate. Every deployed unit gains +1 maximum HP.",
                    cost: 20),
        DoctrineDef(id: .overclockedServos, name: "Overclocked Servos",
                    blurb: "Wind the mainsprings tight. Every unit gains +1 movement range.",
                    cost: 24),
        DoctrineDef(id: .honedStrikers, name: "Honed Strikers",
                    blurb: "Sharpened couplings and tuned hammers. Every unit deals +1 attack damage.",
                    cost: 28),
        DoctrineDef(id: .primedMechanisms, name: "Primed Mechanisms",
                    blurb: "Tuned escapements. Unit abilities recharge one round faster.",
                    cost: 26),
        DoctrineDef(id: .scrapBounty, name: "Scrap Bounty",
                    blurb: "Salvage contracts with the rear echelon. Earn 30% more cores from every battle.",
                    cost: 22),
        DoctrineDef(id: .fieldSalvage, name: "Field Salvage",
                    blurb: "Strip the wreckage before withdrawal. Gain a flat +3 cores on any victory.",
                    cost: 16),
    ]

    static func def(_ id: DoctrineID) -> DoctrineDef { all.first { $0.id == id }! }

    /// Build the engine-side stat modifiers for an equipped doctrine set.
    static func battleModifiers(for equipped: Set<DoctrineID>) -> BattleModifiers {
        var m = BattleModifiers()
        if equipped.contains(.reinforcedPlating) { m.bonusHP += 1 }
        if equipped.contains(.overclockedServos) { m.bonusMove += 1 }
        if equipped.contains(.honedStrikers) { m.bonusDamage += 1 }
        if equipped.contains(.primedMechanisms) { m.abilityCooldownReduction += 1 }
        return m
    }

    /// Core reward shaping (applied in the store after a victory).
    static func coreMultiplier(for equipped: Set<DoctrineID>) -> Double {
        equipped.contains(.scrapBounty) ? 1.30 : 1.0
    }

    static func flatVictoryBonus(for equipped: Set<DoctrineID>) -> Int {
        equipped.contains(.fieldSalvage) ? 3 : 0
    }
}
