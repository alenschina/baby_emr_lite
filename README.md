# 幼儿病例记录（baby_emr_lite）

面向 iOS / Android 的 Flutter 应用，用于记录幼儿病例、用药、疫苗与生长发育数据。项目由既有 Web 版能力迁移而来，并在本仓库中持续迭代。

## 产品介绍

产品对外名称为 **「福宝健康」**：面向新生代家长的幼儿健康助手——记录生长发育、管理日常用药与疫苗、病历与数据本地加密保存，首页即可查看今日用药与接种提醒。

![福宝健康 - 产品界面与卖点介绍](docs/images/product-intro.jpg)

## 项目概述

- **平台**：Flutter（Material 3），主要目标为手机端。
- **数据**：本地 Hive 存储，写入前经 AES 加密；密钥保存在系统安全存储（Keychain / Keystore）。
- **架构**：分层结构（`core` / `domain` / `data` / `presentation`），状态管理使用 **Riverpod**，路由使用 **go_router**。

### 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 状态管理 | **flutter_riverpod**、riverpod_annotation | Provider 与可选代码生成 |
| 路由 | **go_router** | ShellRoute + 底部导航 |
| 本地存储 | **hive**、hive_flutter | 加密 Box 存业务 JSON |
| 安全存储 | **flutter_secure_storage** | 加密密钥 |
| 加密 | **encrypt** | AES 加解密备份与本地条目 |
| 本地通知 | **flutter_local_notifications** | 已在依赖中声明；**尚未在 Dart 侧接入系统级提醒** |
| 图表 | **fl_chart** | 生长曲线等 |
| 国际化/格式 | **intl** | 日期与时间展示 |
| 文件与分享 | **share_plus**、file_picker | 备份导出与导入 |
| 数据类 | **freezed**、json_serializable | 不可变实体与 JSON（需代码生成） |

## 目录结构

```
lib/
├── main.dart                 # 入口
├── app.dart                  # MaterialApp、主题与路由挂载
├── core/
│   ├── constants/            # 常量（备份版本、渠道 ID 等）
│   ├── theme/                # AppTheme、组件主题
│   ├── router/               # GoRouter 与路径常量
│   └── utils/                # 布局、BottomSheet 等工具
├── domain/
│   ├── entities/             # 业务实体与输入模型
│   ├── repositories/         # 仓储接口
│   ├── enums/                # 性别、用药频次、服药状态等
│   └── services/             # 领域服务（如用药时段计算）
├── data/
│   ├── datasources/          # Hive 加密存储
│   ├── repositories/         # 仓储实现
│   ├── encryption/           # 加解密服务
│   └── backup/               # 备份导入导出
└── presentation/
    ├── providers/            # Riverpod
    ├── screens/              # 各主页面
    ├── widgets/              # 通用与表单组件
    └── models/               # 界面层模型（如病例筛选）
```

资源与字体见 `pubspec.yaml`：`assets/images/` 默认头像、`assets/fonts/DouyinSansBold.ttf`（抖音美好体）、`flutter_launcher_icons` 配置的应用图标。

## 功能概览

1. **宝宝档案**  
   添加 / 编辑 / 删除；性别（小王子 / 小公主）；出生日期；当前选中宝宝切换。

2. **病例记录**  
   列表与表单；支持筛选（见 `medical_record_filter`）。

3. **用药**  
   - **用药方案**：药品信息、频次、剂量、每日时间点等（`MedicationPlan` 及相关实体）。  
   - **今日打卡**：对当日应服时段标记已服 / 漏服 / 跳过。  
   - **界面分区**：当前方案、历史与依从性概览等（`MedicationScreen`）。

4. **疫苗接种**  
   计划日期与完成状态；首页「今日提醒」可汇总当日相关项。

5. **生长发育**  
   生长数据录入与 **fl_chart** 曲线展示。

