import Foundation
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile = UserProfile()
    @Published var isEditing = false

    private let storage = StorageService.shared

    var bmiValue: Double? {
        guard let height = profile.heightCm, let weight = profile.weightKg,
              height > 0, weight > 0 else { return nil }
        let heightM = height / 100
        return weight / (heightM * heightM)
    }

    var bmiCategory: String {
        guard let bmi = bmiValue else { return "未知" }
        switch bmi {
        case ..<18.5: return "偏瘦"
        case 18.5..<24: return "正常"
        case 24..<28: return "偏胖"
        default: return "肥胖"
        }
    }

    var styleDescription: String {
        if profile.preferredStyles.isEmpty { return "尚未设置风格偏好" }
        return profile.preferredStyles.map(\.rawValue).joined(separator: " · ")
    }

    func loadProfile() {
        profile = storage.loadProfile()
    }

    func saveProfile() {
        storage.saveProfile(profile)
    }

    func updateAvatar(_ imageData: Data?) {
        profile.avatarData = imageData
        saveProfile()
    }

    func completeOnboarding() {
        profile.hasCompletedOnboarding = true
        saveProfile()
    }
}
