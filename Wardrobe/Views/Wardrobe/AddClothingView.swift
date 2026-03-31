import SwiftUI
import PhotosUI

struct AddClothingView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ClothingCategory = .top
    @State private var subcategory = ""
    @State private var selectedColors: [ClothingColor] = []
    @State private var selectedSeasons: Set<Season> = []
    @State private var selectedStyles: Set<ClothingStyle> = []
    @State private var material = ""
    @State private var brand = ""
    @State private var warmthLevel = 3
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var showingCamera = false

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                basicInfoSection
                colorSection
                seasonSection
                styleSection
                detailSection
                warmthSection
            }
            .navigationTitle("添加衣物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveItem() }
                        .disabled(name.isEmpty)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var photoSection: some View {
        Section {
            VStack(spacing: 12) {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("从相册选择", systemImage: "photo.on.rectangle")
                            .secondaryButtonStyle()
                    }
                }
                .onChange(of: selectedPhoto) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            imageData = data
                        }
                    }
                }
            }
            .listRowBackground(Color.clear)
        }
    }

    private var basicInfoSection: some View {
        Section("基本信息") {
            TextField("衣物名称", text: $name)

            Picker("分类", selection: $category) {
                ForEach(ClothingCategory.allCases) { cat in
                    Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                }
            }

            TextField("子分类（如：T恤、衬衫）", text: $subcategory)
            TextField("品牌", text: $brand)
            TextField("材质", text: $material)
        }
    }

    private var colorSection: some View {
        Section("颜色") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                ForEach(ClothingColor.presets) { color in
                    Button {
                        toggleColor(color)
                    } label: {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(
                                        selectedColors.contains(where: { $0.id == color.id }) ? AppTheme.primaryColor : Color.clear,
                                        lineWidth: 3
                                    )
                                )
                                .overlay(
                                    selectedColors.contains(where: { $0.id == color.id })
                                    ? Image(systemName: "checkmark").font(.caption.bold()).foregroundColor(.white)
                                    : nil
                                )
                            Text(color.name)
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var seasonSection: some View {
        Section("适合季节") {
            HStack(spacing: 12) {
                ForEach(Season.allCases) { season in
                    Button {
                        toggleSeason(season)
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: season.icon)
                                .font(.title3)
                                .foregroundColor(selectedSeasons.contains(season) ? .white : season.color)
                            Text(season.rawValue)
                                .font(.caption)
                                .foregroundColor(selectedSeasons.contains(season) ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedSeasons.contains(season)
                            ? AnyShapeStyle(season.color)
                            : AnyShapeStyle(season.color.opacity(0.1))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var styleSection: some View {
        Section("穿衣风格") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(ClothingStyle.allCases) { style in
                    Button {
                        toggleStyle(style)
                    } label: {
                        Text(style.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedStyles.contains(style)
                                ? AnyShapeStyle(AppTheme.accentGradient)
                                : AnyShapeStyle(Color(.systemGray6))
                            )
                            .foregroundColor(selectedStyles.contains(style) ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var detailSection: some View {
        Section("备注") {
            TextField("添加备注...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var warmthSection: some View {
        Section("保暖程度") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("轻薄")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("厚实")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(warmthLevel) },
                    set: { warmthLevel = Int($0) }
                ), in: 1...5, step: 1)
                .tint(AppTheme.primaryColor)

                HStack {
                    ForEach(1...5, id: \.self) { level in
                        Text(warmthEmoji(level))
                            .frame(maxWidth: .infinity)
                            .opacity(level == warmthLevel ? 1 : 0.3)
                    }
                }
            }
        }
    }

    private func warmthEmoji(_ level: Int) -> String {
        switch level {
        case 1: return "🌞"
        case 2: return "🌤"
        case 3: return "⛅"
        case 4: return "🌥"
        case 5: return "❄️"
        default: return "⛅"
        }
    }

    private func toggleColor(_ color: ClothingColor) {
        if let index = selectedColors.firstIndex(where: { $0.id == color.id }) {
            selectedColors.remove(at: index)
        } else {
            selectedColors.append(color)
        }
    }

    private func toggleSeason(_ season: Season) {
        if selectedSeasons.contains(season) {
            selectedSeasons.remove(season)
        } else {
            selectedSeasons.insert(season)
        }
    }

    private func toggleStyle(_ style: ClothingStyle) {
        if selectedStyles.contains(style) {
            selectedStyles.remove(style)
        } else {
            selectedStyles.insert(style)
        }
    }

    private func saveItem() {
        let item = ClothingItem(
            name: name,
            category: category,
            subcategory: subcategory,
            colors: selectedColors,
            seasons: Array(selectedSeasons),
            styles: Array(selectedStyles),
            material: material,
            brand: brand,
            imageData: imageData,
            notes: notes,
            warmthLevel: warmthLevel
        )
        vm.addItem(item)
        dismiss()
    }
}
