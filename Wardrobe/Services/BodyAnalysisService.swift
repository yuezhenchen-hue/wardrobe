import UIKit
import Vision

/// 体态分析服务：通过全身照片检测体型、估算身高比例
/// 使用 Apple Vision 框架的 2D/3D 人体姿态检测
class BodyAnalysisService {
    static let shared = BodyAnalysisService()
    private init() {}

    struct BodyAnalysisResult {
        var estimatedBodyType: BodyType?
        var shoulderToHipRatio: Double?
        var upperToLowerRatio: Double?
        var bodyProportionDescription: String
        var personDetected: Bool
        var jointPoints: [String: CGPoint]  // 关节点（归一化坐标）
        var segmentationMask: UIImage?       // 人物分割遮罩
        var suggestions: [String]
    }

    // MARK: - 主入口

    func analyzeBody(from image: UIImage) async -> BodyAnalysisResult {
        guard let cgImage = image.cgImage else {
            return emptyResult()
        }

        // 并行执行姿态检测和人物分割
        async let poseResult = detectBodyPose(cgImage: cgImage)
        async let segResult = segmentPerson(cgImage: cgImage)

        let joints = await poseResult
        let mask = await segResult

        guard !joints.isEmpty else {
            return BodyAnalysisResult(
                bodyProportionDescription: "未检测到人体，请上传清晰的全身正面照片",
                personDetected: false,
                jointPoints: [:],
                suggestions: ["确保照片中有完整的全身", "站立姿势、正面朝向镜头效果最佳"]
            )
        }

        let analysis = analyzeProportions(joints: joints)

        return BodyAnalysisResult(
            estimatedBodyType: analysis.bodyType,
            shoulderToHipRatio: analysis.shoulderHipRatio,
            upperToLowerRatio: analysis.upperLowerRatio,
            bodyProportionDescription: analysis.description,
            personDetected: true,
            jointPoints: joints,
            segmentationMask: mask,
            suggestions: analysis.suggestions
        )
    }

    // MARK: - 2D Body Pose Detection

