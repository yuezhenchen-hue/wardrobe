import Foundation

enum Gender: String, CaseIterable, Codable, Identifiable {
    case male = "男"
    case female = "女"
    case nonBinary = "其他"

    var id: String { rawValue }
}

enum BodyType: String, CaseIterable, Codable, Identifiable {
    case slim = "纤细"
    case athletic = "健壮"
    case average = "匀称"
    case curvy = "丰满"
    case petite = "娇小"
    case tall = "高挑"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .slim: return "身形纤细，适合修身剪裁"
        case .athletic: return "身材健壮，适合展现身体线条"
        case .average: return "身材匀称，百搭各种风格"
        case .curvy: return "身材丰满，适合突出曲线美"
        case .petite: return "身材娇小，适合高腰设计拉长比例"
        case .tall: return "身材高挑，适合各种长款设计"
        }
    }
}

enum SkinTone: String, CaseIterable, Codable, Identifiable {
    case fair = "白皙"
    case light = "偏白"
    case medium = "自然色"
    case tan = "小麦色"
    case dark = "深色"

    var id: String { rawValue }

    var recommendedColors: [String] {
        switch self {
        case .fair: return ["莫兰迪色", "浅粉", "浅蓝", "米白"]
        case .light: return ["暖色调", "杏色", "浅绿", "淡紫"]
        case .medium: return ["大地色", "酒红", "深蓝", "墨绿"]
        case .tan: return ["白色", "亮色", "橙色", "金色"]
        case .dark: return ["高饱和度", "亮黄", "宝蓝", "正红"]
        }
    }
}

struct UserProfile: Codable {
    var name: String
    var gender: Gender
    var bodyType: BodyType?
    var heightCm: Double?
    var weightKg: Double?
    var skinTone: SkinTone?
    var preferredStyles: [ClothingStyle]
    var colorPreferences: [ClothingColor]
    var avatarData: Data?
    var hasCompletedOnboarding: Bool

    init(
        name: String = "",
        gender: Gender = .female,
        bodyType: BodyType? = nil,
        heightCm: Double? = nil,
        weightKg: Double? = nil,
        skinTone: SkinTone? = nil,
        preferredStyles: [ClothingStyle] = [],
        colorPreferences: [ClothingColor] = [],
        avatarData: Data? = nil,
        hasCompletedOnboarding: Bool = false
    ) {
        self.name = name
        self.gender = gender
        self.bodyType = bodyType
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.skinTone = skinTone
        self.preferredStyles = preferredStyles
        self.colorPreferences = colorPreferences
        self.avatarData = avatarData
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
