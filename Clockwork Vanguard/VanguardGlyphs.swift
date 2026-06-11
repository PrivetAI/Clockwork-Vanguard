import SwiftUI

// MARK: - Unit class glyphs (composed from custom shapes)

struct UnitGlyph: View {
    let classId: UnitClassID
    var size: CGFloat
    var color: Color = Theme.patina

    var body: some View {
        ZStack {
            switch classId {
            case .pistonKnight:
                PistonShape().fill(color)
            case .cogArcher:
                BowShape().stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round, lineJoin: .round))
            case .steamBulwark:
                ShieldShape().fill(color)
                HexBoltShape()
                    .fill(Theme.bgDeep, style: FillStyle(eoFill: true))
                    .frame(width: size * 0.4, height: size * 0.4)
                    .offset(y: -size * 0.06)
            case .gearSapper:
                MineShape().stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
            case .brassLancer:
                LanceShape().fill(color)
            case .chronoTinker:
                ClockFaceShape().stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Enemy glyphs

struct EnemyGlyph: View {
    let kind: EnemyKind
    var size: CGFloat
    var color: Color = Theme.danger

    var body: some View {
        ZStack {
            switch kind {
            case .scrapCrawler, .scrapling:
                // small angular bug: hex with legs
                HexBoltShape().fill(color, style: FillStyle(eoFill: true))
                    .frame(width: size * 0.66, height: size * 0.66)
                legs
            case .boltSpitter:
                ArrowShape().fill(color)
                    .frame(width: size * 0.6, height: size * 0.85)
            case .beamSentry:
                ReticleShape().stroke(color, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round))
                    .frame(width: size * 0.85, height: size * 0.85)
            case .foundrySpawner:
                GearShape(teeth: 6).fill(color, style: FillStyle(eoFill: true))
                GearShape(teeth: 6).fill(color, style: FillStyle(eoFill: true))
                    .frame(width: size * 0.45, height: size * 0.45)
                    .offset(x: size * 0.3, y: size * 0.3)
            case .rustBurrower:
                // spiral-ish: three nested arcs via drop rotated down
                DropShape().fill(color)
                    .rotationEffect(.degrees(180))
                    .frame(width: size * 0.7, height: size * 0.9)
            case .ironHusk:
                HuskShape().fill(color, style: FillStyle(eoFill: true))
                    .frame(width: size * 0.8, height: size * 0.8)
            case .boilerTick:
                FlameShape().fill(color)
                    .frame(width: size * 0.62, height: size * 0.85)
            case .cogMender:
                WrenchShape().fill(color)
                    .frame(width: size * 0.7, height: size * 0.9)
            case .springLeaper:
                ChevronGlyph(pointing: .up)
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.7, height: size * 0.42)
                    .offset(y: -size * 0.16)
                ChevronGlyph(pointing: .up)
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round, lineJoin: .round))
                    .frame(width: size * 0.7, height: size * 0.42)
                    .offset(y: size * 0.2)
            case .wireSpinner:
                ReticleShape().stroke(color, style: StrokeStyle(lineWidth: size * 0.07))
                    .frame(width: size * 0.8, height: size * 0.8)
                    .rotationEffect(.degrees(45))
            case .gearSplitter:
                GearShape(teeth: 7).fill(color, style: FillStyle(eoFill: true))
                Rectangle().fill(Theme.bgDeep)
                    .frame(width: size * 0.1, height: size)
                    .rotationEffect(.degrees(20))
            case .aegisPlate:
                ShieldShape().stroke(color, lineWidth: size * 0.09)
                    .frame(width: size * 0.78, height: size * 0.9)
            case .mortarHulk:
                // mortar tube: thick angled rect + base
                RoundedRectangle(cornerRadius: size * 0.06)
                    .fill(color)
                    .frame(width: size * 0.26, height: size * 0.8)
                    .rotationEffect(.degrees(38))
                Capsule().fill(color)
                    .frame(width: size * 0.7, height: size * 0.2)
                    .offset(y: size * 0.34)
            case .clockDrone:
                ClockFaceShape().stroke(color, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round))
                    .frame(width: size * 0.74, height: size * 0.74)
            case .foundryKing:
                CrownShape().fill(color).frame(width: size * 0.85, height: size * 0.5).offset(y: -size * 0.26)
                GearShape(teeth: 8).fill(color, style: FillStyle(eoFill: true))
                    .frame(width: size * 0.6, height: size * 0.6).offset(y: size * 0.2)
            case .vaporTyrant:
                CrownShape().fill(color).frame(width: size * 0.85, height: size * 0.5).offset(y: -size * 0.26)
                SteamShape().fill(color)
                    .frame(width: size * 0.62, height: size * 0.55).offset(y: size * 0.2)
            case .cogColossus:
                CrownShape().fill(color).frame(width: size * 0.85, height: size * 0.5).offset(y: -size * 0.26)
                HexBoltShape().fill(color, style: FillStyle(eoFill: true))
                    .frame(width: size * 0.62, height: size * 0.62).offset(y: size * 0.2)
            case .chronoArchon:
                CrownShape().fill(color).frame(width: size * 0.85, height: size * 0.5).offset(y: -size * 0.26)
                ClockFaceShape().stroke(color, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .round))
                    .frame(width: size * 0.56, height: size * 0.56).offset(y: size * 0.22)
            }
        }
        .frame(width: size, height: size)
    }

    private var legs: some View {
        ForEach(0..<4, id: \.self) { i in
            Capsule()
                .fill(color)
                .frame(width: size * 0.5, height: size * 0.07)
                .rotationEffect(.degrees(Double(i) * 45 + 22))
        }
    }
}

