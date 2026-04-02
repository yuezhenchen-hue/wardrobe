import SwiftUI

@main
struct WardrobeApp: App {
    @StateObject private var wardrobeVM = WardrobeViewModel()
    @StateObject private var recommendVM = OutfitRecommendationViewModel()
    @StateObject private var diaryVM = DiaryViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(wardrobeVM)
                .environmentObject(recommendVM)
                .environmentObject(diaryVM)
                .environmentObject(profileVM)
                .environmentObject(weatherService)
                .environmentObject(locationManager)
                .onAppear {
                    wardrobeVM.loadItems()
                    recommendVM.loadSavedOutfits()
                    diaryVM.loadEntries()
                    profileVM.loadProfile()
                    locationManager.requestLocation()
                    LearningService.shared.syncToStyleMatrix()
                }
                .onChange(of: locationManager.location) { _, loc in
                    weatherService.fetchWeather(
                        location: loc,
                        city: locationManager.city
                    )
                }
                .onChange(of: locationManager.city) { _, city in
                    if !city.isEmpty {
                        weatherService.fetchWeather(
                            location: locationManager.location,
                            city: city
                        )
                    }
                }
        }
    }
}
