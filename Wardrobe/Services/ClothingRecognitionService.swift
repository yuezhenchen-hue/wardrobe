import UIKit
import CoreImage
import Vision

/// 衣物图片智能识别服务
/// - 颜色提取：Core Image 提取主色调，映射到预设颜色
/// - 品类识别：Vision 框架图像分类
class ClothingRecognitionService {
    static let shared = ClothingRecognitionService()
    private init() {}

    struct RecognitionResult {
        var suggestedColors: [ClothingColor]
        var suggestedCategory: ClothingCategory?
        var suggestedSubcategory: String
        var suggestedSeasons: [Season]
        var suggestedStyles: [ClothingStyle]
        var confidence: Double
    }

    // MARK: - 主入口

    func recognize(image: UIImage) async -> RecognitionResult {
        async let colors = extractColors(from: image)
        async let classification = classifyClothing(image: image)

        let extractedColors = await colors
        let classResult = await classification

        let category = classResult.category
        let subcategory = classResult.subcategory

        return RecognitionResult(
            suggestedColors: extractedColors,
            suggestedCategory: category,
            suggestedSubcategory: subcategory,
            suggestedSeasons: guessSeasonsFromColors(extractedColors),
            suggestedStyles: guessStylesFromCategory(category),
            confidence: classResult.confidence
        )
    }

    // MARK: - 颜色提取

