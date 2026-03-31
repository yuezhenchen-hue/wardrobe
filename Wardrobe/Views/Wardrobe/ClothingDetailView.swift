import SwiftUI

struct ClothingDetailView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @Environment(\.dismiss) private var dismiss
    let item: ClothingItem

    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerImage

                    VStack(alignment: .leading, spacing: 16) {
                        titleSection
                        Divider()
                        infoGrid
                        Divider()
                        colorsSection
                        Divider()
                        tagsSection
                        Divider()
                        statsSection

                        if !item.notes.isEmpty {
                            Divider()
                            notesSection
                        }

                        colorMatchSection
                    }
                    .padding(.horizontal)
                }
            }
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            vm.toggleFavorite(item)
                        } label: {
                            Label(
                                item.isFavorite ? "取消收藏" : "收藏",
                                systemImage: item.isFavorite ? "heart.slash" : "heart"
                            )
                        }
                        Button {
                            vm.recordWear(item)
                        } label: {
                            Label("记录穿着", systemImage: "checkmark.circle")
                        }
                        Divider()
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
            .alert("确认删除", isPresented: $showDeleteAlert) {
                Button("删除", role: .destructive) {
                    vm.deleteItem(item)
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("删除后无法恢复，确定要删除「\(item.name)」吗？")
            }
        }
    }

    private var headerImage: some View {
        Group {
            if let imageData = item.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [item.category.color.opacity(0.2), item.category.color.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: item.category.icon)
                        .font(.system(size: 60))
                        .foregroundColor(item.category.color.opacity(0.4))
                }
                .frame(height: 250)
            }
        }
    }

    private var titleSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.title2.bold())
                HStack {
                    Image(systemName: item.category.icon)
                        .foregroundColor(item.category.color)
                    Text(item.category.rawValue)
                    if !item.subcategory.isEmpty {
                        Text("·")
                        Text(item.subcategory)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            Spacer()
            if item.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            }
        }
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if !item.brand.isEmpty {
                InfoRow(icon: "tag", title: "品牌", value: item.brand)
            }
            if !item.material.isEmpty {
                InfoRow(icon: "square.3.layers.3d", title: "材质", value: item.material)
            }
            InfoRow(icon: "thermometer", title: "保暖", value: "\(item.warmthLevel)/5")
            InfoRow(icon: "calendar", title: "添加", value: item.dateAdded.formattedDate)
        }
    }

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("颜色")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(item.colors) { color in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 16, height: 16)
                        Text(color.name)
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("适合季节")
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach(item.seasons) { season in
                        Label(season.rawValue, systemImage: season.icon)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(season.color.opacity(0.15))
                            .foregroundColor(season.color)
                            .clipShape(Capsule())
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("穿衣风格")
                    .font(.headline)
                HStack(spacing: 8) {
                    ForEach(item.styles) { style in
                        Text(style.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.primaryColor.opacity(0.1))
                            .foregroundColor(AppTheme.primaryColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("穿着记录")
                .font(.headline)
            HStack(spacing: 20) {
                VStack {
                    Text("\(item.wearCount)")
                        .font(.title.bold())
                        .foregroundColor(AppTheme.primaryColor)
                    Text("穿着次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let lastWorn = item.lastWornDate {
                    VStack {
                        Text(lastWorn.formattedDate)
                            .font(.title3.bold())
                            .foregroundColor(AppTheme.primaryColor)
                        Text("上次穿着")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("备注")
                .font(.headline)
            Text(item.notes)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private var colorMatchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("搭配色建议")
                .font(.headline)

            if let mainColor = item.colors.first {
                let suggestions = ColorMatchingService.shared.suggestComplementaryColors(for: mainColor)
                HStack(spacing: 8) {
                    ForEach(suggestions) { color in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 30, height: 30)
                            Text(color.name)
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 30)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primaryColor)
                .frame(width: 24)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
