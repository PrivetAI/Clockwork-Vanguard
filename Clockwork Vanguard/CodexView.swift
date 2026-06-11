import SwiftUI

// MARK: - Codex: units, enemies, hazards with lore

struct CodexView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode
    @State private var section = 0   // 0 units, 1 enemies, 2 hazards

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    ScreenHeader("Codex", subtitle: "Field manual of the Vanguard",
                                 onBack: { presentationMode.wrappedValue.dismiss() })
                        .frame(width: contentWidth)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    sectionPicker
                        .frame(width: contentWidth)
                        .padding(.bottom, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            switch section {
                            case 0: unitEntries
                            case 1: enemyEntries
                            default: hazardEntries
                            }
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

    private var sectionPicker: some View {
        HStack(spacing: 8) {
            sectionButton(0, "Units")
            sectionButton(1, "Enemies")
            sectionButton(2, "Hazards")
        }
    }

    private func sectionButton(_ idx: Int, _ title: String) -> some View {
        Button(action: { store.tapFeedback(); section = idx }) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(RoundedRectangle(cornerRadius: 9)
                    .fill(section == idx ? Theme.patinaDeep : Theme.bgPanel))
                .overlay(RoundedRectangle(cornerRadius: 9)
                    .strokeBorder(section == idx ? Theme.patina : Theme.brassDim.opacity(0.5), lineWidth: 1.2))
                .foregroundColor(section == idx ? Theme.ivory : Theme.ivoryDim)
        }
    }

    // MARK: Units

    private var unitEntries: some View {
        ForEach(GameContent.unitClasses, id: \.id) { def in
            let unlocked = store.unitUnlocked(def.id)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Theme.bgDeep).frame(width: 44, height: 44)
                            .overlay(Circle().strokeBorder(Theme.patina.opacity(unlocked ? 0.8 : 0.3), lineWidth: 1.3))
                        UnitGlyph(classId: def.id, size: 24, color: unlocked ? Theme.patina : Theme.brassDim)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(def.name)
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(Theme.ivory)
                        Text(def.role)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.patina)
                    }
                    Spacer()
                    Text("HP \(def.baseHP)  DMG \(def.baseDamage)  MOVE \(def.move)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.ivoryDim)
                }
                Text("\(def.attackName): \(def.attackDesc)")
                    .font(.system(size: 12)).foregroundColor(Theme.ivory.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(def.abilityName): \(def.abilityDesc)")
                    .font(.system(size: 12)).foregroundColor(Theme.ivory.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
                Text(def.lore)
                    .font(.system(size: 12, design: .serif).italic())
                    .foregroundColor(Theme.brass.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PanelBackground())
        }
    }

    // MARK: Enemies

    private var enemyEntries: some View {
        ForEach(GameContent.enemyDefs, id: \.kind) { def in
            let seen = store.enemySeen(def.kind)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Theme.bgDeep).frame(width: 44, height: 44)
                            .overlay(Circle().strokeBorder(
                                def.kind.isBoss ? Theme.danger.opacity(seen ? 0.9 : 0.3) : Theme.brassDim.opacity(seen ? 0.8 : 0.3),
                                lineWidth: 1.3))
                        if seen {
                            EnemyGlyph(kind: def.kind, size: 24)
                        } else {
                            Text("?")
                                .font(.system(size: 20, weight: .heavy, design: .serif))
                                .foregroundColor(Theme.brassDim)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(seen ? def.name : "Unidentified Machine")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                            .foregroundColor(seen ? Theme.ivory : Theme.ivoryDim)
                        if def.kind.isBoss {
                            Text("BOSS")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(Theme.danger)
                        }
                    }
                    Spacer()
                    if seen {
                        Text("HP \(def.hp)  DMG \(def.damage)\(def.armor > 0 ? "  ARM \(def.armor)" : "")")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.ivoryDim)
                    }
                }
                if seen {
                    Text(def.summary)
                        .font(.system(size: 12)).foregroundColor(Theme.ivory.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(def.lore)
                        .font(.system(size: 12, design: .serif).italic())
                        .foregroundColor(Theme.brass.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Encounter this machine in battle to add it to the codex.")
                        .font(.system(size: 12)).foregroundColor(Theme.ivoryDim)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PanelBackground())
        }
    }

    // MARK: Hazards

    private var hazardEntries: some View {
        ForEach(GameContent.hazardNotes, id: \.0) { note in
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Theme.bgDeep).frame(width: 40, height: 40)
                    hazardGlyph(note.0)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(note.0)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(Theme.ivory)
                    Text(note.1)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.ivory.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PanelBackground(corner: 11))
        }
    }

    @ViewBuilder
    private func hazardGlyph(_ name: String) -> some View {
        switch name {
        case "Pit":
            RoundedRectangle(cornerRadius: 5).fill(Theme.tilePit).frame(width: 22, height: 22)
                .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Theme.brassDim, lineWidth: 1))
        case "Steam Vent":
            SteamShape().fill(Theme.ivory.opacity(0.6)).frame(width: 22, height: 18)
        case "Conveyor Belt":
            ArrowShape().fill(Theme.brassDim).frame(width: 16, height: 22)
        case "Oil Slick":
            DropShape().fill(Theme.copper).frame(width: 15, height: 21)
        case "Water":
            DropShape().fill(Theme.tileWater).frame(width: 15, height: 21)
                .overlay(DropShape().stroke(Theme.ivory.opacity(0.5), lineWidth: 1).frame(width: 15, height: 21))
        default:
            CrackShape().stroke(Theme.brassDim, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                .frame(width: 20, height: 20)
        }
    }
}
