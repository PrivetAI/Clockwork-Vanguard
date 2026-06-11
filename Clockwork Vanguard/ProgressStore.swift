import SwiftUI
import AudioToolbox
import UIKit

// MARK: - Persisted blob

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
            earned = (2 + mission.region) + improvement * 3 + (outcome.bonusDone ? 2 : 0)
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
        for r in 0..<5 where regionCleared(r) { a.insert("region\(r)") }
        if totalStars >= 30 { a.insert("stars30") }
        if totalStars >= 60 { a.insert("stars60") }
        if totalStars >= 120 { a.insert("stars120") }
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
        if a != data.achievements { data.achievements = a }
    }

    func isMaxed(_ id: UnitClassID) -> Bool {
        let u = upgrades(for: id)
        return u.hpTier >= UnitUpgrades.maxTier && u.dmgTier >= UnitUpgrades.maxTier
            && u.abilityTier >= UnitUpgrades.maxTier
    }

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
