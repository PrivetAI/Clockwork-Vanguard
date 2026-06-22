import SwiftUI

// MARK: - Battle entry (recreates the session on retry)

struct BattleView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode
    let mission: MissionDef
    let squad: [UnitClassID]

    @State private var attempt = 0

    var body: some View {
        BattleSessionView(
            mission: mission,
            squad: squad,
            upgrades: store.allUpgrades,
            modifiers: store.activeModifiers,
            context: .campaign,
            onExit: { presentationMode.wrappedValue.dismiss() },
            onRetry: { attempt += 1 }
        )
        .id(attempt)
        .environmentObject(store)
    }
}

// MARK: - One battle session

struct BattleSessionView: View {
    @EnvironmentObject var store: ProgressStore
    @StateObject private var engine: BattleEngine
    let context: BattleContext
    let onExit: () -> Void
    let onRetry: () -> Void
    let onSkirmishAdvance: (() -> Void)?

    enum ActionMode { case none, move, attack, ability }

    @State private var selectedId: Int? = nil
    @State private var inspectId: Int? = nil
    @State private var mode: ActionMode = .none
    @State private var reward: ProgressStore.BattleReward? = nil
    @State private var skirmishReward: ProgressStore.SkirmishReward? = nil
    @State private var resultApplied = false
    @State private var showForfeit = false

    init(mission: MissionDef, squad: [UnitClassID], upgrades: [UnitClassID: UnitUpgrades],
         modifiers: BattleModifiers = .none, context: BattleContext = .campaign,
         onExit: @escaping () -> Void, onRetry: @escaping () -> Void,
         onSkirmishAdvance: (() -> Void)? = nil) {
        _engine = StateObject(wrappedValue: BattleEngine(mission: mission, squad: squad,
                                                         upgrades: upgrades, modifiers: modifiers))
        self.context = context
        self.onExit = onExit
        self.onRetry = onRetry
        self.onSkirmishAdvance = onSkirmishAdvance
    }

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            let h = geo.size.height
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                if w > h {
                    landscapeLayout(width: w, height: h)
                } else {
                    portraitLayout(width: w, height: h)
                }
                if engine.outcome != nil {
                    switch context {
                    case .campaign:
                        BattleResultOverlay(
                            engine: engine,
                            reward: reward,
                            onContinue: { store.tapFeedback(); onExit() },
                            onRetry: { store.tapFeedback(); onRetry() }
                        )
                    case .skirmish(let battle):
                        SkirmishResultOverlay(
                            engine: engine,
                            battle: battle,
                            reward: skirmishReward,
                            onAdvance: onSkirmishAdvance.map { adv in { store.tapFeedback(); adv() } },
                            onExit: { store.tapFeedback(); onExit() },
                            onRetry: { store.tapFeedback(); onRetry() }
                        )
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onChange(of: engine.outcome) { outcome in
            guard let outcome = outcome, !resultApplied else { return }
            resultApplied = true
            if outcome.victory { store.successFeedback() } else { store.failureFeedback() }
            switch context {
            case .campaign:
                reward = store.applyBattleResult(
                    mission: engine.mission, outcome: outcome,
                    battleStats: engine.battleStats, encountered: engine.encountered,
                    flawless: !engine.damageTakenByPlayer
                )
            case .skirmish(let battle):
                skirmishReward = store.applySkirmishResult(
                    victory: outcome.victory, baseCores: battle.baseCores,
                    isDaily: battle.isDaily, dayKey: battle.dayKey,
                    depth: battle.depth, battleStats: engine.battleStats,
                    encountered: engine.encountered
                )
            }
        }
        .alert(isPresented: $showForfeit) {
            Alert(
                title: Text("Abandon Mission?"),
                message: Text("Battle progress will be lost."),
                primaryButton: .destructive(Text("Abandon")) { onExit() },
                secondaryButton: .cancel(Text("Keep Fighting"))
            )
        }
    }

    // MARK: Layouts

    private func portraitLayout(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            BattleTopBar(engine: engine, onForfeit: { showForfeit = true })
                .padding(.horizontal, 12)
            let boardSide = min(width - 16, height * 0.52)
            board(side: boardSide)
            BattleInfoPanel(engine: engine, selectedId: selectedId, inspectId: inspectId)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
            BattleActionBar(engine: engine, selectedId: selectedId, mode: mode,
                            onMode: setMode, onEndTurn: endTurn)
                .padding(.horizontal, 12)
                .padding(.bottom, 6)
        }
        .padding(.top, 4)
        .frame(width: width, height: height)
    }

    private func landscapeLayout(width: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: 10) {
            let boardSide = min(height - 16, width * 0.52)
            board(side: boardSide)
            VStack(spacing: 8) {
                BattleTopBar(engine: engine, onForfeit: { showForfeit = true })
                BattleInfoPanel(engine: engine, selectedId: selectedId, inspectId: inspectId)
                    .frame(maxHeight: .infinity)
                BattleActionBar(engine: engine, selectedId: selectedId, mode: mode,
                                onMode: setMode, onEndTurn: endTurn)
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 10)
            .padding(.vertical, 8)
        }
        .padding(.leading, 8)
        .frame(width: width, height: height)
    }

    private func board(side: CGFloat) -> some View {
        BattleBoardView(
            engine: engine,
            boardSide: side,
            highlights: currentHighlights,
            highlightColor: highlightColor,
            selectedId: selectedId,
            onTap: handleTap
        )
        .frame(width: side, height: side)
        .clipped()
    }

    // MARK: Interaction

    private var currentHighlights: Set<Coord> {
        guard let id = selectedId else { return [] }
        switch mode {
        case .move: return engine.moveCells(for: id)
        case .attack: return engine.attackCells(for: id)
        case .ability: return engine.abilityCells(for: id)
        case .none: return []
        }
    }

    private var highlightColor: Color {
        switch mode {
        case .move: return Theme.patina
        case .attack: return Theme.danger
        case .ability: return Theme.warning
        case .none: return .clear
        }
    }

    private func setMode(_ newMode: ActionMode) {
        store.tapFeedback()
        mode = (mode == newMode) ? .none : newMode
    }

    private func endTurn() {
        store.heavyFeedback()
        selectedId = nil
        inspectId = nil
        mode = .none
        engine.endPlayerTurn()
    }

    private func handleTap(_ c: Coord) {
        guard engine.outcome == nil else { return }

        // acting on a highlighted cell
        if let id = selectedId, currentHighlights.contains(c) {
            switch mode {
            case .move:
                store.tapFeedback()
                engine.performMove(unitId: id, to: c)
                // convenience: stay selected, switch to attack if possible
                mode = engine.attackCells(for: id).isEmpty ? .none : .attack
                return
            case .attack:
                store.heavyFeedback()
                engine.performAttack(unitId: id, at: c)
                mode = .none
                return
            case .ability:
                store.heavyFeedback()
                engine.performAbility(unitId: id, at: c)
                mode = .none
                return
            case .none:
                break
            }
        }

        // selecting / inspecting
        if let entity = engine.entityAt(c) {
            store.tapFeedback()
            if entity.isUnit {
                selectedId = entity.id
                inspectId = nil
                mode = entity.moved ? (engine.attackCells(for: entity.id).isEmpty ? .none : .attack) : .move
            } else {
                inspectId = entity.id
                if !entity.isStructure || entity.team == .enemy { selectedId = nil; mode = .none }
            }
        } else {
            selectedId = nil
            inspectId = nil
            mode = .none
        }
    }
}
