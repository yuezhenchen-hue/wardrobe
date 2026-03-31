import SwiftUI

struct DiaryEntryView: View {
    @EnvironmentObject var diaryVM: DiaryViewModel
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @EnvironmentObject var weatherService: WeatherService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: Set<UUID> = []
    @State private var occasion = ""
    @State private var selectedMood: Mood = .happy
    @State private var notes = ""
    @State private var rating = 3
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("日期") {
                    DatePicker("选择日期", selection: $selectedDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "zh_CN"))
                }

                Section("心情") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Mood.allCases) { mood in
                                Button {
                                    selectedMood = mood
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(mood.emoji)
                                            .font(.title)
                                        Text(mood.rawValue)
                                            .font(.caption2)
                                    }
                                    .padding(8)
                                    .background(
                                        selectedMood == mood
                                        ? AppTheme.primaryColor.opacity(0.15)
                                        : Color.clear
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("场合") {
                    TextField("今天是什么场合？", text: $occasion)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Occasion.allCases) { occ in
                                Button {
                                    occasion = occ.rawValue
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: occ.icon)
                                            .font(.caption)
                                        Text(occ.rawValue)
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        occasion == occ.rawValue
                                        ? AnyShapeStyle(AppTheme.accentGradient)
                                        : AnyShapeStyle(Color(.systemGray6))
                                    )
                                    .foregroundColor(occasion == occ.rawValue ? .white : .primary)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("今日穿搭") {
                    if wardrobeVM.clothingItems.isEmpty {
                        Text("衣橱中暂无衣物")
                            .foregroundColor(.secondary)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
                            ForEach(wardrobeVM.clothingItems) { item in
                                Button {
                                    toggleItem(item.id)
                                } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            item.category.color.opacity(0.1)
                                            Image(systemName: item.category.icon)
                                                .foregroundColor(item.category.color)
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(
                                                    selectedItems.contains(item.id) ? AppTheme.primaryColor : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )

                                        Text(item.name)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Section("评分") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                rating = star
                            } label: {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                }

                Section("备注") {
                    TextField("记录今天的穿搭心得...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("记录穿搭")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveEntry() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func toggleItem(_ id: UUID) {
        if selectedItems.contains(id) {
            selectedItems.remove(id)
        } else {
            selectedItems.insert(id)
        }
    }

    private func saveEntry() {
        let outfitItems = wardrobeVM.clothingItems.filter { selectedItems.contains($0.id) }
        let outfit = Outfit(
            name: "\(selectedDate.formattedDate)穿搭",
            items: outfitItems,
            occasion: occasion
        )

        let entry = OutfitDiary(
            date: selectedDate,
            outfit: outfit,
            weather: weatherService.currentWeather,
            occasion: occasion,
            mood: selectedMood,
            notes: notes,
            rating: rating
        )

        diaryVM.addEntry(entry)

        for item in outfitItems {
            wardrobeVM.recordWear(item)
        }

        dismiss()
    }
}
