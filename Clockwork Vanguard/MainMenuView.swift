import SwiftUI

// MARK: - Root navigation container

struct RootMenuView: View {
    @EnvironmentObject var store: ProgressStore
    @State private var showOnboarding = false

    var body: some View {
        NavigationView {
            MainMenuView()
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if !store.onboardingDone { showOnboarding = true }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                store.finishOnboarding()
                showOnboarding = false
            }
            .environmentObject(store)
        }
    }
}

// MARK: - Main menu

struct MainMenuView: View {
    @EnvironmentObject var store: ProgressStore

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 480)
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                MenuBackdrop()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        titleBlock
                            .padding(.top, 36)

                        VStack(spacing: 12) {
                            NavigationLink(destination: RegionMapView()) {
                                bigRow(title: "Campaign", subtitle: campaignSubtitle, glyph: .campaign, prominent: true)
                            }
                            NavigationLink(destination: SkirmishView()) {
                                bigRow(title: "Skirmish", subtitle: skirmishSubtitle, glyph: .campaign)
                            }
                            NavigationLink(destination: HangarView()) {
                                bigRow(title: "Hangar", subtitle: "Upgrade your machines", glyph: .hangar)
                            }
                            NavigationLink(destination: DoctrinesView()) {
                                bigRow(title: "Doctrines", subtitle: doctrineSubtitle, glyph: .hangar)
                            }
                            NavigationLink(destination: CodexView()) {
                                bigRow(title: "Codex", subtitle: "Units, enemies and hazards", glyph: .codex)
                            }
                            NavigationLink(destination: AchievementsView()) {
                                bigRow(title: "Achievements", subtitle: achievementSubtitle, glyph: .achievements)
                            }
                            NavigationLink(destination: StatsView()) {
                                bigRow(title: "Statistics", subtitle: "Campaign service record", glyph: .stats)
                            }
                            NavigationLink(destination: SettingsView()) {
                                bigRow(title: "Settings", subtitle: "Sound, haptics and more", glyph: .settings)
                            }
                        }

                        HStack(spacing: 12) {
                            CoreCounter(amount: store.cores)
                            HStack(spacing: 6) {
                                CogStarShape().fill(Theme.warning).frame(width: 15, height: 15)
                                Text("\(store.totalStars) / 144")
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.ivory)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 11)
                            .background(Capsule().fill(Theme.bgRaised))
                            .overlay(Capsule().strokeBorder(Theme.brassDim, lineWidth: 1))
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(width: contentWidth)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var campaignSubtitle: String {
        let won = MissionCatalog.all.filter { store.stars(missionId: $0.id) > 0 }.count
        return won == 0 ? "Begin the counteroffensive" : "\(won) of 48 missions won"
    }

    private var skirmishSubtitle: String {
        let best = store.skirmish.bestEndlessDepth
        return best > 0 ? "Daily & Endless — best depth \(best)" : "Daily & Endless procedural battles"
    }

    private var doctrineSubtitle: String {
        let n = store.equippedDoctrineList.count
        return n > 0 ? "\(n) of \(DoctrineCatalog.loadoutSlots) doctrines equipped" : "Equip passive field doctrines"
    }

    private var achievementSubtitle: String {
        let n = GameContent.achievements.filter { store.achievementUnlocked($0.id) }.count
        return "\(n) of \(GameContent.achievements.count) earned"
    }

    private var titleBlock: some View {
        VStack(spacing: 10) {
            ZStack {
                GearShape(teeth: 12)
                    .fill(Theme.brassDim.opacity(0.35), style: FillStyle(eoFill: true))
                    .frame(width: 130, height: 130)
                ShieldShape()
                    .fill(Theme.patina)
                    .frame(width: 64, height: 74)
                HexBoltShape()
                    .fill(Theme.bgDeep, style: FillStyle(eoFill: true))
                    .frame(width: 28, height: 28)
                    .offset(y: -4)
            }
            Text("CLOCKWORK")
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundColor(Theme.brass)
                .kerning(5)
            Text("VANGUARD")
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundColor(Theme.ivory)
                .kerning(8)
            Text("Deterministic grid tactics")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.ivoryDim)
        }
    }

    private func bigRow(title: String, subtitle: String, glyph: MenuGlyphKind, prominent: Bool = false) -> some View {
        HStack(spacing: 14) {
            MenuGlyph(kind: glyph, size: 26, color: prominent ? Theme.bgDeep : Theme.brass)
                .frame(width: 40, height: 40)
                .background(Circle().fill(prominent ? Theme.brass.opacity(0.5) : Theme.bgDeep))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(prominent ? Theme.bgDeep : Theme.ivory)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(prominent ? Theme.bgDeep.opacity(0.7) : Theme.ivoryDim)
            }
            Spacer()
            ChevronGlyph(pointing: .right)
                .stroke(prominent ? Theme.bgDeep.opacity(0.7) : Theme.brassDim,
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                .frame(width: 9, height: 15)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(prominent ? Theme.brass : Theme.bgPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(prominent ? Theme.ivory.opacity(0.4) : Theme.brassDim.opacity(0.6), lineWidth: 1)
        )
    }
}

// MARK: - Decorative backdrop gears

struct MenuBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            ZStack {
                GearShape(teeth: 14)
                    .fill(Theme.bgPanel.opacity(0.55), style: FillStyle(eoFill: true))
                    .frame(width: w * 0.7, height: w * 0.7)
                    .position(x: w * 0.95, y: geo.size.height * 0.12)
                GearShape(teeth: 9)
                    .fill(Theme.bgPanel.opacity(0.45), style: FillStyle(eoFill: true))
                    .frame(width: w * 0.45, height: w * 0.45)
                    .position(x: w * 0.04, y: geo.size.height * 0.85)
            }
        }
        .allowsHitTesting(false)
        .clipped()
        .edgesIgnoringSafeArea(.all)
    }
}
