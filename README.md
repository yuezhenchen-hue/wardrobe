# 智衣橱 (Smart Wardrobe)

一款帮助用户管理衣橱、学习穿衣搭配的 iOS 应用。

## 功能概览

### 1. 衣橱管理
- 拍照/相册添加衣物
- 衣物分类：上衣、下装、外套、连衣裙、鞋子、包包、配饰等
- 衣物标签：颜色、材质、季节、风格、保暖程度
- 搜索、筛选、排序功能
- 收藏喜爱的衣物
- 穿着次数统计

### 2. 智能穿搭推荐
- 根据天气自动推荐穿搭
- 根据不同场合推荐：日常、工作、约会、派对、运动、旅行等
- 配色和谐度分析
- AI 多套方案推荐
- 保存喜欢的搭配方案

### 3. 穿搭日记
- 每日穿搭记录
- 日历视图
- 心情记录
- 穿搭评分
- 连续记录天数统计
- 风格趋势分析

### 4. 个人形象管理
- 个人资料：身高、体重、体型、肤色
- 风格偏好测试（5 题趣味测试）
- 基于肤色的穿着颜色推荐
- 头像设置

### 5. 购物建议
- 衣橱分析：各分类数量统计
- 智能缺失品建议
- 配色建议
- 购物小贴士

### 6. 其他特性
- 新手引导流程
- 数据本地持久化存储
- 深色模式适配
- 现代化 SwiftUI 界面
- 卡片式设计风格

## 技术栈

| 项目 | 说明 |
|------|------|
| 语言 | Swift 5.9 |
| UI 框架 | SwiftUI |
| 最低支持 | iOS 17.0 |
| 架构 | MVVM |
| 数据存储 | UserDefaults + JSON 编码 |
| 项目管理 | XcodeGen |

## 项目结构

```
Wardrobe/
├── project.yml                 # XcodeGen 项目配置
├── Wardrobe/
│   ├── App/
│   │   ├── WardrobeApp.swift   # App 入口
│   │   └── ContentView.swift   # 根视图 + 新手引导
│   ├── Models/
│   │   ├── ClothingItem.swift  # 衣物数据模型
│   │   ├── Outfit.swift        # 穿搭方案模型
│   │   ├── OutfitDiary.swift   # 穿搭日记模型
│   │   ├── UserProfile.swift   # 用户资料模型
│   │   └── WeatherInfo.swift   # 天气信息模型
│   ├── Views/
│   │   ├── Main/               # 主 Tab 视图
│   │   ├── Wardrobe/           # 衣橱管理视图
│   │   ├── Recommendation/     # 穿搭推荐视图
│   │   ├── Diary/              # 穿搭日记视图
│   │   ├── Profile/            # 个人形象视图
│   │   ├── Shopping/           # 购物建议视图
│   │   └── Components/         # 通用组件
│   ├── ViewModels/
│   │   ├── WardrobeViewModel.swift
│   │   ├── OutfitRecommendationViewModel.swift
│   │   ├── DiaryViewModel.swift
│   │   └── ProfileViewModel.swift
│   ├── Services/
│   │   ├── StorageService.swift       # 数据存储服务
│   │   ├── WeatherService.swift       # 天气服务
│   │   ├── RecommendationEngine.swift # 穿搭推荐引擎
│   │   └── ColorMatchingService.swift # 配色服务
│   ├── Utils/
│   │   ├── Constants.swift     # 主题常量
│   │   └── Extensions.swift    # 扩展工具
│   └── Resources/
│       └── Assets.xcassets     # 资源文件
├── README.md
└── CHANGELOG.md
```

## 开发环境

- Xcode 16.0+
- macOS 15.0+
- XcodeGen（用于生成 .xcodeproj）

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/yuezhenchen-hue/wardrobe.git
cd wardrobe
```

### 2. 生成 Xcode 项目

```bash
# 安装 XcodeGen（如未安装）
brew install xcodegen

# 生成项目
xcodegen generate
```

### 3. 编译运行

```bash
# 命令行编译
xcodebuild -project Wardrobe.xcodeproj -scheme Wardrobe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# 或者直接用 Xcode 打开
open Wardrobe.xcodeproj
```

### 4. 模拟器运行

在 Xcode 中选择 iPhone 模拟器，点击运行即可。

## 后续优化计划

- [ ] Core Data 替代 UserDefaults 存储
- [ ] 接入真实天气 API（OpenWeather / 和风天气）
- [ ] 集成 AI 大模型进行更智能的穿搭推荐
- [ ] 社区功能：分享穿搭、浏览他人搭配
- [ ] 衣物识别：拍照自动识别衣物类型和颜色
- [ ] 虚拟试衣功能
- [ ] CloudKit 云同步
- [ ] Widget 小组件（今日穿搭推荐）
- [ ] Apple Watch 配套 App
- [ ] 多语言支持
- [ ] 购物平台对接（推荐购买链接）

## 许可证

MIT License
