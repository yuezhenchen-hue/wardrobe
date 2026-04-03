import Foundation
import CoreLocation
import Combine

/// 接入 Open-Meteo 免费天气 API，支持定时自动刷新
class WeatherService: ObservableObject {
    @Published var currentWeather: WeatherInfo = .sample
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastUpdateTime: Date?

    private let baseURL = "https://api.open-meteo.com/v1/forecast"
    private var refreshTimer: Timer?
    private var lastLatitude: Double?
    private var lastLongitude: Double?
    private var lastCity: String = ""

    /// 每 30 分钟自动刷新一次天气
    private let refreshInterval: TimeInterval = 30 * 60

    deinit {
        refreshTimer?.invalidate()
    }

    // MARK: - 公开接口

    func fetchWeather(latitude: Double, longitude: Double, city: String = "") {
        lastLatitude = latitude
        lastLongitude = longitude
        if !city.isEmpty { lastCity = city }

        performFetch(latitude: latitude, longitude: longitude, city: lastCity)
        startAutoRefresh()
    }

    func fetchWeather(location: CLLocation?, city: String) {
        let lat = location?.coordinate.latitude ?? lastLatitude ?? 31.23
        let lon = location?.coordinate.longitude ?? lastLongitude ?? 121.47
        fetchWeather(latitude: lat, longitude: lon, city: city)
    }

    /// App 回到前台时调用：如果上次更新超过 10 分钟，自动刷新
    func refreshIfStale() {
        guard let lastUpdate = lastUpdateTime else {
            refreshNow()
            return
        }
        if Date().timeIntervalSince(lastUpdate) > 10 * 60 {
            refreshNow()
        }
    }

    /// 立刻刷新（用缓存的位置）
    func refreshNow() {
        guard let lat = lastLatitude, let lon = lastLongitude else { return }
        performFetch(latitude: lat, longitude: lon, city: lastCity)
    }

    // MARK: - 定时刷新

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.refreshNow()
        }
    }

    // MARK: - 网络请求

    private func performFetch(latitude: Double, longitude: Double, city: String) {
        isLoading = true
        lastError = nil

        let urlString = "\(baseURL)?latitude=\(latitude)&longitude=\(longitude)"
            + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m"
            + "&timezone=auto"

        guard let url = URL(string: urlString) else {
            fallbackToSimulated(city: city)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
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
                self.lastUpdateTime = Date()
            }
        }.resume()
    }

    // MARK: - 降级：模拟天气

    private func fallbackToSimulated(city: String) {
        isLoading = false
        let month = Calendar.current.component(.month, from: Date())
        currentWeather = generateSeasonalWeather(month: month, city: city.isEmpty ? "未知" : city)
        lastUpdateTime = Date()
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
