import Foundation

// MARK: - Region 5 — The Reckoning (post-Chronoforge final region, 8 missions)

extension MissionCatalog {

    private static func r5(
        _ index: Int, _ name: String, _ intro: String,
        obj: ObjectiveKind, bonus: BonusKind, map: [String],
        enemies: [(EnemyKind, Int, Int)],
        structures: [(StructureKind, Int, Int)] = [],
        spawns: [(Int, Int)],
        exit: (Int, Int)? = nil
    ) -> MissionDef {
        let region = 5
        var limit: Int? = nil
        if case .survive(let t) = obj { limit = t }
        return MissionDef(
            id: region * 100 + index, region: region, index: index,
            name: name, intro: intro, objective: obj, bonus: bonus, map: map,
            enemies: enemies.map { ($0.0, Coord(x: $0.1, y: $0.2)) },
            structures: structures.map { ($0.0, Coord(x: $0.1, y: $0.2)) },
            playerSpawns: spawns.map { Coord(x: $0.0, y: $0.1) },
            exitCell: exit.map { Coord(x: $0.0, y: $0.1) },
            turnLimit: limit
        )
    }

    static let region5: [MissionDef] = [

        // 0 — defeatAll
        r5(0, "Ashfall Threshold",
           "The Chronoforge is dead, but its children still march. Hold the cracked threshold where the last road into the citadel begins.",
           obj: .defeatAll, bonus: .finishUnder(turns: 6),
           map: ["........",
                 "..V..V..",
                 "........",
                 "...PP...",
                 "........",
                 "..V..V..",
                 "........",
                 "........"],
           enemies: [(.ironHusk, 2, 2), (.boltSpitter, 5, 2), (.gearSplitter, 4, 2),
                     (.beamSentry, 1, 0), (.springLeaper, 6, 2)],
           spawns: [(1, 7), (4, 7), (6, 7)]),

        // 1 — survive
        r5(1, "The Geyser Gauntlet",
           "Burst steam mains turned the foundry yard into a field of scalding geysers. Outlast the swarm; the pressure will do half your killing.",
           obj: .survive(turns: 5), bonus: .hazardKills(2),
           map: ["........",
                 ".V.VV.V.",
                 "........",
                 "..V..V..",
                 "........",
                 ".V....V.",
                 "........",
                 "........"],
           enemies: [(.scrapCrawler, 1, 2), (.scrapCrawler, 6, 2), (.boltSpitter, 3, 2),
                     (.foundrySpawner, 4, 0), (.springLeaper, 5, 4), (.gearSplitter, 2, 4)],
           spawns: [(2, 7), (4, 7), (6, 7)]),

        // 2 — protectStructure (boiler)
        r5(2, "The Last Boiler",
           "One boiler still feeds the Vanguard's heat-lances. Lose it and the cold finishes what the machines started. Keep it burning.",
           obj: .protectStructure, bonus: .finishUnder(turns: 7),
           map: ["........",
                 "..P..P..",
                 "........",
                 "...OO...",
                 "........",
                 "........",
                 "........",
                 "........"],
           enemies: [(.ironHusk, 1, 1), (.ironHusk, 6, 1), (.boltSpitter, 4, 0),
                     (.beamSentry, 2, 0), (.springLeaper, 5, 2)],
           structures: [(.boiler, 4, 5)],
           spawns: [(1, 7), (3, 7), (6, 7)]),

        // 3 — defeatAll
        r5(3, "Crumbling Span",
           "The viaduct over the slag pits is failing tile by tile. Pick your footing or join the molten dead below.",
           obj: .defeatAll, bonus: .noDamage,
           map: ["........",
                 "..CC.C..",
                 "...PP...",
                 ".C....C.",
                 "...PP...",
                 "..C..C..",
                 "........",
                 "........"],
           enemies: [(.boltSpitter, 1, 1), (.boltSpitter, 6, 1), (.mortarHulk, 3, 0),
                     (.springLeaper, 5, 3), (.gearSplitter, 2, 3)],
           spawns: [(2, 7), (4, 7), (6, 7)]),

        // 4 — defeatAll
        r5(4, "Conveyor of the Damned",
           "The reclamation belts never stopped turning. They will carry the unwary straight into the rendering pits — turn that against the horde.",
           obj: .defeatAll, bonus: .hazardKills(3),
           map: ["........",
                 "..>>>...",
                 "...P....",
                 ".<<<....",
                 "....P...",
                 "..vv....",
                 "........",
                 "........"],
           enemies: [(.ironHusk, 6, 0), (.boltSpitter, 5, 1), (.gearSplitter, 6, 3),
                     (.beamSentry, 0, 2), (.rustBurrower, 4, 3), (.springLeaper, 5, 4)],
           spawns: [(1, 7), (4, 7), (6, 7)]),

        // 5 — escort (convoy + exit near top)
        r5(5, "Run to the Citadel",
           "The wounded and the war-records must reach the citadel gate before the machines close the road. Shepherd the convoy north through the rust.",
           obj: .escort, bonus: .finishUnder(turns: 9),
           map: ["........",
                 "...V....",
                 "..O.....",
                 ".....P..",
                 "...V....",
                 "..O.....",
                 "........",
                 "........"],
           enemies: [(.boltSpitter, 1, 1), (.boltSpitter, 6, 2), (.ironHusk, 5, 1),
                     (.springLeaper, 6, 4), (.gearSplitter, 1, 4)],
           structures: [(.convoy, 4, 7)],
           spawns: [(2, 7), (3, 6), (6, 7)],
           exit: (4, 0)),

        // 6 — defeatAll
        r5(6, "The Vapor Tyrant",
           "A great war-engine drags a shroud of boiling vapor between the smelters. Bring it down before the citadel walls come into range.",
           obj: .defeatAll, bonus: .finishUnder(turns: 8),
           map: ["........",
                 "..V..V..",
                 "........",
                 "...PP...",
                 "........",
                 ".V....V.",
                 "........",
                 "........"],
           enemies: [(.vaporTyrant, 4, 1), (.boltSpitter, 1, 2), (.boltSpitter, 6, 2),
                     (.cogMender, 3, 2), (.beamSentry, 5, 0)],
           spawns: [(1, 7), (4, 7), (6, 7)]),

        // 7 — FINALE boss (chronoArchon + support)
        r5(7, "The Reckoning",
           "It wears the Chronoforge's last heart and remembers every war ever fought. Here, beneath the broken clock, the Vanguard ends the uprising — or the age of men.",
           obj: .defeatAll, bonus: .noDamage,
           map: ["........",
                 "..V..V..",
                 "........",
                 "..P..P..",
                 "........",
                 "...OO...",
                 "........",
                 "........"],
           enemies: [(.chronoArchon, 4, 1), (.cogMender, 2, 2), (.beamSentry, 6, 0),
                     (.mortarHulk, 1, 0), (.springLeaper, 5, 4)],
           spawns: [(1, 7), (4, 7), (6, 7)]),
    ]
}
