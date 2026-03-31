import Foundation
import SwiftUI

enum WeatherCondition: String, CaseIterable, Codable {
    case sunny = "晴天"
    case cloudy = "多云"
    case overcast = "阴天"
    case rainy = "雨天"
    case snowy = "雪天"
    case windy = "大风"
    case foggy = "雾天"
    case hot = "酷热"
    case cold = "严寒"

    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "cloud.snow.fill"
        case .windy: return "wind"
        case .foggy: return "cloud.fog.fill"
        case .hot: return "thermometer.sun.fill"
        case .cold: return "thermometer.snowflake"
        }
    }

    var color: Color {
        switch self {
        case .sunny: return .orange
        case .cloudy: return .gray
        case .overcast: return .secondary
        case .rainy: return .blue
        case .snowy: return .cyan
        case .windy: return .mint
        case .foggy: return .gray.opacity(0.7)
        case .hot: return .red
        case .cold: return .blue
        }
    }
}

struct WeatherInfo: Codable {
    var temperature: Double
    var feelsLike: Double
    var condition: WeatherCondition
    var humidity: Double
    var windSpeed: Double
    var city: String
    var date: Date

    init(
        temperature: Double = 22,
        feelsLike: Double = 22,
        condition: WeatherCondition = .sunny,
        humidity: Double = 50,
        windSpeed: Double = 10,
        city: String = "北京",
        date: Date = Date()
    ) {
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.condition = condition
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.city = city
        self.date = date
    }

    var temperatureDescription: String {
        "\(Int(temperature))°C"
    }

    var dressingSuggestion: String {
        switch temperature {
        case ..<5:
            return "天气寒冷，建议穿厚外套、毛衣、围巾等保暖衣物"
        case 5..<10:
            return "天气较冷，建议穿外套搭配毛衣或卫衣"
        case 10..<15:
            return "天气微凉，建议穿薄外套或风衣"
        case 15..<20:
            return "天气舒适偏凉，可穿长袖衬衫或薄针织衫"
        case 20..<25:
            return "天气舒适，适合穿T恤搭配薄外套"
        case 25..<30:
            return "天气温暖，适合穿短袖或薄衬衫"
        case 30...:
            return "天气炎热，建议穿轻薄透气的衣物"
        default:
            return "请根据体感温度选择合适的衣物"
        }
    }

    var recommendedWarmthLevel: ClosedRange<Int> {
        switch temperature {
        case ..<5: return 4...5
        case 5..<10: return 3...5
        case 10..<20: return 2...4
        case 20..<25: return 1...3
        case 25...: return 1...2
        default: return 2...4
        }
    }

    static let sample = WeatherInfo(
        temperature: 18,
        feelsLike: 16,
        condition: .cloudy,
        humidity: 65,
        windSpeed: 12,
        city: "上海"
    )
}
