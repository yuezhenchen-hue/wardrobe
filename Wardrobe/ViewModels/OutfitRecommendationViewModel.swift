import Foundation

@MainActor
class OutfitRecommendationViewModel: ObservableObject {
    @Published var recommendedOutfits: [Outfit] = []
    @Published var selectedOccasion: Occasion = .daily
    @Published var isLoading = false
    @Published var savedOutfits: [Outfit] = []

    private let engine = RecommendationEngine.shared
    private let storage = StorageService.shared

    func generateRecommendations(
        wardrobe: [ClothingItem],
        weather: WeatherInfo,
        profile: UserProfile
    ) {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
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
    }

    func loadSavedOutfits() {
        savedOutfits = storage.loadOutfits()
    }

    func removeOutfit(_ outfit: Outfit) {
        savedOutfits.removeAll { $0.id == outfit.id }
        storage.saveOutfits(savedOutfits)
    }
}
