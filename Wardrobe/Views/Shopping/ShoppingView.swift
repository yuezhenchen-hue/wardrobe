import SwiftUI

struct ShoppingView: View {
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    private var suggestions: [ShoppingItem] {
        RecommendationEngine.shared.suggestMissingItems(
            wardrobe: wardrobeVM.clothingItems,
            profile: profileVM.profile
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    wardrobeAnalysis
                    suggestionsSection
                    tipsSection
                }
                .padding(.horizontal)
            }
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .navigationTitle("购物建议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var wardrobeAnalysis: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("衣橱分析")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(wardrobeVM.categoryStats, id: \.0) { category, count in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(category.color)
                            .frame(width: 24)
                        Text(category.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Text("\(count)件")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(category.color.opacity(0.6))
                                .frame(width: max(0, geo.size.width * CGFloat(count) / CGFloat(max(wardrobeVM.totalItems, 1))))
                        }
                        .frame(width: 80, height: 6)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("购买建议")
                .font(.headline)

            if suggestions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("你的衣橱很完整！")
                        .font(.headline)
                    Text("暂时没有必要购买的建议")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .cardStyle()
            } else {
                ForEach(suggestions) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.category.icon)
                            .font(.title2)
                            .foregroundColor(item.category.color)
                            .frame(width: 40, height: 40)
                            .background(item.category.color.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.suggestion)
                                .font(.headline)
                            Text(item.reason)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("当前: \(item.currentCount)件")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Capsule())

                                Text("建议: \(item.recommendedCount)件")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                    .cardStyle()
                }
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("购物小贴士")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                TipRow(icon: "lightbulb.fill", text: "优先购买百搭基础款，一件多搭")
                TipRow(icon: "leaf.fill", text: "选择高品质面料，耐穿又舒适")
                TipRow(icon: "paintpalette.fill", text: "参考你的肤色，选择适合的颜色")
                TipRow(icon: "arrow.triangle.2.circlepath", text: "定期整理衣橱，告别冲动消费")
            }
        }
        .padding()
        .cardStyle()
        .padding(.bottom, 20)
    }
}

struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primaryColor)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}
