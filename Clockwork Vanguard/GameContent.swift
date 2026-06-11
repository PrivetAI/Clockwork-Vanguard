import Foundation

// MARK: - Static game content

enum GameContent {

    // MARK: Unit classes

    static let unitClasses: [UnitClassDef] = [
        UnitClassDef(
            id: .pistonKnight, name: "Piston Knight", role: "Melee Pusher",
            baseHP: 5, move: 3, baseDamage: 2,
            attackName: "Piston Fist",
            attackDesc: "Strike an adjacent enemy and shove it 1 tile away.",
            abilityName: "Piston Slam",
            abilityDesc: "Hammer an adjacent target for extra damage and launch it 2 tiles. Upgrades add launch distance.",
            abilityCooldown: 2,
            lore: "Forged from a decommissioned forge-hammer, the Piston Knight settles every argument with hydraulics. Its gauntlets were rated for ten thousand tons of stamping pressure; rust came for the factory, never for its resolve."
        ),
        UnitClassDef(
            id: .cogArcher, name: "Cog Archer", role: "Ranged Striker",
            baseHP: 3, move: 3, baseDamage: 2,
            attackName: "Bolt Shot",
            attackDesc: "Fire along a straight line up to 4 tiles. The first thing hit takes damage and is knocked back 1 tile.",
            abilityName: "Mortar Volley",
            abilityDesc: "Lob a charge onto any tile within 3 squares, damaging whatever sits there. Ignores anything in the way. Upgrades add damage.",
            abilityCooldown: 2,
            lore: "Its bow is a leaf-spring from a freight loco, its quiver a magazine of machined bolts. The Cog Archer calibrates each shot against wind it can no longer feel, out of habit older than its memory wheels."
        ),
        UnitClassDef(
            id: .steamBulwark, name: "Steam Bulwark", role: "Tank / Control",
            baseHP: 7, move: 2, baseDamage: 1,
            attackName: "Boiler Bash",
            attackDesc: "Slam an adjacent enemy and push it 1 tile.",
            abilityName: "Anchor Winch",
            abilityDesc: "Hook any target in a straight line up to 2 tiles and drag it 1 tile toward you. Upgrades extend the winch line.",
            abilityCooldown: 2,
            lore: "A walking pressure vessel plated in boilerplate older than the war. The Bulwark once held a collapsing dam gate shut for nine days. It does not move quickly. It does not need to."
        ),
        UnitClassDef(
            id: .gearSapper, name: "Gear Sapper", role: "Trap Layer",
            baseHP: 4, move: 3, baseDamage: 1,
            attackName: "Wrench Jab",
            attackDesc: "Strike an adjacent enemy.",
            abilityName: "Cog Mine",
            abilityDesc: "Plant a mine on an adjacent empty tile. The first enemy that enters detonates it. Upgrades add mine damage.",
            abilityCooldown: 2,
            lore: "The Sapper was built to clear minefields and decided, after long reflection, that laying them was more efficient. Every mine is hand-wound and signed with a tiny stamped gear."
        ),
        UnitClassDef(
            id: .brassLancer, name: "Brass Lancer", role: "Charger",
            baseHP: 4, move: 3, baseDamage: 2,
            attackName: "Lance Thrust",
            attackDesc: "Strike an adjacent enemy.",
            abilityName: "Rail Charge",
            abilityDesc: "Charge in a straight line up to 4 tiles. The first enemy struck takes heavy damage and is knocked back 1 tile. Upgrades add charge damage.",
            abilityCooldown: 2,
            lore: "Once a courier engine on the Brass Meridian line, the Lancer kept its timetable through derailments, sieges, and one volcanic winter. Its lance is the old coupling rod, sharpened to a promise."
        ),
        UnitClassDef(
            id: .chronoTinker, name: "Chrono Tinker", role: "Displacer",
            baseHP: 3, move: 4, baseDamage: 1,
            attackName: "Spark Arc",
            attackDesc: "Zap the first target in a straight line up to 2 tiles.",
            abilityName: "Escapement Swap",
            abilityDesc: "Instantly trade places with any unit or enemy within 3 squares. Upgrades extend the range.",
            abilityCooldown: 3,
            lore: "The Tinker's chest holds a regulator wheel that ticks one second ahead of everyone else's. It insists swapping places is merely 'correcting a scheduling error in space.'"
        )
    ]

