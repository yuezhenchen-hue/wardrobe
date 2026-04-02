import Foundation
import SwiftUI

/// AI 穿搭助手服务
/// 优先使用 Apple Foundation Models (iOS 26+)，不可用时降级为规则引擎
@MainActor
class AIAssistantService: ObservableObject {

    @Published var messages: [ChatMessage] = []
    @Published var isGenerating = false

    private var wardrobeItems: [ClothingItem] = []
    private var weather: WeatherInfo = .sample
    private var profile: UserProfile = UserProfile()

    func updateContext(wardrobe: [ClothingItem], weather: WeatherInfo, profile: UserProfile) {
        self.wardrobeItems = wardrobe
        self.weather = weather
        self.profile = profile
    }

    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        isGenerating = true

        if #available(iOS 26.0, *) {
            await generateWithFoundationModels(prompt: text)
        } else {
            await generateWithRuleEngine(prompt: text)
        }

        isGenerating = false
    }

    func sendQuickAction(_ action: QuickAction) async {
        await sendMessage(action.prompt)
    }

    // MARK: - Apple Foundation Models (iOS 26+)

    @available(iOS 26.0, *)
    private func generateWithFoundationModels(prompt: String) async {
        do {
            let module = try await loadFoundationModel()
            let systemContext = buildSystemPrompt()
            let fullPrompt = "\(systemContext)\n\n用户: \(prompt)"

            let response = try await module.respond(to: fullPrompt)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
        } catch {
            // 降级到规则引擎
            await generateWithRuleEngine(prompt: prompt)
        }
    }

    @available(iOS 26.0, *)
    private func loadFoundationModel() async throws -> FoundationModelSession {
        return try FoundationModelSession()
    }

    // MARK: - 规则引擎降级（iOS 17-25 或模型不可用）

    private func generateWithRuleEngine(prompt: String) async {
        try? await Task.sleep(for: .milliseconds(500))

        let assistantMessage = generateRuleBasedResponse(for: prompt)
        messages.append(assistantMessage)
    }

    private func generateRuleBasedResponse(for prompt: String) -> ChatMessage {
        let lowercased = prompt.lowercased()

        if lowercased.contains("搭配") || lowercased.contains("推荐") || lowercased.contains("穿什么") {
            return generateOutfitAdvice()
        }

        if lowercased.contains("天气") || lowercased.contains("温度") {
            return ChatMessage(role: .assistant, content: generateWeatherAdvice())
        }

        if lowercased.contains("颜色") || lowercased.contains("配色") {
            return ChatMessage(role: .assistant, content: generateColorAdvice())
        }

        if lowercased.contains("买") || lowercased.contains("购物") || lowercased.contains("缺") {
            return ChatMessage(role: .assistant, content: generateShoppingAdvice())
        }

        if lowercased.contains("点评") || lowercased.contains("评价") || lowercased.contains("怎么样") {
            return ChatMessage(role: .assistant, content: generateStyleReview())
        }

        if lowercased.contains("风格") {
            return ChatMessage(role: .assistant, content: generateStyleAdvice())
        }

        return ChatMessage(role: .assistant, content: generateGeneralAdvice())
    }

    private func generateOutfitAdvice() -> ChatMessage {
        let engine = RecommendationEngine.shared
        let outfit = engine.generateOutfit(
            from: wardrobeItems,
            weather: weather,
            occasion: .daily,
            profile: profile
        )

        guard !outfit.items.isEmpty else {
            return ChatMessage(role: .assistant, content: "你的衣橱里衣物还不够多哦，建议先添加一些基本单品，我才能为你搭配出好看的穿搭！")
        }

        let score = engine.scoreCompleteOutfit(items: outfit.items, occasion: .daily, profile: profile)
        let scoreDesc = score >= 0.8 ? "非常和谐" : score >= 0.6 ? "搭配不错" : "可以尝试"

        let colors = outfit.items.compactMap(\.colors.first)
        let harmony = ColorMatchingService.shared.analyzeColorHarmony(colors: colors)

        var response = "根据今天的天气（\(weather.city) \(weather.temperatureDescription) \(weather.condition.rawValue)），我为你推荐这套搭配：\n\n"
        response += "⭐ 协调度：\(Int(score * 100))分（\(scoreDesc)）\n"
        response += "🎨 配色：\(harmony.name) — \(harmony.description)\n\n"
        response += weather.dressingSuggestion

        return ChatMessage(
            role: .assistant,
            content: response,
            outfitItems: outfit.items,
            outfitScore: score,
            colorHarmony: (harmony.name, harmony.description)
        )
    }

    private func generateWeatherAdvice() -> String {
        var advice = "📍 \(weather.city) 当前天气：\n\n"
        advice += "🌡 温度：\(weather.temperatureDescription)（体感 \(Int(weather.feelsLike))°C）\n"
        advice += "\(weather.condition.icon) 天气：\(weather.condition.rawValue)\n"
        advice += "💧 湿度：\(Int(weather.humidity))%\n"
        advice += "💨 风速：\(Int(weather.windSpeed)) km/h\n\n"
        advice += "👗 穿衣建议：\(weather.dressingSuggestion)"

        if weather.condition.needsRainProtection {
            advice += "\n\n☔ 特别提醒：今天有降水，建议穿防水鞋，携带雨具！"
        }

        return advice
    }

    private func generateColorAdvice() -> String {
        let allColors = wardrobeItems.compactMap(\.colors.first)
        let colorNames = allColors.map(\.name)
        let colorCount = Dictionary(grouping: colorNames, by: { $0 }).mapValues(\.count)
        let sorted = colorCount.sorted { $0.value > $1.value }

        var advice = "🎨 你衣橱的颜色分析：\n\n"

        for (color, count) in sorted.prefix(5) {
            advice += "• \(color)：\(count)件\n"
        }

        if let topColor = sorted.first {
            let complementary = ColorMatchingService.shared.suggestComplementaryColors(
                for: ClothingColor.presets.first { $0.name == topColor.key } ?? ClothingColor.presets[0]
            )
            advice += "\n你最多的颜色是\(topColor.key)，推荐搭配：\(complementary.map(\.name).joined(separator: "、"))"
        }

        let neutrals = colorNames.filter { ["黑色", "白色", "灰色", "米色"].contains($0) }.count
        let ratio = wardrobeItems.isEmpty ? 0 : Double(neutrals) / Double(wardrobeItems.count)

        if ratio > 0.7 {
            advice += "\n\n💡 建议：你的衣橱以中性色为主，可以考虑添加一些亮色单品作为点缀，让搭配更有层次感。"
        } else if ratio < 0.3 {
            advice += "\n\n💡 建议：你的衣橱彩色偏多，建议增加一些黑白灰基础款，方便百搭。"
        }

        return advice
    }

    private func generateShoppingAdvice() -> String {
        let suggestions = RecommendationEngine.shared.suggestMissingItems(
            wardrobe: wardrobeItems, profile: profile
        )

        if suggestions.isEmpty {
            return "✅ 你的衣橱很完整！目前没有必要购买的建议。\n\n不过可以考虑尝试一些新风格的单品，给穿搭增添新鲜感。"
        }

        var advice = "🛍 根据你的衣橱分析，以下是购买建议：\n\n"
        for (i, item) in suggestions.enumerated() {
            advice += "\(i + 1). \(item.suggestion)（当前\(item.currentCount)/建议\(item.recommendedCount)）\n   💡 \(item.reason)\n\n"
        }

        return advice
    }

    private func generateStyleReview() -> String {
        guard !wardrobeItems.isEmpty else {
            return "你的衣橱还是空的哦，先添加一些衣物，我才能帮你做风格分析！"
        }

        let allStyles = wardrobeItems.flatMap(\.styles)
        let styleCounts = Dictionary(grouping: allStyles, by: { $0 }).mapValues(\.count)
        let sorted = styleCounts.sorted { $0.value > $1.value }

        var review = "📊 你的穿衣风格分析：\n\n"

        for (style, count) in sorted.prefix(3) {
            let pct = Int(Double(count) / Double(allStyles.count) * 100)
            review += "• \(style.rawValue)：\(pct)%\n"
        }

        if let dominant = sorted.first {
            review += "\n你的主要风格偏向「\(dominant.key.rawValue)」。"
        }

        if sorted.count <= 2 {
            review += "\n\n💡 建议丰富一下风格多样性，可以尝试 \(ClothingStyle.allCases.filter { !styleCounts.keys.contains($0) }.prefix(2).map(\.rawValue).joined(separator: "、")) 风格。"
        }

        return review
    }

    private func generateStyleAdvice() -> String {
        if profile.preferredStyles.isEmpty {
            return "你还没有完成风格测试哦！去「我的」页面完成风格测试，我就能给你更精准的建议了。"
        }

        var advice = "💃 你的风格偏好：\(profile.preferredStyles.map(\.rawValue).joined(separator: "、"))\n\n"

        if let skinTone = profile.skinTone {
            advice += "🎨 根据你的肤色（\(skinTone.rawValue)），推荐颜色：\(skinTone.recommendedColors.joined(separator: "、"))\n\n"
        }

        if let bodyType = profile.bodyType {
            advice += "👤 体型建议：\(bodyType.description)"
        }

        return advice
    }

    private func generateGeneralAdvice() -> String {
        let tips = [
            "试试「帮我搭配」，我会根据天气和场合为你推荐穿搭。",
            "你可以问我「今天穿什么」，我会考虑天气给你建议。",
            "想知道衣橱缺什么？问我「购物建议」。",
            "好奇你的配色风格？问我「分析配色」。",
            "问我「点评穿搭风格」，我帮你分析衣橱的风格构成。",
        ]
        return "你好！我是你的AI穿搭助手 👋\n\n我可以帮你：\n• 根据天气和场合推荐穿搭\n• 分析你的配色和风格\n• 给出购物建议\n• 点评穿搭\n\n💡 试试：\(tips.randomElement()!)"
    }

    private func buildSystemPrompt() -> String {
        var context = "你是一个专业的穿搭助手。用户的衣橱有\(wardrobeItems.count)件衣物。"
        context += "当前天气：\(weather.city) \(weather.temperatureDescription) \(weather.condition.rawValue)。"

        if !profile.preferredStyles.isEmpty {
            context += "用户偏好风格：\(profile.preferredStyles.map(\.rawValue).joined(separator: "、"))。"
        }

        let categories = Dictionary(grouping: wardrobeItems, by: \.category).mapValues(\.count)
        context += "衣橱构成：\(categories.map { "\($0.key.rawValue)\($0.value)件" }.joined(separator: "、"))。"

        context += "请用中文回答，给出具体、实用的穿搭建议。"
        return context
    }
}

