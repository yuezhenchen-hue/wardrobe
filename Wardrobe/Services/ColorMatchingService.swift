import Foundation
import SwiftUI

class ColorMatchingService {
    static let shared = ColorMatchingService()
    private init() {}

    struct ColorHarmony {
        let name: String
        let description: String
        let score: Double
    }

    func analyzeColorHarmony(colors: [ClothingColor]) -> ColorHarmony {
        guard colors.count >= 2 else {
            return ColorHarmony(name: "单色", description: "简洁大方的单色穿搭", score: 0.7)
        }

        let names = colors.map(\.name)

        let neutralColors = Set(["黑色", "白色", "灰色", "米色"])
        let neutralCount = names.filter { neutralColors.contains($0) }.count

        if neutralCount == colors.count {
            return ColorHarmony(name: "经典中性", description: "黑白灰搭配永不过时，简约有质感", score: 0.9)
        }

        if neutralCount >= colors.count - 1 {
            return ColorHarmony(name: "点缀搭配", description: "中性色为主+亮色点缀，层次分明", score: 0.95)
        }

        let warmColors = Set(["红色", "橙色", "黄色", "棕色", "酒红", "粉色"])
        let coolColors = Set(["蓝色", "藏蓝", "绿色", "紫色", "军绿"])

        let warmCount = names.filter { warmColors.contains($0) }.count
        let coolCount = names.filter { coolColors.contains($0) }.count

        if warmCount > 0 && coolCount > 0 {
            return ColorHarmony(name: "撞色搭配", description: "冷暖色对比，时尚大胆", score: 0.7)
        }

        if warmCount >= 2 {
            return ColorHarmony(name: "暖色系", description: "温暖柔和的色调组合", score: 0.85)
        }

        if coolCount >= 2 {
            return ColorHarmony(name: "冷色系", description: "清爽知性的色调组合", score: 0.85)
        }

        return ColorHarmony(name: "自由搭配", description: "展现个人风格的配色", score: 0.6)
    }

    func suggestComplementaryColors(for color: ClothingColor) -> [ClothingColor] {
        let complementMap: [String: [String]] = [
            "黑色": ["白色", "红色", "粉色", "米色"],
            "白色": ["藏蓝", "黑色", "蓝色", "红色"],
            "灰色": ["粉色", "黄色", "蓝色", "白色"],
            "米色": ["棕色", "藏蓝", "军绿", "酒红"],
            "红色": ["黑色", "白色", "藏蓝", "灰色"],
            "粉色": ["灰色", "白色", "藏蓝", "米色"],
            "蓝色": ["白色", "米色", "卡其", "灰色"],
            "藏蓝": ["白色", "米色", "红色", "卡其"],
            "棕色": ["米色", "白色", "蓝色", "卡其"],
            "绿色": ["白色", "米色", "棕色", "黑色"],
            "军绿": ["卡其", "白色", "米色", "黑色"],
            "紫色": ["白色", "灰色", "黑色", "米色"],
            "黄色": ["灰色", "藏蓝", "白色", "黑色"],
            "橙色": ["藏蓝", "白色", "黑色", "米色"],
            "卡其": ["藏蓝", "白色", "棕色", "军绿"],
            "酒红": ["黑色", "米色", "灰色", "白色"],
        ]

        let suggestions = complementMap[color.name] ?? ["白色", "黑色", "灰色"]
        return ClothingColor.presets.filter { suggestions.contains($0.name) }
    }
}
