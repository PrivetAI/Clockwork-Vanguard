import SwiftUI

// MARK: - Squad picker (choose 3 units before battle)

struct SquadPickerView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode
    let mission: MissionDef

    @State private var selected: [UnitClassID] = []
    @State private var battleOn = false

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    ScreenHeader(mission.name, subtitle: mission.objective.title,
                                 onBack: { presentationMode.wrappedValue.dismiss() })
                        .frame(width: contentWidth)
                        .padding(.top, 10)
                        .padding(.bottom, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            briefing
                            squadSlots
                            VStack(spacing: 10) {
                                ForEach(GameContent.unitClasses, id: \.id) { def in
                                    unitRow(def)
                                }
                            }
                            Spacer(minLength: 12)
                        }
                        .frame(width: contentWidth)
                        .frame(maxWidth: .infinity)
                    }

                    Button(action: deploy) {
                        Text(selected.count == 3 ? "Deploy Squad" : "Select \(3 - selected.count) more")
                            .font(.system(size: 17, weight: .bold, design: .serif))
                    }
                    .buttonStyle(BrassButtonStyle(prominent: selected.count == 3, disabledLook: selected.count != 3))
                    .disabled(selected.count != 3)
                    .frame(width: contentWidth)
                    .padding(.vertical, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: prefill)
        .fullScreenCover(isPresented: $battleOn) {
            BattleView(mission: mission, squad: selected)
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

    private func deploy() {
        guard selected.count == 3 else { return }
        store.heavyFeedback()
        store.rememberSquad(selected)
        battleOn = true
    }

    // MARK: Sections

    private var briefing: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mission.intro)
                .font(.system(size: 13))
                .foregroundColor(Theme.ivory.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Divider().background(Theme.brassDim.opacity(0.4))
            HStack(alignment: .top, spacing: 10) {
                CogStarShape().fill(Theme.warning).frame(width: 13, height: 13).padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Bonus: \(mission.bonus.title)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.warning)
                    Text("3 stars: win, complete the bonus, and lose no units.")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.ivoryDim)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelBackground())
    }

    private var squadSlots: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.bgPanel)
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(i < selected.count ? Theme.patina : Theme.brassDim.opacity(0.5),
                                          style: StrokeStyle(lineWidth: 1.4, dash: i < selected.count ? [] : [5, 4])))
                    if i < selected.count {
                        VStack(spacing: 6) {
                            UnitGlyph(classId: selected[i], size: 30)
                            Text(GameContent.unitDef(selected[i]).name)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Theme.ivory)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(.horizontal, 4)
                    } else {
                        Text("Slot \(i + 1)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.ivoryDim)
                    }
                }
                .frame(height: 74)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func unitRow(_ def: UnitClassDef) -> some View {
        let unlocked = store.unitUnlocked(def.id)
        let isPicked = selected.contains(def.id)
        let up = store.upgrades(for: def.id)

        return Button(action: {
            guard unlocked else { return }
            store.tapFeedback()
            if isPicked {
                selected.removeAll { $0 == def.id }
            } else if selected.count < 3 {
                selected.append(def.id)
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isPicked ? Theme.patinaDeep : Theme.bgDeep)
                        .frame(width: 48, height: 48)
                        .overlay(Circle().strokeBorder(isPicked ? Theme.patina : Theme.brassDim.opacity(0.5), lineWidth: 1.5))
                    if unlocked {
                        UnitGlyph(classId: def.id, size: 26, color: isPicked ? Theme.patina : Theme.brass)
                    } else {
                        LockShape()
                            .stroke(Theme.brassDim, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                            .frame(width: 16, height: 21)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(def.name)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(unlocked ? Theme.ivory : Theme.ivoryDim)
                        Text(def.role)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Theme.patina)
                    }
                    if unlocked {
                        Text("HP \(def.baseHP + up.hpTier * 2)   DMG \(def.baseDamage + up.dmgTier)   MOVE \(def.move)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Theme.ivoryDim)
                        Text(def.abilityName + " - " + def.abilityDesc)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.ivoryDim)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("Unlocks at \(ProgressStore.unlockThresholds[def.id] ?? 0) total stars")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.ivoryDim)
                    }
                }
                Spacer()
                if isPicked {
                    ZStack {
                        Circle().fill(Theme.patina).frame(width: 22, height: 22)
                        CheckGlyph()
                            .stroke(Theme.bgDeep, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                            .frame(width: 11, height: 9)
                    }
                }
            }
            .padding(12)
            .background(PanelBackground(corner: 11,
                                        stroke: isPicked ? Theme.patina.opacity(0.8) : Theme.brassDim.opacity(0.5)))
            .opacity(unlocked ? 1 : 0.65)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!unlocked)
    }
}

struct CheckGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX + rect.width * 0.36, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}
