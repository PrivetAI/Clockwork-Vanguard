import Foundation
import SwiftUI

// MARK: - Battle entities

enum Team { case player, enemy }

struct Entity: Identifiable {
    let id: Int
    var team: Team
    var classId: UnitClassID? = nil
    var enemyKind: EnemyKind? = nil
    var structureKind: StructureKind? = nil
    var name: String
    var hp: Int
    var maxHp: Int
    var damage: Int = 0
    var armor: Int = 0
    var hasShield: Bool = false
    var shieldUp: Bool = false
    var pos: Coord
    var moveRange: Int = 0
    var moved: Bool = false
    var acted: Bool = false
    var cooldown: Int = 0
    var rootedTurns: Int = 0
    var burrowed: Bool = false
    var spawnTick: Int = 0
    var alive: Bool = true

    var isStructure: Bool { structureKind != nil }
    var isUnit: Bool { classId != nil }
    var isEnemyMachine: Bool { team == .enemy && structureKind == nil }
    var blocks: Bool { alive && !burrowed }
}

// MARK: - Telegraphs

struct Telegraph: Identifiable {
    enum Kind {
        case directional(Dir, range: Int, pierce: Bool, push: Int)
        case absolute([Coord])
        case selfBlast
        case heal(targetId: Int)
        case spawn(Coord, EnemyKind)
    }
    let id: Int
    let attackerId: Int
    let kind: Kind
    let damage: Int
    let roots: Bool
}

enum TelegraphMark { case strike, blast, spawn, heal }

enum DamageSource {
    case unit(Int)
    case enemy(Int)
    case hazard
    case trap
    case collision
    case selfDestruct
}

struct BattleOutcome: Equatable {
    let victory: Bool
    let reason: String
    let stars: Int
    let bonusDone: Bool
    let noUnitLost: Bool
    let turnsUsed: Int
}

// MARK: - Engine

final class BattleEngine: ObservableObject {

    let mission: MissionDef
    let squad: [UnitClassID]
    let upgrades: [UnitClassID: UnitUpgrades]

    @Published var tiles: [[Tile]]
    @Published var entities: [Entity] = []
    @Published var telegraphs: [Telegraph] = []
    @Published var turn: Int = 1
    @Published var outcome: BattleOutcome? = nil
    @Published var eventCounter: Int = 0   // bumped to ping the UI for effects

    var battleStats = CampaignStats()
    var encountered = Set<String>()
    private(set) var damageTakenByPlayer = false
    private(set) var unitLostThisBattle = false
    private var nextId = 1
    private var nextTeleId = 1

    // MARK: Init

    init(mission: MissionDef, squad: [UnitClassID], upgrades: [UnitClassID: UnitUpgrades]) {
        self.mission = mission
        self.squad = squad
        self.upgrades = upgrades

        var grid: [[Tile]] = []
        for y in 0..<Coord.boardSize {
            var row: [Tile] = []
            let chars = Array(mission.map.indices.contains(y) ? mission.map[y] : "........")
            for x in 0..<Coord.boardSize {
                row.append(Tile.from(char: x < chars.count ? chars[x] : "."))
            }
            grid.append(row)
        }
        tiles = grid

        // Player squad
        for (i, classId) in squad.enumerated() where i < mission.playerSpawns.count {
            let def = GameContent.unitDef(classId)
            let up = upgrades[classId] ?? UnitUpgrades()
            let hp = def.baseHP + up.hpTier * 2
            var spawn = mission.playerSpawns[i]
            if !tileAt(spawn).walkable { spawn = firstFreeCell(near: spawn) ?? spawn }
            entities.append(Entity(
                id: takeId(), team: .player, classId: classId, name: def.name,
                hp: hp, maxHp: hp, damage: def.baseDamage + up.dmgTier,
                pos: spawn, moveRange: def.move
            ))
        }

        // Structures
        for (kind, pos) in mission.structures {
            let team: Team = (kind == .foundryCore) ? .enemy : .player
            entities.append(Entity(
                id: takeId(), team: team, structureKind: kind, name: kind.name,
                hp: kind.hp, maxHp: kind.hp, pos: pos
            ))
        }

        // Enemies
        for (kind, pos) in mission.enemies {
            spawnEnemy(kind, at: pos)
        }

        battleStats.battlesFought = 1
        planEnemyActions()
    }

    private func takeId() -> Int { defer { nextId += 1 }; return nextId }

    @discardableResult
    private func spawnEnemy(_ kind: EnemyKind, at pos: Coord) -> Int {
        let def = GameContent.enemyDef(kind)
        let r = mission.region
        let bonusHP = kind.isBoss ? r : (r + 1) / 2
        let bonusDmg = (!kind.isBoss && r >= 3) ? 1 : 0
        let hp = def.hp + bonusHP
        let id = takeId()
        entities.append(Entity(
            id: id, team: .enemy, enemyKind: kind, name: def.name,
            hp: hp, maxHp: hp, damage: def.damage + bonusDmg, armor: def.armor,
            hasShield: def.shielded, shieldUp: def.shielded,
            pos: pos, moveRange: def.move
        ))
        encountered.insert(kind.rawValue)
        return id
    }

    private func firstFreeCell(near c: Coord) -> Coord? {
        for radius in 1...3 {
            for y in (c.y - radius)...(c.y + radius) {
                for x in (c.x - radius)...(c.x + radius) {
                    let p = Coord(x: x, y: y)
                    if p.inBounds && tileAt(p).walkable && entityAt(p) == nil { return p }
                }
            }
        }
        return nil
    }

