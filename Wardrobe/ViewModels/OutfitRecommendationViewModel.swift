import Foundation

@MainActor
class OutfitRecommendationViewModel: ObservableObject {
    @Published var recommendedOutfits: [Outfit] = []
    @Published var selectedOccasion: Occasion = .daily
    @Published var isLoading = false
    @Published var savedOutfits: [Outfit] = []

    private let engine = RecommendationEngine.shared
    private let learning = LearningService.shared
    private let storage = StorageService.shared

    func generateRecommendations(
        wardrobe: [ClothingItem],
        weather: WeatherInfo,
        profile: UserProfile
    ) {
        isLoading = true

        // 记录刷新行为（弱负向信号，如果之前有推荐但用户不满意）
        if !recommendedOutfits.isEmpty {
            learning.recordRecommendationRefreshed(outfits: recommendedOutfits)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.recommendedOutfits = self.engine.generateMultipleOutfits(
                from: wardrobe,
                weather: weather,
                occasion: self.selectedOccasion,
                profile: profile,
                count: 3
            )
            self.isLoading = false
        }
    }

    func saveOutfit(_ outfit: Outfit) {
        savedOutfits.append(outfit)
        storage.saveOutfits(savedOutfits)

        // 学习信号：保存 = 正向反馈
        learning.recordOutfitSaved(outfit: outfit)
    }

    func loadSavedOutfits() {
        savedOutfits = storage.loadOutfits()
    }

    func removeOutfit(_ outfit: Outfit) {
        savedOutfits.removeAll { $0.id == outfit.id }
        storage.saveOutfits(savedOutfits)
    }

    /// 获取搭配的协调评分（供 UI 展示）
    func outfitScore(_ outfit: Outfit, occasion: Occasion, profile: UserProfile) -> Double {
        engine.scoreCompleteOutfit(items: outfit.items, occasion: occasion, profile: profile)
    }
}
