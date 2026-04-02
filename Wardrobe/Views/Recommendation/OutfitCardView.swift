import SwiftUI

struct OutfitCardView: View {
    let outfit: Outfit
    var isSaved: Bool = false
    let onAction: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if outfit.isAIGenerated {
                            Image(systemName: "wand.and.stars")
                                .font(.caption)
                                .foregroundColor(AppTheme.primaryColor)
                        }
                        Text(outfit.name)
                            .font(.headline)
                    }
                    HStack(spacing: 6) {
                        Text("\(outfit.items.count)件单品 · \(outfit.occasion)")
                        if outfit.rating > 0 {
                            Text("·")
                            Text("协调度 \(outfit.rating * 20)%")
                                .foregroundColor(outfit.rating >= 4 ? .green : outfit.rating >= 3 ? .orange : .secondary)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Spacer()

                Button(action: onAction) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isSaved ? AppTheme.primaryColor : .secondary)
                }
            }

            if !outfit.items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(outfit.items) { item in
                            outfitItemCard(item)
                        }
                    }
                }
            }

            if isExpanded {
                colorHarmonySection
                styleTagsSection
            }

            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(isExpanded ? "收起详情" : "查看详情")
                        .font(.caption)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.primaryColor)
            }
        }
        .padding()
        .cardStyle()
    }

    private func outfitItemCard(_ item: ClothingItem) -> some View {
        VStack(spacing: 6) {
            ZStack {
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [item.category.color.opacity(0.15), item.category.color.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: item.category.icon)
                        .font(.title3)
                        .foregroundColor(item.category.color.opacity(0.6))
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(item.name)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 80)

            Text(item.category.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var colorHarmonySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            let allColors = outfit.items.flatMap(\.colors)
            let harmony = ColorMatchingService.shared.analyzeColorHarmony(colors: allColors)

            HStack {
                Text("配色分析")
                    .font(.subheadline.bold())
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < Int(harmony.score * 5) ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }

            Text("\(harmony.name) - \(harmony.description)")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(outfit.items.flatMap(\.colors).prefix(6)) { color in
                    Circle()
                        .fill(color.color)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(.top, 4)
    }

    private var styleTagsSection: some View {
        HStack(spacing: 6) {
            ForEach(outfit.styles) { style in
                Text(style.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.primaryColor.opacity(0.1))
                    .foregroundColor(AppTheme.primaryColor)
                    .clipShape(Capsule())
            }
        }
    }
}
