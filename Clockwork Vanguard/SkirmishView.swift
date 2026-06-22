import SwiftUI

// MARK: - Skirmish hub
//
// Entry point for the two procedural modes. The player assembles a squad, then
// deploys into either the date-seeded Daily Operation or the escalating Endless
// Gauntlet. Both reuse the live BattleEngine through BattleContext.skirmish.

struct SkirmishView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode

    @State private var selected: [UnitClassID] = []
    @State private var launch: SkirmishMode? = nil

    private var todayKey: Int { SkirmishGenerator.dayKey(for: Date()) }
    private var dailyDone: Bool { store.dailyDone(dayKey: todayKey) }

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    ScreenHeader("Skirmish", subtitle: "Procedural battles for endless salvage",
                                 onBack: { presentationMode.wrappedValue.dismiss() })
                        .frame(width: contentWidth)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            dailyCard
                            endlessCard
                            squadSection
                            Spacer(minLength: 12)
                        }
                        .frame(width: contentWidth)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: prefill)
        .fullScreenCover(item: $launch) { mode in
            SkirmishBattleHost(mode: mode, squad: selected)
                .environmentObject(store)
        }
    }

    private func prefill() {
        guard selected.isEmpty else { return }
        var squad = store.lastSquad
        for id in UnitClassID.allCases where squad.count < 3 {
            if store.unitUnlocked(id) && !squad.contains(id) { squad.append(id) }
        }
        selected = Array(squad.prefix(3))
    }

    private var canDeploy: Bool { selected.count == 3 }

    private func deploy(_ mode: SkirmishMode) {
        guard canDeploy else { return }
        store.heavyFeedback()
        store.rememberSquad(selected)
        launch = mode
    }

    // MARK: Cards

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                CogStarShape().fill(Theme.warning).frame(width: 22, height: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Operation")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(Theme.ivory)
                    Text(dailyDone ? "Completed today — resets tomorrow" : "One fixed battle, the same for everyone today")
                        .font(.system(size: 11))
                        .foregroundColor(dailyDone ? Theme.good : Theme.ivoryDim)
                }
                Spacer()
            }
            Text("Completed: \(store.skirmish.dailyCompletions)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.ivoryDim)
            Button(action: { deploy(.daily(dayKey: todayKey)) }) {
                Text(dailyDone ? "Replay Daily" : "Deploy — Daily")
                    .font(.system(size: 15, weight: .bold, design: .serif))
            }
            .buttonStyle(BrassButtonStyle(prominent: !dailyDone, disabledLook: !canDeploy))
            .disabled(!canDeploy)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelBackground())
    }

    private var endlessCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                GearIcon(size: 22, color: Theme.patina)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Endless Gauntlet")
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(Theme.ivory)
                    Text("Push as deep as you can — each depth escalates")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.ivoryDim)
                }
                Spacer()
            }
            Text("Best depth reached: \(store.skirmish.bestEndlessDepth)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.warning)
            Button(action: { deploy(.endless(depth: 1)) }) {
                Text("Deploy — Gauntlet")
                    .font(.system(size: 15, weight: .bold, design: .serif))
            }
            .buttonStyle(BrassButtonStyle(prominent: true, disabledLook: !canDeploy))
            .disabled(!canDeploy)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelBackground())
    }

    private var squadSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Squad")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(Theme.brass)
                Spacer()
                Text(canDeploy ? "Ready" : "Pick \(3 - selected.count) more")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(canDeploy ? Theme.good : Theme.ivoryDim)
            }
            let cols = [GridItem(.adaptive(minimum: 92), spacing: 8)]
            LazyVGrid(columns: cols, spacing: 8) {
                ForEach(GameContent.unitClasses, id: \.id) { def in
                    unitChip(def)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelBackground())
    }

    private func unitChip(_ def: UnitClassDef) -> some View {
        let unlocked = store.unitUnlocked(def.id)
        let picked = selected.contains(def.id)
        return Button(action: {
            guard unlocked else { return }
            store.tapFeedback()
            if picked { selected.removeAll { $0 == def.id } }
            else if selected.count < 3 { selected.append(def.id) }
        }) {
            VStack(spacing: 5) {
                UnitGlyph(classId: def.id, size: 24, color: picked ? Theme.patina : (unlocked ? Theme.brass : Theme.ivoryDim))
                Text(def.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(unlocked ? Theme.ivory : Theme.ivoryDim)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(PanelBackground(corner: 10,
                        stroke: picked ? Theme.patina : Theme.brassDim.opacity(0.5)))
            .opacity(unlocked ? 1 : 0.5)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!unlocked)
    }
}

// MARK: - Battle host (drives depth progression / retries)

struct SkirmishBattleHost: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode
    let mode: SkirmishMode
    let squad: [UnitClassID]

    @State private var depth: Int
    @State private var attempt = 0

    init(mode: SkirmishMode, squad: [UnitClassID]) {
        self.mode = mode
        self.squad = squad
        switch mode {
        case .daily: _depth = State(initialValue: 4)
        case .endless(let d): _depth = State(initialValue: max(1, d))
        }
    }

    private var battle: SkirmishBattle {
        switch mode {
        case .daily(let key): return SkirmishGenerator.make(.daily(dayKey: key))
        case .endless: return SkirmishGenerator.make(.endless(depth: depth))
        }
    }

    var body: some View {
        let b = battle
        BattleSessionView(
            mission: b.mission,
            squad: squad,
            upgrades: store.allUpgrades,
            modifiers: store.activeModifiers,
            context: .skirmish(b),
            onExit: { presentationMode.wrappedValue.dismiss() },
            onRetry: { attempt += 1 },
            onSkirmishAdvance: mode.isDaily ? nil : { depth += 1; attempt += 1 }
        )
        .id("\(depth)-\(attempt)")
        .environmentObject(store)
    }
}

