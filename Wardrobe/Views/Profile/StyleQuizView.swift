import SwiftUI

struct StyleQuizView: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var currentQuestion = 0
    @State private var answers: [Int] = Array(repeating: -1, count: 5)

    private let questions: [(question: String, options: [(text: String, styles: [ClothingStyle])])] = [
        (
            question: "周末出门你最可能穿什么？",
            options: [
                ("牛仔裤+T恤，舒服就好", [.casual, .minimalist]),
                ("精心搭配的连衣裙", [.romantic, .elegant]),
                ("运动套装，随时准备动", [.sporty, .casual]),
                ("潮牌卫衣+工装裤", [.streetwear]),
            ]
        ),
        (
            question: "你选衣服最看重什么？",
            options: [
                ("舒适度和实用性", [.casual, .minimalist]),
                ("独特设计和剪裁", [.vintage, .bohemian]),
                ("品牌和质感", [.elegant, .business]),
                ("潮流和个性", [.streetwear]),
            ]
        ),
        (
            question: "你理想中的衣橱颜色？",
            options: [
                ("黑白灰为主", [.minimalist, .formal]),
                ("大地色和暖色调", [.bohemian, .vintage]),
                ("明亮的彩色系", [.romantic, .streetwear]),
                ("深色为主偶尔亮色点缀", [.elegant, .business]),
            ]
        ),
        (
            question: "参加朋友聚会你会穿？",
            options: [
                ("简单干净的基础款", [.minimalist, .casual]),
                ("有点小心机的时尚单品", [.elegant, .romantic]),
                ("最新潮的outfit", [.streetwear]),
                ("有文艺气息的搭配", [.vintage, .bohemian]),
            ]
        ),
        (
            question: "你买衣服的频率？",
            options: [
                ("很少买，每件都精挑细选", [.minimalist, .elegant]),
                ("换季就更新衣橱", [.casual, .business]),
                ("看到喜欢就买", [.streetwear, .romantic]),
                ("喜欢淘二手和vintage", [.vintage, .bohemian]),
            ]
        ),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                progressBar

                if currentQuestion < questions.count {
                    questionView
                } else {
                    resultView
                }
            }
            .padding()
            .background(AppTheme.warmBackground.ignoresSafeArea())
            .navigationTitle("风格测试")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.accentGradient)
                    .frame(
                        width: geo.size.width * CGFloat(min(currentQuestion + 1, questions.count)) / CGFloat(questions.count),
                        height: 6
                    )
                    .animation(.easeInOut, value: currentQuestion)
            }
        }
        .frame(height: 6)
    }

    private var questionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("问题 \(currentQuestion + 1)/\(questions.count)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(questions[currentQuestion].question)
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                ForEach(0..<questions[currentQuestion].options.count, id: \.self) { index in
                    Button {
                        selectAnswer(index)
                    } label: {
                        Text(questions[currentQuestion].options[index].text)
                            .font(.body)
                            .foregroundColor(
                                answers[currentQuestion] == index ? .white : .primary
                            )
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                answers[currentQuestion] == index
                                ? AnyShapeStyle(AppTheme.accentGradient)
                                : AnyShapeStyle(Color(.systemBackground))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 4)
                    }
                }
            }

            Spacer()
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(AppTheme.accentGradient)

            Text("你的风格分析")
                .font(.title.bold())

            let styles = calculateTopStyles()

            VStack(spacing: 12) {
                ForEach(styles.prefix(3), id: \.0) { style, score in
                    HStack {
                        Text(style.rawValue)
                            .font(.headline)
                        Spacer()
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.accentGradient)
                                .frame(width: geo.size.width * CGFloat(score) / CGFloat(max(styles.first?.1 ?? 1, 1)))
                        }
                        .frame(width: 100, height: 8)
                    }
                    .padding()
                    .cardStyle()
                }
            }

            Spacer()

            Button {
                profileVM.profile.preferredStyles = styles.prefix(3).map(\.0)
                profileVM.saveProfile()
                dismiss()
            } label: {
                Text("保存我的风格")
                    .primaryButtonStyle()
            }
        }
    }

    private func selectAnswer(_ index: Int) {
        answers[currentQuestion] = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                currentQuestion += 1
            }
        }
    }

    private func calculateTopStyles() -> [(ClothingStyle, Int)] {
        var styleCounts: [ClothingStyle: Int] = [:]

        for (questionIndex, answerIndex) in answers.enumerated() {
            guard answerIndex >= 0, questionIndex < questions.count else { continue }
            let styles = questions[questionIndex].options[answerIndex].styles
            for style in styles {
                styleCounts[style, default: 0] += 1
            }
        }

        return styleCounts.sorted { $0.value > $1.value }
    }
}
