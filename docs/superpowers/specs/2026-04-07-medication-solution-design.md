# 用药 Solution（方案 C）设计文档

日期：2026-04-07  
范围：重新定义用药计划的数据模型、打卡模型、提醒模型（可选）、存储形状与仓库 API。  
约束：当前无生产数据；药品图片保持原有逻辑不改；用药计划编辑页只需要输入药品名称。  

---

## 目标

- 支持“用药计划编辑页”形态：
  - 只输入药品名称（药品图片不改）
  - 用药频率（可选）：每天 / 每几天 / 每几周
  - 用药时间点可添加多个
  - 每日次数与时间点数量强关联（次数为派生数据，不单独存）
  - 每次剂量：多少片/多少颗（amount + unit）
  - 服用周期：起始日期到结束日期（结束日期可空=进行中）
- 支持依从性：按“时间点”打卡（一天多个时间点=需要多次打卡）
- 支持编辑“原子更新”：一次提交同时更新药名/频率/时间点/剂量/周期/备注
- 计划变更立即生效：从“今天”起使用新规则生成应服用槽位

非目标（本期不做）：
- 引入复杂的“变更生效日期”策略
- 持久化存储所有“应服用事件”（槽位）；优先按需计算

---

## 核心概念

- **计划（Plan）**：描述一段周期内，某种药应该如何服用（频率 + 一天内时间点 + 剂量）。
- **时间点（Time）**：一天内的一个服药时间点（例如 10:00）。
- **槽位（Slot，派生）**：某一天某个时间点的“应服用一次”的抽象，唯一键为 `(planId, scheduledDate, timeId)`。
- **打卡（IntakeStatus）**：对某个槽位的实际记录（taken/missed/skipped）。

---

## 数据模型

### 1) MedicationPlan（计划主表）

一条 `MedicationPlan` 代表“一种药的一个用药周期计划”。

字段：
- `id: String`
- `babyId: String`
- `medicationName: String`（仅输入药名）
- `startDate: DateTime`（日期语义）
- `endDate: DateTime?`（可空=进行中）
- `notes: String?`
- `createdAt: DateTime`
- `updatedAt: DateTime`

约束：
- `medicationName`：`trim` 后非空；建议长度 ≤ 50
- `endDate == null || endDate >= startDate`

派生：
- `isActive` 可由 `endDate == null || endDate >= today` 派生（是否额外落库由实现决定）

---

### 2) MedicationFrequency（频率，1:1 归属 Plan）

字段：
- `planId: String`
- `type: MedicationFrequencyType`
  - `none | daily | every_n_days | every_n_weeks`
- `interval: int?`

约束：
- `type == none` → `interval == null`
- `type == daily` → `interval == null`（或固定为 1，但不建议存）
- `type in {every_n_days, every_n_weeks}` → `interval != null && interval >= 1`
  - UI 侧可将“每几天/每几周”的最小值限制为 2，以避免语义歧义

---

### 3) MedicationTime（时间点，1:N 归属 Plan）

字段：
- `id: String`
- `planId: String`
- `timeOfDay: String`（严格 `"HH:mm"`）
- `isEnabled: bool`（默认 `true`）
- `createdAt: DateTime`

约束：
- 同一 `planId` 下 `timeOfDay` 唯一（去重）
- 展示顺序按 `timeOfDay` 升序（建议读取时排序）

派生：
- **每日次数**：`enabledTimes.length`（不落库）

---

### 4) MedicationDose（剂量，1:1 归属 Plan）

字段：
- `planId: String`
- `amount: num`（支持 `0.5` 等小数）
- `unit: String`（例如：片/颗/袋/ml 等，先用字符串）

约束：
- `amount > 0`
- `unit.trim()` 非空

---

### 5) MedicationIntakeStatus（按时间点打卡）

字段：
- `id: String`
- `planId: String`
- `scheduledDate: DateTime`（日期语义）
- `timeId: String`（指向 `MedicationTime.id`）
- `status: MedicationIntakeStatusType`
  - `taken | missed | skipped`
- `recordedAt: DateTime`
- `notes: String?`
- `stockDelta: num?`（可选，taken 时可为 `-dose.amount`）

约束：
- 唯一键建议：`(planId, scheduledDate, timeId)`
  - 同一槽位只能有一个最终状态；更改状态应更新同一条记录

---

## Reminders（提醒）模型（可选）

若需要到点提醒，建议提醒与时间点 1:1：

### MedicationTimeReminder
- `id: String`
- `timeId: String`（指向 `MedicationTime.id`）
- `isEnabled: bool`
- `createdAt: DateTime`

