import SwiftUI
import AudioToolbox
import UIKit

// MARK: - Persisted blob

struct SkirmishStats: Codable, Equatable {
    var battlesWon: Int = 0
    var bestEndlessDepth: Int = 0
    var dailyCompletions: Int = 0
    var lastDailyDay: Int = 0          // yyyymmdd of the last completed Daily Operation
    var coresEarned: Int = 0
}

struct VanguardSaveData: Codable, Equatable {
    var missionStars: [Int: Int] = [:]          // mission id -> 0...3
    var cores: Int = 0
    var upgrades: [String: UnitUpgrades] = [:]  // class raw value -> tiers
    var achievements: Set<String> = []
    var stats: CampaignStats = CampaignStats()
    var encounteredEnemies: Set<String> = []
    var soundOn: Bool = true
    var hapticsOn: Bool = true
    var onboardingDone: Bool = false
    var lastSquad: [String] = []
    // Enrichment additions (decoded tolerantly so older saves upgrade cleanly):
    var doctrinesOwned: Set<String> = []
    var doctrinesEquipped: [String] = []        // ordered, capped at the loadout size
    var skirmish: SkirmishStats = SkirmishStats()

    init() {}

    private enum CodingKeys: String, CodingKey {
        case missionStars, cores, upgrades, achievements, stats, encounteredEnemies
        case soundOn, hapticsOn, onboardingDone, lastSquad
        case doctrinesOwned, doctrinesEquipped, skirmish
    }

    // Tolerant decode: any key absent in an older save falls back to its default,
    // so adding fields never wipes existing progress.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        missionStars = try c.decodeIfPresent([Int: Int].self, forKey: .missionStars) ?? [:]
        cores = try c.decodeIfPresent(Int.self, forKey: .cores) ?? 0
        upgrades = try c.decodeIfPresent([String: UnitUpgrades].self, forKey: .upgrades) ?? [:]
        achievements = try c.decodeIfPresent(Set<String>.self, forKey: .achievements) ?? []
        stats = try c.decodeIfPresent(CampaignStats.self, forKey: .stats) ?? CampaignStats()
        encounteredEnemies = try c.decodeIfPresent(Set<String>.self, forKey: .encounteredEnemies) ?? []
        soundOn = try c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? true
        hapticsOn = try c.decodeIfPresent(Bool.self, forKey: .hapticsOn) ?? true
        onboardingDone = try c.decodeIfPresent(Bool.self, forKey: .onboardingDone) ?? false
        lastSquad = try c.decodeIfPresent([String].self, forKey: .lastSquad) ?? []
        doctrinesOwned = try c.decodeIfPresent(Set<String>.self, forKey: .doctrinesOwned) ?? []
        doctrinesEquipped = try c.decodeIfPresent([String].self, forKey: .doctrinesEquipped) ?? []
        skirmish = try c.decodeIfPresent(SkirmishStats.self, forKey: .skirmish) ?? SkirmishStats()
    }
}

// MARK: - Store

final class ProgressStore: ObservableObject {

    static let saveKey = "cwv.save.v1"

    @Published private(set) var data: VanguardSaveData {
        didSet { persist() }
    }

    init() {
        if let raw = UserDefaults.standard.data(forKey: ProgressStore.saveKey),
           let decoded = try? JSONDecoder().decode(VanguardSaveData.self, from: raw) {
            data = decoded
        } else {
            data = VanguardSaveData()
        }
    }

