import SwiftUI

// MARK: - Custom shape primitives (no SF Symbols anywhere)

/// Classic toothed gear with a center hole.
struct GearShape: Shape {
    var teeth: Int = 8
    var toothDepth: CGFloat = 0.22
    var holeRatio: CGFloat = 0.3

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOut = min(rect.width, rect.height) / 2
        let rIn = rOut * (1 - toothDepth)
        let steps = teeth * 4
        for i in 0...steps {
            let angle = (CGFloat(i) / CGFloat(steps)) * .pi * 2 - .pi / 2
            let phase = i % 4
            let r = (phase == 0 || phase == 1) ? rOut : rIn
            let pt = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        let hole = rOut * holeRatio
        p.addEllipse(in: CGRect(x: c.x - hole, y: c.y - hole, width: hole * 2, height: hole * 2))
        return p
    }
}

struct GearIcon: View {
    var size: CGFloat
    var color: Color
    var teeth: Int = 8
    var body: some View {
        GearShape(teeth: teeth)
            .fill(color, style: FillStyle(eoFill: true))
            .frame(width: size, height: size)
    }
}

/// Hex bolt head with center dot.
struct HexBoltShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        for i in 0...5 {
            let a = CGFloat(i) / 6 * .pi * 2 - .pi / 2
            let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        let hole = r * 0.32
        p.addEllipse(in: CGRect(x: c.x - hole, y: c.y - hole, width: hole * 2, height: hole * 2))
        return p
    }
}

/// Vertical piston: rod + head block.
struct PistonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // head block
        p.addRoundedRect(in: CGRect(x: rect.minX + w * 0.1, y: rect.minY, width: w * 0.8, height: h * 0.34),
                         cornerSize: CGSize(width: w * 0.08, height: w * 0.08))
        // rod
        p.addRect(CGRect(x: rect.midX - w * 0.11, y: rect.minY + h * 0.34, width: w * 0.22, height: h * 0.4))
        // base
        p.addRoundedRect(in: CGRect(x: rect.minX + w * 0.2, y: rect.minY + h * 0.74, width: w * 0.6, height: h * 0.26),
                         cornerSize: CGSize(width: w * 0.07, height: w * 0.07))
        return p
    }
}

/// Four-point compact star used for mission stars (cog-like points).
struct CogStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOut = min(rect.width, rect.height) / 2
        let rIn = rOut * 0.42
        for i in 0..<10 {
            let a = CGFloat(i) / 10 * .pi * 2 - .pi / 2
            let r = i % 2 == 0 ? rOut : rIn
            let pt = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// Simple chevron stroke for back buttons / disclosure.
struct ChevronGlyph: Shape {
    enum Pointing { case left, right, up, down }
    var pointing: Pointing = .right

    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch pointing {
        case .right:
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .left:
            p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .up:
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .down:
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        return p
    }
}

/// Directional arrow (filled) used for conveyor belts and telegraph directions.
struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // pointing up; rotate externally
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.45))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.18, y: rect.minY + h * 0.45))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.18, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - w * 0.18, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - w * 0.18, y: rect.minY + h * 0.45))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.45))
        p.closeSubpath()
        return p
    }
}

/// Crosshair / target reticle for telegraph strike marks.
struct ReticleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.addEllipse(in: CGRect(x: c.x - r * 0.62, y: c.y - r * 0.62, width: r * 1.24, height: r * 1.24))
        for i in 0..<4 {
            let a = CGFloat(i) / 4 * .pi * 2
            p.move(to: CGPoint(x: c.x + cos(a) * r * 0.4, y: c.y + sin(a) * r * 0.4))
            p.addLine(to: CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r))
        }
        return p
    }
}

/// Flame for burning tiles.
struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX - w * 0.08, y: rect.minY + h * 0.62),
                   control1: CGPoint(x: rect.midX + w * 0.4, y: rect.minY + h * 0.18),
                   control2: CGPoint(x: rect.maxX - w * 0.05, y: rect.minY + h * 0.36))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX - w * 0.1, y: rect.minY + h * 0.88),
                   control2: CGPoint(x: rect.midX + w * 0.26, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.62),
                   control1: CGPoint(x: rect.midX - w * 0.26, y: rect.maxY),
                   control2: CGPoint(x: rect.minX + w * 0.1, y: rect.minY + h * 0.88))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                   control1: CGPoint(x: rect.minX + w * 0.05, y: rect.minY + h * 0.36),
                   control2: CGPoint(x: rect.midX - w * 0.4, y: rect.minY + h * 0.18))
        p.closeSubpath()
        return p
    }
}

/// Water droplet.
struct DropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX + w * 0.12, y: rect.minY + h * 0.62),
                   control2: CGPoint(x: rect.midX + w * 0.42, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                   control1: CGPoint(x: rect.midX - w * 0.42, y: rect.maxY),
                   control2: CGPoint(x: rect.minX - w * 0.12, y: rect.minY + h * 0.62))
        p.closeSubpath()
        return p
    }
}

