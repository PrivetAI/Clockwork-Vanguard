import SwiftUI

// MARK: - Region map (campaign overview)

struct RegionMapView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    ScreenHeader("Campaign", subtitle: "\(store.totalStars) stars earned",
                                 onBack: { presentationMode.wrappedValue.dismiss() })
                        .frame(width: contentWidth)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            ForEach(GameContent.regions) { region in
                                regionCard(region)
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

    @ViewBuilder
    private func regionCard(_ region: RegionDef) -> some View {
        let unlocked = store.regionUnlocked(region)
        let stars = store.regionStars(region.id)
        let cleared = store.regionCleared(region.id)

        if unlocked {
            NavigationLink(destination: MissionSelectView(region: region)) {
                regionCardBody(region, unlocked: true, stars: stars, cleared: cleared)
            }
        } else {
            regionCardBody(region, unlocked: false, stars: stars, cleared: cleared)
        }
    }

    private func regionCardBody(_ region: RegionDef, unlocked: Bool, stars: Int, cleared: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(unlocked ? Theme.patinaDeep : Theme.bgDeep)
                    .frame(width: 54, height: 54)
                    .overlay(Circle().strokeBorder(unlocked ? Theme.patina : Theme.brassDim.opacity(0.5), lineWidth: 1.5))
                if unlocked {
                    regionGlyph(region.id)
                } else {
                    LockShape()
                        .stroke(Theme.brassDim, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                        .frame(width: 20, height: 26)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Region \(region.id + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Theme.brass)
                        .padding(.vertical, 2).padding(.horizontal, 7)
                        .background(Capsule().fill(Theme.bgDeep))
                    if cleared {
                        Text("CLEARED")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(Theme.good)
                            .padding(.vertical, 2).padding(.horizontal, 7)
                            .background(Capsule().fill(Theme.bgDeep))
                    }
                }
                Text(region.name)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(unlocked ? Theme.ivory : Theme.ivoryDim)
                Text(unlocked ? region.tagline : "Requires \(region.starsRequired) total stars")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.ivoryDim)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if unlocked {
                    HStack(spacing: 6) {
                        CogStarShape().fill(Theme.warning).frame(width: 12, height: 12)
                        Text("\(stars) / 24")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.ivoryDim)
                    }
                }
            }
            Spacer()
            if unlocked {
                ChevronGlyph(pointing: .right)
                    .stroke(Theme.brassDim, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                    .frame(width: 9, height: 15)
            }
        }
        .padding(14)
        .background(PanelBackground(stroke: unlocked ? Theme.brassDim.opacity(0.7) : Theme.brassDim.opacity(0.3)))
        .opacity(unlocked ? 1 : 0.75)
    }

    @ViewBuilder
    private func regionGlyph(_ id: Int) -> some View {
        switch id {
        case 0: GearIcon(size: 28, color: Theme.brass, teeth: 7)
        case 1: SteamShape().fill(Theme.ivory.opacity(0.85)).frame(width: 28, height: 24)
        case 2: HexBoltShape().fill(Theme.copper, style: FillStyle(eoFill: true)).frame(width: 28, height: 28)
        case 3: ShieldShape().fill(Theme.patina).frame(width: 24, height: 28)
        default: ClockFaceShape().stroke(Theme.warning, style: StrokeStyle(lineWidth: 2.4, lineCap: .round)).frame(width: 26, height: 26)
        }
    }
}

// MARK: - Mission select within a region

struct MissionSelectView: View {
    @EnvironmentObject var store: ProgressStore
    @Environment(\.presentationMode) var presentationMode
    let region: RegionDef

    var body: some View {
        GeometryReader { geo in
            let width = min(geo.size.width, UIScreen.main.bounds.width)
            let contentWidth = min(width - 40, 520)
            ZStack {
                Theme.bgDeep.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    ScreenHeader(region.name, subtitle: region.tagline,
                                 onBack: { presentationMode.wrappedValue.dismiss() })
                        .frame(width: contentWidth)
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(MissionCatalog.missions(inRegion: region.id)) { mission in
                                missionRow(mission)
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

    @ViewBuilder
    private func missionRow(_ mission: MissionDef) -> some View {
        let unlocked = store.missionUnlocked(mission)
        let stars = store.stars(missionId: mission.id)

        if unlocked {
            NavigationLink(destination: SquadPickerView(mission: mission)) {
                missionRowBody(mission, unlocked: true, stars: stars)
            }
        } else {
            missionRowBody(mission, unlocked: false, stars: stars)
        }
    }

    private func missionRowBody(_ mission: MissionDef, unlocked: Bool, stars: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(Theme.bgDeep)
                    .frame(width: 44, height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(mission.isBossMission ? Theme.danger.opacity(0.8) : Theme.brassDim.opacity(0.6), lineWidth: 1.2))
                if unlocked {
                    if mission.isBossMission {
                        CrownShape().fill(Theme.danger).frame(width: 24, height: 16)
                    } else {
                        Text("\(mission.index + 1)")
                            .font(.system(size: 18, weight: .heavy, design: .serif))
                            .foregroundColor(Theme.brass)
                    }
                } else {
                    LockShape()
                        .stroke(Theme.brassDim, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                        .frame(width: 15, height: 20)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(mission.name)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(unlocked ? Theme.ivory : Theme.ivoryDim)
                Text(mission.objective.title)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.ivoryDim)
                    .lineLimit(1)
                if mission.isBossMission && unlocked {
                    Text("BOSS BATTLE")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(Theme.danger)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                StarRow(earned: stars, total: 3, size: 12)
                if unlocked {
                    ChevronGlyph(pointing: .right)
                        .stroke(Theme.brassDim, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 7, height: 12)
                }
            }
        }
        .padding(12)
        .background(PanelBackground(corner: 11,
                                    stroke: unlocked ? Theme.brassDim.opacity(0.6) : Theme.brassDim.opacity(0.3)))
        .opacity(unlocked ? 1 : 0.7)
    }
}
