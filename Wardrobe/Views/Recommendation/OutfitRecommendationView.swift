import SwiftUI

struct OutfitRecommendationView: View {
    @EnvironmentObject var recommendVM: OutfitRecommendationViewModel
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var weatherService: WeatherService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    WeatherBannerView(weather: weatherService.currentWeather)

                    occasionPicker

                    if recommendVM.isLoading {
                        loadingView
                    } else if recommendVM.recommendedOutfits.isEmpty {
                        emptyStateView
                    } else {
                        outfitsList
                    }

                    if !recommendVM.savedOutfits.isEmpty {
                        savedOutfitsSection
                    }
                }
                .padding(.horizontal)
            }
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.todayOutfit)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        generateRecommendations()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                if recommendVM.recommendedOutfits.isEmpty {
                    generateRecommendations()
                }
            }
        }
    }

    private var occasionPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("选择场合")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Occasion.allCases) { occasion in
                        Button {
                            recommendVM.selectedOccasion = occasion
                            generateRecommendations()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: occasion.icon)
                                    .font(.title3)
                                Text(occasion.rawValue)
                                    .font(.caption)
                            }
                            .frame(width: 65, height: 65)
                            .background(
                                recommendVM.selectedOccasion == occasion
                                ? AnyShapeStyle(AppTheme.accentGradient)
                                : AnyShapeStyle(Color(.systemGray6))
                            )
                            .foregroundColor(
                                recommendVM.selectedOccasion == occasion ? .white : .primary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        }
    }

    private var outfitsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("为你推荐")
                .font(.headline)

            ForEach(recommendVM.recommendedOutfits) { outfit in
                OutfitCardView(outfit: outfit) {
                    recommendVM.saveOutfit(outfit)
                }
            }
        }
    }

    private var savedOutfitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("已保存的搭配")
                .font(.headline)
            ForEach(recommendVM.savedOutfits) { outfit in
                OutfitCardView(outfit: outfit, isSaved: true) {
                    recommendVM.removeOutfit(outfit)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在为你搭配中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tshirt")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("衣橱里还没有足够的衣物")
                .font(.headline)
            Text("先去添加一些衣物吧")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func generateRecommendations() {
        recommendVM.generateRecommendations(
            wardrobe: wardrobeVM.clothingItems,
            weather: weatherService.currentWeather,
            profile: profileVM.profile
        )
    }
}
