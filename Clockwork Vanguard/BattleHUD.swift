import SwiftUI

// MARK: - Top bar: turn, objective, forfeit

struct BattleTopBar: View {
    @ObservedObject var engine: BattleEngine
    let onForfeit: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onForfeit) {
                ChevronGlyph(pointing: .left)
                    .stroke(Theme.brass, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .frame(width: 10, height: 16)
                    .padding(9)
                    .background(Circle().fill(Theme.bgRaised))
                    .overlay(Circle().strokeBorder(Theme.brassDim, lineWidth: 1))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(engine.mission.name)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(Theme.ivory)
                    .lineLimit(1)
                Text(objectiveLine)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.ivoryDim)
                    .lineLimit(1)
            }
            Spacer()
            VStack(spacing: 1) {
                Text("TURN")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(Theme.brass)
                Text(turnText)
                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                    .foregroundColor(Theme.ivory)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgRaised))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.brassDim, lineWidth: 1))
        }
    }

    private var turnText: String {
        if case .survive(let t) = engine.mission.objective {
            return "\(min(engine.turn, t)) / \(t)"
        }
        return "\(engine.turn)"
    }

    private var objectiveLine: String {
        var line = engine.mission.objective.title
        if case .protectStructure = engine.mission.objective,
           let boiler = engine.entities.first(where: { $0.structureKind == .boiler }) {
            line += boiler.alive ? "  (boiler \(boiler.hp)/\(boiler.maxHp))" : ""
        }
        return line
    }
}

// MARK: - Contextual info panel

struct BattleInfoPanel: View {
    @ObservedObject var engine: BattleEngine
    let selectedId: Int?
    let inspectId: Int?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 6) {
                if let id = inspectId, let idx = engine.entityIndex(id: id) {
                    entityInfo(engine.entities[idx])
                } else if let id = selectedId, let idx = engine.entityIndex(id: id) {
                    unitInfo(engine.entities[idx])
                } else {
                    defaultInfo
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .background(PanelBackground(corner: 10))
    }

    private var defaultInfo: some View {
        VStack(alignment: .leading, spacing: 5) {
            labelRow(color: Theme.patina, text: "Tap a unit to command it. Tap an enemy to read its intent.")
            labelRow(color: Theme.warning, text: "Bonus: \(engine.mission.bonus.title)")
            labelRow(color: Theme.danger, text: "Marked tiles are next turn's enemy strikes.")
            HStack(spacing: 10) {
                statChip("Units \(engine.playerUnits.count)")
                statChip("Enemies \(engine.enemyMachines.count)")
                statChip("Plots \(engine.telegraphs.count)")
            }
            .padding(.top, 2)
        }
    }

    private func unitInfo(_ e: Entity) -> some View {
        let def = GameContent.unitDef(e.classId!)
        return VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                UnitGlyph(classId: e.classId!, size: 20)
                Text(def.name)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(Theme.ivory)
                Spacer()
                statChip("HP \(e.hp)/\(e.maxHp)")
                statChip("DMG \(e.damage)")
                statChip("MOVE \(e.moveRange)")
            }
            Text("\(def.attackName): \(def.attackDesc)")
                .font(.system(size: 11)).foregroundColor(Theme.ivoryDim)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(def.abilityName): \(def.abilityDesc)\(e.cooldown > 0 ? "  (ready in \(e.cooldown))" : "")")
                .font(.system(size: 11))
                .foregroundColor(e.cooldown > 0 ? Theme.ivoryDim.opacity(0.7) : Theme.warning.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            if e.moved || e.acted {
                Text(e.acted ? "This unit has acted this turn." : "Already moved - it can still attack or use its ability.")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.patina)
            }
            if e.rootedTurns > 0 {
                Text("Snared: cannot move this turn.")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.danger)
            }
        }
    }

    private func entityInfo(_ e: Entity) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                if let kind = e.enemyKind {
                    EnemyGlyph(kind: kind, size: 20)
                } else if let s = e.structureKind {
                    StructureGlyph(kind: s, size: 20)
                }
                Text(e.name)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(e.team == .enemy ? Theme.danger : Theme.ivory)
                Spacer()
                statChip("HP \(e.hp)/\(e.maxHp)")
                if e.armor > 0 { statChip("ARMOR \(e.armor)") }
                if e.hasShield { statChip(e.shieldUp ? "SHIELD UP" : "SHIELD DOWN") }
            }
            if let kind = e.enemyKind {
                Text(GameContent.enemyDef(kind).summary)
                    .font(.system(size: 11)).foregroundColor(Theme.ivoryDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let intent = engine.intentDescription(for: e.id) {
                labelRow(color: Theme.danger, text: "Intent: \(intent) - strikes when you end your turn.")
            } else if e.isEnemyMachine {
                labelRow(color: Theme.patina, text: "No attack planned this turn.")
            }
            if let s = e.structureKind {
                switch s {
                case .boiler: labelRow(color: Theme.copper, text: "Friendly structure. If it falls, the mission fails.")
                case .convoy: labelRow(color: Theme.copper, text: "Moves one tile toward the exit each turn. Keep its path clear and its hull intact.")
                case .foundryCore: labelRow(color: Theme.warning, text: "Destroy every core to win.")
                }
            }
        }
    }

    private func labelRow(color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6).padding(.top, 4)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(Theme.ivory.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func statChip(_ s: String) -> some View {
        Text(s)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(Theme.ivory)
            .padding(.vertical, 3).padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 5).fill(Theme.bgDeep))
    }
}

// MARK: - Action bar

