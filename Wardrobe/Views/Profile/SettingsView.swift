import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingClearAlert = false
    @State private var name: String = ""
    @State private var gender: Gender = .female
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    @State private var bodyType: BodyType = .average
    @State private var skinTone: SkinTone = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("个人信息") {
                    TextField("昵称", text: $name)

                    Picker("性别", selection: $gender) {
                        ForEach(Gender.allCases) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }

                    HStack {
                        Text("身高 (cm)")
                        Spacer()
                        TextField("165", text: $heightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }

                    HStack {
                        Text("体重 (kg)")
                        Spacer()
                        TextField("55", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("体型") {
                    Picker("体型", selection: $bodyType) {
                        ForEach(BodyType.allCases) { type in
                            VStack(alignment: .leading) {
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("肤色") {
                    Picker("肤色", selection: $skinTone) {
                        ForEach(SkinTone.allCases) { tone in
                            Text(tone.rawValue).tag(tone)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("应用名称")
                        Spacer()
                        Text("衣橱管家")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("清除所有数据")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveSettings() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadCurrentProfile() }
            .alert("确认清除", isPresented: $showingClearAlert) {
                Button("清除", role: .destructive) {
                    StorageService.shared.clearAll()
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将清除所有衣物、穿搭记录和个人设置，此操作不可恢复。")
            }
        }
    }

    private func loadCurrentProfile() {
        name = profileVM.profile.name
        gender = profileVM.profile.gender
        heightText = profileVM.profile.heightCm.map { "\(Int($0))" } ?? ""
        weightText = profileVM.profile.weightKg.map { "\(Int($0))" } ?? ""
        bodyType = profileVM.profile.bodyType ?? .average
        skinTone = profileVM.profile.skinTone ?? .medium
    }

    private func saveSettings() {
        profileVM.profile.name = name
        profileVM.profile.gender = gender
        profileVM.profile.heightCm = Double(heightText)
        profileVM.profile.weightKg = Double(weightText)
        profileVM.profile.bodyType = bodyType
        profileVM.profile.skinTone = skinTone
        profileVM.saveProfile()
        dismiss()
    }
}
