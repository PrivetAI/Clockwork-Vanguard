import SwiftUI

// MARK: - 8x8 battle board

struct BattleBoardView: View {
    @ObservedObject var engine: BattleEngine
    let boardSide: CGFloat
    let highlights: Set<Coord>
    let highlightColor: Color
    let selectedId: Int?
    let onTap: (Coord) -> Void

    var body: some View {
        let cell = boardSide / CGFloat(Coord.boardSize)
        let marks = engine.telegraphMarks()
        let burrowedSpots = Set(engine.entities.filter { $0.alive && $0.burrowed }.map { $0.pos })

        VStack(spacing: 0) {
            ForEach(0..<Coord.boardSize, id: \.self) { y in
                HStack(spacing: 0) {
                    ForEach(0..<Coord.boardSize, id: \.self) { x in
                        let c = Coord(x: x, y: y)
                        BoardCellView(
                            coord: c,
                            tile: engine.tiles[y][x],
                            entity: engine.entityAt(c),
                            mark: marks[c],
                            highlighted: highlights.contains(c),
                            highlightColor: highlightColor,
                            isSelected: selectedId != nil && engine.entityAt(c)?.id == selectedId,
                            isExit: engine.mission.exitCell == c,
                            burrowedBelow: burrowedSpots.contains(c),
                            cellSize: cell
                        )
                        .frame(width: cell, height: cell)
                        .contentShape(Rectangle())
                        .onTapGesture { onTap(c) }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.bgPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Theme.brassDim, lineWidth: 2)
        )
    }
}

// MARK: - Single cell

struct BoardCellView: View {
    let coord: Coord
    let tile: Tile
    let entity: Entity?
    let mark: TelegraphMark?
    let highlighted: Bool
    let highlightColor: Color
    let isSelected: Bool
    let isExit: Bool
    let burrowedBelow: Bool
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            tileBase
            tileDecoration
            if tile.onFire {
                FlameShape().fill(Theme.danger.opacity(0.85))
                    .frame(width: cellSize * 0.4, height: cellSize * 0.52)
                    .offset(x: cellSize * 0.22, y: -cellSize * 0.2)
            }
            if let dmg = tile.trapDamage {
                MineShape()
                    .stroke(Theme.warning, style: StrokeStyle(lineWidth: max(1.2, cellSize * 0.045), lineCap: .round))
                    .frame(width: cellSize * 0.46, height: cellSize * 0.46)
                Text("\(dmg)")
                    .font(.system(size: cellSize * 0.2, weight: .heavy, design: .monospaced))
                    .foregroundColor(Theme.warning)
            }
            if isExit {
                ArrowShape().fill(Theme.good.opacity(0.7))
                    .frame(width: cellSize * 0.4, height: cellSize * 0.56)
            }
            if burrowedBelow && entity == nil {
                Circle()
                    .strokeBorder(Theme.danger.opacity(0.55),
                                  style: StrokeStyle(lineWidth: max(1, cellSize * 0.035), dash: [3, 3]))
                    .frame(width: cellSize * 0.55, height: cellSize * 0.55)
            }
            if let m = mark { markView(m) }
            if highlighted {
                RoundedRectangle(cornerRadius: cellSize * 0.12)
                    .fill(highlightColor.opacity(0.28))
                    .padding(cellSize * 0.05)
                RoundedRectangle(cornerRadius: cellSize * 0.12)
                    .strokeBorder(highlightColor.opacity(0.9), lineWidth: max(1.2, cellSize * 0.04))
                    .padding(cellSize * 0.05)
            }
            if let e = entity { entityView(e) }
        }
        .frame(width: cellSize, height: cellSize)
    }

    private var tileBase: some View {
        let fill: Color
        switch tile.kind {
        case .pit: fill = Theme.tilePit
        case .water: fill = Theme.tileWater
        case .oil: fill = Theme.tileOil
        default: fill = (coord.x + coord.y).isMultiple(of: 2) ? Theme.tilePlainA : Theme.tilePlainB
        }
        return Rectangle()
            .fill(fill)
            .overlay(Rectangle().strokeBorder(Theme.bgDeep.opacity(0.6), lineWidth: 0.5))
    }