    static func unitDef(_ id: UnitClassID) -> UnitClassDef {
        unitClasses.first { $0.id == id }!
    }

    // MARK: Enemies

    static let enemyDefs: [EnemyDef] = [
        EnemyDef(kind: .scrapCrawler, name: "Scrap Crawler", hp: 2, move: 3, damage: 1, armor: 0, shielded: false,
                 behavior: .melee(push: 0),
                 summary: "Skitters to an adjacent tile and bites.",
                 lore: "Self-assembling vermin of the Rustyard. Each one is a fistful of stripped gears that decided, collectively, to be angry."),
        EnemyDef(kind: .boltSpitter, name: "Bolt Spitter", hp: 2, move: 2, damage: 1, armor: 0, shielded: false,
                 behavior: .ranged(range: 3),
                 summary: "Fires down a row or column at the first thing in line, up to 3 tiles.",
                 lore: "A rivet gun that grew legs and opinions. Spits red-hot fasteners with the enthusiasm of a machine that never learned what fasteners are for."),
        EnemyDef(kind: .beamSentry, name: "Beam Sentry", hp: 3, move: 0, damage: 2, armor: 0, shielded: false,
                 behavior: .beam,
                 summary: "Stationary. Sweeps an entire row or column with a cutting beam that hits everything in line.",
                 lore: "Bolted-down watchtowers of the old perimeter. Their lenses no longer distinguish intruder from owner, which the Vanguard considers a design flaw worth exploiting."),
        EnemyDef(kind: .foundrySpawner, name: "Foundry Spawner", hp: 4, move: 0, damage: 0, armor: 0, shielded: false,
                 behavior: .spawner(.scrapCrawler, every: 2),
                 summary: "Stationary. Assembles a new Scrap Crawler every 2 turns.",
                 lore: "A rogue assembly kiln still running its last work order: CRAWLERS, QTY: REMAINDER OF TIME."),
        EnemyDef(kind: .rustBurrower, name: "Rust Burrower", hp: 3, move: 4, damage: 2, armor: 0, shielded: false,
                 behavior: .burrower,
                 summary: "Tunnels underground, untouchable, then surfaces to strike a marked tile.",
                 lore: "A mining worm re-tasked by corrosion. You hear it before you see it, and you see it exactly once."),
        EnemyDef(kind: .ironHusk, name: "Iron Husk", hp: 4, move: 2, damage: 2, armor: 1, shielded: false,
                 behavior: .melee(push: 1),
                 summary: "Armored brawler (reduces all damage by 1). Its blow shoves the target 1 tile.",
                 lore: "The empty chassis of a labor titan, walking out its final instruction. Its armor was meant for rockfalls; your bolts merely annoy it."),
        EnemyDef(kind: .boilerTick, name: "Boiler Tick", hp: 1, move: 4, damage: 2, armor: 0, shielded: false,
                 behavior: .exploder,
                 summary: "Sprints close, then detonates, blasting all 4 adjacent tiles. Dies in the blast.",
                 lore: "A kettle with ambitions. Its whole philosophy fits in one sentence and ends with a bang."),
        EnemyDef(kind: .cogMender, name: "Cog Mender", hp: 2, move: 3, damage: 0, armor: 0, shielded: false,
                 behavior: .healer(amount: 2),
                 summary: "Repairs the most damaged nearby machine for 2 HP each turn.",
                 lore: "A field-repair unit that never updated its friend-or-foe ledger. It mends whatever creaks loudest, and the horde always creaks."),
        EnemyDef(kind: .springLeaper, name: "Spring Leaper", hp: 2, move: 3, damage: 1, armor: 0, shielded: false,
                 behavior: .leaper(range: 3),
                 summary: "Vaults over obstacles up to 3 tiles, landing beside its prey.",
                 lore: "Mostly coil, partly malice. Surveyors built it to cross chasms; the chasms were less of a problem than what it learned on the other side."),
        EnemyDef(kind: .wireSpinner, name: "Wire Spinner", hp: 3, move: 2, damage: 1, armor: 0, shielded: false,
                 behavior: .rooter(range: 3),
                 summary: "Shoots snare-wire down a line: damages and roots the target in place for a turn.",
                 lore: "It spools razor filament the way spiders spool silk, and files every catch under 'inventory.'"),
        EnemyDef(kind: .gearSplitter, name: "Gear Splitter", hp: 4, move: 2, damage: 1, armor: 0, shielded: false,
                 behavior: .splitter,
                 summary: "On destruction, breaks apart into two Scraplings.",
                 lore: "A redundancy engine: every critical part exists twice. Break it and both halves file a grievance, with teeth."),
        EnemyDef(kind: .scrapling, name: "Scrapling", hp: 1, move: 3, damage: 1, armor: 0, shielded: false,
                 behavior: .melee(push: 0),
                 summary: "Half of a Gear Splitter. Fragile, fast, furious.",
                 lore: "Half the gears, all of the grudge."),
        EnemyDef(kind: .aegisPlate, name: "Aegis Plate", hp: 3, move: 2, damage: 2, armor: 0, shielded: true,
                 behavior: .melee(push: 0),
                 summary: "Carries a kinetic shield that absorbs the first hit it takes each round.",
                 lore: "Parade armor of the Bastion garrison, still patrolling a parade ground that fell into the sea. The shield resets with clockwork patience."),
        EnemyDef(kind: .mortarHulk, name: "Mortar Hulk", hp: 3, move: 1, damage: 2, armor: 0, shielded: false,
                 behavior: .artillery,
                 summary: "Lobs a shell onto a marked 2x2 area anywhere on the field. The mark does not move.",
                 lore: "A siege piece that grew tired of waiting for orders and started providing its own coordinates."),
        EnemyDef(kind: .clockDrone, name: "Clock Drone", hp: 2, move: 4, damage: 1, armor: 0, shielded: false,
                 behavior: .melee(push: 0),
                 summary: "The Chronoforge's swift hands. Fast, precise, expendable.",
                 lore: "Each drone is wound once and never again. They spend their single mainspring with terrifying economy."),
        // Bosses
        EnemyDef(kind: .foundryKing, name: "The Foundry King", hp: 12, move: 2, damage: 3, armor: 1, shielded: false,
                 behavior: .bossFoundryKing,
                 summary: "BOSS. Slams a 2-tile line, shoving victims. Below half health it also assembles Scrap Crawlers.",
                 lore: "First of the rogue overseers. It crowned itself with a ladle of cooling slag and ruled the Rustyard by the only law it knew: throughput."),
        EnemyDef(kind: .vaporTyrant, name: "Vapor Tyrant", hp: 14, move: 2, damage: 2, armor: 0, shielded: false,
                 behavior: .bossVaporTyrant,
                 summary: "BOSS. Sweeps cutting beams down full lines. Below half health it vents a scalding blast around itself.",
                 lore: "It speaks in whistle-codes through a hundred stolen safety valves. The Steamworks obey, because the alternative is silence."),
        EnemyDef(kind: .cogColossus, name: "Cog Colossus", hp: 16, move: 1, damage: 2, armor: 2, shielded: false,
                 behavior: .bossCogColossus,
                 summary: "BOSS. Heavily armored. Rains mortar fire on a 2x2 mark; below half health it instead grinds forward with a piercing charge.",
                 lore: "The Gearspine's patron mountain. Miners swore the deepest stratum had a heartbeat. They were correct, and it was counting."),
        EnemyDef(kind: .chronoArchon, name: "Chrono Archon", hp: 16, move: 3, damage: 2, armor: 0, shielded: false,
                 behavior: .bossChronoArchon,
                 summary: "BOSS. Fires regulator beams; below half health it detonates temporal bursts in a cross around its prey.",
                 lore: "Keeper of the Chronoforge and author of the uprising's timetable. It believes every machine you have ever lost is merely 'rescheduled.'"),
    ]

