import SwiftUI

@main
struct WardrobeApp: App {
    @StateObject private var wardrobeVM = WardrobeViewModel()
    @StateObject private var recommendVM = OutfitRecommendationViewModel()
    @StateObject private var diaryVM = DiaryViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var weatherService = WeatherService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wardrobeVM)
                .environmentObject(recommendVM)
                .environmentObject(diaryVM)
                .environmentObject(profileVM)
                .environmentObject(weatherService)
                .onAppear {
                    wardrobeVM.loadItems()
                    recommendVM.loadSavedOutfits()
                    diaryVM.loadEntries()
                    profileVM.loadProfile()
                    weatherService.fetchWeather()
                }
        }
    }
}