    @ViewBuilder
    private var tileDecoration: some View {
        switch tile.kind {
        case .pit:
            RoundedRectangle(cornerRadius: cellSize * 0.16)
                .strokeBorder(Theme.bgRaised.opacity(0.8), lineWidth: max(1, cellSize * 0.03))
                .padding(cellSize * 0.1)
        case .vent:
            SteamShape().fill(Theme.ivory.opacity(0.32))
                .frame(width: cellSize * 0.52, height: cellSize * 0.42)
            Circle().strokeBorder(Theme.brassDim.opacity(0.6), lineWidth: max(1, cellSize * 0.03))
                .frame(width: cellSize * 0.7, height: cellSize * 0.7)
        case .conveyor(let dir):
            ArrowShape().fill(Theme.brassDim.opacity(0.75))
                .frame(width: cellSize * 0.36, height: cellSize * 0.52)
                .rotationEffect(.degrees(dir.angle))
        case .oil:
            DropShape().fill(Theme.copper.opacity(0.5))
                .frame(width: cellSize * 0.3, height: cellSize * 0.4)
        case .water:
            DropShape().fill(Theme.ivory.opacity(0.35))
                .frame(width: cellSize * 0.26, height: cellSize * 0.36)
        case .crumbling:
            CrackShape()
                .stroke(Theme.bgDeep.opacity(0.9), style: StrokeStyle(lineWidth: max(1, cellSize * 0.035), lineCap: .round))
                .padding(cellSize * 0.14)
        case .plain:
            EmptyView()
        }
    }

    @ViewBuilder
    private func markView(_ m: TelegraphMark) -> some View {
        switch m {
        case .strike:
            ReticleShape()
                .stroke(Theme.danger.opacity(0.9), style: StrokeStyle(lineWidth: max(1.4, cellSize * 0.05), lineCap: .round))
                .frame(width: cellSize * 0.62, height: cellSize * 0.62)
        case .blast:
            RoundedRectangle(cornerRadius: cellSize * 0.1)
                .fill(Theme.danger.opacity(0.3))
                .padding(cellSize * 0.07)
            ReticleShape()
                .stroke(Theme.warning.opacity(0.95), style: StrokeStyle(lineWidth: max(1.4, cellSize * 0.05), lineCap: .round))
                .frame(width: cellSize * 0.6, height: cellSize * 0.6)
        case .spawn:
            GearShape(teeth: 6)
                .fill(Theme.danger.opacity(0.5), style: FillStyle(eoFill: true))
                .frame(width: cellSize * 0.5, height: cellSize * 0.5)
        case .heal:
            WrenchShape().fill(Theme.good.opacity(0.8))
                .frame(width: cellSize * 0.36, height: cellSize * 0.5)
                .offset(x: cellSize * 0.24, y: -cellSize * 0.22)
        }
    }

    private func entityView(_ e: Entity) -> some View {
        let tint: Color = e.team == .player ? (e.isStructure ? Theme.copper : Theme.patina) : Theme.danger
        return VStack(spacing: cellSize * 0.04) {
            ZStack {
                if isSelected {
                    Circle()
                        .strokeBorder(Theme.warning, lineWidth: max(1.6, cellSize * 0.05))
                        .frame(width: cellSize * 0.86, height: cellSize * 0.86)
                }
                if e.shieldUp {
                    Circle()
                        .strokeBorder(Theme.ivory.opacity(0.8),
                                      style: StrokeStyle(lineWidth: max(1.2, cellSize * 0.04), dash: [3, 2]))
                        .frame(width: cellSize * 0.8, height: cellSize * 0.8)
                }
                glyph(for: e, tint: tint)
                if e.rootedTurns > 0 {
                    ReticleShape()
                        .stroke(Theme.warning.opacity(0.9), style: StrokeStyle(lineWidth: max(1, cellSize * 0.035)))
                        .frame(width: cellSize * 0.5, height: cellSize * 0.5)
                        .rotationEffect(.degrees(45))
                }
            }
            .frame(height: cellSize * 0.62)
            HPBar(hp: e.hp, maxHp: e.maxHp, tint: e.team == .player ? Theme.good : Theme.danger)
                .frame(width: cellSize * 0.66, height: max(2.5, cellSize * 0.07))
        }
    }

    @ViewBuilder
    private func glyph(for e: Entity, tint: Color) -> some View {
        if let cls = e.classId {
            UnitGlyph(classId: cls, size: cellSize * 0.55, color: tint)
        } else if let kind = e.enemyKind {
            EnemyGlyph(kind: kind, size: cellSize * (kind.isBoss ? 0.62 : 0.55), color: tint)
        } else if let s = e.structureKind {
            StructureGlyph(kind: s, size: cellSize * 0.58)
        }
    }
}

// MARK: - Crack lines for crumbling tiles

struct CrackShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX + w * 0.15, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.4, y: rect.minY + h * 0.35))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + h * 0.7))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.25))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.55, y: rect.minY + h * 0.5))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.7, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX + w * 0.4, y: rect.minY + h * 0.35))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.55, y: rect.minY + h * 0.5))
        return p
    }
}