    static func enemyDef(_ kind: EnemyKind) -> EnemyDef {
        enemyDefs.first { $0.kind == kind }!
    }

    // MARK: Regions

    static let regions: [RegionDef] = [
        RegionDef(id: 0, name: "Rustyard Outskirts", tagline: "Where the uprising first sparked among the scrap heaps.", starsRequired: 0),
        RegionDef(id: 1, name: "The Steamworks", tagline: "Vents shriek and belts run wild in the pressure district.", starsRequired: 10),
        RegionDef(id: 2, name: "Gearspine Mines", tagline: "Crumbling galleries above a dark, ticking deep.", starsRequired: 24),
        RegionDef(id: 3, name: "Patina Bastion", tagline: "The old fortress, green with age and bristling with guns.", starsRequired: 40),
        RegionDef(id: 4, name: "The Chronoforge", tagline: "Where the Archon winds the war like a watch.", starsRequired: 58),
    ]

    // MARK: Achievements

    static let achievements: [AchievementDef] = [
        AchievementDef(id: "firstWin", name: "Ignition", detail: "Win your first mission."),
        AchievementDef(id: "region0", name: "Rustyard Liberated", detail: "Defeat The Foundry King and clear the Rustyard Outskirts."),
        AchievementDef(id: "region1", name: "Steamworks Stilled", detail: "Defeat the Vapor Tyrant and clear The Steamworks."),
        AchievementDef(id: "region2", name: "Gearspine Cleared", detail: "Defeat the Cog Colossus and clear the Gearspine Mines."),
        AchievementDef(id: "region3", name: "Bastion Broken", detail: "Clear Patina Bastion."),
        AchievementDef(id: "region4", name: "Chronoforge Sealed", detail: "Defeat the Chrono Archon and clear The Chronoforge."),
        AchievementDef(id: "stars30", name: "Polished Brass", detail: "Earn 30 mission stars."),
        AchievementDef(id: "stars60", name: "Gleaming Cohort", detail: "Earn 60 mission stars."),
        AchievementDef(id: "stars120", name: "Immaculate Campaign", detail: "Earn all 120 mission stars."),
        AchievementDef(id: "pitKill", name: "Long Way Down", detail: "Shove an enemy into a pit."),
        AchievementDef(id: "hazard10", name: "Industrial Accident", detail: "Destroy 10 enemies with hazards."),
        AchievementDef(id: "redirect", name: "Friendly Crossfire", detail: "Make an enemy destroy another enemy."),
        AchievementDef(id: "trapKill", name: "Mind the Step", detail: "Destroy an enemy with a Cog Mine."),
        AchievementDef(id: "flawless", name: "Untouched Plating", detail: "Win a mission without taking any damage."),
        AchievementDef(id: "maxUnit", name: "Masterwork", detail: "Fully upgrade one unit."),
        AchievementDef(id: "allUnits", name: "Full Roster", detail: "Unlock all six unit classes."),
        AchievementDef(id: "wins10", name: "Seasoned Commander", detail: "Win 10 missions."),
        AchievementDef(id: "wins40", name: "Campaign Veteran", detail: "Win all 40 missions."),
        AchievementDef(id: "kills100", name: "Scrapheap Mountain", detail: "Destroy 100 enemies."),
        AchievementDef(id: "bonus20", name: "Perfectionist", detail: "Complete 20 bonus objectives."),
    ]

    // MARK: Hazard codex blurbs

    static let hazardNotes: [(String, String)] = [
        ("Pit", "Bottomless. Anything pushed or carried in is destroyed instantly."),
        ("Steam Vent", "Scalds whatever stands on it for 1 damage at the end of every round."),
        ("Conveyor Belt", "Carries whoever stands on it 1 tile in the arrow's direction at the end of every round. Belts feeding pits are an opportunity."),
        ("Oil Slick", "Any attack that lands here ignites it. Burning tiles deal 1 damage per round and spread to adjacent oil."),
        ("Water", "Cannot burn. Solid footing when the floor is on fire."),
        ("Crumbling Floor", "Collapses into a pit when something steps off it, or when an attack lands on it."),
    ]
}
