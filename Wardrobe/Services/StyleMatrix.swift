import Foundation

/// 数据驱动的风格评分矩阵，替代硬编码映射
class StyleMatrix {
    static let shared = StyleMatrix()

    // MARK: - 场合×风格匹配度矩阵 (0.0~1.0)

    private var occasionStyleScores: [String: [String: Double]] = [
        "日常": ["休闲": 0.95, "极简": 0.85, "街头": 0.7, "运动": 0.6, "复古": 0.5, "波西米亚": 0.5, "浪漫": 0.3, "商务": 0.1, "正式": 0.05, "优雅": 0.4],
        "工作": ["商务": 0.95, "正式": 0.85, "极简": 0.8, "优雅": 0.7, "休闲": 0.2, "街头": 0.05, "运动": 0.0, "复古": 0.15, "浪漫": 0.1, "波西米亚": 0.05],
        "约会": ["浪漫": 0.95, "优雅": 0.9, "极简": 0.65, "休闲": 0.5, "复古": 0.55, "波西米亚": 0.4, "商务": 0.2, "正式": 0.3, "街头": 0.3, "运动": 0.1],
        "派对": ["优雅": 0.9, "街头": 0.85, "浪漫": 0.7, "复古": 0.65, "休闲": 0.4, "极简": 0.5, "波西米亚": 0.55, "商务": 0.15, "正式": 0.3, "运动": 0.1],
        "运动": ["运动": 0.95, "休闲": 0.75, "街头": 0.5, "极简": 0.3, "商务": 0.0, "正式": 0.0, "优雅": 0.0, "浪漫": 0.0, "复古": 0.05, "波西米亚": 0.05],
        "旅行": ["休闲": 0.95, "运动": 0.7, "街头": 0.6, "极简": 0.65, "波西米亚": 0.6, "复古": 0.4, "优雅": 0.2, "商务": 0.1, "正式": 0.05, "浪漫": 0.3],
        "面试": ["正式": 0.95, "商务": 0.95, "极简": 0.7, "优雅": 0.6, "休闲": 0.1, "街头": 0.0, "运动": 0.0, "浪漫": 0.15, "复古": 0.1, "波西米亚": 0.0],
        "婚礼": ["正式": 0.95, "优雅": 0.95, "浪漫": 0.8, "极简": 0.5, "商务": 0.4, "复古": 0.35, "休闲": 0.05, "街头": 0.0, "运动": 0.0, "波西米亚": 0.3],
        "休闲聚会": ["休闲": 0.95, "街头": 0.8, "极简": 0.7, "复古": 0.6, "波西米亚": 0.55, "浪漫": 0.4, "优雅": 0.3, "运动": 0.35, "商务": 0.1, "正式": 0.05],
        "逛街": ["休闲": 0.9, "街头": 0.85, "极简": 0.75, "运动": 0.5, "复古": 0.5, "波西米亚": 0.45, "浪漫": 0.35, "优雅": 0.25, "商务": 0.05, "正式": 0.05],
    ]

    // MARK: - 风格正式度等级 (0.0=最休闲, 1.0=最正式)

    let formalityLevels: [String: Double] = [
        "正式": 1.0,
        "商务": 0.85,
        "优雅": 0.75,
        "极简": 0.6,
        "浪漫": 0.5,
        "复古": 0.45,
        "休闲": 0.35,
        "波西米亚": 0.3,
        "街头": 0.25,
        "运动": 0.15,
    ]

    // MARK: - 颜色搭配评分矩阵

    /// 颜色对的协调度评分 (0.0~1.0)
    private let colorPairScores: [Set<String>: Double] = {
        var scores: [Set<String>: Double] = [:]
        let perfect: [(String, String)] = [
            ("黑色", "白色"), ("藏蓝", "白色"), ("米色", "棕色"),
            ("藏蓝", "卡其"), ("黑色", "红色"), ("军绿", "卡其"),
            ("灰色", "粉色"), ("白色", "蓝色"), ("酒红", "黑色"),
        ]
        let great: [(String, String)] = [
            ("白色", "红色"), ("米色", "藏蓝"), ("灰色", "蓝色"),
            ("黑色", "粉色"), ("米色", "军绿"), ("白色", "绿色"),
            ("棕色", "蓝色"), ("灰色", "黄色"), ("藏蓝", "红色"),
            ("白色", "橙色"), ("白色", "紫色"), ("米色", "酒红"),
            ("卡其", "白色"), ("棕色", "白色"), ("黑色", "灰色"),
        ]
        let good: [(String, String)] = [
            ("粉色", "白色"), ("粉色", "藏蓝"), ("绿色", "米色"),
            ("紫色", "灰色"), ("橙色", "藏蓝"), ("军绿", "黑色"),
            ("酒红", "灰色"), ("酒红", "米色"), ("黄色", "藏蓝"),
            ("蓝色", "卡其"), ("棕色", "卡其"), ("绿色", "棕色"),
        ]

        for (a, b) in perfect { scores[Set([a, b])] = 1.0 }
        for (a, b) in great { scores[Set([a, b])] = 0.85 }
        for (a, b) in good { scores[Set([a, b])] = 0.7 }
        return scores
    }()

