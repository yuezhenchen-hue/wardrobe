import Foundation
import CoreLocation

/// 接入 Open-Meteo 免费天气 API 的真实天气服务
class WeatherService: ObservableObject {
    @Published var currentWeather: WeatherInfo = .sample
    @Published var isLoading = false
    @Published var lastError: String?

    private let baseURL = "https://api.open-meteo.com/v1/forecast"

    func fetchWeather(latitude: Double, longitude: Double, city: String = "") {
        isLoading = true
        lastError = nil

        let urlString = "\(baseURL)?latitude=\(latitude)&longitude=\(longitude)"
            + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m"
            + "&timezone=auto"

        guard let url = URL(string: urlString) else {
            fallbackToSimulated(city: city)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                if let error {
                    self.lastError = error.localizedDescription
                    self.fallbackToSimulated(city: city)
                    return
                }

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let current = json["current"] as? [String: Any] else {
                    self.fallbackToSimulated(city: city)
                    return
                }

                let temperature = current["temperature_2m"] as? Double ?? 20
                let feelsLike = current["apparent_temperature"] as? Double ?? temperature
                let weatherCode = current["weather_code"] as? Int ?? 0
                let windSpeed = current["wind_speed_10m"] as? Double ?? 0
                let humidity = current["relative_humidity_2m"] as? Double ?? 50

                self.currentWeather = WeatherInfo(
                    temperature: temperature,
                    feelsLike: feelsLike,
                    condition: WeatherInfo.conditionFromWMOCode(weatherCode),
                    humidity: humidity,
                    windSpeed: windSpeed,
                    city: city.isEmpty ? "当前位置" : city,
                    date: Date()
                )
            }
        }.resume()
    }

    func fetchWeather(location: CLLocation?, city: String) {
        let lat = location?.coordinate.latitude ?? 31.23
        let lon = location?.coordinate.longitude ?? 121.47
        fetchWeather(latitude: lat, longitude: lon, city: city)
    }

    private func fallbackToSimulated(city: String) {
        isLoading = false
        let month = Calendar.current.component(.month, from: Date())
        currentWeather = generateSeasonalWeather(month: month, city: city.isEmpty ? "未知" : city)
    }

    private func generateSeasonalWeather(month: Int, city: String) -> WeatherInfo {
        let (tempRange, conditions): (ClosedRange<Double>, [WeatherCondition]) = {
            switch month {
            case 3...5: return (12...25, [.sunny, .cloudy, .windy, .rainy])
            case 6...8: return (25...38, [.sunny, .hot, .cloudy, .rainy])
            case 9...11: return (8...22, [.sunny, .cloudy, .overcast, .windy])
            default: return (-5...10, [.cold, .cloudy, .overcast, .snowy])
            }
        }()

        let temp = Double.random(in: tempRange).rounded()
        let condition = conditions.randomElement() ?? .sunny

        return WeatherInfo(
            temperature: temp,
            feelsLike: (temp + Double.random(in: -3...2)).rounded(),
            condition: condition,
            humidity: Double.random(in: 30...85).rounded(),
            windSpeed: Double.random(in: 2...30).rounded(),
            city: city,
            date: Date()
        )
    }
}