struct BattleActionBar: View {
    @ObservedObject var engine: BattleEngine
    let selectedId: Int?
    let mode: BattleSessionView.ActionMode
    let onMode: (BattleSessionView.ActionMode) -> Void
    let onEndTurn: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            actionButton("Move", active: mode == .move, enabled: canMove, tint: Theme.patina) {
                onMode(.move)
            }
            actionButton("Attack", active: mode == .attack, enabled: canAttack, tint: Theme.danger) {
                onMode(.attack)
            }
            actionButton(abilityLabel, active: mode == .ability, enabled: canAbility, tint: Theme.warning) {
                onMode(.ability)
            }
            Button(action: onEndTurn) {
                VStack(spacing: 2) {
                    Text("End Turn")
                        .font(.system(size: 13, weight: .heavy, design: .serif))
                    Text("resolve attacks")
                        .font(.system(size: 8, weight: .medium))
                        .opacity(0.7)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 9).fill(Theme.brass))
                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Theme.ivory.opacity(0.4), lineWidth: 1))
                .foregroundColor(Theme.bgDeep)
            }
        }
    }

    private var selectedUnit: Entity? {
        guard let id = selectedId, let idx = engine.entityIndex(id: id) else { return nil }
        let e = engine.entities[idx]
        return e.isUnit ? e : nil
    }

    private var canMove: Bool {
        guard let e = selectedUnit else { return false }
        return !e.moved && !e.acted && e.rootedTurns == 0 && !engine.moveCells(for: e.id).isEmpty
    }

    private var canAttack: Bool {
        guard let e = selectedUnit else { return false }
        return !e.acted && !engine.attackCells(for: e.id).isEmpty
    }

    private var canAbility: Bool {
        guard let e = selectedUnit else { return false }
        return engine.abilityReady(unitId: e.id) && !engine.abilityCells(for: e.id).isEmpty
    }

    private var abilityLabel: String {
        guard let e = selectedUnit else { return "Ability" }
        if e.cooldown > 0 { return "Recharge (\(e.cooldown))" }
        return GameContent.unitDef(e.classId!).abilityName
    }

    private func actionButton(_ title: String, active: Bool, enabled: Bool, tint: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 9).fill(active ? tint.opacity(0.35) : Theme.bgRaised))
                .overlay(RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(active ? tint : Theme.brassDim.opacity(0.7), lineWidth: active ? 1.6 : 1))
                .foregroundColor(enabled ? Theme.ivory : Theme.ivoryDim.opacity(0.5))
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
    }
}

// MARK: - Result overlay

struct BattleResultOverlay: View {
    @ObservedObject var engine: BattleEngine
    let reward: ProgressStore.BattleReward?
    let onContinue: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).edgesIgnoringSafeArea(.all)
            if let outcome = engine.outcome {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if outcome.victory {
                            CogStarShape().fill(Theme.warning).frame(width: 54, height: 54)
                        } else {
                            HuskShape()
                                .fill(Theme.danger, style: FillStyle(eoFill: true))
                                .frame(width: 54, height: 54)
                        }
                        Text(outcome.victory ? "Mission Complete" : "Mission Failed")
                            .font(.system(size: 24, weight: .heavy, design: .serif))
                            .foregroundColor(outcome.victory ? Theme.brass : Theme.danger)
                        Text(outcome.reason)
                            .font(.system(size: 13))
                            .foregroundColor(Theme.ivory.opacity(0.85))
                            .multilineTextAlignment(.center)

                        if outcome.victory {
                            StarRow(earned: outcome.stars, total: 3, size: 26)
                            VStack(spacing: 6) {
                                resultLine(done: true, text: "Primary objective complete")
                                resultLine(done: outcome.bonusDone, text: engine.mission.bonus.title)
                                resultLine(done: outcome.noUnitLost, text: "No unit destroyed")
                            }
                            .padding(12)
                            .background(PanelBackground(corner: 10))

                            if let r = reward, r.coresEarned > 0 {
                                HStack(spacing: 8) {
                                    GearIcon(size: 18, color: Theme.patina)
                                    Text("+\(r.coresEarned) cores salvaged")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Theme.patina)
                                }
                            }
                        }

                        if let r = reward, !r.newAchievements.isEmpty {
                            VStack(spacing: 5) {
                                ForEach(r.newAchievements) { a in
                                    HStack(spacing: 8) {
                                        CogStarShape().fill(Theme.warning).frame(width: 14, height: 14)
                                        Text("Achievement: \(a.name)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Theme.warning)
                                    }
                                }
                            }
                        }

                        VStack(spacing: 10) {
                            Button(action: onContinue) {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .bold, design: .serif))
                            }
                            .buttonStyle(BrassButtonStyle(prominent: true))
                            Button(action: onRetry) {
                                Text(outcome.victory ? "Replay Mission" : "Retry Mission")
                                    .font(.system(size: 16, weight: .bold, design: .serif))
                            }
                            .buttonStyle(BrassButtonStyle())
                        }
                        .padding(.top, 4)
                    }
                    .padding(22)
                    .frame(maxWidth: 380)
                    .background(PanelBackground(corner: 16, stroke: Theme.brass.opacity(0.6)))
                    .padding(24)
                }
                .frame(maxWidth: 440)
            }
        }
    }

    private func resultLine(done: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            if done {
                CheckGlyph()
                    .stroke(Theme.good, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 13, height: 11)
            } else {
                CrossGlyph()
                    .stroke(Theme.danger.opacity(0.8), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    .frame(width: 11, height: 11)
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(done ? Theme.ivory : Theme.ivoryDim)
            Spacer()
        }
    }
}

struct CrossGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}