// MARK: - Skirmish result overlay

struct SkirmishResultOverlay: View {
    @ObservedObject var engine: BattleEngine
    let battle: SkirmishBattle
    let reward: ProgressStore.SkirmishReward?
    let onAdvance: (() -> Void)?
    let onExit: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).edgesIgnoringSafeArea(.all)
            if let outcome = engine.outcome {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if outcome.victory {
                            CogStarShape().fill(Theme.warning).frame(width: 50, height: 50)
                        } else {
                            HuskShape().fill(Theme.danger, style: FillStyle(eoFill: true))
                                .frame(width: 50, height: 50)
                        }
                        Text(title(outcome.victory))
                            .font(.system(size: 23, weight: .heavy, design: .serif))
                            .foregroundColor(outcome.victory ? Theme.brass : Theme.danger)
                        Text(subtitle(outcome.victory))
                            .font(.system(size: 13))
                            .foregroundColor(Theme.ivory.opacity(0.85))
                            .multilineTextAlignment(.center)

                        if outcome.victory, let r = reward, r.coresEarned > 0 {
                            HStack(spacing: 8) {
                                GearIcon(size: 18, color: Theme.patina)
                                Text("+\(r.coresEarned) cores salvaged")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Theme.patina)
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
                            if outcome.victory, let advance = onAdvance {
                                Button(action: advance) {
                                    Text("Advance to Depth \(battle.depth + 1)")
                                        .font(.system(size: 16, weight: .bold, design: .serif))
                                }
                                .buttonStyle(BrassButtonStyle(prominent: true))
                                Button(action: onExit) {
                                    Text("Retire to Vanguard")
                                        .font(.system(size: 15, weight: .bold, design: .serif))
                                }
                                .buttonStyle(BrassButtonStyle())
                            } else {
                                Button(action: onExit) {
                                    Text("Return")
                                        .font(.system(size: 16, weight: .bold, design: .serif))
                                }
                                .buttonStyle(BrassButtonStyle(prominent: true))
                                Button(action: onRetry) {
                                    Text("Retry Battle")
                                        .font(.system(size: 15, weight: .bold, design: .serif))
                                }
                                .buttonStyle(BrassButtonStyle())
                            }
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

    private func title(_ victory: Bool) -> String {
        if battle.isDaily { return victory ? "Operation Complete" : "Operation Failed" }
        return victory ? "Depth \(battle.depth) Cleared" : "Gauntlet Ended"
    }

    private func subtitle(_ victory: Bool) -> String {
        if victory {
            return battle.isDaily
                ? "Today's contract is fulfilled. Return tomorrow for a fresh deployment."
                : "The line holds. Press deeper for richer salvage, or retire to bank your cores."
        } else {
            return battle.isDaily
                ? "The operation was lost. You may retry today's battle."
                : "You fell at depth \(battle.depth). Regroup and run the gauntlet again."
        }
    }
}
