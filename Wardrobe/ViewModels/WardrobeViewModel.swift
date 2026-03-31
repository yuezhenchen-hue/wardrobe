import Foundation
import SwiftUI

@MainActor
class WardrobeViewModel: ObservableObject {
    @Published var clothingItems: [ClothingItem] = []
    @Published var selectedCategory: ClothingCategory?
    @Published var searchText = ""
    @Published var sortOption: SortOption = .dateAdded
    @Published var showingAddSheet = false

    private let storage = StorageService.shared

    enum SortOption: String, CaseIterable {
        case dateAdded = "添加时间"
        case name = "名称"
        case wearCount = "穿着次数"
        case category = "分类"
    }

    var filteredItems: [ClothingItem] {
        var items = clothingItems

        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            items = items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.brand.localizedCaseInsensitiveContains(searchText) ||
                $0.material.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOption {
        case .dateAdded:
            items.sort { $0.dateAdded > $1.dateAdded }
        case .name:
            items.sort { $0.name < $1.name }
        case .wearCount:
            items.sort { $0.wearCount > $1.wearCount }
        case .category:
            items.sort { $0.category.rawValue < $1.category.rawValue }
        }

        return items
    }

    var categoryStats: [(ClothingCategory, Int)] {
        let grouped = Dictionary(grouping: clothingItems, by: \.category)
        return ClothingCategory.allCases.map { ($0, grouped[$0]?.count ?? 0) }
    }

    var totalItems: Int { clothingItems.count }
    var favoriteItems: [ClothingItem] { clothingItems.filter(\.isFavorite) }

    func loadItems() {
        let saved = storage.loadClothingItems()
        if saved.isEmpty {
            clothingItems = ClothingItem.sampleItems
            saveItems()
        } else {
            clothingItems = saved
        }
    }

    func addItem(_ item: ClothingItem) {
        clothingItems.insert(item, at: 0)
        saveItems()
    }

    func updateItem(_ item: ClothingItem) {
        if let index = clothingItems.firstIndex(where: { $0.id == item.id }) {
            clothingItems[index] = item
            saveItems()
        }
    }

    func deleteItem(_ item: ClothingItem) {
        clothingItems.removeAll { $0.id == item.id }
        saveItems()
    }

    func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { filteredItems[$0] }
        for item in itemsToDelete {
            clothingItems.removeAll { $0.id == item.id }
        }
        saveItems()
    }

    func toggleFavorite(_ item: ClothingItem) {
        if let index = clothingItems.firstIndex(where: { $0.id == item.id }) {
            clothingItems[index].isFavorite.toggle()
            saveItems()
        }
    }

    func recordWear(_ item: ClothingItem) {
        if let index = clothingItems.firstIndex(where: { $0.id == item.id }) {
            clothingItems[index].wearCount += 1
            clothingItems[index].lastWornDate = Date()
            saveItems()
        }
    }

    private func saveItems() {
        storage.saveClothingItems(clothingItems)
    }
}
