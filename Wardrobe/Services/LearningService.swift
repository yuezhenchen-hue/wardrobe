import Foundation

/// 用户行为学习服务：追踪偏好、动态调整推荐权重
class LearningService: ObservableObject {
    static let shared = LearningService()

    // MARK: - 学习到的用户偏好权重

    @Published private(set) var colorPairBoosts: [String: Double] = [:]  // "黑色+白色" -> 0.15
    @Published private(set) var styleBoosts: [String: Double] = [:]     // "休闲" -> 0.2
    @Published private(set) var categoryPreferences: [String: Double] = [:] // "上衣" -> 0.1

    private let storageKey = "wardrobe_learning_data"
    private let defaults = UserDefaults.standard

    private init() {
        loadLearningData()
    }

    // MARK: - 信号采集

    /// 穿搭日记评分反馈（最强信号）
    func recordDiaryRating(outfit: Outfit, rating: Int) {
        // rating: 1-5, 中间值3为中性
        let delta = Double(rating - 3) * 0.03  // ±0.03 ~ ±0.06 per event

        learnFromOutfitStyles(outfit, delta: delta)
        learnFromOutfitColors(outfit, delta: delta)
        learnFromCategories(outfit, delta: delta)
        saveLearningData()
    }

    /// 保存推荐方案（中等正向信号）
    func recordOutfitSaved(outfit: Outfit) {
        learnFromOutfitStyles(outfit, delta: 0.02)
        learnFromOutfitColors(outfit, delta: 0.02)
        saveLearningData()
    }

    /// 刷新推荐（弱负向信号）
    func recordRecommendationRefreshed(outfits: [Outfit]) {
        for outfit in outfits {
            learnFromOutfitStyles(outfit, delta: -0.005)
        }
        saveLearningData()
    }

    /// 衣物穿着记录（隐式正向信号）
    func recordItemWorn(item: ClothingItem) {
        for style in item.styles {
            adjustStyleBoost(style.rawValue, delta: 0.01)
        }
        if let color = item.colors.first {
            adjustCategoryPreference(item.category.rawValue, delta: 0.005)
            _ = color // 记录颜色偏好也可以
        }
        saveLearningData()
    }

    // MARK: - 查询学习权重

    /// 获取风格加成分
    func styleBoost(for style: ClothingStyle) -> Double {
        styleBoosts[style.rawValue] ?? 0.0
    }

    /// 获取颜色组合加成分
    func colorPairBoost(color1: String, color2: String) -> Double {
        let key = [color1, color2].sorted().joined(separator: "+")
        return colorPairBoosts[key] ?? 0.0
    }

    /// 获取品类偏好分
    func categoryBoost(for category: ClothingCategory) -> Double {
        categoryPreferences[category.rawValue] ?? 0.0
    }

    /// 获取综合学习加成（用于推荐评分）
    func outfitBoostScore(for outfit: Outfit) -> Double {
        var boost = 0.0

        // 风格加成
        let styles = outfit.items.flatMap(\.styles)
        for style in styles {
            boost += styleBoost(for: style) * 0.5
        }

        // 颜色组合加成
        let colors = outfit.items.compactMap(\.colors.first?.name)
        for i in 0..<colors.count {
            for j in (i+1)..<colors.count {
                boost += colorPairBoost(color1: colors[i], color2: colors[j]) * 0.3
            }
        }

        return min(2.0, max(-1.0, boost))
    }

    // MARK: - 同步风格矩阵

    func syncToStyleMatrix() {
        let matrix = StyleMatrix.shared
        for (style, boost) in styleBoosts {
            for occasion in ["日常", "工作", "约会", "派对", "运动", "旅行"] {
                matrix.adjustOccasionStyleScore(
                    occasion: occasion,
                    style: style,
                    delta: boost * 0.1
                )
            }
        }
    }

    // MARK: - Private

    private func learnFromOutfitStyles(_ outfit: Outfit, delta: Double) {
        let styles = outfit.items.flatMap(\.styles)
        for style in styles {
            adjustStyleBoost(style.rawValue, delta: delta)
        }
    }

    private func learnFromOutfitColors(_ outfit: Outfit, delta: Double) {
        let colors = outfit.items.compactMap(\.colors.first?.name)
        for i in 0..<colors.count {
            for j in (i+1)..<colors.count {
                let key = [colors[i], colors[j]].sorted().joined(separator: "+")
                let current = colorPairBoosts[key] ?? 0.0
                colorPairBoosts[key] = clamp(current + delta)
            }
        }
    }

    private func learnFromCategories(_ outfit: Outfit, delta: Double) {
        for item in outfit.items {
            adjustCategoryPreference(item.category.rawValue, delta: delta)
        }
    }

    private func adjustStyleBoost(_ style: String, delta: Double) {
        let current = styleBoosts[style] ?? 0.0
        styleBoosts[style] = clamp(current + delta)
    }

    private func adjustCategoryPreference(_ category: String, delta: Double) {
        let current = categoryPreferences[category] ?? 0.0
        categoryPreferences[category] = clamp(current + delta)
    }

    /// 限制权重范围避免极端值
    private func clamp(_ value: Double) -> Double {
        min(1.0, max(-0.5, value))
    }

    // MARK: - Persistence

    private struct LearningData: Codable {
        var colorPairBoosts: [String: Double]
        var styleBoosts: [String: Double]
        var categoryPreferences: [String: Double]
    }

    private func saveLearningData() {
        let data = LearningData(
            colorPairBoosts: colorPairBoosts,
            styleBoosts: styleBoosts,
            categoryPreferences: categoryPreferences
        )
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: storageKey)
        }
    }

    private func loadLearningData() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(LearningData.self, from: data) else { return }
        colorPairBoosts = decoded.colorPairBoosts
        styleBoosts = decoded.styleBoosts
        categoryPreferences = decoded.categoryPreferences
    }
}
