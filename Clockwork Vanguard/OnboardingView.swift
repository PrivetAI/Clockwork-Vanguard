import SwiftUI

// MARK: - 5-step skippable onboarding

struct OnboardingView: View {
    @EnvironmentObject var store: ProgressStore
    let onDone: () -> Void
    @State private var page = 0

    private let pageCount = 5

    var body: some View {
        ZStack {
            Theme.bgDeep.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { store.tapFeedback(); onDone() }) {
                        Text("Skip")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Theme.ivoryDim)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Capsule().fill(Theme.bgRaised))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Spacer(minLength: 8)

                Group {
                    switch page {
                    case 0: stepWelcome
                    case 1: stepTelegraphs
                    case 2: stepDisplacement
                    case 3: stepHazards
                    default: stepProgression
                    }
                }
                .frame(maxWidth: 440)
                .padding(.horizontal, 26)

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    ForEach(0..<pageCount, id: \.self) { i in
                        Circle()
                            .fill(i == page ? Theme.brass : Theme.brassDim.opacity(0.4))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 16)

                HStack(spacing: 12) {
                    if page > 0 {
                        Button(action: { store.tapFeedback(); page -= 1 }) {
                            Text("Back").font(.system(size: 16, weight: .bold, design: .serif))
                        }
                        .buttonStyle(BrassButtonStyle())
                    }
                    Button(action: {
                        store.tapFeedback()
                        if page < pageCount - 1 { page += 1 } else { onDone() }
                    }) {
                        Text(page < pageCount - 1 ? "Next" : "To Battle")
                            .font(.system(size: 16, weight: .bold, design: .serif))
                    }
                    .buttonStyle(BrassButtonStyle(prominent: true))
                }
                .frame(maxWidth: 440)
                .padding(.horizontal, 26)
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: Steps

    private func stepFrame(icon: AnyView, title: String, lines: [String]) -> some View {
        VStack(spacing: 18) {
            icon
                .frame(width: 110, height: 110)
                .background(Circle().fill(Theme.bgPanel))
                .overlay(Circle().strokeBorder(Theme.brassDim, lineWidth: 1))
            Text(title)
                .font(.system(size: 24, weight: .heavy, design: .serif))
                .foregroundColor(Theme.ivory)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 10) {
                        HexBoltShape()
                            .fill(Theme.patina, style: FillStyle(eoFill: true))
                            .frame(width: 12, height: 12)
                            .padding(.top, 4)
                        Text(line)
                            .font(.system(size: 15))
                            .foregroundColor(Theme.ivory.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(PanelBackground())
        }
    }

    private var stepWelcome: some View {
        stepFrame(
            icon: AnyView(GearIcon(size: 64, color: Theme.brass, teeth: 10)),
            title: "Command the Vanguard",
            lines: [
                "Lead a squad of three clockwork machines across an 8 by 8 battlefield.",
                "Combat is fully deterministic: no dice, no luck. Everything you see will happen exactly as shown.",
                "Each turn, every unit may move and then act: attack, use an ability, or hold."
            ])
    }

    private var stepTelegraphs: some View {
        stepFrame(
            icon: AnyView(ReticleShape().stroke(Theme.danger, style: StrokeStyle(lineWidth: 5, lineCap: .round)).frame(width: 60, height: 60)),
            title: "Read the Telegraphs",
            lines: [
                "Enemies announce their next attack one full turn in advance. Marked tiles show exactly where they will strike.",
                "Tap any enemy to see its intent and stats.",
                "If a marked tile is empty when the blow lands, it simply misses. Make it miss."
            ])
    }

    private var stepDisplacement: some View {
        stepFrame(
            icon: AnyView(ArrowShape().fill(Theme.patina).frame(width: 48, height: 66)),
            title: "Push, Pull, Swap",
            lines: [
                "Your attacks shove enemies. Push them into pits, onto mines, into steam vents, or into each other's attacks.",
                "A pushed machine that hits another deals collision damage to both.",
                "Repositioning an attacker redirects its telegraphed strike: it still fires along the same line, from wherever it now stands."
            ])
    }

    private var stepHazards: some View {
        stepFrame(
            icon: AnyView(FlameShape().fill(Theme.danger).frame(width: 46, height: 64)),
            title: "Use the Terrain",
            lines: [
                "Pits destroy anything that falls in. Steam vents scald. Conveyors carry whoever stands on them.",
                "Oil ignites when struck and fire spreads across connected slicks. Water never burns.",
                "Crumbling floors collapse into pits when stepped off or struck."
            ])
    }

    private var stepProgression: some View {
        stepFrame(
            icon: AnyView(CogStarShape().fill(Theme.warning).frame(width: 58, height: 58)),
            title: "Stars and Steel",
            lines: [
                "Earn up to 3 stars per mission: win, complete the bonus objective, and lose no units.",
                "Stars unlock new regions and new unit classes across six regions and forty-eight missions.",
                "Spend cores in the Hangar to upgrade units, and on Vanguard Doctrines for passive perks. Then test your squad in procedural Skirmish battles."
            ])
    }
}
