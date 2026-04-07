# Medication Solution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 `docs/superpowers/specs/2026-04-07-medication-solution-design.md` 重新实现用药 Solution（方案 C）：计划/频率/时间点/剂量/按时间点打卡，编辑页原子更新，计划变更立即生效，图片逻辑保持不改。

**Architecture:** 以“聚合根 + 子实体 + 槽位按需计算”为核心。存储仍使用 Hive 加密盒（`HiveStorage`），按实体分 key 存 list；UI 层通过 `MedicationPlanAggregate` 驱动列表、编辑、提醒与依从性统计。

**Tech Stack:** Flutter + Riverpod + Hive(加密 JSON) + freezed/json_serializable

---

## Scope Check

本计划聚焦用药域的全量重构（数据模型 + 存储 + providers + UI）。不包含推送/系统通知等平台集成；提醒只做数据层开关/绑定，UI 先能展示与打卡统计即可。

---

## File Structure（将新增/修改的文件）

**Create (domain/entities):**
- `lib/domain/entities/medication_plan.dart`
- `lib/domain/entities/medication_frequency.dart`
- `lib/domain/entities/medication_time.dart`
- `lib/domain/entities/medication_dose.dart`
- `lib/domain/entities/medication_intake_status.dart`
- `lib/domain/enums/medication_frequency_type.dart`
- `lib/domain/enums/medication_intake_status_type.dart`
- `lib/domain/entities/medication_plan_aggregate.dart`

**Create (domain/repositories):**
- `lib/domain/repositories/medication_plan_repository.dart`
- `lib/domain/repositories/medication_intake_status_repository.dart`

**Create (data/repositories):**
- `lib/data/repositories/medication_plan_repository_impl.dart`
- `lib/data/repositories/medication_intake_status_repository_impl.dart`

**Create (domain/services):**
- `lib/domain/services/medication_slot_service.dart`（计算槽位/发生日/依从性）

**Modify (presentation/providers):**
- `lib/presentation/providers/medication_providers.dart`（切到新聚合/新打卡）

**Modify / Replace (presentation/widgets/forms):**
- 修改现有：`lib/presentation/widgets/forms/medication_record_form.dart`
  - 重命名/替换为新的计划编辑表单（仍可复用样式与 bottom sheet 外壳）

**Modify (presentation/screens):**
- `lib/presentation/screens/medication_screen.dart`（列表/统计接新聚合）

**Modify (presentation/widgets):**
- `lib/presentation/widgets/today_reminders_section.dart`（今日提醒基于“今日槽位-未打卡”）

**Tests:**
- `test/medication/medication_slot_service_test.dart`
- `test/medication/medication_plan_repository_impl_test.dart`（可选，若 hive 测试成本高则先不做）

---

### Task 1: 新 enums 与实体（freezed/json）

**Files:**
- Create: `lib/domain/enums/medication_frequency_type.dart`
- Create: `lib/domain/enums/medication_intake_status_type.dart`
- Create: `lib/domain/entities/medication_plan.dart`
- Create: `lib/domain/entities/medication_frequency.dart`
- Create: `lib/domain/entities/medication_time.dart`
- Create: `lib/domain/entities/medication_dose.dart`
- Create: `lib/domain/entities/medication_intake_status.dart`
- Create: `lib/domain/entities/medication_plan_aggregate.dart`

- [ ] **Step 1: 写一个会失败的单测（先定义我们需要的 JSON 形状）**

```dart
// test/medication/medication_slot_service_test.dart (先占位；Task 3 会补齐)
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder - will fail until entities exist', () {
    // ignore: unnecessary_null_comparison
    expect(null, isNotNull);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/medication/medication_slot_service_test.dart -r expanded`  
Expected: FAIL

- [ ] **Step 3: 创建 enums 与 entities（freezed + fromJson/toJson）**

实现要点：
- `MedicationPlan` 字段按 spec
- `MedicationFrequency`（1:1 归属 plan，用 `planId` 作为外键）
- `MedicationTime.timeOfDay` 固定 `"HH:mm"`
- `MedicationIntakeStatus` 唯一键由 repo 保证（后续 Task）
- `MedicationPlanAggregate`：`plan/frequency/dose/times`

