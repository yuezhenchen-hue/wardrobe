import SwiftUI

struct WeatherBannerView: View {
    let weather: WeatherInfo

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                    Text(weather.city)
                        .font(.subheadline)
                }
                .foregroundColor(.white.opacity(0.9))

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(weather.temperature))")
                        .font(.system(size: 44, weight: .light))
                    Text("°C")
                        .font(.title3)
                }
                .foregroundColor(.white)

                Text(weather.dressingSuggestion)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
            }

            Spacer()

            VStack(spacing: 8) {
                Image(systemName: weather.condition.icon)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)

                Text(weather.condition.rawValue)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: weatherGradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private var weatherGradientColors: [Color] {
        switch weather.condition {
        case .sunny, .hot:
            return [Color(hex: "#FF8C42"), Color(hex: "#FFA07A")]
        case .cloudy:
            return [Color(hex: "#6B8CAE"), Color(hex: "#8AAFC4")]
        case .overcast:
            return [Color(hex: "#7A8B99"), Color(hex: "#95A5A6")]
        case .rainy:
            return [Color(hex: "#4A6FA5"), Color(hex: "#6B8FBF")]
        case .snowy:
            return [Color(hex: "#7EB8DA"), Color(hex: "#A8D8EA")]
        case .windy:
            return [Color(hex: "#5DADE2"), Color(hex: "#7EC8E3")]
        case .foggy:
            return [Color(hex: "#95A5A6"), Color(hex: "#BDC3C7")]
        case .cold:
            return [Color(hex: "#2E4057"), Color(hex: "#4A6FA5")]
        }
    }
}
