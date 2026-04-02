import Foundation

/// 多阶段关联评分推荐引擎
/// Phase 1: 候选过滤（天气+季节）
/// Phase 2: 锚点选择（独立评分选上衣）
/// Phase 3: 关联选品（后续单品考虑已选单品的颜色、风格、正式度协调）
/// Phase 4: 整套评分
class RecommendationEngine {
    static let shared = RecommendationEngine()

    private let matrix = StyleMatrix.shared
    private let learning = LearningService.shared

    private init() {}

    // MARK: - 评分权重配置

    struct ScoringWeights {
        var colorHarmony: Double = 0.30
        var styleConsistency: Double = 0.25
        var formalityCoherence: Double = 0.20
        var occasionMatch: Double = 0.15
        var userPreference: Double = 0.10

        static let `default` = ScoringWeights()
    }

    // MARK: - 生成单套搭配

    func generateOutfit(
        from wardrobe: [ClothingItem],
        weather: WeatherInfo,
        occasion: Occasion,
        profile: UserProfile,
        weights: ScoringWeights = .default
    ) -> Outfit {
        // Phase 1: 候选过滤
        let candidates = filterCandidates(wardrobe: wardrobe, weather: weather)

        // Phase 2 & 3: 按品类序列化选品
        let selectionOrder: [ClothingCategory] = buildSelectionOrder(weather: weather)
        var selectedItems: [ClothingItem] = []

        for category in selectionOrder {
            if let best = selectBestItem(
                from: candidates,
                category: category,
                occasion: occasion,
                profile: profile,
                alreadySelected: selectedItems,
                weights: weights
            ) {
                selectedItems.append(best)
            }
        }

        // Phase 4: 整套评分
        let outfitScore = scoreCompleteOutfit(items: selectedItems, occasion: occasion, profile: profile)
        let outfitName = generateOutfitName(occasion: occasion, weather: weather, score: outfitScore)

        return Outfit(
            name: outfitName,
            items: selectedItems,
            occasion: occasion.rawValue,
            seasons: currentSeason.map { [$0] } ?? [],
            styles: determineOutfitStyles(items: selectedItems),
            rating: Int(outfitScore * 5),
            isAIGenerated: true
        )
    }

    // MARK: - 生成多套搭配（去重）

    func generateMultipleOutfits(
        from wardrobe: [ClothingItem],
        weather: WeatherInfo,
        occasion: Occasion,
        profile: UserProfile,
        count: Int = 3
    ) -> [Outfit] {
        var outfits: [Outfit] = []
        var usedItemIDs: Set<UUID> = []

        for i in 0..<count {
            let available = wardrobe.filter { !usedItemIDs.contains($0.id) }
            guard !available.isEmpty else { break }

            // 后续方案适当增加随机性以差异化
            var weights = ScoringWeights.default
            weights.colorHarmony += Double(i) * 0.05
            weights.styleConsistency -= Double(i) * 0.03

            let outfit = generateOutfit(
                from: available,
                weather: weather,
                occasion: occasion,
                profile: profile,
                weights: weights
            )

            if !outfit.items.isEmpty {
                outfits.append(outfit)
                outfit.items.forEach { usedItemIDs.insert($0.id) }
            }
        }

        // 按整套评分排序
        outfits.sort { ($0.rating) > ($1.rating) }

        if outfits.isEmpty {
            let fallback = generateOutfit(from: wardrobe, weather: weather, occasion: occasion, profile: profile)
            if !fallback.items.isEmpty {
                outfits.append(fallback)
            }
        }

        return outfits
    }

    // MARK: - 购物建议

