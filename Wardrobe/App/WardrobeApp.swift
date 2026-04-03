import SwiftUI

@main
struct WardrobeApp: App {
    @StateObject private var wardrobeVM = WardrobeViewModel()
    @StateObject private var recommendVM = OutfitRecommendationViewModel()
    @StateObject private var diaryVM = DiaryViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationManager = LocationManager()
    @Environment(\.scenePhase) private var scenePhase

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
                // 当定位+城市都就绪时，获取天气（消除竞态）
                .onChange(of: locationManager.locationReady) { _, ready in
                    if ready {
                        weatherService.fetchWeather(
                            location: locationManager.location,
                            city: locationManager.city
                        )
                    }
                }
                // 位置显著变化时刷新天气
                .onChange(of: locationManager.location) { oldLoc, newLoc in
                    guard locationManager.locationReady,
                          let newLoc, let oldLoc else { return }
                    if newLoc.distance(from: oldLoc) > 1000 {
                        weatherService.fetchWeather(
                            location: newLoc,
                            city: locationManager.city
                        )
                    }
                }
                // App 回到前台时刷新定位和天气
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        locationManager.refreshIfNeeded()
                        weatherService.refreshIfStale()
                    }
                }
        }
    }
}
