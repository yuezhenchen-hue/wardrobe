import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int

    var body: some View {
        TabView(selection: $selectedTab) {
            WardrobeView()
                .tabItem {
                    Label(AppStrings.wardrobeTab, systemImage: "cabinet")
                }
                .tag(0)

            OutfitRecommendationView()
                .tabItem {
                    Label(AppStrings.recommendTab, systemImage: "wand.and.stars")
                }
                .tag(1)

            AIAssistantView()
                .tabItem {
                    Label("助手", systemImage: "sparkles")
                }
                .tag(2)

            OutfitDiaryView()
                .tabItem {
                    Label(AppStrings.diaryTab, systemImage: "book")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label(AppStrings.profileTab, systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        .tint(AppTheme.primaryColor)
    }
}
