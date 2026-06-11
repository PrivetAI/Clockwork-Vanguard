import SwiftUI

// MARK: - Achievements

struct AchievementsView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            let earnedCount = GameContent.achievements.filter { store.achievementUnlocked($0.id) }.count
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    ScreenHeader("Achievements",
                                 subtitle: "\(earnedCount) of \(GameContent.achievements.count) earned",
                                 onBack: { presentationMode.wrappedValue.dismiss() })
                        .frame(width: contentWidth)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(GameContent.achievements) { def in
                                achievementRow(def)
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

    private func achievementRow(_ def: AchievementDef) -> some View {
        let earned = store.achievementUnlocked(def.id)
        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(earned ? Theme.patinaDeep : Theme.bgDeep)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(earned ? Theme.warning : Theme.brassDim.opacity(0.4), lineWidth: 1.4))
                CogStarShape()
                    .fill(earned ? Theme.warning : Theme.brassDim.opacity(0.5))
                    .frame(width: 20, height: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(def.name)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(earned ? Theme.ivory : Theme.ivoryDim)
                Text(def.detail)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.ivoryDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if earned {
                Text("EARNED")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(Theme.good)
                    .padding(.vertical, 3).padding(.horizontal, 7)
                    .background(Capsule().fill(Theme.bgDeep))
            }
        }
        .padding(12)
        .background(PanelBackground(corner: 11,
                                    stroke: earned ? Theme.warning.opacity(0.45) : Theme.brassDim.opacity(0.4)))
        .opacity(earned ? 1 : 0.8)
    }
}

// MARK: - Statistics

struct StatsView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            let s = store.stats
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    ScreenHeader("Statistics", subtitle: "Campaign service record",
                                 onBack: { presentationMode.wrappedValue.dismiss() })
                        .frame(width: contentWidth)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            summaryBand
                            statGroup("Combat", [
                                ("Battles fought", s.battlesFought),
                                ("Missions won", s.missionsWon),
                                ("Enemies destroyed", s.enemiesDestroyed),
                                ("Bosses destroyed", s.bossesDestroyed),
                                ("Turns played", s.turnsPlayed),
                            ])
                            statGroup("Craft", [
                                ("Hazard kills", s.hazardKills),
                                ("Pit kills", s.pitKills),
                                ("Mine kills", s.trapKills),
                                ("Redirected kills", s.redirectKills),
                                ("Collisions caused", s.collisions),
                            ])
                            statGroup("Cost", [
                                ("Units lost", s.unitsLost),
                                ("Cores earned", s.coresEarned),
                                ("Bonus objectives", s.bonusObjectives),
                            ])
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

    private var summaryBand: some View {
        HStack(spacing: 10) {
            bandBox(value: "\(store.totalStars)", label: "STARS", tint: Theme.warning)
            bandBox(value: "\(store.cores)", label: "CORES", tint: Theme.patina)
            bandBox(value: "\(MissionCatalog.all.filter { store.stars(missionId: $0.id) > 0 }.count)/40",
                    label: "MISSIONS", tint: Theme.brass)
        }
    }

    private func bandBox(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                .foregroundColor(tint)
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundColor(Theme.ivoryDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(PanelBackground(corner: 11))
    }

    private func statGroup(_ title: String, _ rows: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(Theme.brass)
                .padding(.bottom, 8)
            ForEach(rows, id: \.0) { row in
                HStack {
                    Text(row.0)
                        .font(.system(size: 13))
                        .foregroundColor(Theme.ivory.opacity(0.85))
                    Spacer()
                    Text("\(row.1)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.ivory)
                }
                .padding(.vertical, 7)
                if row.0 != rows.last?.0 {
                    Divider().background(Theme.brassDim.opacity(0.25))
                }
            }
        }
        .padding(14)
        .background(PanelBackground())
    }
}
