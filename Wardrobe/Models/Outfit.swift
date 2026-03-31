import Foundation

struct Outfit: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [ClothingItem]
    var occasion: String
    var seasons: [Season]
    var styles: [ClothingStyle]
    var rating: Int
    var imageData: Data?
    var dateCreated: Date
    var isAIGenerated: Bool

    init(
        name: String = "",
        items: [ClothingItem] = [],
        occasion: String = "",
        seasons: [Season] = [],
        styles: [ClothingStyle] = [],
        rating: Int = 0,
        imageData: Data? = nil,
        isAIGenerated: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.items = items
        self.occasion = occasion
        self.seasons = seasons
        self.styles = styles
        self.rating = rating
        self.imageData = imageData
        self.dateCreated = Date()
        self.isAIGenerated = isAIGenerated
    }

    var categoryBreakdown: [ClothingCategory: [ClothingItem]] {
        Dictionary(grouping: items, by: \.category)
    }
}

enum Occasion: String, CaseIterable, Identifiable {
    case daily = "日常"
    case work = "工作"
    case date = "约会"
    case party = "派对"
    case sport = "运动"
    case travel = "旅行"
    case interview = "面试"
    case wedding = "婚礼"
    case casual = "休闲聚会"
    case shopping = "逛街"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .daily: return "house"
        case .work: return "briefcase"
        case .date: return "heart"
        case .party: return "party.popper"
        case .sport: return "figure.run"
        case .travel: return "airplane"
        case .interview: return "person.text.rectangle"
        case .wedding: return "gift"
        case .casual: return "cup.and.saucer"
        case .shopping: return "bag"
        }
    }
}
