import Foundation
import SwiftUI

enum ClothingCategory: String, CaseIterable, Codable, Identifiable {
    case top = "上衣"
    case bottom = "下装"
    case outerwear = "外套"
    case dress = "连衣裙"
    case shoes = "鞋子"
    case bag = "包包"
    case accessory = "配饰"
    case other = "其他"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .top: return "tshirt"
        case .bottom: return "figure.walk"
        case .outerwear: return "jacket"
        case .dress: return "figure.dress.line.vertical.figure"
        case .shoes: return "shoe"
        case .bag: return "bag"
        case .accessory: return "eyeglasses"
        case .other: return "ellipsis.circle"
        }
    }

    var color: Color {
        switch self {
        case .top: return .blue
        case .bottom: return .indigo
        case .outerwear: return .brown
        case .dress: return .pink
        case .shoes: return .orange
        case .bag: return .purple
        case .accessory: return .teal
        case .other: return .gray
        }
    }
}

enum Season: String, CaseIterable, Codable, Identifiable {
    case spring = "春"
    case summer = "夏"
    case autumn = "秋"
    case winter = "冬"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .spring: return "leaf"
        case .summer: return "sun.max"
        case .autumn: return "wind"
        case .winter: return "snowflake"
        }
    }

    var color: Color {
        switch self {
        case .spring: return .green
        case .summer: return .orange
        case .autumn: return .brown
        case .winter: return .blue
        }
    }
}

enum ClothingStyle: String, CaseIterable, Codable, Identifiable {
    case casual = "休闲"
    case formal = "正式"
    case business = "商务"
    case sporty = "运动"
    case romantic = "浪漫"
    case streetwear = "街头"
    case vintage = "复古"
    case minimalist = "极简"
    case bohemian = "波西米亚"
    case elegant = "优雅"

    var id: String { rawValue }
}

struct ClothingColor: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let hex: String

    init(name: String, hex: String) {
        self.id = UUID()
        self.name = name
        self.hex = hex
    }

    var color: Color {
        Color(hex: hex)
    }

    static let presets: [ClothingColor] = [
        ClothingColor(name: "黑色", hex: "#1C1C1E"),
        ClothingColor(name: "白色", hex: "#F5F5F5"),
        ClothingColor(name: "灰色", hex: "#8E8E93"),
        ClothingColor(name: "米色", hex: "#F5F0E1"),
        ClothingColor(name: "棕色", hex: "#8B6914"),
        ClothingColor(name: "红色", hex: "#FF3B30"),
        ClothingColor(name: "粉色", hex: "#FF6B8A"),
        ClothingColor(name: "橙色", hex: "#FF9500"),
        ClothingColor(name: "黄色", hex: "#FFCC00"),
        ClothingColor(name: "绿色", hex: "#34C759"),
        ClothingColor(name: "蓝色", hex: "#007AFF"),
        ClothingColor(name: "藏蓝", hex: "#1C3D5A"),
        ClothingColor(name: "紫色", hex: "#AF52DE"),
        ClothingColor(name: "卡其", hex: "#C3B091"),
        ClothingColor(name: "军绿", hex: "#4B5320"),
        ClothingColor(name: "酒红", hex: "#722F37"),
    ]
}

struct ClothingItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: ClothingCategory
    var subcategory: String
    var colors: [ClothingColor]
    var seasons: [Season]
    var styles: [ClothingStyle]
    var material: String
    var brand: String
    var imageData: Data?
    var purchaseDate: Date?
    var price: Double?
    var isFavorite: Bool
    var wearCount: Int
    var lastWornDate: Date?
    var notes: String
    var dateAdded: Date
    var warmthLevel: Int // 1-5, 1=轻薄 5=厚实

    init(
        name: String = "",
        category: ClothingCategory = .top,
        subcategory: String = "",
        colors: [ClothingColor] = [],
        seasons: [Season] = [],
        styles: [ClothingStyle] = [],
        material: String = "",
        brand: String = "",
        imageData: Data? = nil,
        purchaseDate: Date? = nil,
        price: Double? = nil,
        isFavorite: Bool = false,
        notes: String = "",
        warmthLevel: Int = 3
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.subcategory = subcategory
        self.colors = colors
        self.seasons = seasons
        self.styles = styles
        self.material = material
        self.brand = brand
        self.imageData = imageData
        self.purchaseDate = purchaseDate
        self.price = price
        self.isFavorite = isFavorite
        self.wearCount = 0
        self.lastWornDate = nil
        self.notes = notes
        self.dateAdded = Date()
        self.warmthLevel = warmthLevel
    }
}

extension ClothingItem {
    static let sampleItems: [ClothingItem] = [
        ClothingItem(
            name: "白色基础T恤",
            category: .top,
            subcategory: "T恤",
            colors: [ClothingColor.presets[1]],
            seasons: [.spring, .summer],
            styles: [.casual, .minimalist],
            material: "棉",
            brand: "UNIQLO",
            warmthLevel: 1
        ),
        ClothingItem(
            name: "深蓝色牛仔裤",
            category: .bottom,
            subcategory: "牛仔裤",
            colors: [ClothingColor.presets[11]],
            seasons: [.spring, .autumn, .winter],
            styles: [.casual, .streetwear],
            material: "牛仔布",
            brand: "Levi's",
            warmthLevel: 3
        ),
        ClothingItem(
            name: "驼色风衣",
            category: .outerwear,
            subcategory: "风衣",
            colors: [ClothingColor.presets[13]],
            seasons: [.spring, .autumn],
            styles: [.elegant, .business],
            material: "涤纶混纺",
            brand: "ZARA",
            warmthLevel: 3
        ),
        ClothingItem(
            name: "小黑裙",
            category: .dress,
            subcategory: "连衣裙",
            colors: [ClothingColor.presets[0]],
            seasons: [.spring, .summer, .autumn],
            styles: [.elegant, .formal],
            material: "丝绸混纺",
            brand: "COS",
            warmthLevel: 1
        ),
        ClothingItem(
            name: "白色运动鞋",
            category: .shoes,
            subcategory: "运动鞋",
            colors: [ClothingColor.presets[1]],
            seasons: Season.allCases,
            styles: [.casual, .sporty, .streetwear],
            material: "皮革/织物",
            brand: "Nike",
            warmthLevel: 2
        ),
        ClothingItem(
            name: "黑色斜挎包",
            category: .bag,
            subcategory: "斜挎包",
            colors: [ClothingColor.presets[0]],
            seasons: Season.allCases,
            styles: [.casual, .minimalist],
            material: "真皮",
            brand: "Coach",
            warmthLevel: 1
        ),
    ]
}
