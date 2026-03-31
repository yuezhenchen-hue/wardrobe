import Foundation

class StorageService {
    static let shared = StorageService()
    private let defaults = UserDefaults.standard

    private let clothingKey = "wardrobe_clothing_items"
    private let outfitsKey = "wardrobe_outfits"
    private let diaryKey = "wardrobe_diary_entries"
    private let profileKey = "wardrobe_user_profile"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func saveClothingItems(_ items: [ClothingItem]) {
        if let data = try? encoder.encode(items) {
            defaults.set(data, forKey: clothingKey)
        }
    }

    func loadClothingItems() -> [ClothingItem] {
        guard let data = defaults.data(forKey: clothingKey),
              let items = try? decoder.decode([ClothingItem].self, from: data) else {
            return []
        }
        return items
    }

    func saveOutfits(_ outfits: [Outfit]) {
        if let data = try? encoder.encode(outfits) {
            defaults.set(data, forKey: outfitsKey)
        }
    }

    func loadOutfits() -> [Outfit] {
        guard let data = defaults.data(forKey: outfitsKey),
              let outfits = try? decoder.decode([Outfit].self, from: data) else {
            return []
        }
        return outfits
    }

    func saveDiaryEntries(_ entries: [OutfitDiary]) {
        if let data = try? encoder.encode(entries) {
            defaults.set(data, forKey: diaryKey)
        }
    }

    func loadDiaryEntries() -> [OutfitDiary] {
        guard let data = defaults.data(forKey: diaryKey),
              let entries = try? decoder.decode([OutfitDiary].self, from: data) else {
            return []
        }
        return entries
    }

    func saveProfile(_ profile: UserProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: profileKey)
        }
    }

    func loadProfile() -> UserProfile {
        guard let data = defaults.data(forKey: profileKey),
              let profile = try? decoder.decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }

    func clearAll() {
        defaults.removeObject(forKey: clothingKey)
        defaults.removeObject(forKey: outfitsKey)
        defaults.removeObject(forKey: diaryKey)
        defaults.removeObject(forKey: profileKey)
    }
}