    private func detectBodyPose(cgImage: CGImage) async -> [String: CGPoint] {
        await withCheckedContinuation { continuation in
            let request = VNDetectHumanBodyPoseRequest { request, error in
                guard let observations = request.results as? [VNHumanBodyPoseObservation],
                      let body = observations.first else {
                    continuation.resume(returning: [:])
                    return
                }

                var points: [String: CGPoint] = [:]
                let jointNames: [(VNHumanBodyPoseObservation.JointName, String)] = [
                    (.nose, "nose"),
                    (.neck, "neck"),
                    (.leftShoulder, "leftShoulder"),
                    (.rightShoulder, "rightShoulder"),
                    (.leftElbow, "leftElbow"),
                    (.rightElbow, "rightElbow"),
                    (.leftWrist, "leftWrist"),
                    (.rightWrist, "rightWrist"),
                    (.leftHip, "leftHip"),
                    (.rightHip, "rightHip"),
                    (.leftKnee, "leftKnee"),
                    (.rightKnee, "rightKnee"),
                    (.leftAnkle, "leftAnkle"),
                    (.rightAnkle, "rightAnkle"),
                    (.root, "root"),
                ]

                for (jointName, key) in jointNames {
                    if let point = try? body.recognizedPoint(jointName),
                       point.confidence > 0.3 {
                        points[key] = CGPoint(x: point.location.x, y: point.location.y)
                    }
                }

                continuation.resume(returning: points)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [:])
            }
        }
    }

    // MARK: - Person Segmentation

    private func segmentPerson(cgImage: CGImage) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest()
            request.qualityLevel = .balanced

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
                guard let result = request.results?.first,
                      let maskBuffer = result.pixelBuffer as CVPixelBuffer? else {
                    continuation.resume(returning: nil)
                    return
                }
                let ciImage = CIImage(cvPixelBuffer: maskBuffer)
                let context = CIContext()
                guard let cg = context.createCGImage(ciImage, from: ciImage.extent) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: UIImage(cgImage: cg))
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - 体型分析

    private struct ProportionAnalysis {
        var bodyType: BodyType?
        var shoulderHipRatio: Double?
        var upperLowerRatio: Double?
        var description: String
        var suggestions: [String]
    }

    private func analyzeProportions(joints: [String: CGPoint]) -> ProportionAnalysis {
        // 计算肩宽
        let shoulderWidth: Double? = {
            guard let ls = joints["leftShoulder"], let rs = joints["rightShoulder"] else { return nil }
            return abs(ls.x - rs.x)
        }()

        // 计算臀宽
        let hipWidth: Double? = {
            guard let lh = joints["leftHip"], let rh = joints["rightHip"] else { return nil }
            return abs(lh.x - rh.x)
        }()

        // 肩臀比
        let shoulderHipRatio: Double? = {
            guard let sw = shoulderWidth, let hw = hipWidth, hw > 0.01 else { return nil }
            return sw / hw
        }()

        // 上下身比例（脖子到臀 vs 臀到脚踝）
        let upperLowerRatio: Double? = {
            guard let neck = joints["neck"], let root = joints["root"],
                  let ankle = joints["leftAnkle"] ?? joints["rightAnkle"] else { return nil }
            let upper = abs(neck.y - root.y)
            let lower = abs(root.y - ankle.y)
            guard lower > 0.01 else { return nil }
            return upper / lower
        }()

        // 推断体型
        let bodyType = estimateBodyType(
            shoulderHipRatio: shoulderHipRatio,
            upperLowerRatio: upperLowerRatio
        )

        // 生成描述
        var description = ""
        var suggestions: [String] = []

        if let ratio = shoulderHipRatio {
            if ratio > 1.3 {
                description += "肩部较宽，呈倒三角体型。"
                suggestions.append("V 领和深色上衣可以平衡肩部视觉宽度")
            } else if ratio < 0.9 {
                description += "臀部相对较宽。"
                suggestions.append("A 字裙和宽肩设计上衣可以平衡比例")
            } else {
                description += "肩臀比例均匀。"
                suggestions.append("身材匀称，大部分剪裁都适合")
            }
        }

        if let ratio = upperLowerRatio {
            if ratio > 0.65 {
                description += "上半身偏长。"
                suggestions.append("高腰设计可以优化身材比例，拉长腿部线条")
            } else if ratio < 0.45 {
                description += "腿部比例较长，身材高挑。"
                suggestions.append("身材比例很好，可以尝试各种长度的下装")
            } else {
                description += "上下身比例标准。"
            }
        }

        if let bt = bodyType {
            description += " 推荐体型分类：\(bt.rawValue)。"
            suggestions.append(bt.description)
        }

        if description.isEmpty {
            description = "已检测到人体关节点，但信息不足以完整分析。建议上传更清晰的全身正面照。"
        }

        return ProportionAnalysis(
            bodyType: bodyType,
            shoulderHipRatio: shoulderHipRatio,
            upperLowerRatio: upperLowerRatio,
            description: description,
            suggestions: suggestions
        )
    }

    private func estimateBodyType(shoulderHipRatio: Double?, upperLowerRatio: Double?) -> BodyType? {
        guard let shr = shoulderHipRatio else { return nil }

        if shr > 1.25 {
            return .athletic  // 宽肩窄臀 → 健壮
        } else if shr < 0.85 {
            return .curvy     // 窄肩宽臀 → 丰满
        }

        if let ulr = upperLowerRatio {
            if ulr < 0.45 {
                return .tall  // 腿长 → 高挑
            } else if ulr > 0.7 {
                return .petite // 上身长 → 娇小
            }
        }

        return .average // 匀称
    }

    private func emptyResult() -> BodyAnalysisResult {
        BodyAnalysisResult(
            bodyProportionDescription: "请上传一张全身照片进行分析",
            personDetected: false,
            jointPoints: [:],
            suggestions: []
        )
    }
}