- [ ] **Step 4: 运行 build_runner（生成 freezed/g.dart）**

Run: `dart run build_runner build --delete-conflicting-outputs`  
Expected: 成功生成对应 `*.freezed.dart` / `*.g.dart`

- [ ] **Step 5: 修复占位失败测试（让它通过）**

将 Task 1 的占位测试删掉或改成断言 `toJson/fromJson` roundtrip。

- [ ] **Step 6: 运行测试确认通过**

Run: `flutter test test/medication/medication_slot_service_test.dart -r expanded`  
Expected: PASS

---

### Task 2: Plan 聚合 Upsert Repository（Hive 分 key 存储）

**Files:**
- Create: `lib/domain/repositories/medication_plan_repository.dart`
- Create: `lib/data/repositories/medication_plan_repository_impl.dart`
- Modify (wiring): `lib/presentation/providers/core_providers.dart`（若需要新增 provider）

- [ ] **Step 1: 写一个会失败的仓库单测（只测纯逻辑，不依赖真 Hive 也行）**

策略：
- 如果现有 `HiveStorage` 无法轻易 mock，可先写“差集同步算法”的纯函数测试（输入旧 times 与新 times，输出 add/remove）。

- [ ] **Step 2: 实现 `MedicationPlanRepository` 接口**

建议接口：
- `Future<MedicationPlanAggregate> upsertWithDetails(MedicationPlanUpsertInput input)`
- `Future<MedicationPlanAggregate?> getAggregateById(String planId)`
- `Future<List<MedicationPlanAggregate>> listAggregatesByBabyId(String babyId)`
- `Future<void> deletePlan(String planId)`

存储 key（按 spec）：
- `medication_plans`
- `medication_frequencies`
- `medication_times`
- `medication_doses`

同步 `times` 的规则：
- input.times 是最终集合
- 旧 times（按 planId）与新 times（timeOfDay）做差集
- 删除被移除的 time（并在未来 Task 里级联删除 time reminders / intake statuses（可选））

- [ ] **Step 3: 运行相关测试并修复**

Run: `flutter test test/medication -r expanded`  
Expected: PASS

---

### Task 3: 槽位生成与依从性计算服务（不落库）

**Files:**
- Create: `lib/domain/services/medication_slot_service.dart`
- Test: `test/medication/medication_slot_service_test.dart`

- [ ] **Step 1: 写失败测试（频率 + times → 槽位数量）**

覆盖：
- daily + 2 times + 3 天区间 → 6 槽位
- every_n_days(interval=2) → 发生日步进正确
- none → 0 槽位
- endDate=null → 截止到 today（测试里注入“today”参数）

- [ ] **Step 2: 实现 `MedicationSlotService`**

建议函数：
- `List<DateTime> computeOccurrenceDates({required DateTime start, required DateTime endInclusive, required MedicationFrequency frequency})`
- `List<MedicationSlot> computeSlots({required MedicationPlanAggregate agg, required DateTime today})`
- `MedicationCompliance computeCompliance({required List<MedicationSlot> slots, required List<MedicationIntakeStatus> statuses})`

其中 `MedicationSlot` 可为轻量 value object（不落库）：
- `planId`
- `scheduledDate`（日期）
- `timeId`
- `timeOfDay`

- [ ] **Step 3: 跑测试确认通过**

Run: `flutter test test/medication/medication_slot_service_test.dart -r expanded`  
Expected: PASS

---

### Task 4: IntakeStatus Repository（按时间点打卡唯一键）

**Files:**
- Create: `lib/domain/repositories/medication_intake_status_repository.dart`
- Create: `lib/data/repositories/medication_intake_status_repository_impl.dart`

- [ ] **Step 1: 写失败测试（同一槽位 upsert 覆盖而不是新增）**

唯一键：`(planId, scheduledDate, timeId)`