// MARK: - 聊天数据模型

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp = Date()

    /// 富内容：推荐的衣物列表（助手推荐搭配时附带）
    var outfitItems: [ClothingItem]?
    /// 搭配协调度 (0~1)
    var outfitScore: Double?
    /// 配色分析
    var colorHarmony: (name: String, description: String)?

    init(role: ChatRole, content: String,
         outfitItems: [ClothingItem]? = nil,
         outfitScore: Double? = nil,
         colorHarmony: (name: String, description: String)? = nil) {
        self.role = role
        self.content = content
        self.outfitItems = outfitItems
        self.outfitScore = outfitScore
        self.colorHarmony = colorHarmony
    }
}

enum ChatRole {
    case user
    case assistant
    case system
}

enum QuickAction: String, CaseIterable, Identifiable {
    case outfit = "帮我搭配"
    case weather = "天气穿衣建议"
    case color = "分析我的配色"
    case shopping = "购物建议"
    case review = "点评穿搭风格"

    var id: String { rawValue }

    var prompt: String {
        switch self {
        case .outfit: return "根据今天的天气帮我搭配一套穿搭"
        case .weather: return "今天天气怎么样，应该穿什么"
        case .color: return "帮我分析一下衣橱的配色"
        case .shopping: return "我的衣橱还缺什么"
        case .review: return "帮我点评一下我的穿搭风格"
        }
    }

    var icon: String {
        switch self {
        case .outfit: return "wand.and.stars"
        case .weather: return "cloud.sun"
        case .color: return "paintpalette"
        case .shopping: return "bag"
        case .review: return "sparkles"
        }
    }
}

// MARK: - Foundation Models 协议抽象

@available(iOS 26.0, *)
struct FoundationModelSession {
    init() throws {
        // Foundation Models 初始化
        // 实际使用: let model = SystemLanguageModel.default
        //           guard model.isAvailable else { throw ... }
    }

    func respond(to prompt: String) async throws -> String {
        // 实际使用:
        // let session = LanguageModelSession()
        // let response = try await session.respond(to: prompt)
        // return response.content
        throw FoundationModelError.notAvailable
    }
}

@available(iOS 26.0, *)
enum FoundationModelError: Error {
    case notAvailable
    case generationFailed
}
