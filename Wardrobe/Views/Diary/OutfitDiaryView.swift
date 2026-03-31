import SwiftUI

struct OutfitDiaryView: View {
    @EnvironmentObject var diaryVM: DiaryViewModel
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @EnvironmentObject var weatherService: WeatherService
    @State private var showingAddEntry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsSection

                    calendarSection

                    entriesSection
                }
                .padding(.horizontal)
            }
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.outfitDiary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.accentGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                DiaryEntryView()
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 16) {
            DiaryStatCard(
                value: "\(diaryVM.entries.count)",
                title: "总记录",
                icon: "book.fill",
                color: .blue
            )
            DiaryStatCard(
                value: "\(diaryVM.streakDays)",
                title: "连续天数",
                icon: "flame.fill",
                color: .orange
            )
            DiaryStatCard(
                value: "\(diaryVM.thisMonthEntries.count)",
                title: "本月",
                icon: "calendar",
                color: .purple
            )
        }
    }

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本月日历")
                .font(.headline)

            CalendarGridView(
                selectedDate: $diaryVM.selectedDate,
                hasEntry: { diaryVM.hasEntry(for: $0) }
            )
            .cardStyle()
        }
    }

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(diaryVM.selectedDate.isToday ? "今天的穿搭" : diaryVM.selectedDate.formattedDate)
                    .font(.headline)
                Spacer()
            }

            if diaryVM.entriesForSelectedDate.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("这天还没有穿搭记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button {
                        showingAddEntry = true
                    } label: {
                        Text("记录今天的穿搭")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.primaryColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .cardStyle()
            } else {
                ForEach(diaryVM.entriesForSelectedDate) { entry in
                    DiaryEntryCard(entry: entry) {
                        diaryVM.deleteEntry(entry)
                    }
                }
            }

            if !diaryVM.mostWornStyles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("穿搭风格统计")
                        .font(.headline)
                    ForEach(diaryVM.mostWornStyles, id: \.0) { style, count in
                        HStack {
                            Text(style.rawValue)
                                .font(.subheadline)
                            Spacer()
                            Text("\(count)次")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.accentGradient)
                                    .frame(width: max(0, geo.size.width * CGFloat(count) / CGFloat(max(diaryVM.entries.count, 1))))
                            }
                            .frame(width: 80, height: 8)
                        }
                    }
                }
                .padding()
                .cardStyle()
            }
        }
    }
}

struct DiaryStatCard: View {
    let value: String
    let title: String
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

struct DiaryEntryCard: View {
    let entry: OutfitDiary
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.mood.emoji)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(entry.occasion.isEmpty ? "日常穿搭" : entry.occasion)
                        .font(.headline)
                    Text(entry.date.formattedDate + " " + entry.date.weekdayString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < entry.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            if !entry.outfit.items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.outfit.items) { item in
                            VStack {
                                ZStack {
                                    item.category.color.opacity(0.1)
                                    Image(systemName: item.category.icon)
                                        .foregroundColor(item.category.color)
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(item.category.rawValue)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let weather = entry.weather {
                HStack(spacing: 4) {
                    Image(systemName: weather.condition.icon)
                        .font(.caption)
                    Text("\(weather.temperatureDescription) \(weather.condition.rawValue)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .cardStyle()
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    let hasEntry: (Date) -> Bool

    private let calendar = Calendar.current
    private let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthYearString)
                    .font(.headline)
                Spacer()
                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }

            let days = generateDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    if let date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasEntry: hasEntry(date)
                        )
                        .onTapGesture {
                            selectedDate = date
                        }
                    } else {
                        Text("")
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding()
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate)
    }

    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func generateDays() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }

        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        return days
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasEntry: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : (isToday ? AppTheme.primaryColor : .primary))
                .frame(width: 32, height: 32)
                .background(
                    isSelected ? AnyShapeStyle(AppTheme.accentGradient) :
                    isToday ? AnyShapeStyle(AppTheme.primaryColor.opacity(0.1)) :
                    AnyShapeStyle(Color.clear)
                )
                .clipShape(Circle())

            Circle()
                .fill(hasEntry ? AppTheme.primaryColor : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(height: 40)
    }
}
