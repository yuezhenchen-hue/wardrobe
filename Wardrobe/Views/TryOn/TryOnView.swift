import SwiftUI
import PhotosUI

/// 虚拟试穿预览：上传个人全身照 → 选择衣橱中的衣物 → 查看搭配效果
struct TryOnView: View {
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var personPhoto: PhotosPickerItem?
    @State private var personImageData: Data?
    @State private var selectedOutfitItems: [ClothingItem] = []
    @State private var showItemPicker = false

    // 体态分析
    @State private var isAnalyzing = false
    @State private var analysisResult: BodyAnalysisService.BodyAnalysisResult?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    personPhotoSection
                    if analysisResult?.personDetected == true {
                        bodyAnalysisSection
                    }
                    outfitSelectionSection
                    tryOnPreviewSection
                    if !selectedOutfitItems.isEmpty {
                        matchAnalysisSection
                    }
                }
                .padding(.horizontal)
            }
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .navigationTitle("试穿预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showItemPicker) {
                OutfitItemPickerView(
                    items: wardrobeVM.clothingItems,
                    selected: $selectedOutfitItems
                )
            }
        }
    }

    // MARK: - 个人照片区

    private var personPhotoSection: some View {
        VStack(spacing: 12) {
            Text("上传全身照")
                .font(.headline)

            if let data = personImageData, let uiImage = UIImage(data: data) {
                ZStack(alignment: .bottom) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    if isAnalyzing {
                        HStack(spacing: 8) {
                            ProgressView().tint(.white)
                            Text("正在分析体态...").font(.caption.bold()).foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 12)
                    }

                    // 如果有分割遮罩，显示轮廓
                    if let mask = analysisResult?.segmentationMask {
                        Image(uiImage: mask)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .blendMode(.overlay)
                            .opacity(0.3)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .allowsHitTesting(false)
                    }
                }

                PhotosPicker(selection: $personPhoto, matching: .images) {
                    Text("更换照片")
                        .font(.caption)
                        .foregroundColor(AppTheme.primaryColor)
                }
            } else {
                PhotosPicker(selection: $personPhoto, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.primaryColor.opacity(0.5))
                        Text("上传一张全身照片")
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.primaryColor)
                        Text("系统将自动分析体型、比例\n并为你推荐最适合的穿搭")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(AppTheme.primaryColor.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(AppTheme.primaryColor.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8]))
                    )
                }
            }
        }
        .onChange(of: personPhoto) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    personImageData = data
                    await analyzeBody(data: data)
                }
            }
        }
    }

    // MARK: - 体态分析结果

    private var bodyAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.stand")
                    .foregroundColor(AppTheme.primaryColor)
                Text("体态分析")
                    .font(.headline)
            }

            if let result = analysisResult {
                Text(result.bodyProportionDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let bodyType = result.estimatedBodyType {
                    HStack {
                        Text("推荐体型")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(bodyType.rawValue)
                            .font(.subheadline.bold())
                            .foregroundColor(AppTheme.primaryColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppTheme.primaryColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }

                if let shr = result.shoulderToHipRatio {
                    HStack(spacing: 16) {
                        MeasureTag(label: "肩臀比", value: String(format: "%.2f", shr))
                        if let ulr = result.upperToLowerRatio {
                            MeasureTag(label: "上下身比", value: String(format: "%.2f", ulr))
                        }
                    }
                }

                if !result.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("穿搭建议").font(.caption.bold())
                        ForEach(result.suggestions, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - 搭配选择

    private var outfitSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("选择试穿衣物")
                    .font(.headline)
                Spacer()
                Button {
                    showItemPicker = true
                } label: {
                    Label("添加", systemImage: "plus.circle")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primaryColor)
                }
            }

            if selectedOutfitItems.isEmpty {
                Text("从衣橱中选择你想试穿的衣物")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(selectedOutfitItems) { item in
                            VStack(spacing: 4) {
                                ZStack {
                                    if let imgData = item.imageData, let img = UIImage(data: imgData) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        item.category.color.opacity(0.15)
                                        Image(systemName: item.category.icon)
                                            .foregroundColor(item.category.color)
                                    }
                                }
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                Text(item.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .frame(width: 70)
                            }
                            .onTapGesture {
                                selectedOutfitItems.removeAll { $0.id == item.id }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - 试穿预览

    private var tryOnPreviewSection: some View {
        Group {
            if let personData = personImageData, let personImage = UIImage(data: personData),
               !selectedOutfitItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("试穿预览")
                        .font(.headline)

                    // 人物照片 + 衣物叠加展示
                    ZStack {
                        Image(uiImage: personImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        // 衣物缩略图排列在侧边
                        VStack(spacing: 8) {
                            ForEach(selectedOutfitItems) { item in
                                itemOverlay(item)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                        .padding(.trailing, 8)
                    }

                    Text("提示：拖动衣物图片可调整位置，查看搭配效果")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .cardStyle()
            }
        }
    }

    private func itemOverlay(_ item: ClothingItem) -> some View {
        VStack(spacing: 2) {
            ZStack {
                if let imgData = item.imageData, let img = UIImage(data: imgData) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    item.category.color.opacity(0.3)
                    Image(systemName: item.category.icon)
                        .font(.title3)
                        .foregroundColor(item.category.color)
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white, lineWidth: 2))
            .shadow(radius: 4)

            Text(item.category.rawValue)
                .font(.system(size: 9))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
        }
    }

    // MARK: - 搭配分析

    private var matchAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("搭配分析")
                .font(.headline)

            let score = RecommendationEngine.shared.scoreCompleteOutfit(
                items: selectedOutfitItems,
                occasion: .daily,
                profile: ProfileViewModel().profile
            )

            // 协调度
            HStack {
                Text("协调度")
                    .font(.subheadline)
                Spacer()
                Text("\(Int(score * 100))%")
                    .font(.title2.bold())
                    .foregroundColor(score >= 0.7 ? .green : score >= 0.5 ? .orange : .red)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(score >= 0.7 ? Color.green : score >= 0.5 ? Color.orange : Color.red)
                        .frame(width: geo.size.width * score)
                }
            }
            .frame(height: 8)

            // 配色分析
            let colors = selectedOutfitItems.compactMap(\.colors.first)
            if colors.count >= 2 {
                let harmony = ColorMatchingService.shared.analyzeColorHarmony(colors: colors)
                HStack {
                    Text("配色")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(harmony.name) — \(harmony.description)")
                        .font(.caption)
                }
            }

            // 体型适配建议
            if let bodyType = analysisResult?.estimatedBodyType {
                VStack(alignment: .leading, spacing: 4) {
                    Text("体型适配")
                        .font(.caption.bold())
                    Text(bodySpecificAdvice(bodyType: bodyType, items: selectedOutfitItems))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .cardStyle()
        .padding(.bottom, 30)
    }

    private func bodySpecificAdvice(bodyType: BodyType, items: [ClothingItem]) -> String {
        switch bodyType {
        case .slim:
            return "你的身材纤细，选择的搭配可以尝试更多层次感，叠穿效果会很好。"
        case .athletic:
            return "健壮身材适合展现线条，V领和修身款上衣会很显精神。"
        case .average:
            return "匀称身材百搭各种风格，当前搭配很适合你。"
        case .curvy:
            return "建议选择收腰设计突出曲线美，A字剪裁下装会很修饰。"
        case .petite:
            return "高腰设计和同色系搭配可以拉长比例，尽量避免过长的下装。"
        case .tall:
            return "高挑身材的优势很大，各种长款设计都能驾驭。"
        }
    }

    // MARK: - Actions

    private func analyzeBody(data: Data) async {
        guard let image = UIImage(data: data) else { return }
        isAnalyzing = true
        analysisResult = await BodyAnalysisService.shared.analyzeBody(from: image)
        isAnalyzing = false
    }
}

// MARK: - 辅助视图

struct MeasureTag: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(AppTheme.primaryColor)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 衣物选择器

struct OutfitItemPickerView: View {
    let items: [ClothingItem]
    @Binding var selected: [ClothingItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ClothingCategory.allCases) { category in
                    let categoryItems = items.filter { $0.category == category }
                    if !categoryItems.isEmpty {
                        Section(category.rawValue) {
                            ForEach(categoryItems) { item in
                                Button {
                                    toggleSelection(item)
                                } label: {
                                    HStack {
                                        ZStack {
                                            if let data = item.imageData, let img = UIImage(data: data) {
                                                Image(uiImage: img)
                                                    .resizable()
                                                    .scaledToFill()
                                            } else {
                                                item.category.color.opacity(0.15)
                                                Image(systemName: item.category.icon)
                                                    .foregroundColor(item.category.color)
                                            }
                                        }
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                        VStack(alignment: .leading) {
                                            Text(item.name)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            Text(item.colors.map(\.name).joined(separator: "、"))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        if selected.contains(where: { $0.id == item.id }) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(AppTheme.primaryColor)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择衣物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成(\(selected.count))") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func toggleSelection(_ item: ClothingItem) {
        if let index = selected.firstIndex(where: { $0.id == item.id }) {
            selected.remove(at: index)
        } else {
            selected.append(item)
        }
    }
}
