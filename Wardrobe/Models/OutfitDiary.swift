import Foundation

struct OutfitDiary: Identifiable, Codable {
    let id: UUID
    var date: Date
    var outfit: Outfit
    var weather: WeatherInfo?
    var occasion: String
    var mood: Mood
    var notes: String
    var photoData: Data?
    var rating: Int

    init(
        date: Date = Date(),
        outfit: Outfit = Outfit(),
        weather: WeatherInfo? = nil,
        occasion: String = "",
        mood: Mood = .happy,
        notes: String = "",
        photoData: Data? = nil,
        rating: Int = 3
    ) {
        self.id = UUID()
        self.date = date
        self.outfit = outfit
        self.weather = weather
        self.occasion = occasion
        self.mood = mood
        self.notes = notes
        self.photoData = photoData
        self.rating = rating
    }
}

enum Mood: String, CaseIterable, Codable, Identifiable {
    case happy = "开心"
    case confident = "自信"
    case relaxed = "放松"
    case energetic = "活力"
    case romantic = "浪漫"
    case professional = "专业"
    case creative = "创意"
    case neutral = "平淡"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .confident: return "😎"
        case .relaxed: return "😌"
        case .energetic: return "⚡"
        case .romantic: return "💕"
        case .professional: return "💼"
        case .creative: return "🎨"
        case .neutral: return "😐"
        }
    }
}