    /// 从图片中提取主要颜色，映射到预设 ClothingColor
    func extractColors(from image: UIImage, maxColors: Int = 3) async -> [ClothingColor] {
        guard let cgImage = image.cgImage else { return [] }

        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()

        // 缩小图片提高性能
        let scale = min(200.0 / CGFloat(cgImage.width), 200.0 / CGFloat(cgImage.height))
        let resized = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // 把图片分成 9 宫格区域，提取每块的平均色
        let extent = resized.extent
        var regionColors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = []

        let gridSize = 3
        let cellW = extent.width / CGFloat(gridSize)
        let cellH = extent.height / CGFloat(gridSize)

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let rect = CGRect(
                    x: extent.origin.x + CGFloat(col) * cellW,
                    y: extent.origin.y + CGFloat(row) * cellH,
                    width: cellW,
                    height: cellH
                )
                if let avgColor = averageColor(ciImage: resized, rect: rect, context: context) {
                    regionColors.append(avgColor)
                }
            }
        }

        // 聚类找主色调
        let dominantColors = findDominantColors(from: regionColors, count: maxColors)

        // 映射到预设颜色
        return dominantColors.compactMap { mapToPresetColor(r: $0.r, g: $0.g, b: $0.b) }
            .removingDuplicates()
            .prefix(maxColors)
            .map { $0 }
    }

    private func averageColor(ciImage: CIImage, rect: CGRect, context: CIContext) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: rect), forKey: "inputExtent")

        guard let output = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &bitmap, rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

        return (
            r: CGFloat(bitmap[0]) / 255.0,
            g: CGFloat(bitmap[1]) / 255.0,
            b: CGFloat(bitmap[2]) / 255.0
        )
    }

    /// 简单的 K 聚类找主色
    private func findDominantColors(
        from colors: [(r: CGFloat, g: CGFloat, b: CGFloat)],
        count: Int
    ) -> [(r: CGFloat, g: CGFloat, b: CGFloat)] {
        guard !colors.isEmpty else { return [] }

        // 去掉接近白色和接近黑色的背景色
        let filtered = colors.filter { c in
            let brightness = c.r * 0.299 + c.g * 0.587 + c.b * 0.114
            return brightness > 0.08 && brightness < 0.92
        }

        let source = filtered.isEmpty ? colors : filtered

        // 按 HSB 色相分桶聚类
        var buckets: [Int: [(r: CGFloat, g: CGFloat, b: CGFloat)]] = [:]
        for color in source {
            let hue = hueFromRGB(r: color.r, g: color.g, b: color.b)
            let saturation = saturationFromRGB(r: color.r, g: color.g, b: color.b)

            let bucketKey: Int
            if saturation < 0.15 {
                // 低饱和度 → 灰度桶
                let brightness = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
                bucketKey = 100 + Int(brightness * 3) // 100, 101, 102
            } else {
                bucketKey = Int(hue * 12) // 12 色相桶
            }
            buckets[bucketKey, default: []].append(color)
        }

        // 按桶大小排序，取前 N 个桶的平均色
        let sorted = buckets.sorted { $0.value.count > $1.value.count }
        return sorted.prefix(count).map { bucket in
            let avgR = bucket.value.map(\.r).reduce(0, +) / CGFloat(bucket.value.count)
            let avgG = bucket.value.map(\.g).reduce(0, +) / CGFloat(bucket.value.count)
            let avgB = bucket.value.map(\.b).reduce(0, +) / CGFloat(bucket.value.count)
            return (r: avgR, g: avgG, b: avgB)
        }
    }

    /// RGB → 最近的预设颜色（使用 CIEDE2000 简化版色差）
    private func mapToPresetColor(r: CGFloat, g: CGFloat, b: CGFloat) -> ClothingColor? {
        let presetRGBs: [(ClothingColor, CGFloat, CGFloat, CGFloat)] = [
            (ClothingColor.presets[0],  0.11, 0.11, 0.12), // 黑色
            (ClothingColor.presets[1],  0.96, 0.96, 0.96), // 白色
            (ClothingColor.presets[2],  0.56, 0.56, 0.58), // 灰色
            (ClothingColor.presets[3],  0.96, 0.94, 0.88), // 米色
            (ClothingColor.presets[4],  0.55, 0.41, 0.08), // 棕色
            (ClothingColor.presets[5],  1.00, 0.23, 0.19), // 红色
            (ClothingColor.presets[6],  1.00, 0.42, 0.54), // 粉色
            (ClothingColor.presets[7],  1.00, 0.58, 0.00), // 橙色
            (ClothingColor.presets[8],  1.00, 0.80, 0.00), // 黄色
            (ClothingColor.presets[9],  0.20, 0.78, 0.35), // 绿色
            (ClothingColor.presets[10], 0.00, 0.48, 1.00), // 蓝色
            (ClothingColor.presets[11], 0.11, 0.24, 0.35), // 藏蓝
            (ClothingColor.presets[12], 0.69, 0.32, 0.87), // 紫色
            (ClothingColor.presets[13], 0.76, 0.69, 0.57), // 卡其
            (ClothingColor.presets[14], 0.29, 0.33, 0.13), // 军绿
            (ClothingColor.presets[15], 0.45, 0.18, 0.22), // 酒红
        ]

        var bestMatch: ClothingColor?
        var bestDistance = CGFloat.infinity

        for (preset, pr, pg, pb) in presetRGBs {
            let dist = sqrt(pow(r - pr, 2) * 0.3 + pow(g - pg, 2) * 0.59 + pow(b - pb, 2) * 0.11)
            if dist < bestDistance {
                bestDistance = dist
                bestMatch = preset
            }
        }

        return bestMatch
    }

    // MARK: - 品类识别 (Vision)

    struct ClassificationResult {
        var category: ClothingCategory?
        var subcategory: String
        var confidence: Double
    }

    func classifyClothing(image: UIImage) async -> ClassificationResult {
        guard let cgImage = image.cgImage else {
            return ClassificationResult(category: nil, subcategory: "", confidence: 0)
        }

        return await withCheckedContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: ClassificationResult(category: nil, subcategory: "", confidence: 0))
                    return
                }

                let mapped = self.mapVisionResults(results)
                continuation.resume(returning: mapped)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: ClassificationResult(category: nil, subcategory: "", confidence: 0))
            }
        }
    }

    private func mapVisionResults(_ observations: [VNClassificationObservation]) -> ClassificationResult {
        // Vision 的分类标签 → 我们的衣物品类
        let categoryMapping: [String: (ClothingCategory, String)] = [
            // 上衣类
            "shirt": (.top, "衬衫"),
            "jersey": (.top, "针织衫"),
            "T-shirt": (.top, "T恤"),
            "sweatshirt": (.top, "卫衣"),
            "cardigan": (.top, "开衫"),
            "blouse": (.top, "上衣"),
            "polo_shirt": (.top, "Polo衫"),
            "tank_top": (.top, "背心"),
            // 下装类
            "jean": (.bottom, "牛仔裤"),
            "trouser": (.bottom, "裤子"),
            "skirt": (.bottom, "裙子"),
            "miniskirt": (.bottom, "短裙"),
            "shorts": (.bottom, "短裤"),
            // 外套类
            "coat": (.outerwear, "大衣"),
            "jacket": (.outerwear, "夹克"),
            "blazer": (.outerwear, "西装外套"),
            "parka": (.outerwear, "派克大衣"),
            "windbreaker": (.outerwear, "风衣"),
            "sweater": (.outerwear, "毛衣"),
            "hoodie": (.outerwear, "连帽衫"),
            "vest": (.outerwear, "马甲"),
            "down_jacket": (.outerwear, "羽绒服"),
            // 连衣裙
            "dress": (.dress, "连衣裙"),
            "gown": (.dress, "礼服"),
            "sundress": (.dress, "吊带裙"),
            // 鞋子
            "shoe": (.shoes, "鞋子"),
            "sneaker": (.shoes, "运动鞋"),
            "boot": (.shoes, "靴子"),
            "sandal": (.shoes, "凉鞋"),
            "high_heel": (.shoes, "高跟鞋"),
            "loafer": (.shoes, "乐福鞋"),
            "slipper": (.shoes, "拖鞋"),
            "running_shoe": (.shoes, "跑鞋"),
            // 包
            "bag": (.bag, "包"),
            "handbag": (.bag, "手提包"),
            "backpack": (.bag, "双肩包"),
            "purse": (.bag, "钱包"),
            "tote": (.bag, "托特包"),
            // 配饰
            "hat": (.accessory, "帽子"),
            "scarf": (.accessory, "围巾"),
            "tie": (.accessory, "领带"),
            "belt": (.accessory, "腰带"),
            "sunglasses": (.accessory, "太阳镜"),
            "watch": (.accessory, "手表"),
            "necklace": (.accessory, "项链"),
            "bracelet": (.accessory, "手链"),
            "earring": (.accessory, "耳环"),
            "glove": (.accessory, "手套"),
        ]

        // 遍历 Vision 结果，找到第一个匹配的
        for obs in observations where obs.confidence > 0.1 {
            let identifier = obs.identifier.lowercased()

            // 精确匹配
            for (key, value) in categoryMapping {
                if identifier.contains(key.lowercased()) {
                    return ClassificationResult(
                        category: value.0,
                        subcategory: value.1,
                        confidence: Double(obs.confidence)
                    )
                }
            }

            // 模糊匹配关键词
            let clothingKeywords: [(String, ClothingCategory, String)] = [
                ("fabric", .top, ""),
                ("textile", .top, ""),
                ("leather", .bag, "皮具"),
                ("wool", .outerwear, "羊毛衫"),
                ("denim", .bottom, "牛仔"),
                ("silk", .dress, "丝绸"),
                ("cotton", .top, "棉质"),
                ("knit", .top, "针织"),
            ]

            for (keyword, cat, sub) in clothingKeywords {
                if identifier.contains(keyword) {
                    return ClassificationResult(
                        category: cat,
                        subcategory: sub,
                        confidence: Double(obs.confidence) * 0.7
                    )
                }
            }
        }

        return ClassificationResult(category: nil, subcategory: "", confidence: 0)
    }

    // MARK: - 辅助推断

    private func guessSeasonsFromColors(_ colors: [ClothingColor]) -> [Season] {
        let colorNames = Set(colors.map(\.name))

        // 深色/厚重色 → 秋冬
        let warmSeasonColors: Set<String> = ["酒红", "棕色", "军绿", "藏蓝"]
        // 浅色/明亮色 → 春夏
        let coolSeasonColors: Set<String> = ["白色", "粉色", "黄色", "橙色"]

        let hasWarm = !colorNames.intersection(warmSeasonColors).isEmpty
        let hasCool = !colorNames.intersection(coolSeasonColors).isEmpty

        if hasWarm && !hasCool { return [.autumn, .winter] }
        if hasCool && !hasWarm { return [.spring, .summer] }
        if colorNames.contains("黑色") || colorNames.contains("灰色") {
            return Season.allCases // 百搭色
        }

        return [.spring, .autumn] // 默认春秋
    }

    private func guessStylesFromCategory(_ category: ClothingCategory?) -> [ClothingStyle] {
        switch category {
        case .shoes:
            return [.casual]
        case .bag:
            return [.casual, .minimalist]
        case .accessory:
            return [.elegant]
        case .dress:
            return [.elegant, .romantic]
        default:
            return []
        }
    }

    // MARK: - HSB 辅助

    private func hueFromRGB(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        let delta = maxVal - minVal

        guard delta > 0.001 else { return 0 }

        var hue: CGFloat
        if maxVal == r {
            hue = (g - b) / delta
        } else if maxVal == g {
            hue = 2 + (b - r) / delta
        } else {
            hue = 4 + (r - g) / delta
        }

        hue /= 6
        if hue < 0 { hue += 1 }
        return hue
    }

    private func saturationFromRGB(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        let maxVal = max(r, g, b)
        let minVal = min(r, g, b)
        guard maxVal > 0.001 else { return 0 }
        return (maxVal - minVal) / maxVal
    }
}

// MARK: - Array 去重扩展

extension Array where Element: Identifiable {
    func removingDuplicates() -> [Element] {
        var seen = Set<String>()
        return filter { element in
            let id = "\(element.id)"
            if seen.contains(id) { return false }
            seen.insert(id)
            return true
        }
    }
}
