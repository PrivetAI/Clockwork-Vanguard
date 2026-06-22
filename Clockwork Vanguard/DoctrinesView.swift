import SwiftUI

// MARK: - Vanguard Doctrines screen
//
// Buy permanent doctrines with cores, then equip a limited loadout. Equipped
// doctrines feed BattleModifiers (and core-reward shaping) into every battle,
// campaign or skirmish.

struct DoctrinesView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    ScreenHeader("Doctrines", subtitle: "Equip up to \(DoctrineCatalog.loadoutSlots) field doctrines",
                                 onBack: { presentationMode.wrappedValue.dismiss() })
                        .frame(width: contentWidth)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            header
                            ForEach(DoctrineCatalog.all) { def in
                                row(def)
                            }
                            Spacer(minLength: 12)
                        }
                        .frame(width: contentWidth)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack(spacing: 12) {
            CoreCounter(amount: store.cores)
            Spacer()
            Text("Equipped \(store.equippedDoctrineList.count) / \(DoctrineCatalog.loadoutSlots)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.patina)
                .padding(.vertical, 6).padding(.horizontal, 11)
                .background(Capsule().fill(Theme.bgRaised))
                .overlay(Capsule().strokeBorder(Theme.brassDim, lineWidth: 1))
        }
    }

    private func row(_ def: DoctrineDef) -> some View {
        let owned = store.ownsDoctrine(def.id)
        let equipped = store.isEquipped(def.id)
        let canAfford = store.cores >= def.cost
        let slotsFull = store.equippedDoctrineList.count >= DoctrineCatalog.loadoutSlots

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(equipped ? Theme.patinaDeep : Theme.bgDeep)
                        .frame(width: 40, height: 40)
                        .overlay(Circle().strokeBorder(equipped ? Theme.patina : Theme.brassDim.opacity(0.5), lineWidth: 1.5))
                    GearIcon(size: 20, color: equipped ? Theme.patina : Theme.brass)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(def.name)
                        .font(.system(size: 15, weight: .bold, design: .serif))
                        .foregroundColor(Theme.ivory)
                    Text(owned ? (equipped ? "Equipped" : "Owned") : "\(def.cost) cores")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(equipped ? Theme.patina : (owned ? Theme.ivoryDim : (canAfford ? Theme.warning : Theme.danger)))
                }
                Spacer()
            }
            Text(def.blurb)
                .font(.system(size: 12))
                .foregroundColor(Theme.ivoryDim)
                .fixedSize(horizontal: false, vertical: true)

            actionButton(def: def, owned: owned, equipped: equipped,
                         canAfford: canAfford, slotsFull: slotsFull)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelBackground(corner: 12, stroke: equipped ? Theme.patina.opacity(0.7) : Theme.brassDim.opacity(0.5)))
    }

    @ViewBuilder
    private func actionButton(def: DoctrineDef, owned: Bool, equipped: Bool,
                              canAfford: Bool, slotsFull: Bool) -> some View {
        if !owned {
            Button(action: {
                if store.purchaseDoctrine(def.id) { store.successFeedback() }
                else { store.failureFeedback() }
            }) {
                Text(canAfford ? "Acquire — \(def.cost) cores" : "Need \(def.cost) cores")
                    .font(.system(size: 14, weight: .bold, design: .serif))
            }
            .buttonStyle(BrassButtonStyle(prominent: canAfford, disabledLook: !canAfford))
            .disabled(!canAfford)
        } else {
            let blockEquip = !equipped && slotsFull
            Button(action: {
                if store.toggleDoctrine(def.id) { store.tapFeedback() }
                else { store.failureFeedback() }
            }) {
                Text(equipped ? "Unequip" : (blockEquip ? "Loadout Full" : "Equip"))
                    .font(.system(size: 14, weight: .bold, design: .serif))
            }
            .buttonStyle(BrassButtonStyle(prominent: equipped, disabledLook: blockEquip))
            .disabled(blockEquip)
        }
    }
}
