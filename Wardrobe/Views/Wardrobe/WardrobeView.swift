import SwiftUI

struct WardrobeView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @State private var showingDetail: ClothingItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsBar

                    categoryFilter

                    clothingGrid
                }
                .padding(.horizontal)
            }
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.myWardrobe)
            .searchable(text: $vm.searchText, prompt: "搜索衣物...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.accentGradient)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(WardrobeViewModel.SortOption.allCases, id: \.self) { option in
                            Button {
                                vm.sortOption = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if vm.sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $vm.showingAddSheet) {
                AddClothingView()
            }
            .sheet(item: $showingDetail) { item in
                ClothingDetailView(item: item)
            }
        }
    }

    private var statsBar: some View {
        HStack(spacing: 16) {
            StatCard(title: "总计", value: "\(vm.totalItems)", icon: "tshirt", color: .blue)
            StatCard(title: "收藏", value: "\(vm.favoriteItems.count)", icon: "heart.fill", color: .pink)
            StatCard(title: "分类", value: "\(vm.categoryStats.filter { $0.1 > 0 }.count)", icon: "folder", color: .orange)
        }
        .padding(.top, 8)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryChip(title: "全部", isSelected: vm.selectedCategory == nil) {
                    withAnimation { vm.selectedCategory = nil }
                }

                ForEach(ClothingCategory.allCases) { category in
                    let count = vm.categoryStats.first(where: { $0.0 == category })?.1 ?? 0
                    CategoryChip(
                        title: "\(category.rawValue) \(count)",
                        icon: category.icon,
                        isSelected: vm.selectedCategory == category
                    ) {
                        withAnimation {
                            vm.selectedCategory = vm.selectedCategory == category ? nil : category
                        }
                    }
                }
            }
        }
    }

    private var clothingGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(vm.filteredItems) { item in
                ClothingCardView(item: item) {
                    showingDetail = item
                } onFavorite: {
                    vm.toggleFavorite(item)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .cardStyle()
    }
}

struct CategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(Color(.systemGray6)))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}