    /// 万能百搭色
    private let neutralColors: Set<String> = ["黑色", "白色", "灰色", "米色", "藏蓝"]

    private init() {}

    // MARK: - Public API

    /// 查询场合×风格的匹配度
    func score(occasion: String, style: ClothingStyle) -> Double {
        occasionStyleScores[occasion]?[style.rawValue] ?? 0.3
    }

    /// 获取场合推荐的前 N 风格
    func topStyles(for occasion: String, count: Int = 3) -> [(ClothingStyle, Double)] {
        guard let scores = occasionStyleScores[occasion] else { return [] }
        return scores
            .compactMap { (key, value) -> (ClothingStyle, Double)? in
                guard let style = ClothingStyle(rawValue: key) else { return nil }
                return (style, value)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(count)
            .map { ($0.0, $0.1) }
    }

    /// 计算衣物的正式度（取其所有风格标签的平均值）
    func formalityLevel(of item: ClothingItem) -> Double {
        guard !item.styles.isEmpty else { return 0.5 }
        let total = item.styles.reduce(0.0) { $0 + (formalityLevels[$1.rawValue] ?? 0.5) }
        return total / Double(item.styles.count)
    }

    /// 计算两件衣物之间的颜色搭配分
    func colorMatchScore(item1: ClothingItem, item2: ClothingItem) -> Double {
        guard let c1 = item1.colors.first, let c2 = item2.colors.first else { return 0.5 }
        if c1.name == c2.name { return 0.6 }
        if let pairScore = colorPairScores[Set([c1.name, c2.name])] {
            return pairScore
        }
        if neutralColors.contains(c1.name) || neutralColors.contains(c2.name) {
            return 0.75
        }
        return 0.4
    }

    /// 计算候选衣物与已选衣物组的综合颜色搭配分
    func colorHarmonyScore(candidate: ClothingItem, selected: [ClothingItem]) -> Double {
        guard !selected.isEmpty else { return 0.7 }
        let scores = selected.map { colorMatchScore(item1: candidate, item2: $0) }
        return scores.reduce(0.0, +) / Double(scores.count)
    }

    /// 计算候选衣物与已选衣物组的风格一致性（Jaccard 相似度）
    func styleConsistencyScore(candidate: ClothingItem, selected: [ClothingItem]) -> Double {
        guard !selected.isEmpty else { return 0.7 }
        let candidateStyles = Set(candidate.styles)
        let selectedStyles = Set(selected.flatMap(\.styles))
        guard !candidateStyles.isEmpty, !selectedStyles.isEmpty else { return 0.5 }
        let intersection = candidateStyles.intersection(selectedStyles).count
        let union = candidateStyles.union(selectedStyles).count
        return Double(intersection) / Double(union)
    }

    /// 计算候选衣物与已选衣物组的正式度协调（标准差越小越好）
    func formalityCoherenceScore(candidate: ClothingItem, selected: [ClothingItem]) -> Double {
        let allItems = selected + [candidate]
        let levels = allItems.map { formalityLevel(of: $0) }
        let mean = levels.reduce(0.0, +) / Double(levels.count)
        let variance = levels.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(levels.count)
        let stddev = sqrt(variance)
        // stddev 0 = 完美协调(1.0), stddev 0.5 = 不太协调(0.0)
        return max(0, 1.0 - stddev * 2.0)
    }

    // MARK: - 学习接口（供 LearningService 动态调整权重）

    func adjustOccasionStyleScore(occasion: String, style: String, delta: Double) {
        guard var scores = occasionStyleScores[occasion] else { return }
        let current = scores[style] ?? 0.3
        scores[style] = min(1.0, max(0.0, current + delta))
        occasionStyleScores[occasion] = scores
    }

    func exportMatrix() -> [String: [String: Double]] {
        occasionStyleScores
    }

    func importMatrix(_ matrix: [String: [String: Double]]) {
        occasionStyleScores = matrix
    }
}