- [ ] **Step 2: 实现仓库**

建议接口：
- `Future<List<MedicationIntakeStatus>> listByPlanId(String planId)`
- `Future<MedicationIntakeStatus> upsertForSlot({required String planId, required DateTime scheduledDate, required String timeId, required MedicationIntakeStatusType status, String? notes, num? stockDelta})`
- `Future<void> deleteByPlanId(String planId)`

存储 key：
- `medication_intake_statuses`

- [ ] **Step 3: 跑测试确认通过**

Run: `flutter test test/medication -r expanded`  
Expected: PASS

---

### Task 5: Providers 重构（新聚合 + 今日提醒 + 依从性）

**Files:**
- Modify: `lib/presentation/providers/medication_providers.dart`

- [ ] **Step 1: 写失败测试（可选；若无 provider 测试基础则跳过）**

- [ ] **Step 2: 引入新的 providers**

替换点：
- `medicationRecordsProvider/activeMedicationsProvider/...` → 变为 `MedicationPlanAggregate` 列表
- `todayMedicationRemindersProvider` → 基于“今日槽位 - 未打卡”生成多条提醒（同一计划可多条）
- `medicationComplianceProvider` → 基于 slots + intake statuses 计算（不再用旧 `MedicationStatus`）

立即生效：
- 任何 plan 更新后，today reminders 与 compliance 要自动刷新（可继续沿用 listen/notifier 触发 reload）

---

### Task 6: 编辑页表单（按 spec 的字段与交互）

**Files:**
- Modify: `lib/presentation/widgets/forms/medication_record_form.dart`

- [ ] **Step 1: 将表单字段调整为**
- 药品名称：TextField
- 用药频率：选择器（none/daily/every_n_days/every_n_weeks + interval 输入）
- 用药时间：可添加多个时间点（TimePicker），支持删除
- 每次剂量：amount + unit（unit 默认 `AppConstants.defaultMedicationUnit`）
- 服用周期：startDate/endDate（endDate 可清除）
- 备注：可选

- [ ] **Step 2: 提交逻辑改为调用 `MedicationPlanRepository.upsertWithDetails`（经 notifier/provider 封装）**

- [ ] **Step 3: 回填逻辑：编辑时从 aggregate 填充上述字段**

- [ ] **Step 4: 自测**
- 新建：daily + 2 times + dose + start/end
- 编辑：删除一个 time、改频率、清除 endDate

---

### Task 7: 用药列表与统计页接新模型

**Files:**
- Modify: `lib/presentation/screens/medication_screen.dart`
- Modify: `lib/presentation/widgets/forms/medication_record_form.dart`（卡片 UI 如需同步）

- [ ] **Step 1: 列表页改用 aggregate 渲染**
- 标题仍用 `plan.medicationName`
- 显示：dose（amount+unit）、frequency（格式化文案）、times（可显示“10:00,20:00”或“2次/天”）
- 日期范围：start - (end ?? 进行中)

- [ ] **Step 2: 依从性统计改用 slots + intake statuses**
- 总体依从性：所有 active plans 的平均或加权（按槽位数加权更合理）

---

### Task 8: 今日提醒区接新“今日槽位”

**Files:**
- Modify: `lib/presentation/widgets/today_reminders_section.dart`

- [ ] **Step 1: `TodayMedicationReminder` 结构调整**
- 需要包含：`planId`, `medicationName`, `doseText`, `timeOfDay`, `timeId`, `scheduledDate`

- [ ] **Step 2: 点击提醒进入用药页（保持现有行为）**

---

### Task 9: 清理旧用药模型（可选分阶段）

**Files:**
- 保留旧 `MedicationRecord/MedicationStatus/MedicationReminder` 一段时间也可以（避免一次性大爆炸）

- [ ] **Step 1: 将路由/页面完全切到新模型后，再删除旧代码**
- [ ] **Step 2: 确保无未使用 import、build_runner 输出干净**

---

## Verification Checklist（每个任务完成后）

- `dart format .`
- `dart analyze`
- `flutter test`