    private func persist() {
        if let raw = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(raw, forKey: ProgressStore.saveKey)
        }
    }

    // MARK: Derived state

    var totalStars: Int { data.missionStars.values.reduce(0, +) }
    var cores: Int { data.cores }
    var stats: CampaignStats { data.stats }
    var soundOn: Bool { data.soundOn }
    var hapticsOn: Bool { data.hapticsOn }
    var onboardingDone: Bool { data.onboardingDone }

    func stars(missionId: Int) -> Int { data.missionStars[missionId] ?? 0 }

    func regionUnlocked(_ region: RegionDef) -> Bool { totalStars >= region.starsRequired }

    func regionCleared(_ regionId: Int) -> Bool {
        stars(missionId: regionId * 100 + 7) > 0
    }

    func regionStars(_ regionId: Int) -> Int {
        MissionCatalog.missions(inRegion: regionId).reduce(0) { $0 + stars(missionId: $1.id) }
    }

    /// Mission is playable if its region is unlocked and the previous mission was won.
    func missionUnlocked(_ mission: MissionDef) -> Bool {
        guard let region = GameContent.regions.first(where: { $0.id == mission.region }),
              regionUnlocked(region) else { return false }
        if mission.index == 0 { return true }
        return stars(missionId: mission.region * 100 + mission.index - 1) > 0
    }

    // MARK: Unit roster

    static let unlockThresholds: [UnitClassID: Int] = [
        .pistonKnight: 0, .cogArcher: 0, .steamBulwark: 0,
        .gearSapper: 8, .brassLancer: 18, .chronoTinker: 30
    ]

    func unitUnlocked(_ id: UnitClassID) -> Bool {
        totalStars >= (ProgressStore.unlockThresholds[id] ?? 0)
    }

    var unlockedUnits: [UnitClassID] {
        UnitClassID.allCases.filter { unitUnlocked($0) }
    }

    func upgrades(for id: UnitClassID) -> UnitUpgrades {
        data.upgrades[id.rawValue] ?? UnitUpgrades()
    }

    var allUpgrades: [UnitClassID: UnitUpgrades] {
        var result: [UnitClassID: UnitUpgrades] = [:]
        for id in UnitClassID.allCases { result[id] = upgrades(for: id) }
        return result
    }

    // MARK: Upgrade purchases

    static let tierCosts = [8, 14, 22]   // cost to reach tier 1, 2, 3

    enum UpgradeTrack { case hp, dmg, ability }

    func currentTier(_ id: UnitClassID, _ track: UpgradeTrack) -> Int {
        let u = upgrades(for: id)
        switch track {
        case .hp: return u.hpTier
        case .dmg: return u.dmgTier
        case .ability: return u.abilityTier
        }
    }

    func upgradeCost(_ id: UnitClassID, _ track: UpgradeTrack) -> Int? {
        let tier = currentTier(id, track)
        guard tier < UnitUpgrades.maxTier else { return nil }
        return ProgressStore.tierCosts[tier]
    }

    @discardableResult
    func purchaseUpgrade(_ id: UnitClassID, _ track: UpgradeTrack) -> Bool {
        guard let cost = upgradeCost(id, track), data.cores >= cost else { return false }
        var u = upgrades(for: id)
        switch track {
        case .hp: u.hpTier += 1
        case .dmg: u.dmgTier += 1
        case .ability: u.abilityTier += 1
        }
        data.cores -= cost
        data.upgrades[id.rawValue] = u
        evaluateAchievements()
        return true
    }

    // MARK: Squad memory

    var lastSquad: [UnitClassID] {
        data.lastSquad.compactMap { UnitClassID(rawValue: $0) }.filter { unitUnlocked($0) }
    }

    func rememberSquad(_ squad: [UnitClassID]) {
        data.lastSquad = squad.map { $0.rawValue }
    }

    // MARK: Battle results

    struct BattleReward {
        let coresEarned: Int
        let newStars: Int
        let oldStars: Int
        let newAchievements: [AchievementDef]
    }

    @discardableResult
    func applyBattleResult(mission: MissionDef, outcome: BattleOutcome,
                           battleStats: CampaignStats, encountered: Set<String>,
                           flawless: Bool) -> BattleReward {
        let before = data.achievements

        // merge stats
        var s = data.stats
        s.battlesFought += battleStats.battlesFought
        s.missionsWon += battleStats.missionsWon
        s.enemiesDestroyed += battleStats.enemiesDestroyed
        s.bossesDestroyed += battleStats.bossesDestroyed
        s.unitsLost += battleStats.unitsLost
        s.hazardKills += battleStats.hazardKills
        s.trapKills += battleStats.trapKills
        s.redirectKills += battleStats.redirectKills
        s.pitKills += battleStats.pitKills
        s.collisions += battleStats.collisions
        s.turnsPlayed += battleStats.turnsPlayed
        s.bonusObjectives += battleStats.bonusObjectives

        data.encounteredEnemies.formUnion(encountered)

        var earned = 0
        let old = stars(missionId: mission.id)
        if outcome.victory {
            let improvement = max(0, outcome.stars - old)
            let base = (2 + mission.region) + improvement * 3 + (outcome.bonusDone ? 2 : 0)
            let eq = equippedDoctrines
            earned = Int((Double(base) * DoctrineCatalog.coreMultiplier(for: eq)).rounded())
                + DoctrineCatalog.flatVictoryBonus(for: eq)
            data.cores += earned
            s.coresEarned += earned
            if outcome.stars > old {
                data.missionStars[mission.id] = outcome.stars
            }
        }
        data.stats = s
        evaluateAchievements(flawlessWin: outcome.victory && flawless)

        let newOnes = data.achievements.subtracting(before)
        let defs = GameContent.achievements.filter { newOnes.contains($0.id) }
        return BattleReward(coresEarned: earned, newStars: outcome.victory ? outcome.stars : 0,
                            oldStars: old, newAchievements: defs)
    }

    func markEncountered(_ kinds: Set<String>) {
        if !kinds.subtracting(data.encounteredEnemies).isEmpty {
            data.encounteredEnemies.formUnion(kinds)
        }
    }

    func enemySeen(_ kind: EnemyKind) -> Bool {
        data.encounteredEnemies.contains(kind.rawValue)
    }

    // MARK: Achievements

    func achievementUnlocked(_ id: String) -> Bool { data.achievements.contains(id) }

    func evaluateAchievements(flawlessWin: Bool = false) {
        var a = data.achievements
        let s = data.stats
        if s.missionsWon >= 1 { a.insert("firstWin") }
        for r in 0..<6 where regionCleared(r) { a.insert("region\(r)") }
        if totalStars >= 30 { a.insert("stars30") }
        if totalStars >= 60 { a.insert("stars60") }
        if totalStars >= 144 { a.insert("stars120") }
        if s.pitKills >= 1 { a.insert("pitKill") }
        if s.hazardKills >= 10 { a.insert("hazard10") }
        if s.redirectKills >= 1 { a.insert("redirect") }
        if s.trapKills >= 1 { a.insert("trapKill") }
        if flawlessWin { a.insert("flawless") }
        if UnitClassID.allCases.contains(where: { isMaxed($0) }) { a.insert("maxUnit") }
        if UnitClassID.allCases.allSatisfy({ unitUnlocked($0) }) { a.insert("allUnits") }
        if s.missionsWon >= 10 { a.insert("wins10") }
        let allWon = MissionCatalog.all.allSatisfy { stars(missionId: $0.id) > 0 }
        if allWon { a.insert("wins40") }
        if s.enemiesDestroyed >= 100 { a.insert("kills100") }
        if s.bonusObjectives >= 20 { a.insert("bonus20") }
        // Skirmish & doctrine milestones
        if data.skirmish.battlesWon >= 1 { a.insert("skirmishWin") }
        if data.skirmish.bestEndlessDepth >= 8 { a.insert("endless8") }
        if data.skirmish.dailyCompletions >= 5 { a.insert("daily5") }
        if data.doctrinesEquipped.count >= DoctrineCatalog.loadoutSlots { a.insert("fullDoctrine") }
        if data.doctrinesOwned.count >= DoctrineCatalog.all.count { a.insert("allDoctrines") }
        if a != data.achievements { data.achievements = a }
    }

    func isMaxed(_ id: UnitClassID) -> Bool {
        let u = upgrades(for: id)
        return u.hpTier >= UnitUpgrades.maxTier && u.dmgTier >= UnitUpgrades.maxTier
            && u.abilityTier >= UnitUpgrades.maxTier
    }

    // MARK: Doctrines

    var ownedDoctrines: Set<DoctrineID> {
        Set(data.doctrinesOwned.compactMap { DoctrineID(rawValue: $0) })
    }
    var equippedDoctrines: Set<DoctrineID> {
        Set(data.doctrinesEquipped.compactMap { DoctrineID(rawValue: $0) })
    }
    var equippedDoctrineList: [DoctrineID] {
        data.doctrinesEquipped.compactMap { DoctrineID(rawValue: $0) }
    }
    func ownsDoctrine(_ id: DoctrineID) -> Bool { data.doctrinesOwned.contains(id.rawValue) }
    func isEquipped(_ id: DoctrineID) -> Bool { data.doctrinesEquipped.contains(id.rawValue) }

    var activeModifiers: BattleModifiers {
        DoctrineCatalog.battleModifiers(for: equippedDoctrines)
    }

    @discardableResult
    func purchaseDoctrine(_ id: DoctrineID) -> Bool {
        guard !ownsDoctrine(id) else { return false }
        let cost = DoctrineCatalog.def(id).cost
        guard data.cores >= cost else { return false }
        data.cores -= cost
        data.doctrinesOwned.insert(id.rawValue)
        evaluateAchievements()
        return true
    }

    /// Toggle a doctrine in/out of the active loadout. Returns false if equipping
    /// would exceed the slot cap (or the doctrine isn't owned).
    @discardableResult
    func toggleDoctrine(_ id: DoctrineID) -> Bool {
        guard ownsDoctrine(id) else { return false }
        if let idx = data.doctrinesEquipped.firstIndex(of: id.rawValue) {
            data.doctrinesEquipped.remove(at: idx)
            return true
        }
        guard data.doctrinesEquipped.count < DoctrineCatalog.loadoutSlots else { return false }
        data.doctrinesEquipped.append(id.rawValue)
        evaluateAchievements()
        return true
    }

    // MARK: Skirmish results

    var skirmish: SkirmishStats { data.skirmish }

    struct SkirmishReward {
        let coresEarned: Int
        let newAchievements: [AchievementDef]
        let isDaily: Bool
        let depthReached: Int
    }

    @discardableResult
    func applySkirmishResult(victory: Bool, baseCores: Int, isDaily: Bool, dayKey: Int,
                             depth: Int, battleStats: CampaignStats,
                             encountered: Set<String>) -> SkirmishReward {
        let before = data.achievements

        var s = data.stats
        s.battlesFought += battleStats.battlesFought
        s.enemiesDestroyed += battleStats.enemiesDestroyed
        s.bossesDestroyed += battleStats.bossesDestroyed
        s.hazardKills += battleStats.hazardKills
        s.trapKills += battleStats.trapKills
        s.redirectKills += battleStats.redirectKills
        s.pitKills += battleStats.pitKills
        s.collisions += battleStats.collisions
        s.turnsPlayed += battleStats.turnsPlayed
        data.encounteredEnemies.formUnion(encountered)

        var earned = 0
        var sk = data.skirmish
        if victory {
            let eq = equippedDoctrines
            earned = Int((Double(baseCores) * DoctrineCatalog.coreMultiplier(for: eq)).rounded())
                + DoctrineCatalog.flatVictoryBonus(for: eq)
            data.cores += earned
            s.coresEarned += earned
            sk.battlesWon += 1
            sk.coresEarned += earned
            sk.bestEndlessDepth = max(sk.bestEndlessDepth, depth)
            if isDaily {
                if sk.lastDailyDay != dayKey { sk.dailyCompletions += 1 }
                sk.lastDailyDay = dayKey
            }
        }
        data.stats = s
        data.skirmish = sk
        evaluateAchievements()

        let newOnes = data.achievements.subtracting(before)
        let defs = GameContent.achievements.filter { newOnes.contains($0.id) }
        return SkirmishReward(coresEarned: earned, newAchievements: defs,
                              isDaily: isDaily, depthReached: depth)
    }

    /// True if today's Daily Operation has already been completed.
    func dailyDone(dayKey: Int) -> Bool { data.skirmish.lastDailyDay == dayKey }

    // MARK: Settings

    func setSound(_ on: Bool) { data.soundOn = on }
    func setHaptics(_ on: Bool) { data.hapticsOn = on }
    func finishOnboarding() { data.onboardingDone = true }

    func resetProgress() {
        let sound = data.soundOn
        let haptics = data.hapticsOn
        var fresh = VanguardSaveData()
        fresh.soundOn = sound
        fresh.hapticsOn = haptics
        fresh.onboardingDone = true
        data = fresh
    }

    // MARK: Feedback

    func tapFeedback() {
        if data.soundOn { AudioServicesPlaySystemSound(1104) }
        if data.hapticsOn { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    }

    func heavyFeedback() {
        if data.soundOn { AudioServicesPlaySystemSound(1105) }
        if data.hapticsOn { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    }

    func successFeedback() {
        if data.soundOn { AudioServicesPlaySystemSound(1057) }
        if data.hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    }

    func failureFeedback() {
        if data.soundOn { AudioServicesPlaySystemSound(1053) }
        if data.hapticsOn { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    }
}
