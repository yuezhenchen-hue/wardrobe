import Foundation

class WeatherService: ObservableObject {
    @Published var currentWeather: WeatherInfo = .sample
    @Published var isLoading = false

    func fetchWeather() {
        isLoading = true

        // Simulate fetching weather with realistic data based on current month
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            let month = Calendar.current.component(.month, from: Date())
            self.currentWeather = self.generateSeasonalWeather(month: month)
            self.isLoading = false
        }
    }

    private func generateSeasonalWeather(month: Int) -> WeatherInfo {
        let (tempRange, conditions): (ClosedRange<Double>, [WeatherCondition]) = {
            switch month {
            case 3...5:
                return (12...25, [.sunny, .cloudy, .windy, .rainy])
            case 6...8:
                return (25...38, [.sunny, .hot, .cloudy, .rainy])
            case 9...11:
                return (8...22, [.sunny, .cloudy, .overcast, .windy])
            default:
                return (-5...10, [.cold, .cloudy, .overcast, .snowy])
            }
        }()

        let temp = Double.random(in: tempRange)
        let condition = conditions.randomElement() ?? .sunny

        return WeatherInfo(
            temperature: temp.rounded(),
            feelsLike: (temp + Double.random(in: -3...2)).rounded(),
            condition: condition,
            humidity: Double.random(in: 30...85).rounded(),
            windSpeed: Double.random(in: 2...30).rounded(),
            city: "上海",
            date: Date()
        )
    }
}
