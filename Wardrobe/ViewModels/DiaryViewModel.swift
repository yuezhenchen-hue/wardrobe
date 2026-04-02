import Foundation

@MainActor
class DiaryViewModel: ObservableObject {
    @Published var entries: [OutfitDiary] = []
    @Published var selectedDate = Date()

    private let storage = StorageService.shared
    private let learning = LearningService.shared

    var entriesForSelectedDate: [OutfitDiary] {
        entries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }

    var thisMonthEntries: [OutfitDiary] {
        entries.filter { $0.date.isThisMonth }
    }

    var thisWeekEntries: [OutfitDiary] {
        entries.filter { $0.date.isThisWeek }
    }

    var streakDays: Int {
        guard !entries.isEmpty else { return 0 }
        let sortedDates = entries.map(\.date).sorted(by: >)
        let calendar = Calendar.current

        guard calendar.isDateInToday(sortedDates[0]) || calendar.isDateInYesterday(sortedDates[0]) else {
            return 0
        }

        var streak = 1
        for i in 1..<sortedDates.count {
            let daysBetween = calendar.dateComponents([.day], from: sortedDates[i], to: sortedDates[i - 1]).day ?? 0
            if daysBetween == 1 {
                streak += 1
            } else if daysBetween > 1 {
                break
            }
        }
        return streak
    }

    var mostWornStyles: [(ClothingStyle, Int)] {
        let allStyles = entries.flatMap { $0.outfit.items.flatMap(\.styles) }
        let grouped = Dictionary(grouping: allStyles, by: { $0 }).mapValues(\.count)
        return grouped.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    func loadEntries() {
        entries = storage.loadDiaryEntries()
    }

    func addEntry(_ entry: OutfitDiary) {
        entries.insert(entry, at: 0)
        saveEntries()

        // 学习信号：日记评分是最强信号
        learning.recordDiaryRating(outfit: entry.outfit, rating: entry.rating)

        // 记录每件衣物的穿着
        for item in entry.outfit.items {
            learning.recordItemWorn(item: item)
        }
    }

    func deleteEntry(_ entry: OutfitDiary) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    func hasEntry(for date: Date) -> Bool {
        entries.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func saveEntries() {
        storage.saveDiaryEntries(entries)
    }
}
