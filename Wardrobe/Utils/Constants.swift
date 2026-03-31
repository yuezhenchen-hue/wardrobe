import SwiftUI

enum AppTheme {
    static let primaryColor = Color(hex: "#D4606F")
    static let secondaryColor = Color(hex: "#8B6914")
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "#D4606F"), Color(hex: "#E88D67")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "#FDF6F0"), Color(hex: "#FFFFFF")],
        startPoint: .top,
        endPoint: .bottom
    )
    static let cardBackground = Color(hex: "#FAFAFA")
    static let warmBackground = Color(hex: "#FDF6F0")

    static let cornerRadius: CGFloat = 16
    static let cardShadowRadius: CGFloat = 8
    static let spacing: CGFloat = 16
}

enum AppStrings {
    static let appName = "智衣橱"
    static let wardrobeTab = "衣橱"
    static let recommendTab = "推荐"
    static let diaryTab = "日记"
    static let profileTab = "我的"

    static let addClothing = "添加衣物"
    static let myWardrobe = "我的衣橱"
    static let todayOutfit = "今日推荐"
    static let outfitDiary = "穿搭日记"
    static let styleProfile = "个人形象"
    static let shopping = "购物清单"
}
