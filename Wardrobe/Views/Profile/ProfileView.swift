import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var wardrobeVM: WardrobeViewModel
    @EnvironmentObject var diaryVM: DiaryViewModel
    @State private var showingStyleQuiz = false
    @State private var showingShoppingView = false
    @State private var showingSettings = false
    @State private var showingTryOn = false
    @State private var showingBodyAnalysis = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var bodyPhoto: PhotosPickerItem?
    @State private var bodyAnalysisResult: BodyAnalysisService.BodyAnalysisResult?
    @State private var isAnalyzingBody = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    avatarSection
                    statsOverview
                    quickActions
                    if showingBodyAnalysis { bodyAnalysisUploadSection }
                    stylePreferences
                    bodyInfoSection
                }
                .padding(.horizontal)
            }
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.styleProfile)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingStyleQuiz) {
                StyleQuizView()
            }
            .sheet(isPresented: $showingShoppingView) {
                ShoppingView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingTryOn) {
                TryOnView()
            }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                if let data = profileVM.profile.avatarData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(AppTheme.primaryColor.opacity(0.3))
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "camera.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, AppTheme.primaryColor)
                }
                .onChange(of: selectedPhoto) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            profileVM.updateAvatar(data)
                        }
                    }
                }
            }

            Text(profileVM.profile.name.isEmpty ? "设置昵称" : profileVM.profile.name)
                .font(.title2.bold())

            if !profileVM.styleDescription.isEmpty {
                Text(profileVM.styleDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top)
    }

    private var statsOverview: some View {
        HStack(spacing: 0) {
            ProfileStatItem(value: "\(wardrobeVM.totalItems)", label: "衣物")
            Divider().frame(height: 30)
            ProfileStatItem(value: "\(diaryVM.entries.count)", label: "穿搭记录")
            Divider().frame(height: 30)
            ProfileStatItem(value: "\(diaryVM.streakDays)", label: "连续天数")
        }
        .padding(.vertical, 16)
        .cardStyle()
    }

    private var quickActions: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ActionCard(title: "风格测试", icon: "sparkles", color: .purple) {
                    showingStyleQuiz = true
                }
                ActionCard(title: "购物清单", icon: "bag", color: .orange) {
                    showingShoppingView = true
                }
            }
            HStack(spacing: 12) {
                ActionCard(title: "试穿预览", icon: "person.crop.rectangle.stack", color: .pink) {
                    showingTryOn = true
                }
                ActionCard(title: "体态分析", icon: "figure.stand", color: .teal) {
                    showingBodyAnalysis = true
                }
            }
        }
    }

    private var stylePreferences: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("风格偏好")
                .font(.headline)

            if profileVM.profile.preferredStyles.isEmpty {
                Button {
                    showingStyleQuiz = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("完成风格测试，发现你的穿衣风格")
                    }
                    .font(.subheadline)
                    .foregroundColor(AppTheme.primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primaryColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                    ForEach(profileVM.profile.preferredStyles) { style in
                        Text(style.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(AppTheme.primaryColor.opacity(0.1))
                            .foregroundColor(AppTheme.primaryColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }

    private var bodyInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("身体信息")
                    .font(.headline)
                Spacer()
                Button("编辑") {
                    profileVM.isEditing = true
                }
                .font(.subheadline)
                .foregroundColor(AppTheme.primaryColor)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                BodyInfoCard(
                    title: "身高",
                    value: profileVM.profile.heightCm.map { "\(Int($0)) cm" } ?? "未设置",
                    icon: "ruler"
                )
                BodyInfoCard(
                    title: "体重",
                    value: profileVM.profile.weightKg.map { "\(Int($0)) kg" } ?? "未设置",
                    icon: "scalemass"
                )
                BodyInfoCard(
                    title: "体型",
                    value: profileVM.profile.bodyType?.rawValue ?? "未设置",
                    icon: "figure.stand"
                )
                BodyInfoCard(
                    title: "肤色",
                    value: profileVM.profile.skinTone?.rawValue ?? "未设置",
                    icon: "paintpalette"
                )
            }

            if let skinTone = profileVM.profile.skinTone {
                VStack(alignment: .leading, spacing: 4) {
                    Text("推荐穿着颜色")
                        .font(.caption.bold())
                    Text(skinTone.recommendedColors.joined(separator: "、"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .cardStyle()
    }

    // MARK: - 体态分析上传

    private var bodyAnalysisUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.stand")
                    .foregroundColor(.teal)
                Text("AI 体态分析")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation { showingBodyAnalysis = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Text("上传全身照片，AI 自动分析体型比例并推荐穿搭")
                .font(.caption)
                .foregroundColor(.secondary)

            PhotosPicker(selection: $bodyPhoto, matching: .images) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text(isAnalyzingBody ? "分析中..." : "上传全身照片")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isAnalyzingBody ? Color.gray : Color.teal)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isAnalyzingBody)
            .onChange(of: bodyPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        isAnalyzingBody = true
                        let result = await BodyAnalysisService.shared.analyzeBody(from: image)
                        bodyAnalysisResult = result
                        isAnalyzingBody = false

                        if let bodyType = result.estimatedBodyType {
                            profileVM.profile.bodyType = bodyType
                            profileVM.saveProfile()
                        }
                    }
                }
            }

            if let result = bodyAnalysisResult {
                if result.personDetected {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("分析完成")
                                .font(.subheadline.bold())
                        }

                        Text(result.bodyProportionDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let bodyType = result.estimatedBodyType {
                            Text("推荐体型：\(bodyType.rawValue)")
                                .font(.caption.bold())
                                .foregroundColor(AppTheme.primaryColor)
                        }

                        ForEach(result.suggestions, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 4) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text(tip)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(result.bodyProportionDescription)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .cardStyle()
    }
}

struct ProfileStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(AppTheme.primaryColor)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct BodyInfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primaryColor)
                .frame(width: 24)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