// MARK: - Structure glyphs

struct StructureGlyph: View {
    let kind: StructureKind
    var size: CGFloat

    var body: some View {
        ZStack {
            switch kind {
            case .boiler:
                Capsule()
                    .fill(Theme.copper)
                    .frame(width: size * 0.62, height: size * 0.85)
                SteamShape().fill(Theme.ivory.opacity(0.7))
                    .frame(width: size * 0.4, height: size * 0.32)
                    .offset(y: -size * 0.42)
            case .foundryCore:
                GearShape(teeth: 10, holeRatio: 0.45)
                    .fill(Theme.warning, style: FillStyle(eoFill: true))
                Circle().fill(Theme.danger)
                    .frame(width: size * 0.22, height: size * 0.22)
            case .convoy:
                RoundedRectangle(cornerRadius: size * 0.1)
                    .fill(Theme.brass)
                    .frame(width: size * 0.82, height: size * 0.5)
                    .offset(y: -size * 0.1)
                HStack(spacing: size * 0.18) {
                    Circle().fill(Theme.bgDeep).overlay(Circle().strokeBorder(Theme.brass, lineWidth: size * 0.04))
                        .frame(width: size * 0.26, height: size * 0.26)
                    Circle().fill(Theme.bgDeep).overlay(Circle().strokeBorder(Theme.brass, lineWidth: size * 0.04))
                        .frame(width: size * 0.26, height: size * 0.26)
                }
                .offset(y: size * 0.26)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Menu row icons

enum MenuGlyphKind {
    case campaign, hangar, codex, achievements, stats, settings, sound, haptics, reset, privacy, tutorial
}

struct MenuGlyph: View {
    let kind: MenuGlyphKind
    var size: CGFloat = 22
    var color: Color = Theme.brass

    var body: some View {
        ZStack {
            switch kind {
            case .campaign:
                ArrowShape().fill(color).frame(width: size * 0.62, height: size * 0.9)
                    .rotationEffect(.degrees(45))
            case .hangar:
                WrenchShape().fill(color).frame(width: size * 0.72, height: size * 0.95)
                    .rotationEffect(.degrees(-30))
            case .codex:
                // book: two panels
                HStack(spacing: size * 0.05) {
                    RoundedRectangle(cornerRadius: size * 0.08).fill(color)
                        .frame(width: size * 0.38, height: size * 0.8)
                    RoundedRectangle(cornerRadius: size * 0.08).fill(color.opacity(0.6))
                        .frame(width: size * 0.38, height: size * 0.8)
                }
            case .achievements:
                CogStarShape().fill(color)
            case .stats:
                HStack(alignment: .bottom, spacing: size * 0.1) {
                    RoundedRectangle(cornerRadius: size * 0.05).fill(color).frame(width: size * 0.18, height: size * 0.4)
                    RoundedRectangle(cornerRadius: size * 0.05).fill(color).frame(width: size * 0.18, height: size * 0.75)
                    RoundedRectangle(cornerRadius: size * 0.05).fill(color).frame(width: size * 0.18, height: size * 0.55)
                }
            case .settings:
                GearShape(teeth: 8).fill(color, style: FillStyle(eoFill: true))
            case .sound:
                // speaker wedge + waves
                SpeakerGlyph().fill(color)
            case .haptics:
                ZStack {
                    Capsule().stroke(color, lineWidth: size * 0.08)
                        .frame(width: size * 0.5, height: size * 0.9)
                    Circle().fill(color).frame(width: size * 0.14, height: size * 0.14)
                        .offset(y: size * 0.28)
                }
            case .reset:
                // circular arrow
                Circle()
                    .trim(from: 0.1, to: 0.85)
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                    .frame(width: size * 0.74, height: size * 0.74)
                ArrowShape().fill(color)
                    .frame(width: size * 0.3, height: size * 0.4)
                    .rotationEffect(.degrees(60))
                    .offset(x: size * 0.34, y: -size * 0.18)
            case .privacy:
                LockShape().stroke(color, style: StrokeStyle(lineWidth: size * 0.09, lineJoin: .round))
                    .frame(width: size * 0.66, height: size * 0.85)
            case .tutorial:
                Circle().stroke(color, lineWidth: size * 0.08)
                    .frame(width: size * 0.85, height: size * 0.85)
                Text("?")
                    .font(.system(size: size * 0.5, weight: .heavy, design: .serif))
                    .foregroundColor(color)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SpeakerGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.35))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.3, y: rect.minY + h * 0.35))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.55, y: rect.minY + h * 0.1))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.55, y: rect.maxY - h * 0.1))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.3, y: rect.maxY - h * 0.35))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - h * 0.35))
        p.closeSubpath()
        // waves
        p.move(to: CGPoint(x: rect.minX + w * 0.7, y: rect.midY - h * 0.18))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.7, y: rect.midY + h * 0.18),
                       control: CGPoint(x: rect.minX + w * 0.92, y: rect.midY))
        return p
    }
}

// MARK: - Custom toggle (no system Toggle styling dependency)

struct BrassToggle: View {
    @Binding var isOn: Bool
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            isOn.toggle()
            action?()
        }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Theme.patinaDeep : Theme.bgDeep)
                    .overlay(Capsule().strokeBorder(isOn ? Theme.patina : Theme.brassDim, lineWidth: 1))
                    .frame(width: 52, height: 30)
                Circle()
                    .fill(isOn ? Theme.patina : Theme.brassDim)
                    .frame(width: 24, height: 24)
                    .padding(3)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isOn)
    }
}