说明：
- 先做“时间点级别开关”即可；未来若需要“计划级别总开关”，可再引入 `planId + timeId?` 的模型。

---

## 槽位（应服用事件）生成规则（不落库）

输入：某个 `MedicationPlan` 的聚合数据（plan + frequency + times + dose）。

步骤：
1. 确定生效日期区间：`[startDate, endDate ?? today]`
2. 根据 `MedicationFrequency` 计算“发生日集合”：
   - `none`：发生日集合为空（不生成槽位）
   - `daily`：区间内每天都是发生日
   - `every_n_days`：从 `startDate` 起按 `interval` 天步进
   - `every_n_weeks`：从 `startDate` 起按 `interval * 7` 天步进
3. 对每个发生日，展开为所有 `isEnabled == true` 的 `MedicationTime`
4. 每个槽位唯一键：`(planId, scheduledDate, timeId)`
5. 用唯一键匹配 `MedicationIntakeStatus`，得到该槽位已打卡状态或未打卡

备注：
- `scheduledDate` 建议规范化到“当天 00:00”的本地日期，避免时区漂移造成的比较问题（实现细节）。

---

## 编辑页提交 Payload（统一 Upsert）

编辑页以“最终态集合”提交，简化增删改：

### MedicationPlanUpsertInput
- `planId?: String`（新建为空；编辑有值）
- `babyId: String`
- `medicationName: String`
- `startDate: DateTime`
- `endDate?: DateTime?`
- `notes?: String?`
- `frequency`：
  - `type: none | daily | every_n_days | every_n_weeks`
  - `interval?: int?`
- `dose`：
  - `amount: num`
  - `unit: String`
- `times: List<String>`（`"HH:mm"`；允许空；建议前端先去重排序）

原则：
- `times` 表示“最终集合”，不是增量 patch。

---

## Repository API（建议形状）

为了“原子更新”，提供一个聚合级接口：

- `createOrUpdatePlanWithDetails(input: MedicationPlanUpsertInput) -> MedicationPlanAggregate`
  - 内部逻辑：
    - upsert `MedicationPlan`
    - upsert `MedicationFrequency`（按 `planId` 覆盖）
    - upsert `MedicationDose`（按 `planId` 覆盖）
    - 同步 `MedicationTime` 集合：
      - 读取现有 times（按 `planId`）
      - 删除不在新集合中的 times（并级联删除提醒，如启用）
      - 新增新集合中不存在的 times（为每个 timeOfDay 创建新 id）

查询：
- `getPlanAggregate(planId) -> MedicationPlanAggregate`
- `listPlanAggregatesByBaby(babyId, {activeOnly?}) -> List<MedicationPlanAggregate>`

删除：
- `deletePlan(planId)`：级联删除 frequency/dose/times/intakeStatuses/reminders

### MedicationPlanAggregate
- `plan: MedicationPlan`
- `frequency: MedicationFrequency`
- `dose: MedicationDose`
- `times: List<MedicationTime>`（按 `timeOfDay` 排序）

---

## 计划变更与打卡数据的处理规则（立即生效）

关键原则：**打卡是事实记录；计划是生成规则；计划变更不篡改事实。**

规则：
1. **不删除历史**：任何已存在的 `MedicationIntakeStatus` 不自动删除。
2. **时间点变更**：
   - 新增 time：从今天起会生成新的槽位；历史不受影响。
   - 删除 time：未来不再生成该 time 槽位；历史状态仍保留（可在 UI 历史里展示，或在默认视图隐藏）。
3. **周期变更**：
   - 缩短周期：周期外未来槽位不再生成；周期外历史状态仍保留。
4. **频率变更**：
   - 影响从今天起的槽位生成；不回溯改写历史。

立即生效定义：
- 计划编辑保存后，槽位生成逻辑从“今天（含）”起使用新规则。

---

## 存储形状（Hive/JSON 建议）

延续现有模式：每类实体一个 storage key，值形如 `{ list: [...] }`：

- `medication_plans`
- `medication_frequencies`
- `medication_times`
- `medication_doses`
- `medication_intake_statuses`
- （可选）`medication_time_reminders`

---

## 开放问题（后续实现阶段再定）

- `interval` 的 UI 最小值：`>=1` 还是 `>=2`
- `scheduledDate` 的日期规范化策略（本地 00:00 vs UTC）
- `stockDelta` 的计算口径：taken 是否一定扣减、missed/skipped 是否影响库存