/// Shield outline.
struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.18))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.66),
                   control2: CGPoint(x: rect.midX + w * 0.3, y: rect.minY + h * 0.88))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.18),
                   control1: CGPoint(x: rect.midX - w * 0.3, y: rect.minY + h * 0.88),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.66))
        p.closeSubpath()
        return p
    }
}

/// Wrench silhouette.
struct WrenchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // jaw (C shape) at top
        p.move(to: CGPoint(x: rect.midX - w * 0.3, y: rect.minY + h * 0.05))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.3, y: rect.minY + h * 0.05))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.3, y: rect.minY + h * 0.22))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.1, y: rect.minY + h * 0.3))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.1, y: rect.maxY - h * 0.08))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.maxY - h * 0.08),
                 radius: w * 0.1, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.midX - w * 0.1, y: rect.minY + h * 0.3))
        p.addLine(to: CGPoint(x: rect.midX - w * 0.3, y: rect.minY + h * 0.22))
        p.closeSubpath()
        return p
    }
}

/// Lance / spear pointing up.
struct LanceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.22, y: rect.minY + h * 0.3))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.08, y: rect.minY + h * 0.3))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.08, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - w * 0.08, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - w * 0.08, y: rect.minY + h * 0.3))
        p.addLine(to: CGPoint(x: rect.midX - w * 0.22, y: rect.minY + h * 0.3))
        p.closeSubpath()
        return p
    }
}

/// Clock face with hands.
struct ClockFaceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        // hands
        p.move(to: c)
        p.addLine(to: CGPoint(x: c.x, y: c.y - r * 0.62))
        p.move(to: c)
        p.addLine(to: CGPoint(x: c.x + r * 0.45, y: c.y + r * 0.2))
        return p
    }
}

/// Bow-and-bolt glyph (archer).
struct BowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // bow arc on left
        p.move(to: CGPoint(x: rect.minX + w * 0.2, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.2, y: rect.maxY),
                       control: CGPoint(x: rect.maxX - w * 0.1, y: rect.midY))
        // string
        p.move(to: CGPoint(x: rect.minX + w * 0.2, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.2, y: rect.maxY))
        // arrow
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.move(to: CGPoint(x: rect.maxX - w * 0.18, y: rect.midY - h * 0.12))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.18, y: rect.midY + h * 0.12))
        return p
    }
}

/// Spiked mine glyph.
struct MineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.addEllipse(in: CGRect(x: c.x - r * 0.55, y: c.y - r * 0.55, width: r * 1.1, height: r * 1.1))
        for i in 0..<8 {
            let a = CGFloat(i) / 8 * .pi * 2
            p.move(to: CGPoint(x: c.x + cos(a) * r * 0.55, y: c.y + sin(a) * r * 0.55))
            p.addLine(to: CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r))
        }
        return p
    }
}

/// Crown for boss markers.
struct CrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.25))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + h * 0.55))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.25, y: rect.minY + h * 0.55))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.25))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// Steam puff (three rising circles) for vents.
struct SteamShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addEllipse(in: CGRect(x: rect.minX + w * 0.1, y: rect.minY + h * 0.45, width: w * 0.42, height: h * 0.42))
        p.addEllipse(in: CGRect(x: rect.minX + w * 0.45, y: rect.minY + h * 0.3, width: w * 0.5, height: h * 0.5))
        p.addEllipse(in: CGRect(x: rect.minX + w * 0.3, y: rect.minY, width: w * 0.36, height: h * 0.36))
        return p
    }
}

/// Lock body + shackle for locked content.
struct LockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY + h * 0.42, width: w, height: h * 0.58),
                         cornerSize: CGSize(width: w * 0.12, height: w * 0.12))
        p.move(to: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.42))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.22, y: rect.minY + h * 0.26))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY + h * 0.26),
                 radius: w * 0.28, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.22, y: rect.minY + h * 0.42))
        return p
    }
}

/// Skull-ish chassis glyph for defeat banners (rounded plate + eye holes).
struct HuskShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(in: CGRect(x: rect.minX, y: rect.minY, width: w, height: h * 0.78),
                         cornerSize: CGSize(width: w * 0.3, height: w * 0.3))
        p.addRect(CGRect(x: rect.minX + w * 0.2, y: rect.minY + h * 0.78, width: w * 0.14, height: h * 0.2))
        p.addRect(CGRect(x: rect.midX - w * 0.07, y: rect.minY + h * 0.78, width: w * 0.14, height: h * 0.2))
        p.addRect(CGRect(x: rect.maxX - w * 0.34, y: rect.minY + h * 0.78, width: w * 0.14, height: h * 0.2))
        p.addEllipse(in: CGRect(x: rect.minX + w * 0.2, y: rect.minY + h * 0.24, width: w * 0.2, height: h * 0.22))
        p.addEllipse(in: CGRect(x: rect.maxX - w * 0.4, y: rect.minY + h * 0.24, width: w * 0.2, height: h * 0.22))
        return p
    }
}
