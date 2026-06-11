import SwiftUI

// MARK: - Steampunk clockwork palette

enum Theme {
    static let bgDeep = Color(red: 0.09, green: 0.07, blue: 0.05)      // near-black bronze
    static let bgPanel = Color(red: 0.15, green: 0.12, blue: 0.08)     // dark bronze panel
    static let bgRaised = Color(red: 0.21, green: 0.16, blue: 0.10)    // raised plate
    static let brass = Color(red: 0.78, green: 0.60, blue: 0.26)       // brass
    static let brassDim = Color(red: 0.52, green: 0.40, blue: 0.19)    // dull brass
    static let copper = Color(red: 0.66, green: 0.40, blue: 0.22)      // copper
    static let patina = Color(red: 0.28, green: 0.62, blue: 0.56)      // teal patina
    static let patinaDeep = Color(red: 0.13, green: 0.34, blue: 0.32)
    static let ivory = Color(red: 0.93, green: 0.89, blue: 0.79)       // ivory text
    static let ivoryDim = Color(red: 0.93, green: 0.89, blue: 0.79).opacity(0.55)
    static let danger = Color(red: 0.80, green: 0.30, blue: 0.18)      // rust red
    static let warning = Color(red: 0.88, green: 0.62, blue: 0.18)     // amber
    static let good = Color(red: 0.45, green: 0.72, blue: 0.35)        // verdigris green

    // Board tile tints
    static let tilePlainA = Color(red: 0.19, green: 0.15, blue: 0.10)
    static let tilePlainB = Color(red: 0.165, green: 0.13, blue: 0.085)
    static let tilePit = Color(red: 0.045, green: 0.035, blue: 0.03)
    static let tileWater = Color(red: 0.12, green: 0.24, blue: 0.30)
    static let tileOil = Color(red: 0.13, green: 0.11, blue: 0.06)
}

// MARK: - Reusable styling

struct PanelBackground: View {
    var corner: CGFloat = 12
    var stroke: Color = Theme.brassDim.opacity(0.6)
    var fill: Color = Theme.bgPanel

    var body: some View {
        RoundedRectangle(cornerRadius: corner)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: corner)
                    .strokeBorder(stroke, lineWidth: 1)
            )
    }
}

struct BrassButtonStyle: ButtonStyle {
    var prominent: Bool = false
    var disabledLook: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 11)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(prominent ? Theme.brass : Theme.bgRaised)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(prominent ? Theme.ivory.opacity(0.5) : Theme.brassDim, lineWidth: 1)
            )
            .foregroundColor(prominent ? Theme.bgDeep : Theme.ivory)
            .opacity(disabledLook ? 0.4 : (configuration.isPressed ? 0.7 : 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct CompactBrassButtonStyle: ButtonStyle {
    var tint: Color = Theme.brass

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.bgRaised))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(tint.opacity(0.7), lineWidth: 1))
            .foregroundColor(Theme.ivory)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct ScreenHeader: View {
    let title: String
    let subtitle: String?
    let onBack: (() -> Void)?

    init(_ title: String, subtitle: String? = nil, onBack: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
    }

    var body: some View {
        HStack(spacing: 12) {
            if let onBack = onBack {
                Button(action: onBack) {
                    ChevronGlyph(pointing: .left)
                        .stroke(Theme.brass, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .frame(width: 13, height: 21)
                        .padding(10)
                        .background(Circle().fill(Theme.bgRaised))
                        .overlay(Circle().strokeBorder(Theme.brassDim, lineWidth: 1))
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 22, weight: .heavy, design: .serif))
                    .foregroundColor(Theme.ivory)
                if let s = subtitle {
                    Text(s)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.ivoryDim)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Small shared widgets

struct CoreCounter: View {
    let amount: Int
    var body: some View {
        HStack(spacing: 6) {
            GearIcon(size: 16, color: Theme.patina)
            Text("\(amount)")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.ivory)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 11)
        .background(Capsule().fill(Theme.bgRaised))
        .overlay(Capsule().strokeBorder(Theme.patinaDeep, lineWidth: 1))
    }
}

struct StarRow: View {
    let earned: Int
    let total: Int
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { i in
                CogStarShape()
                    .fill(i < earned ? Theme.warning : Theme.bgDeep)
                    .overlay(CogStarShape().stroke(i < earned ? Theme.warning : Theme.brassDim.opacity(0.6), lineWidth: 1))
                    .frame(width: size, height: size)
            }
        }
    }
}

struct HPBar: View {
    let hp: Int
    let maxHp: Int
    var tint: Color = Theme.good

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.bgDeep)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, geo.size.width * CGFloat(hp) / CGFloat(max(1, maxHp))))
            }
        }
        .frame(height: 6)
    }
}