6. **数据管理**  
   加密备份导出（系统分享）、文件导入恢复；与当前应用使用同一套加密密钥方可解密。

7. **首页**  
   欢迎卡片、生长摘要、**应用内**「今日提醒」（用药 + 疫苗）；底部导航进入各模块。  
   **系统推送**：尚未实现，与 `flutter_local_notifications` 仅为预留依赖。

### UI 与品牌

- 主品牌色：**#6B5CE7**（见 `lib/core/theme/app_theme.dart`）。  
- 风格：浅色背景、玻璃拟态卡片、大圆角；标题字体使用 **DouyinSans**。

## 领域模型（实体）

| 实体 / 聚合 | 说明 |
|-------------|------|
| Baby | 宝宝档案 |
| MedicalRecord | 病例记录 |
| VaccinationRecord | 疫苗记录 |
| GrowthData | 生长发育测量 |
| MedicationPlan | 用药方案主表 |
| MedicationFrequency / MedicationDose / MedicationTime | 方案关联的频次、剂量、时间点 |
| MedicationIntakeStatus | 某方案在某日某时间点的服药打卡状态 |
| MedicationPlanAggregate 等 | 组合展示或写入用的输入模型 |

## 运行与构建

### 环境要求

- **Dart SDK**：以 `pubspec.yaml` 为准（当前为 `^3.11.4`）。  
- 安装与该 Dart 版本匹配的 **Flutter** 稳定版，并配置好 **Android Studio** / **Xcode**（真机或模拟器）。

### 依赖与代码生成

```bash
cd baby_emr_lite
flutter pub get
```

若克隆后编译提示缺少 `*.freezed.dart` / `*.g.dart` 等生成文件，执行：

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 运行与测试

```bash
flutter run
flutter run -d ios
flutter run -d android

flutter test
```

### 发布构建

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

## 备份与迁移

1. 在应用内「数据管理」导出备份（内容为 **整份 JSON 经应用加密后的字符串**，扩展名可能为 `.json`，实为密文）。  
2. 在另一台设备或重装后，使用「导入恢复」并选择同一备份文件（需能解密：同一套安全存储中的密钥逻辑；换机场景请遵循应用内说明与数据安全策略）。  
3. 若曾与 Web 版互通，以**当前应用实际支持的备份格式与版本**为准；`schemaVersion` 由 `AppConstants.backupSchemaVersion` 定义（当前为 **1**）。

解密后的逻辑结构示例（外层固定，内层 `payload` 为 Hive 中各业务键及其 `Map`，例如 `babies`、`medical_records`、`medication_plans` 等）：

```json
{
  "schemaVersion": 1,
  "exportedAt": "2026-04-09T10:30:00.000",
  "exportedFrom": "flutter",
  "payload": {
    "babies": { "list": [] },
    "medical_records": { "list": [] },
    "medication_plans": { "list": [] }
  }
}
```

实际键集合以 `lib/data/repositories/*_impl.dart` 中写入的 Hive 键为准。

## 后续工作（参考）

- [x] 工程与分层、本地加密存储  
- [x] 领域模型与主要页面（病例 / 用药方案与打卡 / 疫苗 / 生长 / 数据管理）  
- [x] 备份导入导出  
- [ ] **系统级本地通知**（依赖已加，业务未接入）  
- [ ] 性能与体验优化（启动、列表大数量等，按需排期）

## 注意事项

1. **首次启动**会在安全存储中生成加密密钥，请妥善保管设备与备份文件。  
2. **定期导出备份**，避免设备损坏或误删导致数据不可恢复。  
3. 若后续接入系统通知，需在 iOS / Android 配置权限与渠道，并向用户申请通知授权。

## 许可证

本仓库**公开源码**，但**不适用于商业用途**（例如：向第三方收费提供与本项目实质相同的产品或服务、将本项目作为商业产品的一部分对外分发等）。个人学习、研究、非营利与符合条件的机构使用等，以许可证正文为准。

