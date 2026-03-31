import SwiftUI

struct ContentView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var selectedTab = 0

    var body: some View {
        if profileVM.profile.hasCompletedOnboarding {
            MainTabView(selectedTab: $selectedTab)
        } else {
            OnboardingView()
        }
    }
}

struct OnboardingView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var currentPage = 0
    @State private var name = ""
    @State private var selectedGender: Gender = .female
    @State private var selectedStyles: Set<ClothingStyle> = []

    var body: some View {
        ZStack {
            AppTheme.warmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    welcomePage.tag(0)
                    profilePage.tag(1)
                    stylePage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                pageIndicator
                    .padding(.bottom, 20)

                actionButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "tshirt.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.accentGradient)

            Text("欢迎来到智衣橱")
                .font(.largeTitle.bold())

            Text("你的专属穿搭助手\n让每天的穿搭变得简单又时尚")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private var profilePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("告诉我关于你")
                .font(.title.bold())

            VStack(spacing: 16) {
                TextField("你的名字", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("性别")
                        .font(.headline)
                    Picker("性别", selection: $selectedGender) {
                        ForEach(Gender.allCases) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private var stylePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("你喜欢什么风格？")
                .font(.title.bold())

            Text("选择你偏好的穿衣风格（可多选）")
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(ClothingStyle.allCases) { style in
                    Button {
                        if selectedStyles.contains(style) {
                            selectedStyles.remove(style)
                        } else {
                            selectedStyles.insert(style)
                        }
                    } label: {
                        Text(style.rawValue)
                            .font(.subheadline.bold())
                            .foregroundColor(selectedStyles.contains(style) ? .white : AppTheme.primaryColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedStyles.contains(style)
                                ? AnyShapeStyle(AppTheme.accentGradient)
                                : AnyShapeStyle(AppTheme.primaryColor.opacity(0.1))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? AppTheme.primaryColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var actionButton: some View {
        Button {
            if currentPage < 2 {
                withAnimation { currentPage += 1 }
            } else {
                profileVM.profile.name = name
                profileVM.profile.gender = selectedGender
                profileVM.profile.preferredStyles = Array(selectedStyles)
                profileVM.completeOnboarding()
            }
        } label: {
            Text(currentPage < 2 ? "下一步" : "开始使用")
                .primaryButtonStyle()
        }
    }
}