    func suggestMissingItems(wardrobe: [ClothingItem], profile: UserProfile) -> [ShoppingItem] {
        var suggestions: [ShoppingItem] = []

        let categoryCount = Dictionary(grouping: wardrobe, by: \.category).mapValues(\.count)
        let essentialCategories: [(ClothingCategory, Int, String)] = [
            (.top, 5, "基础上衣是衣橱核心，建议至少5件以覆盖不同场合"),
            (.bottom, 3, "下装搭配需要多样性，建议至少3条"),
            (.outerwear, 2, "外套是换季必备，建议至少2件不同厚度"),
            (.shoes, 3, "不同场合需要不同鞋子，建议至少3双"),
        ]

        for (category, minCount, reason) in essentialCategories {
            let current = categoryCount[category] ?? 0
            if current < minCount {
                suggestions.append(ShoppingItem(
                    category: category,
                    suggestion: "建议添加\(category.rawValue)",
                    reason: reason,
                    currentCount: current,
                    recommendedCount: minCount
                ))
            }
        }

        // 检查百搭色缺失
        let allColorNames = Set(wardrobe.flatMap(\.colors).map(\.name))
        let essentialColors = ["白色", "黑色"]
        for color in essentialColors where !allColorNames.contains(color) {
            suggestions.append(ShoppingItem(
                category: .top,
                suggestion: "\(color)基础款",
                reason: "\(color)是百搭色，衣橱中不可缺少",
                currentCount: 0,
                recommendedCount: 1
            ))
        }

        // 检查风格单一性
        let allStyles = wardrobe.flatMap(\.styles)
        let styleSet = Set(allStyles)
        if styleSet.count < 3 && wardrobe.count > 5 {
            let missing = ClothingStyle.allCases.filter { !styleSet.contains($0) }
            if let suggested = missing.first {
                suggestions.append(ShoppingItem(
                    category: .top,
                    suggestion: "尝试\(suggested.rawValue)风格单品",
                    reason: "衣橱风格较单一，增加多样性可以应对更多场合",
                    currentCount: styleSet.count,
                    recommendedCount: 3
                ))
            }
        }

        return suggestions
    }

    // MARK: - Phase 1: 候选过滤

    private func filterCandidates(wardrobe: [ClothingItem], weather: WeatherInfo) -> [ClothingItem] {
        wardrobe.filter { item in
            let seasonOK = currentSeason.map { item.seasons.contains($0) } ?? true
            let warmthOK = weather.recommendedWarmthLevel.contains(item.warmthLevel)
            // 宽松过滤：季节合适 或 保暖度合适
            return seasonOK || warmthOK
        }
    }

    // MARK: - Phase 2 & 3: 关联选品

    private func buildSelectionOrder(weather: WeatherInfo) -> [ClothingCategory] {
        var order: [ClothingCategory] = [.top, .bottom]
        if weather.temperature < 20 {
            order.append(.outerwear)
        }
        order.append(contentsOf: [.shoes, .bag])
        return order
    }

    /// 核心评分函数：综合考虑场合匹配 + 用户偏好 + 与已选单品的协调度
    private func selectBestItem(
        from candidates: [ClothingItem],
        category: ClothingCategory,
        occasion: Occasion,
        profile: UserProfile,
        alreadySelected: [ClothingItem],
        weights: ScoringWeights
    ) -> ClothingItem? {
        let categoryItems = candidates.filter { $0.category == category }
        guard !categoryItems.isEmpty else { return nil }

        let scored = categoryItems.map { item -> (ClothingItem, Double) in
            var score = 0.0

            // 维度 1: 场合风格匹配（使用评分矩阵，非硬编码）
            let occasionScore = item.styles.map { matrix.score(occasion: occasion.rawValue, style: $0) }.max() ?? 0.3
            score += occasionScore * weights.occasionMatch * 10

            // 维度 2: 用户风格偏好匹配
            let preferenceOverlap = Set(item.styles).intersection(Set(profile.preferredStyles)).count
            let preferenceScore = min(1.0, Double(preferenceOverlap) * 0.5)
            score += preferenceScore * weights.userPreference * 10

            // 维度 3: 颜色和谐度（与已选单品）
            if !alreadySelected.isEmpty {
                let colorScore = matrix.colorHarmonyScore(candidate: item, selected: alreadySelected)
                score += colorScore * weights.colorHarmony * 10
            } else {
                score += 0.7 * weights.colorHarmony * 10
            }

            // 维度 4: 风格一致性（与已选单品）
            if !alreadySelected.isEmpty {
                let styleScore = matrix.styleConsistencyScore(candidate: item, selected: alreadySelected)
                score += styleScore * weights.styleConsistency * 10
            } else {
                score += 0.7 * weights.styleConsistency * 10
            }

            // 维度 5: 正式度协调（与已选单品）
            if !alreadySelected.isEmpty {
                let formalityScore = matrix.formalityCoherenceScore(candidate: item, selected: alreadySelected)
                score += formalityScore * weights.formalityCoherence * 10
            } else {
                score += 0.7 * weights.formalityCoherence * 10
            }

            // 额外加分项
            if item.isFavorite { score += 0.5 }

            // 学习权重加成
            let learnBoost = item.styles.map { learning.styleBoost(for: $0) }.reduce(0.0, +)
            score += learnBoost

            // 随机探索因子（防止过拟合）
            score += Double.random(in: 0...0.8)

            return (item, score)
        }

        return scored.max(by: { $0.1 < $1.1 })?.0
    }

