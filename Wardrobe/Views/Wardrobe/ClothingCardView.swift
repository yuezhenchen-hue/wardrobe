import SwiftUI

struct ClothingCardView: View {
    let item: ClothingItem
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    clothingImage
                    favoriteButton
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: item.category.icon)
                            .font(.caption2)
                            .foregroundColor(item.category.color)
                        Text(item.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        if !item.colors.isEmpty {
                            HStack(spacing: 2) {
                                ForEach(item.colors.prefix(3)) { color in
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 10, height: 10)
                                        .overlay(Circle().stroke(.white, lineWidth: 0.5))
                                }
                            }
                        }
                    }

                    if !item.brand.isEmpty {
                        Text(item.brand)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var clothingImage: some View {
        Group {
            if let imageData = item.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [item.category.color.opacity(0.15), item.category.color.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: item.category.icon)
                        .font(.system(size: 36))
                        .foregroundColor(item.category.color.opacity(0.5))
                }
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }

    private var favoriteButton: some View {
        Button(action: onFavorite) {
            Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                .font(.body)
                .foregroundColor(item.isFavorite ? .red : .white)
                .padding(8)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .padding(8)
    }
}
