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

    // 识别相关状态
    @State private var isRecognizing = false
    @State private var recognitionDone = false
    @State private var recognitionConfidence: Double = 0

    private let recognizer = ClothingRecognitionService.shared

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                if recognitionDone { recognitionBanner }
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

    // MARK: - 照片区域

    private var photoSection: some View {
        Section {
            VStack(spacing: 12) {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if isRecognizing {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .tint(.white)
                                Text("识别中...")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(8)
                        }
                    }
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
                            await performRecognition(data: data)
                        }
                    }
                }

                if imageData == nil {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("拍照或选择衣物图片，自动识别颜色和品类")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - 识别结果提示

    private var recognitionBanner: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.primaryColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("已自动识别")
                        .font(.subheadline.bold())
                    Text("颜色、品类等信息已自动填入，你可以手动调整")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if recognitionConfidence > 0 {
                    Text("\(Int(recognitionConfidence * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(recognitionConfidence > 0.5 ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            (recognitionConfidence > 0.5 ? Color.green : Color.orange).opacity(0.1)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 基本信息

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

    // MARK: - 颜色

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

    // MARK: - 季节

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

    // MARK: - 风格

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
                    Text("轻薄").font(.caption).foregroundColor(.secondary)
                    Spacer()
                    Text("厚实").font(.caption).foregroundColor(.secondary)
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

    // MARK: - 智能识别

    private func performRecognition(data: Data) async {
        guard let uiImage = UIImage(data: data) else { return }

        isRecognizing = true
        let result = await recognizer.recognize(image: uiImage)
        isRecognizing = false

        withAnimation(.easeInOut(duration: 0.3)) {
            // 填充颜色
            if !result.suggestedColors.isEmpty {
                selectedColors = result.suggestedColors
            }

            // 填充品类
            if let cat = result.suggestedCategory {
                category = cat
            }

            // 填充子分类
            if !result.suggestedSubcategory.isEmpty {
                subcategory = result.suggestedSubcategory
            }

            // 填充季节
            if !result.suggestedSeasons.isEmpty {
                selectedSeasons = Set(result.suggestedSeasons)
            }

            // 填充风格
            if !result.suggestedStyles.isEmpty {
                selectedStyles = Set(result.suggestedStyles)
            }

            // 自动生成名称
            if name.isEmpty {
                let colorName = result.suggestedColors.first?.name ?? ""
                let catName = result.suggestedCategory?.rawValue ?? "衣物"
                let subName = result.suggestedSubcategory
                name = "\(colorName)\(subName.isEmpty ? catName : subName)"
            }

            recognitionConfidence = result.confidence
            recognitionDone = true
        }
    }

    // MARK: - Helpers

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
