# 幼儿病例记录 - Flutter 版

基于 React Web 应用迁移的跨平台移动应用。

## 项目概述

本项目是将原有的 React + TypeScript + Vite Web 应用完整迁移到 Flutter 框架，支持 iOS 和 Android 双平台。

### 技术栈

| 层级 | 技术选型 | 说明 |
|------|----------|------|
| 状态管理 | **Riverpod** | 类型安全、可测试 |
| 路由 | **go_router** | 声明式路由 |
| 本地存储 | **Hive** | 轻量级 KV 存储 |
| 安全存储 | **flutter_secure_storage** | Keychain/Keystore |
| 加密 | **encrypt (AES-GCM)** | 标准加密算法 |
| 通知 | **flutter_local_notifications** | 本地提醒 |
| 图表 | **fl_chart** | 生长曲线 |
| 代码生成 | **freezed** | 不可变数据类 |

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 应用配置
├── core/                        # 核心基础设施
│   ├── constants/               # 常量定义
│   ├── theme/                   # 主题配置
│   ├── router/                  # 路由配置
│   └── utils/                   # 工具函数
├── domain/                      # 领域层
│   ├── entities/                # 业务实体 (7个核心模型)
│   ├── repositories/            # 仓库接口
│   └── enums/                   # 枚举定义
├── data/                        # 数据层
│   ├── datasources/             # 数据源 (Hive)
│   ├── repositories/            # 仓库实现
│   ├── encryption/              # 加密服务
│   └── backup/                  # 备份导入导出
├── presentation/                # 表现层
│   ├── providers/               # Riverpod Providers
│   ├── screens/                 # 页面
│   └── widgets/                 # 可复用组件
└── services/                    # 服务层
```

## 核心功能

### 已实现功能

1. **宝宝管理**
   - 添加/编辑/删除宝宝信息
   - 性别选择（小王子/小公主）
   - 出生日期设置
   - 当前宝宝切换

2. **数据安全**
   - AES-GCM 加密存储
   - 密钥安全存储于 Keychain/Keystore
   - 加密数据备份导出

3. **页面导航**
   - 首页（宝宝欢迎卡片、生长摘要、今日提醒）
   - 病例记录
   - 用药管理（Tab 切换：当前/历史/依从性）
   - 疫苗接种
   - 生长发育
   - 数据管理/备份

4. **UI 设计**
   - 对齐 Web 版设计风格
   - 品牌色：#5B5AF6
   - 圆角卡片设计
   - 底部导航栏

### 数据模型

| 实体 | 说明 |
|------|------|
| Baby | 宝宝基本信息 |
| MedicalRecord | 病例记录 |
| VaccinationRecord | 疫苗接种记录 |
| GrowthData | 生长发育数据 |
| MedicationRecord | 用药记录 |
| MedicationStatus | 用药状态（已服/漏服/跳过）|
| MedicationReminder | 用药提醒 |

## 运行项目

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode

### 安装依赖

```bash
cd baby_emr_lite
flutter pub get
```

### 运行应用

```bash
# 调试模式
flutter run

# 指定设备
flutter run -d ios
flutter run -d android
```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 数据迁移

### Web → Flutter 迁移

1. 在 Web 版导出备份文件
2. 在 Flutter 版使用"导入恢复"功能
3. 备份格式兼容，数据自动解密导入

### 备份文件格式

```json
{
  "schemaVersion": 1,
  "exportedAt": "2024-01-15T10:30:00Z",
  "exportedFrom": "flutter",
  "payload": {
    "babies": [...],
    "medicalRecords": [...],
    "medications": [...],
    ...
  }
}
```

## 开发计划

- [x] Phase 1: 工程搭建
- [x] Phase 2: 数据层与领域模型
- [x] Phase 3: 页面迁移
- [ ] Phase 4: 本地通知提醒
- [x] Phase 5: 备份导入导出
- [ ] Phase 6: 性能优化

## 注意事项

1. **首次运行**：应用首次启动时会生成加密密钥，请确保设备安全
2. **数据备份**：建议定期导出备份，防止数据丢失
3. **权限申请**：通知功能需要用户授权

## 许可证

本项目为私有项目，未经授权不得使用。