    // MARK: - Phase 4: 整套评分

    func scoreCompleteOutfit(items: [ClothingItem], occasion: Occasion, profile: UserProfile) -> Double {
        guard items.count >= 2 else { return 0.3 }

        // 配色和谐度
        var colorScoreSum = 0.0
        var colorPairCount = 0
        for i in 0..<items.count {
            for j in (i+1)..<items.count {
                colorScoreSum += matrix.colorMatchScore(item1: items[i], item2: items[j])
                colorPairCount += 1
            }
        }
        let colorHarmony = colorPairCount > 0 ? colorScoreSum / Double(colorPairCount) : 0.5

        // 风格一致性
        let allStyles = items.flatMap(\.styles)
        let uniqueStyles = Set(allStyles)
        let styleCounts = Dictionary(grouping: allStyles, by: { $0 }).mapValues(\.count)
        let dominantStyleRatio = Double(styleCounts.values.max() ?? 0) / Double(allStyles.count)
        let styleConsistency = min(1.0, dominantStyleRatio + 0.2)

        // 正式度协调
        let formalityLevels = items.map { matrix.formalityLevel(of: $0) }
        let mean = formalityLevels.reduce(0.0, +) / Double(formalityLevels.count)
        let variance = formalityLevels.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(formalityLevels.count)
        let formalityCoherence = max(0, 1.0 - sqrt(variance) * 2.0)

        // 场合匹配度
        let occasionScores = items.flatMap(\.styles).map { matrix.score(occasion: occasion.rawValue, style: $0) }
        let occasionMatch = occasionScores.isEmpty ? 0.3 : occasionScores.reduce(0.0, +) / Double(occasionScores.count)

        // 品类完整度
        let categories = Set(items.map(\.category))
        let completeness: Double = {
            var score = 0.0
            if categories.contains(.top) || categories.contains(.dress) { score += 0.3 }
            if categories.contains(.bottom) || categories.contains(.dress) { score += 0.3 }
            if categories.contains(.shoes) { score += 0.2 }
            if categories.contains(.outerwear) || categories.contains(.bag) || categories.contains(.accessory) { score += 0.2 }
            return score
        }()

        // 学习加成
        let learnBoost = learning.outfitBoostScore(for: Outfit(items: items))

        let finalScore = colorHarmony * 0.25
            + styleConsistency * 0.2
            + formalityCoherence * 0.15
            + occasionMatch * 0.2
            + completeness * 0.15
            + min(0.1, max(-0.05, learnBoost * 0.05))

        return min(1.0, max(0.0, finalScore))
    }

    // MARK: - Helpers

    private var currentSeason: Season? {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }

    private func determineOutfitStyles(items: [ClothingItem]) -> [ClothingStyle] {
        let allStyles = items.flatMap(\.styles)
        let styleCounts = Dictionary(grouping: allStyles, by: { $0 }).mapValues(\.count)
        return styleCounts.sorted { $0.value > $1.value }.prefix(2).map(\.key)
    }

    private func generateOutfitName(occasion: Occasion, weather: WeatherInfo, score: Double) -> String {
        let tempWord: String = {
            switch weather.temperature {
            case ..<10: return "温暖"
            case 10..<20: return "舒适"
            case 20..<28: return "清爽"
            default: return "清凉"
            }
        }()
        let qualityWord: String = {
            switch score {
            case 0.8...: return "精选"
            case 0.6..<0.8: return "推荐"
            default: return ""
            }
        }()
        return "\(qualityWord)\(tempWord)\(occasion.rawValue)穿搭"
    }
}

struct ShoppingItem: Identifiable {
    let id = UUID()
    let category: ClothingCategory
    let suggestion: String
    let reason: String
    let currentCount: Int
    let recommendedCount: Int
}
