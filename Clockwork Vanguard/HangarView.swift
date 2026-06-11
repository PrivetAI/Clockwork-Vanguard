import SwiftUI

// MARK: - Hangar: unit upgrades

struct HangarView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedClass: UnitClassID = .pistonKnight

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    HStack {
                        ScreenHeader("Hangar", subtitle: "Refit and upgrade the Vanguard",
                                     onBack: { presentationMode.wrappedValue.dismiss() })
                        CoreCounter(amount: store.cores)
                    }
                    .frame(width: contentWidth)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                    classStrip(contentWidth: contentWidth)
                        .padding(.bottom, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            unitCard
                            upgradeSection
                            Spacer(minLength: 24)
                        }
                        .frame(width: contentWidth)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: Class selector strip

    private func classStrip(contentWidth: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GameContent.unitClasses, id: \.id) { def in
                    let unlocked = store.unitUnlocked(def.id)
                    Button(action: {
                        if unlocked {
                            store.tapFeedback()
                            selectedClass = def.id
                        }
                    }) {
                        VStack(spacing: 4) {
                            if unlocked {
                                UnitGlyph(classId: def.id, size: 24,
                                          color: selectedClass == def.id ? Theme.patina : Theme.brassDim)
                            } else {
                                LockShape()
                                    .stroke(Theme.brassDim, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
                                    .frame(width: 14, height: 18)
                                    .frame(width: 24, height: 24)
                            }
                            Text(shortName(def.id))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(selectedClass == def.id ? Theme.ivory : Theme.ivoryDim)
                        }
                        .frame(width: 64, height: 56)
                        .background(RoundedRectangle(cornerRadius: 9)
                            .fill(selectedClass == def.id ? Theme.patinaDeep.opacity(0.6) : Theme.bgPanel))
                        .overlay(RoundedRectangle(cornerRadius: 9)
                            .strokeBorder(selectedClass == def.id ? Theme.patina : Theme.brassDim.opacity(0.4), lineWidth: 1.2))
                        .opacity(unlocked ? 1 : 0.55)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
    }

    private func shortName(_ id: UnitClassID) -> String {
        switch id {
        case .pistonKnight: return "Knight"
        case .cogArcher: return "Archer"
        case .steamBulwark: return "Bulwark"
        case .gearSapper: return "Sapper"
        case .brassLancer: return "Lancer"
        case .chronoTinker: return "Tinker"
        }
    }

    // MARK: Selected unit card

    private var unitCard: some View {
        let def = GameContent.unitDef(selectedClass)
        let up = store.upgrades(for: selectedClass)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Theme.patinaDeep).frame(width: 56, height: 56)
                        .overlay(Circle().strokeBorder(Theme.patina, lineWidth: 1.4))
                    UnitGlyph(classId: selectedClass, size: 30)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(def.name)
                        .font(.system(size: 19, weight: .heavy, design: .serif))
                        .foregroundColor(Theme.ivory)
                    Text(def.role)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.patina)
                }
                Spacer()
                if store.isMaxed(selectedClass) {
                    Text("MASTERWORK")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(Theme.warning)
                        .padding(.vertical, 4).padding(.horizontal, 8)
                        .background(Capsule().fill(Theme.bgDeep))
                        .overlay(Capsule().strokeBorder(Theme.warning.opacity(0.6), lineWidth: 1))
                }
            }
            HStack(spacing: 8) {
                statBox("HULL", "\(def.baseHP + up.hpTier * 2)")
                statBox("DAMAGE", "\(def.baseDamage + up.dmgTier)")
                statBox("MOVE", "\(def.move)")
                statBox("COOLDOWN", "\(def.abilityCooldown)")
            }
            Text("\(def.attackName): \(def.attackDesc)")
                .font(.system(size: 12)).foregroundColor(Theme.ivoryDim)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(def.abilityName): \(def.abilityDesc)")
                .font(.system(size: 12)).foregroundColor(Theme.ivoryDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelBackground())
    }

    private func statBox(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .heavy))
                .foregroundColor(Theme.brass)
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundColor(Theme.ivory)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgDeep))
    }

    // MARK: Upgrade tracks

    private var upgradeSection: some View {
        VStack(spacing: 10) {
            upgradeRow(track: .hp, title: "Reinforced Hull", detail: "+2 HP per tier")
            upgradeRow(track: .dmg, title: "Hardened Strikers", detail: "+1 damage per tier")
            upgradeRow(track: .ability, title: "Ability Calibration", detail: abilityUpgradeDetail)
        }
    }

    private var abilityUpgradeDetail: String {
        switch selectedClass {
        case .pistonKnight: return "+1 slam launch distance per tier"
        case .cogArcher: return "+1 mortar volley damage per tier"
        case .steamBulwark: return "+1 winch range per tier"
        case .gearSapper: return "+1 mine damage per tier"
        case .brassLancer: return "+1 charge damage per tier"
        case .chronoTinker: return "+1 swap range per tier"
        }
    }

    private func upgradeRow(track: ProgressStore.UpgradeTrack, title: String, detail: String) -> some View {
        let tier = store.currentTier(selectedClass, track)
        let cost = store.upgradeCost(selectedClass, track)
        let affordable = cost.map { store.cores >= $0 } ?? false

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(Theme.ivory)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.ivoryDim)
                HStack(spacing: 4) {
                    ForEach(0..<UnitUpgrades.maxTier, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i < tier ? Theme.patina : Theme.bgDeep)
                            .frame(width: 26, height: 8)
                            .overlay(RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(i < tier ? Theme.patina : Theme.brassDim.opacity(0.5), lineWidth: 1))
                    }
                }
            }
            Spacer()
            if let cost = cost {
                Button(action: {
                    if store.purchaseUpgrade(selectedClass, track) {
                        store.successFeedback()
                    } else {
                        store.failureFeedback()
                    }
                }) {
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            GearIcon(size: 12, color: affordable ? Theme.bgDeep : Theme.ivoryDim)
                            Text("\(cost)")
                                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        }
                        Text("UPGRADE")
                            .font(.system(size: 8, weight: .heavy))
                    }
                    .foregroundColor(affordable ? Theme.bgDeep : Theme.ivoryDim)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(RoundedRectangle(cornerRadius: 9)
                        .fill(affordable ? Theme.brass : Theme.bgRaised))
                    .overlay(RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(affordable ? Theme.ivory.opacity(0.4) : Theme.brassDim.opacity(0.5), lineWidth: 1))
                }
                .disabled(!affordable)
            } else {
                Text("MAX")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(Theme.warning)
                    .padding(.vertical, 10).padding(.horizontal, 18)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Theme.bgDeep))
                    .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(Theme.warning.opacity(0.5), lineWidth: 1))
            }
        }
        .padding(12)
        .background(PanelBackground(corner: 11))
    }
}
