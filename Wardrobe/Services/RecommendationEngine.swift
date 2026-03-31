import Foundation

class RecommendationEngine {
    static let shared = RecommendationEngine()
    private init() {}

    func generateOutfit(
        from wardrobe: [ClothingItem],
        weather: WeatherInfo,
        occasion: Occasion,
        profile: UserProfile
    ) -> Outfit {
        let suitableItems = wardrobe.filter { item in
            let seasonMatch = currentSeason.map { item.seasons.contains($0) } ?? true
            let warmthMatch = weather.recommendedWarmthLevel.contains(item.warmthLevel)
            return seasonMatch || warmthMatch
        }

        var selectedItems: [ClothingItem] = []

        if let top = selectBest(from: suitableItems, category: .top, occasion: occasion, profile: profile) {
            selectedItems.append(top)
        }

        if let bottom = selectBest(from: suitableItems, category: .bottom, occasion: occasion, profile: profile) {
            selectedItems.append(bottom)
        }

        if weather.temperature < 20,
           let outerwear = selectBest(from: suitableItems, category: .outerwear, occasion: occasion, profile: profile) {
            selectedItems.append(outerwear)
        }

        if let shoes = selectBest(from: suitableItems, category: .shoes, occasion: occasion, profile: profile) {
            selectedItems.append(shoes)
        }

        if let bag = selectBest(from: suitableItems, category: .bag, occasion: occasion, profile: profile) {
            selectedItems.append(bag)
        }

        let outfitName = generateOutfitName(occasion: occasion, weather: weather)

        return Outfit(
            name: outfitName,
            items: selectedItems,
            occasion: occasion.rawValue,
            seasons: currentSeason.map { [$0] } ?? [],
            styles: determineOutfitStyles(items: selectedItems),
            isAIGenerated: true
        )
    }

    func generateMultipleOutfits(
        from wardrobe: [ClothingItem],
        weather: WeatherInfo,
        occasion: Occasion,
        profile: UserProfile,
        count: Int = 3
    ) -> [Outfit] {
        var outfits: [Outfit] = []
        var usedItemIDs: Set<UUID> = []

        for _ in 0..<count {
            let availableItems = wardrobe.filter { !usedItemIDs.contains($0.id) }
            guard !availableItems.isEmpty else { break }

            let outfit = generateOutfit(from: availableItems, weather: weather, occasion: occasion, profile: profile)
            if !outfit.items.isEmpty {
                outfits.append(outfit)
                outfit.items.forEach { usedItemIDs.insert($0.id) }
            }
        }

        if outfits.isEmpty {
            let fallback = generateOutfit(from: wardrobe, weather: weather, occasion: occasion, profile: profile)
            if !fallback.items.isEmpty {
                outfits.append(fallback)
            }
        }

        return outfits
    }

    func suggestMissingItems(wardrobe: [ClothingItem], profile: UserProfile) -> [ShoppingItem] {
        var suggestions: [ShoppingItem] = []

        let categoryCount = Dictionary(grouping: wardrobe, by: \.category).mapValues(\.count)
        let essentialCategories: [(ClothingCategory, Int, String)] = [
            (.top, 5, "基础上衣是衣橱的核心，建议至少有5件"),
            (.bottom, 3, "下装搭配需要多样性，建议至少3条"),
            (.outerwear, 2, "外套是换季必备，建议至少2件"),
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

        let colors = wardrobe.flatMap(\.colors).map(\.name)
        let colorSet = Set(colors)
        if !colorSet.contains("白色") {
            suggestions.append(ShoppingItem(
                category: .top,
                suggestion: "白色基础款",
                reason: "白色是百搭色，衣橱中不可缺少",
                currentCount: 0,
                recommendedCount: 1
            ))
        }

        return suggestions
    }

    func colorMatchScore(item1: ClothingItem, item2: ClothingItem) -> Double {
        guard let color1 = item1.colors.first, let color2 = item2.colors.first else { return 0.5 }
        let matchingPairs: Set<Set<String>> = [
            ["黑色", "白色"], ["藏蓝", "白色"], ["米色", "棕色"],
            ["黑色", "红色"], ["灰色", "粉色"], ["蓝色", "白色"],
            ["军绿", "卡其"], ["酒红", "黑色"], ["白色", "蓝色"],
        ]

        if matchingPairs.contains(Set([color1.name, color2.name])) {
            return 1.0
        }

        if color1.name == "黑色" || color1.name == "白色" || color1.name == "灰色" ||
           color2.name == "黑色" || color2.name == "白色" || color2.name == "灰色" {
            return 0.8
        }

        return 0.5
    }

    // MARK: - Private Helpers

    private func selectBest(
        from items: [ClothingItem],
        category: ClothingCategory,
        occasion: Occasion,
        profile: UserProfile
    ) -> ClothingItem? {
        let categoryItems = items.filter { $0.category == category }
        guard !categoryItems.isEmpty else { return nil }

        let scored = categoryItems.map { item -> (ClothingItem, Double) in
            var score = 0.0

            let occasionStyles = stylesForOccasion(occasion)
            let styleOverlap = Set(item.styles).intersection(Set(occasionStyles)).count
            score += Double(styleOverlap) * 2.0

            let preferenceOverlap = Set(item.styles).intersection(Set(profile.preferredStyles)).count
            score += Double(preferenceOverlap) * 1.5

            if item.isFavorite { score += 1.0 }

            score += Double.random(in: 0...1.5)

            return (item, score)
        }

        return scored.max(by: { $0.1 < $1.1 })?.0
    }

    private func stylesForOccasion(_ occasion: Occasion) -> [ClothingStyle] {
        switch occasion {
        case .daily: return [.casual, .minimalist]
        case .work: return [.business, .formal, .minimalist]
        case .date: return [.romantic, .elegant]
        case .party: return [.streetwear, .elegant]
        case .sport: return [.sporty, .casual]
        case .travel: return [.casual, .sporty]
        case .interview: return [.formal, .business]
        case .wedding: return [.formal, .elegant]
        case .casual: return [.casual, .streetwear]
        case .shopping: return [.casual, .streetwear, .minimalist]
        }
    }

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

    private func generateOutfitName(occasion: Occasion, weather: WeatherInfo) -> String {
        let seasonWord: String = {
            switch weather.temperature {
            case ..<10: return "温暖"
            case 10..<20: return "舒适"
            case 20..<28: return "清爽"
            default: return "清凉"
            }
        }()
        return "\(seasonWord)\(occasion.rawValue)穿搭"
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
