import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var retryCount = 0
    private let maxRetries = 3

    @Published var location: CLLocation?
    @Published var city: String = ""
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var locationReady = false  // location + city 都就绪

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 1000 // 移动 1km 才触发更新
    }

    func requestLocation() {
        isLoading = true
        retryCount = 0
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isLoading = false
            useFallback()
        @unknown default:
            isLoading = false
            useFallback()
        }
    }

    /// App 回到前台时调用，刷新位置
    func refreshIfNeeded() {
        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else {
            if location == nil { useFallback() }
            return
        }
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }

        let isNewEnough = loc.timestamp.timeIntervalSinceNow > -60
        let isBetterAccuracy = location == nil ||
            loc.horizontalAccuracy < (location?.horizontalAccuracy ?? .greatestFiniteMagnitude)

        if isNewEnough || isBetterAccuracy || location == nil {
            location = loc
            reverseGeocode(loc)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let clError = error as? CLError
        if clError?.code == .denied {
            isLoading = false
            useFallback()
            return
        }

        retryCount += 1
        if retryCount < maxRetries {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(retryCount) * 2) { [weak self] in
                self?.manager.requestLocation()
            }
        } else {
            isLoading = false
            useFallback()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            retryCount = 0
            manager.requestLocation()
        case .denied, .restricted:
            isLoading = false
            useFallback()
        default:
            break
        }
    }

    // MARK: - Private

    private func reverseGeocode(_ location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false

                if let placemark = placemarks?.first {
                    let cityName = placemark.locality
                        ?? placemark.subAdministrativeArea
                        ?? placemark.administrativeArea
                        ?? "当前位置"
                    self.city = cityName
                } else {
                    if self.city.isEmpty { self.city = "当前位置" }
                }

                self.locationReady = true
            }
        }
    }

    private func useFallback() {
        if location == nil {
            location = CLLocation(latitude: 31.23, longitude: 121.47)
            city = "上海"
            locationReady = true
        }
    }
}