    // MARK: Lookups

    func tileAt(_ c: Coord) -> Tile { tiles[c.y][c.x] }

    func entityAt(_ c: Coord) -> Entity? {
        entities.first { $0.alive && !$0.burrowed && $0.pos == c }
    }

    func entityIndex(id: Int) -> Int? {
        entities.firstIndex { $0.id == id && $0.alive }
    }

    var playerUnits: [Entity] { entities.filter { $0.alive && $0.isUnit } }
    var enemyMachines: [Entity] { entities.filter { $0.alive && $0.isEnemyMachine } }

    private var playerTargets: [Entity] {
        entities.filter { $0.alive && $0.team == .player && !$0.burrowed }
    }

    // MARK: Movement queries

    func moveCells(for unitId: Int) -> Set<Coord> {
        guard let idx = entityIndex(id: unitId) else { return [] }
        let e = entities[idx]
        guard e.isUnit, !e.moved, !e.acted, e.rootedTurns == 0 else { return [] }
        return reachable(from: e.pos, range: e.moveRange, team: e.team).destinations
    }

    struct ReachResult {
        var parents: [Coord: Coord] = [:]
        var destinations: Set<Coord> = []
    }

    /// BFS. Parents map covers every visited cell (for path reconstruction);
    /// destinations contains only cells the mover may stop on.
    private func reachable(from start: Coord, range: Int, team: Team) -> ReachResult {
        var result = ReachResult()
        var dist: [Coord: Int] = [start: 0]
        var queue: [Coord] = [start]
        while !queue.isEmpty {
            let cur = queue.removeFirst()
            let d = dist[cur] ?? 0
            if d >= range { continue }
            for n in cur.neighbors.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }) {
                guard dist[n] == nil, tiles[n.y][n.x].walkable else { continue }
                if let blocker = entityAt(n) {
                    // can pass through same-team entities only
                    if blocker.team != team || blocker.isStructure { continue }
                }
                dist[n] = d + 1
                result.parents[n] = cur
                queue.append(n)
                if entityAt(n) == nil { result.destinations.insert(n) }
            }
        }
        return result
    }

    private func path(to dest: Coord, parents: [Coord: Coord], start: Coord) -> [Coord] {
        var path: [Coord] = [dest]
        var cur = dest
        while let p = parents[cur], p != start {
            path.append(p)
            cur = p
        }
        return path.reversed()
    }

    // MARK: Player actions

    func performMove(unitId: Int, to dest: Coord) {
        guard outcome == nil, let idx = entityIndex(id: unitId) else { return }
        let e = entities[idx]
        guard e.isUnit, !e.moved, !e.acted else { return }
        let reach = reachable(from: e.pos, range: e.moveRange, team: e.team)
        guard reach.destinations.contains(dest) else { return }
        let steps = path(to: dest, parents: reach.parents, start: e.pos)
        var from = e.pos
        for cell in steps {
            leaveTile(from)
            entities[idx].pos = cell
            from = cell
        }
        entities[idx].moved = true
        bump()
        checkOutcome()
    }

    func attackCells(for unitId: Int) -> Set<Coord> {
        guard let idx = entityIndex(id: unitId) else { return [] }
        let e = entities[idx]
        guard e.isUnit, !e.acted, let cls = e.classId else { return [] }
        switch cls {
        case .cogArcher:
            return lineTargets(from: e.pos, range: 4, hitEnemiesOnly: true)
        case .chronoTinker:
            return lineTargets(from: e.pos, range: 2, hitEnemiesOnly: true)
        default:
            return Set(e.pos.neighbors.filter { c in
                guard let t = entityAt(c) else { return false }
                return t.team == .enemy
            })
        }
    }

    private func lineTargets(from: Coord, range: Int, hitEnemiesOnly: Bool) -> Set<Coord> {
        var result = Set<Coord>()
        for dir in Dir.allCases {
            var c = from
            for _ in 0..<range {
                c = c.step(dir)
                guard c.inBounds else { break }
                if let t = entityAt(c) {
                    if t.team == .enemy || !hitEnemiesOnly { result.insert(c) }
                    break
                }
            }
        }
        return result
    }

    func performAttack(unitId: Int, at target: Coord) {
        guard outcome == nil, let idx = entityIndex(id: unitId) else { return }
        let e = entities[idx]
        guard e.isUnit, !e.acted, attackCells(for: unitId).contains(target) else { return }
        let dir = e.pos.dirTo(target) ?? .up
        let push: Int
        switch e.classId! {
        case .pistonKnight, .steamBulwark, .cogArcher: push = 1
        default: push = 0
        }
        strikeCell(target, damage: e.damage, source: .unit(e.id), pushDir: dir, push: push, roots: false)
        entities[idx].acted = true
        entities[idx].moved = true
        bump()
        checkOutcome()
    }

    // MARK: Abilities

    func abilityReady(unitId: Int) -> Bool {
        guard let idx = entityIndex(id: unitId) else { return false }
        let e = entities[idx]
        return e.isUnit && !e.acted && e.cooldown == 0
    }

    func abilityCells(for unitId: Int) -> Set<Coord> {
        guard abilityReady(unitId: unitId), let idx = entityIndex(id: unitId) else { return [] }
        let e = entities[idx]
        let tier = (upgrades[e.classId!] ?? UnitUpgrades()).abilityTier
        switch e.classId! {
        case .pistonKnight:
            return Set(e.pos.neighbors.filter { c in
                guard let t = entityAt(c) else { return false }
                return t.team == .enemy
            })
        case .cogArcher:
            var cells = Set<Coord>()
            for y in 0..<Coord.boardSize {
                for x in 0..<Coord.boardSize {
                    let c = Coord(x: x, y: y)
                    if c.manhattan(to: e.pos) <= 3 && c != e.pos && !tileAt(c).isPit { cells.insert(c) }
                }
            }
            return cells
        case .steamBulwark:
            // distance >= 2 so the drag actually moves the target (adjacent
            // targets would just collide into the Bulwark itself)
            return lineTargets(from: e.pos, range: 2 + tier, hitEnemiesOnly: false)
                .filter { entityAt($0)?.isStructure == false && $0.manhattan(to: e.pos) > 1 }
        case .gearSapper:
            return Set(e.pos.neighbors.filter { c in
                tileAt(c).walkable && entityAt(c) == nil && tileAt(c).trapDamage == nil
            })
        case .brassLancer:
            var cells = Set<Coord>()
            for dir in Dir.allCases {
                var c = e.pos
                for _ in 0..<4 {
                    c = c.step(dir)
                    guard c.inBounds, !tileAt(c).isPit else { break }
                    if let t = entityAt(c) {
                        if t.team == .enemy { cells.insert(c) }
                        break
                    }
                    cells.insert(c)
                }
            }
            return cells
        case .chronoTinker:
            let range = 3 + tier
            return Set(entities.filter {
                $0.alive && !$0.burrowed && !$0.isStructure && $0.id != e.id
                    && $0.pos.manhattan(to: e.pos) <= range
            }.map { $0.pos })
        }
    }

    func performAbility(unitId: Int, at target: Coord) {
        guard outcome == nil, let idx = entityIndex(id: unitId) else { return }
        let e = entities[idx]
        guard abilityCells(for: unitId).contains(target), let cls = e.classId else { return }
        let def = GameContent.unitDef(cls)
        let tier = (upgrades[cls] ?? UnitUpgrades()).abilityTier

        switch cls {
        case .pistonKnight:
            let dir = e.pos.dirTo(target) ?? .up
            strikeCell(target, damage: e.damage + 1, source: .unit(e.id), pushDir: dir, push: 2 + tier, roots: false)
        case .cogArcher:
            blastCell(target, damage: 2 + tier, source: .unit(e.id))
        case .steamBulwark:
            if let victim = entityAt(target), let dir = target.dirTo(e.pos) {
                if let vIdx = entityIndex(id: victim.id) {
                    displace(entityIdx: vIdx, dir: dir, distance: 1, source: .unit(e.id))
                }
            }
        case .gearSapper:
            tiles[target.y][target.x].trapDamage = 2 + tier
        case .brassLancer:
            let dir = e.pos.dirTo(target) ?? .up
            if let victim = entityAt(target) {
                // stop adjacent to the victim, strike hard
                var stop = e.pos
                var c = e.pos.step(dir)
                while c != target && c.inBounds {
                    stop = c
                    c = c.step(dir)
                }
                moveEntity(idx: idx, along: dashPath(from: e.pos, to: stop, dir: dir))
                if entities[idx].alive, let vIdx = entityIndex(id: victim.id) {
                    applyDamage(entityIdx: vIdx, amount: 3 + tier, source: .unit(e.id))
                    if let vIdx2 = entityIndex(id: victim.id) {
                        displace(entityIdx: vIdx2, dir: dir, distance: 1, source: .unit(e.id))
                    }
                }
            } else {
                moveEntity(idx: idx, along: dashPath(from: e.pos, to: target, dir: dir))
            }
        case .chronoTinker:
            if let other = entityAt(target), let oIdx = entityIndex(id: other.id) {
                let myPos = entities[idx].pos
                let otherPos = entities[oIdx].pos
                entities[idx].pos = otherPos
                entities[oIdx].pos = myPos
                // both tiles remain occupied after the swap, so crumbling
                // floors do not collapse (default leaveTile skips occupied)
                leaveTile(myPos)
                leaveTile(otherPos)
                enterTile(entityIdx: idx)
                if let oIdx2 = entityIndex(id: other.id) { enterTile(entityIdx: oIdx2) }
            }
        }
        if let idx2 = entityIndex(id: unitId) {
            entities[idx2].acted = true
            entities[idx2].moved = true
            entities[idx2].cooldown = def.abilityCooldown
        }
        bump()
        checkOutcome()
    }

    private func dashPath(from: Coord, to: Coord, dir: Dir) -> [Coord] {
        var cells: [Coord] = []
        var c = from
        while c != to {
            c = c.step(dir)
            guard c.inBounds else { break }
            cells.append(c)
            if c == to { break }
        }
        return cells
    }

    private func moveEntity(idx: Int, along cells: [Coord]) {
        var from = entities[idx].pos
        for cell in cells {
            guard entities[idx].alive else { return }
            leaveTile(from)
            entities[idx].pos = cell
            enterTile(entityIdx: idx)
            from = cell
        }
    }

    // MARK: Damage / displacement core

    private func strikeCell(_ c: Coord, damage: Int, source: DamageSource, pushDir: Dir, push: Int, roots: Bool) {
        igniteIfOil(c)
        collapseIfEmptyCrumbling(c)
        guard let victim = entityAt(c), let vIdx = entityIndex(id: victim.id) else { return }
        applyDamage(entityIdx: vIdx, amount: damage, source: source)
        if roots, let vIdx2 = entityIndex(id: victim.id) {
            entities[vIdx2].rootedTurns = 1
        }
        if push > 0, let vIdx3 = entityIndex(id: victim.id), !entities[vIdx3].isStructure {
            displace(entityIdx: vIdx3, dir: pushDir, distance: push, source: source)
        }
    }

    private func blastCell(_ c: Coord, damage: Int, source: DamageSource) {
        igniteIfOil(c)
        collapseIfEmptyCrumbling(c)
        if let victim = entityAt(c), let vIdx = entityIndex(id: victim.id) {
            applyDamage(entityIdx: vIdx, amount: damage, source: source)
        }
    }

    private func igniteIfOil(_ c: Coord) {
        if tiles[c.y][c.x].kind == .oil { tiles[c.y][c.x].onFire = true }
    }

    private func collapseIfEmptyCrumbling(_ c: Coord) {
        if tiles[c.y][c.x].kind == .crumbling && entityAt(c) == nil {
            tiles[c.y][c.x] = Tile(kind: .pit)
        }
    }

    private func leaveTile(_ c: Coord, skipIfOccupied: Bool = true) {
        if tiles[c.y][c.x].kind == .crumbling {
            if skipIfOccupied && entityAt(c) != nil { return }
            tiles[c.y][c.x] = Tile(kind: .pit)
        }
    }

    private func enterTile(entityIdx: Int) {
        let e = entities[entityIdx]
        guard e.alive else { return }
        let c = e.pos
        if let dmg = tiles[c.y][c.x].trapDamage, e.team == .enemy {
            tiles[c.y][c.x].trapDamage = nil
            applyDamage(entityIdx: entityIdx, amount: dmg, source: .trap)
        }
    }

    func displace(entityIdx: Int, dir: Dir, distance: Int, source: DamageSource) {
        guard entities[entityIdx].alive, !entities[entityIdx].isStructure else { return }
        for _ in 0..<distance {
            let cur = entities[entityIdx].pos
            let next = cur.step(dir)
            guard next.inBounds else { break }
            if tiles[next.y][next.x].isPit {
                leaveTile(cur)
                entities[entityIdx].pos = next
                killEntity(idx: entityIdx, source: .hazard, pitFall: true)
                return
            }
            if let blocker = entityAt(next) {
                battleStats.collisions += 1
                if let bIdx = entityIndex(id: blocker.id) {
                    applyDamage(entityIdx: bIdx, amount: 1, source: .collision)
                }
                applyDamage(entityIdx: entityIdx, amount: 1, source: .collision)
                break
            }
            leaveTile(cur)
            entities[entityIdx].pos = next
            enterTile(entityIdx: entityIdx)
            if !entities[entityIdx].alive { return }
        }
    }

    func applyDamage(entityIdx: Int, amount: Int, source: DamageSource) {
        guard entities[entityIdx].alive, amount > 0 else { return }
        if entities[entityIdx].shieldUp {
            entities[entityIdx].shieldUp = false
            return
        }
        let effective = max(1, amount - entities[entityIdx].armor)
        entities[entityIdx].hp -= effective
        if entities[entityIdx].team == .player {
            damageTakenByPlayer = true
        }
        if entities[entityIdx].hp <= 0 {
            killEntity(idx: entityIdx, source: source, pitFall: false)
        }
    }

    private func killEntity(idx: Int, source: DamageSource, pitFall: Bool) {
        guard entities[idx].alive else { return }
        entities[idx].alive = false
        entities[idx].hp = 0
        let e = entities[idx]

        if e.isUnit {
            unitLostThisBattle = true
            battleStats.unitsLost += 1
        } else if e.isEnemyMachine {
            battleStats.enemiesDestroyed += 1
            if e.enemyKind?.isBoss == true { battleStats.bossesDestroyed += 1 }
            switch source {
            case .hazard:
                battleStats.hazardKills += 1
                if pitFall { battleStats.pitKills += 1 }
            case .trap:
                battleStats.trapKills += 1
                battleStats.hazardKills += 1
            case .enemy, .collision:
                battleStats.redirectKills += 1
            default:
                break
            }
            // Splitter breaks apart
            if e.enemyKind == .gearSplitter && !pitFall {
                var spawned = 0
                for n in e.pos.neighbors.sorted(by: { ($0.y, $0.x) < ($1.y, $1.x) }) {
                    guard spawned < 2 else { break }
                    if tiles[n.y][n.x].walkable && entityAt(n) == nil && !tiles[n.y][n.x].isPit {
                        spawnEnemy(.scrapling, at: n)
                        spawned += 1
                    }
                }
            }
        }
        // cancel its telegraphs
        telegraphs.removeAll { $0.attackerId == e.id }
        bump()
    }

    // MARK: End of player turn

    func endPlayerTurn() {
        guard outcome == nil else { return }
        resolveTelegraphs()
        if outcome == nil { environmentPhase() }
        if outcome == nil { convoyPhase() }
        battleStats.turnsPlayed += 1
        if outcome == nil, case .survive(let t) = mission.objective, turn >= t {
            finish(victory: true, reason: "You held the line for \(t) turns.")
        }
        if outcome == nil {
            turn += 1
            planEnemyActions()
            for i in entities.indices where entities[i].isUnit && entities[i].alive {
                entities[i].moved = false
                entities[i].acted = false
                entities[i].cooldown = max(0, entities[i].cooldown - 1)
                entities[i].rootedTurns = max(0, entities[i].rootedTurns - 1)
            }
            checkOutcome()
        }
        bump()
    }

    // MARK: Telegraph resolution

    private func resolveTelegraphs() {
        let queue = telegraphs
        telegraphs = []
        for tele in queue {
            guard outcome == nil else { return }
            guard let aIdx = entityIndex(id: tele.attackerId), entities[aIdx].alive else { continue }
            switch tele.kind {
            case .directional(let dir, let range, let pierce, let push):
                resolveDirectional(attackerIdx: aIdx, dir: dir, range: range, pierce: pierce,
                                   push: push, damage: tele.damage, roots: tele.roots)
            case .absolute(let cells):
                if entities[aIdx].burrowed {
                    entities[aIdx].burrowed = false
                    // surfacing cell may have been occupied since planning
                    let p = entities[aIdx].pos
                    let selfId = entities[aIdx].id
                    if entities.contains(where: { $0.alive && !$0.burrowed && $0.id != selfId && $0.pos == p }) {
                        let free = p.neighbors.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
                            .first { tiles[$0.y][$0.x].walkable && entityAt($0) == nil }
                        if let f = free {
                            entities[aIdx].pos = f
                        } else {
                            entities[aIdx].burrowed = true
                            continue
                        }
                    }
                }
                for c in cells where c.inBounds {
                    blastCell(c, damage: tele.damage, source: .enemy(tele.attackerId))
                }
            case .selfBlast:
                let center = entities[aIdx].pos
                for c in center.neighbors {
                    blastCell(c, damage: tele.damage, source: .enemy(tele.attackerId))
                }
                killEntity(idx: aIdx, source: .selfDestruct, pitFall: false)
            case .heal(let targetId):
                if let tIdx = entityIndex(id: targetId), entities[tIdx].alive {
                    entities[tIdx].hp = min(entities[tIdx].maxHp, entities[tIdx].hp + tele.damage)
                }
            case .spawn(let cell, let kind):
                if cell.inBounds && tiles[cell.y][cell.x].walkable && entityAt(cell) == nil {
                    spawnEnemy(kind, at: cell)
                }
            }
            checkOutcome()
        }
    }

    private func resolveDirectional(attackerIdx: Int, dir: Dir, range: Int, pierce: Bool,
                                    push: Int, damage: Int, roots: Bool) {
        let origin = entities[attackerIdx].pos
        var c = origin
        var lastCell: Coord? = nil
        for _ in 0..<range {
            c = c.step(dir)
            guard c.inBounds else { break }
            lastCell = c
            if pierce {
                strikeCell(c, damage: damage, source: .enemy(entities[attackerIdx].id),
                           pushDir: dir, push: push, roots: roots)
            } else {
                if entityAt(c) != nil {
                    strikeCell(c, damage: damage, source: .enemy(entities[attackerIdx].id),
                               pushDir: dir, push: push, roots: roots)
                    return
                }
                if range == 1 {
                    strikeCell(c, damage: damage, source: .enemy(entities[attackerIdx].id),
                               pushDir: dir, push: push, roots: roots)
                    return
                }
            }
        }
        // projectile hit the ground at the end of its flight
        if !pierce, let land = lastCell {
            igniteIfOil(land)
            collapseIfEmptyCrumbling(land)
        }
    }

    // MARK: Environment phase

    private func environmentPhase() {
        // fire damage
        for i in entities.indices where entities[i].alive && !entities[i].burrowed {
            let p = entities[i].pos
            if tiles[p.y][p.x].onFire {
                applyDamage(entityIdx: i, amount: 1, source: .hazard)
            }
        }
        // fire spread
        var toIgnite: [Coord] = []
        for y in 0..<Coord.boardSize {
            for x in 0..<Coord.boardSize where tiles[y][x].onFire {
                for n in Coord(x: x, y: y).neighbors
                where tiles[n.y][n.x].kind == .oil && !tiles[n.y][n.x].onFire {
                    toIgnite.append(n)
                }
            }
        }
        for c in toIgnite { tiles[c.y][c.x].onFire = true }
        // vents
        for i in entities.indices where entities[i].alive && !entities[i].burrowed && !entities[i].isStructure {
            let p = entities[i].pos
            if tiles[p.y][p.x].kind == .vent {
                applyDamage(entityIdx: i, amount: 1, source: .hazard)
            }
        }
        // conveyors
        let riders = entities.filter { $0.alive && !$0.burrowed && !$0.isStructure }
            .sorted { $0.id < $1.id }
        for rider in riders {
            guard let idx = entityIndex(id: rider.id), entities[idx].alive else { continue }
            let p = entities[idx].pos
            if case .conveyor(let dir) = tiles[p.y][p.x].kind {
                displace(entityIdx: idx, dir: dir, distance: 1, source: .hazard)
            }
        }
        checkOutcome()
    }

    // MARK: Convoy phase (escort)

    private func convoyPhase() {
        guard mission.objective == .escort, let exit = mission.exitCell else { return }
        guard let idx = entities.firstIndex(where: { $0.alive && $0.structureKind == .convoy }) else { return }
        let pos = entities[idx].pos
        if pos == exit { return }
        var options: [Dir] = []
        if exit.y < pos.y { options.append(.up) }
        if exit.y > pos.y { options.append(.down) }
        if exit.x < pos.x { options.append(.left) }
        if exit.x > pos.x { options.append(.right) }
        for dir in options {
            let next = pos.step(dir)
            guard next.inBounds, tiles[next.y][next.x].walkable, !tiles[next.y][next.x].isPit,
                  entityAt(next) == nil else { continue }
            leaveTile(pos)
            entities[idx].pos = next
            break
        }
        if entities[idx].pos == exit {
            finish(victory: true, reason: "The supply crawler reached the exit.")
        }
    }

    // MARK: Enemy planning

    private func planEnemyActions() {
        telegraphs = []
        let enemies = entities.filter { $0.alive && $0.isEnemyMachine }.sorted { $0.id < $1.id }
        for enemy in enemies {
            guard let idx = entityIndex(id: enemy.id) else { continue }
            planFor(enemyIdx: idx)
            if entities[idx].alive {
                if entities[idx].hasShield { entities[idx].shieldUp = true }
                if entities[idx].rootedTurns > 0 {
                    entities[idx].rootedTurns -= 1
                }
            }
        }
    }

    private func addTelegraph(attacker: Int, kind: Telegraph.Kind, damage: Int, roots: Bool = false) {
        telegraphs.append(Telegraph(id: nextTeleId, attackerId: attacker, kind: kind, damage: damage, roots: roots))
        nextTeleId += 1
    }

    private func nearestPlayerTarget(to pos: Coord) -> Entity? {
        playerTargets.min { a, b in
            let da = a.pos.manhattan(to: pos), db = b.pos.manhattan(to: pos)
            return da == db ? a.id < b.id : da < db
        }
    }

    private func nearestPlayerUnit(to pos: Coord) -> Entity? {
        playerUnits.min { a, b in
            let da = a.pos.manhattan(to: pos), db = b.pos.manhattan(to: pos)
            return da == db ? a.id < b.id : da < db
        }
    }

    /// Move enemy toward a position; returns final position.
    @discardableResult
    private func aiMove(enemyIdx: Int, toward goal: Coord, idealDistance: Int = 1) -> Coord {
        let e = entities[enemyIdx]
        guard e.moveRange > 0, e.rootedTurns == 0 else { return e.pos }
        let reach = reachable(from: e.pos, range: e.moveRange, team: .enemy)
        var best = e.pos
        var bestScore = abs(e.pos.manhattan(to: goal) - idealDistance)
        let candidates = reach.destinations.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        for cell in candidates {
            // avoid stepping onto bad tiles when possible
            let t = tiles[cell.y][cell.x]
            var score = abs(cell.manhattan(to: goal) - idealDistance)
            if t.kind == .vent || t.onFire { score += 2 }
            if t.trapDamage != nil { score += 1 }
            if score < bestScore {
                bestScore = score
                best = cell
            }
        }
        if best != e.pos {
            let steps = path(to: best, parents: reach.parents, start: e.pos)
            moveEntity(idx: enemyIdx, along: steps)
        }
        return entities[enemyIdx].alive ? entities[enemyIdx].pos : e.pos
    }

    /// First player-team entity found scanning a direction; nil if an enemy blocks first.
    private func scanDir(from: Coord, dir: Dir, range: Int) -> (Entity, Int)? {
        var c = from
        for step in 1...range {
            c = c.step(dir)
            guard c.inBounds else { return nil }
            if let t = entityAt(c) {
                return t.team == .player ? (t, step) : nil
            }
        }
        return nil
    }

    private func planFor(enemyIdx: Int) {
        let e = entities[enemyIdx]
        guard let kind = e.enemyKind else { return }
        let def = GameContent.enemyDef(kind)

        switch def.behavior {
        case .melee(let push):
            meleePlan(enemyIdx: enemyIdx, push: push, damage: entities[enemyIdx].damage)

        case .ranged(let range):
            guard let target = nearestPlayerTarget(to: e.pos) else { return }
            aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 2)
            let pos = entities[enemyIdx].pos
            for dir in Dir.allCases {
                if scanDir(from: pos, dir: dir, range: range) != nil {
                    addTelegraph(attacker: e.id,
                                 kind: .directional(dir, range: range, pierce: false, push: 0),
                                 damage: entities[enemyIdx].damage)
                    return
                }
            }

        case .beam:
            let pos = e.pos
            for dir in Dir.allCases {
                if scanDir(from: pos, dir: dir, range: 7) != nil {
                    addTelegraph(attacker: e.id,
                                 kind: .directional(dir, range: 7, pierce: true, push: 0),
                                 damage: entities[enemyIdx].damage)
                    return
                }
            }

        case .spawner(let spawnKind, let every):
            entities[enemyIdx].spawnTick += 1
            if entities[enemyIdx].spawnTick >= every {
                entities[enemyIdx].spawnTick = 0
                let free = e.pos.neighbors.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
                    .first { tiles[$0.y][$0.x].walkable && entityAt($0) == nil }
                if let cell = free {
                    addTelegraph(attacker: e.id, kind: .spawn(cell, spawnKind), damage: 0)
                }
            }

        case .burrower:
            if entities[enemyIdx].burrowed {
                guard let target = nearestPlayerTarget(to: e.pos) else { return }
                // tunnel to a free cell adjacent to the target
                let dest = target.pos.neighbors.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
                    .first { tiles[$0.y][$0.x].walkable && entityAt($0) == nil }
                if let d = dest {
                    entities[enemyIdx].pos = d
                    addTelegraph(attacker: e.id, kind: .absolute([target.pos]),
                                 damage: entities[enemyIdx].damage)
                } else {
                    aiMove(enemyIdx: enemyIdx, toward: target.pos)
                }
            } else {
                entities[enemyIdx].burrowed = true
            }

        case .exploder:
            guard let target = nearestPlayerTarget(to: e.pos) else { return }
            aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 1)
            let pos = entities[enemyIdx].pos
            let adjacentToTarget = pos.neighbors.contains { c in
                entityAt(c)?.team == .player
            }
            if adjacentToTarget {
                addTelegraph(attacker: e.id, kind: .selfBlast, damage: entities[enemyIdx].damage)
            }

        case .healer(let amount):
            let wounded = enemyMachines
                .filter { $0.id != e.id && $0.hp < $0.maxHp }
                .min { a, b in
                    let ra = a.maxHp - a.hp, rb = b.maxHp - b.hp
                    return ra == rb ? a.id < b.id : ra > rb
                }
            if let patient = wounded {
                aiMove(enemyIdx: enemyIdx, toward: patient.pos, idealDistance: 1)
                if entities[enemyIdx].pos.manhattan(to: patient.pos) <= 2 {
                    addTelegraph(attacker: e.id, kind: .heal(targetId: patient.id), damage: amount)
                }
            } else if let target = nearestPlayerTarget(to: e.pos) {
                aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 3)
            }

        case .leaper(let range):
            guard let target = nearestPlayerTarget(to: e.pos) else { return }
            if e.rootedTurns == 0, e.pos.manhattan(to: target.pos) <= range + 1 {
                let dest = target.pos.neighbors.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
                    .first { tiles[$0.y][$0.x].walkable && entityAt($0) == nil }
                if let d = dest {
                    leaveTile(e.pos)
                    entities[enemyIdx].pos = d
                    enterTile(entityIdx: enemyIdx)
                }
            } else {
                aiMove(enemyIdx: enemyIdx, toward: target.pos)
            }
            guard entities[enemyIdx].alive else { return }
            meleeTelegraphIfAdjacent(enemyIdx: enemyIdx, push: 0)

        case .rooter(let range):
            guard let target = nearestPlayerTarget(to: e.pos) else { return }
            aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 2)
            let pos = entities[enemyIdx].pos
            for dir in Dir.allCases {
                if scanDir(from: pos, dir: dir, range: range) != nil {
                    addTelegraph(attacker: e.id,
                                 kind: .directional(dir, range: range, pierce: false, push: 0),
                                 damage: entities[enemyIdx].damage, roots: true)
                    return
                }
            }

        case .splitter:
            meleePlan(enemyIdx: enemyIdx, push: 0, damage: entities[enemyIdx].damage)

        case .artillery:
            guard let target = nearestPlayerUnit(to: e.pos) ?? nearestPlayerTarget(to: e.pos) else { return }
            aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 4)
            let t = target.pos
            let bx = min(max(0, t.x), Coord.boardSize - 2)
            let by = min(max(0, t.y), Coord.boardSize - 2)
            let cells = [Coord(x: bx, y: by), Coord(x: bx + 1, y: by),
                         Coord(x: bx, y: by + 1), Coord(x: bx + 1, y: by + 1)]
            addTelegraph(attacker: e.id, kind: .absolute(cells), damage: entities[enemyIdx].damage)

        case .bossFoundryKing:
            guard let target = nearestPlayerTarget(to: e.pos) else { return }
            aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 1)
            let pos = entities[enemyIdx].pos
            var slammed = false
            for dir in Dir.allCases {
                if scanDir(from: pos, dir: dir, range: 2) != nil {
                    addTelegraph(attacker: e.id,
                                 kind: .directional(dir, range: 2, pierce: true, push: 1),
                                 damage: entities[enemyIdx].damage)
                    slammed = true
                    break
                }
            }
            _ = slammed
            if entities[enemyIdx].hp <= entities[enemyIdx].maxHp / 2 {
                entities[enemyIdx].spawnTick += 1
                if entities[enemyIdx].spawnTick >= 2 {
                    entities[enemyIdx].spawnTick = 0
                    let free = pos.neighbors.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
                        .first { tiles[$0.y][$0.x].walkable && entityAt($0) == nil }
                    if let cell = free {
                        addTelegraph(attacker: e.id, kind: .spawn(cell, .scrapCrawler), damage: 0)
                    }
                }
            }

        case .bossVaporTyrant:
            guard let target = nearestPlayerTarget(to: e.pos) else { return }
            aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 3)
            let pos = entities[enemyIdx].pos
            for dir in Dir.allCases {
                if scanDir(from: pos, dir: dir, range: 7) != nil {
                    addTelegraph(attacker: e.id,
                                 kind: .directional(dir, range: 7, pierce: true, push: 0),
                                 damage: entities[enemyIdx].damage)
                    break
                }
            }
            if entities[enemyIdx].hp <= entities[enemyIdx].maxHp / 2 {
                addTelegraph(attacker: e.id, kind: .selfBlast, damage: 2)
            }

        case .bossCogColossus:
            guard let target = nearestPlayerUnit(to: e.pos) ?? nearestPlayerTarget(to: e.pos) else { return }
            aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 3)
            let pos = entities[enemyIdx].pos
            let phase2 = entities[enemyIdx].hp <= entities[enemyIdx].maxHp / 2
            if phase2 {
                for dir in Dir.allCases {
                    if scanDir(from: pos, dir: dir, range: 7) != nil {
                        addTelegraph(attacker: e.id,
                                     kind: .directional(dir, range: 7, pierce: true, push: 1),
                                     damage: entities[enemyIdx].damage + 1)
                        return
                    }
                }
            }
            let t = target.pos
            let bx = min(max(0, t.x), Coord.boardSize - 2)
            let by = min(max(0, t.y), Coord.boardSize - 2)
            let cells = [Coord(x: bx, y: by), Coord(x: bx + 1, y: by),
                         Coord(x: bx, y: by + 1), Coord(x: bx + 1, y: by + 1)]
            addTelegraph(attacker: e.id, kind: .absolute(cells), damage: entities[enemyIdx].damage)

        case .bossChronoArchon:
            guard let target = nearestPlayerUnit(to: e.pos) ?? nearestPlayerTarget(to: e.pos) else { return }
            aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 3)
            let pos = entities[enemyIdx].pos
            let phase2 = entities[enemyIdx].hp <= entities[enemyIdx].maxHp / 2
            if phase2 {
                let t = target.pos
                var cells = [t]
                cells.append(contentsOf: t.neighbors)
                addTelegraph(attacker: e.id, kind: .absolute(cells), damage: entities[enemyIdx].damage + 1)
            } else {
                for dir in Dir.allCases {
                    if scanDir(from: pos, dir: dir, range: 7) != nil {
                        addTelegraph(attacker: e.id,
                                     kind: .directional(dir, range: 7, pierce: true, push: 0),
                                     damage: entities[enemyIdx].damage)
                        return
                    }
                }
            }
        }
    }

    private func meleePlan(enemyIdx: Int, push: Int, damage: Int) {
        let e = entities[enemyIdx]
        guard let target = nearestPlayerTarget(to: e.pos) else { return }
        aiMove(enemyIdx: enemyIdx, toward: target.pos, idealDistance: 1)
        guard entities[enemyIdx].alive else { return }
        meleeTelegraphIfAdjacent(enemyIdx: enemyIdx, push: push)
    }

    private func meleeTelegraphIfAdjacent(enemyIdx: Int, push: Int) {
        let pos = entities[enemyIdx].pos
        for dir in Dir.allCases {
            let c = pos.step(dir)
            guard c.inBounds else { continue }
            if let t = entityAt(c), t.team == .player {
                addTelegraph(attacker: entities[enemyIdx].id,
                             kind: .directional(dir, range: 1, pierce: false, push: push),
                             damage: entities[enemyIdx].damage)
                return
            }
        }
    }

    // MARK: Telegraph display

    func telegraphMarks() -> [Coord: TelegraphMark] {
        var marks: [Coord: TelegraphMark] = [:]
        for tele in telegraphs {
            guard let aIdx = entityIndex(id: tele.attackerId) else { continue }
            let origin = entities[aIdx].pos
            switch tele.kind {
            case .directional(let dir, let range, let pierce, _):
                var c = origin
                for _ in 0..<range {
                    c = c.step(dir)
                    guard c.inBounds else { break }
                    marks[c] = .strike
                    if !pierce && entityAt(c) != nil { break }
                }
            case .absolute(let cells):
                for c in cells where c.inBounds { marks[c] = .blast }
            case .selfBlast:
                for c in origin.neighbors { marks[c] = .blast }
            case .heal(let targetId):
                if let tIdx = entityIndex(id: targetId) {
                    marks[entities[tIdx].pos] = .heal
                }
            case .spawn(let cell, _):
                marks[cell] = .spawn
            }
        }
        return marks
    }

    func intentDescription(for entityId: Int) -> String? {
        guard let tele = telegraphs.first(where: { $0.attackerId == entityId }) else { return nil }
        switch tele.kind {
        case .directional(_, _, let pierce, _):
            return pierce ? "Beam \(tele.damage)" : (tele.roots ? "Snare \(tele.damage)" : "Strike \(tele.damage)")
        case .absolute: return "Barrage \(tele.damage)"
        case .selfBlast: return "Detonate \(tele.damage)"
        case .heal: return "Repair \(tele.damage)"
        case .spawn: return "Assemble"
        }
    }

    // MARK: Outcome

    private func checkOutcome() {
        guard outcome == nil else { return }
        // global defeat: all player units destroyed
        if playerUnits.isEmpty {
            finish(victory: false, reason: "All Vanguard units were destroyed.")
            return
        }
        switch mission.objective {
        case .defeatAll:
            if enemyMachines.isEmpty {
                finish(victory: true, reason: "Every enemy machine lies in scrap.")
            }
        case .survive:
            if enemyMachines.isEmpty {
                finish(victory: true, reason: "Every enemy machine lies in scrap.")
            }
        case .protectStructure:
            if !entities.contains(where: { $0.alive && $0.structureKind == .boiler }) {
                finish(victory: false, reason: "The boiler was destroyed.")
            } else if enemyMachines.isEmpty {
                finish(victory: true, reason: "The boiler stands. The enemy does not.")
            }
        case .escort:
            if !entities.contains(where: { $0.alive && $0.structureKind == .convoy }) {
                finish(victory: false, reason: "The supply crawler was destroyed.")
            }
        case .destroyTargets:
            if !entities.contains(where: { $0.alive && $0.structureKind == .foundryCore }) {
                finish(victory: true, reason: "All foundry cores destroyed.")
            }
        }
    }

    private func finish(victory: Bool, reason: String) {
        guard outcome == nil else { return }
        var bonusDone = false
        if victory {
            switch mission.bonus {
            case .finishUnder(let t): bonusDone = turn <= t
            case .hazardKills(let n): bonusDone = battleStats.hazardKills >= n
            case .noDamage: bonusDone = !damageTakenByPlayer
            }
        }
        let noLoss = !unitLostThisBattle
        var stars = 0
        if victory {
            stars = 1 + (bonusDone ? 1 : 0) + (noLoss ? 1 : 0)
            battleStats.missionsWon = 1
            if bonusDone { battleStats.bonusObjectives = 1 }
        }
        outcome = BattleOutcome(victory: victory, reason: reason, stars: stars,
                                bonusDone: bonusDone, noUnitLost: noLoss, turnsUsed: turn)
        bump()
    }

    private func bump() { eventCounter += 1 }
}
