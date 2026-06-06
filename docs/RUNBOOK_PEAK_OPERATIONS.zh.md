# 高峰运营应急手册（单页）

> **打开 PDF：** 在资源管理器中双击 [`RUNBOOK_PEAK_OPERATIONS.zh.pdf`](RUNBOOK_PEAK_OPERATIONS.zh.pdf)（与本文件同目录）。Cursor 内可能无法预览 PDF；勿用桌面副本 `tfg_vday-runbook-zh.pdf` 从 IDE 打开。

情人节高峰期间 **值班 / 一线店员** 快速处理指引。  
应用：TFG VDAY · Firebase `tfg-sales-record` · 完整流程见 [WORKFLOW.md](WORKFLOW.md)

---

## 1. 断网 / 应用一直加载

| 步骤 | 责任人 | 操作 |
|------|--------|------|
| 1 | 任何人 | 确认 Wi‑Fi/移动数据；关闭飞行模式，**重新打开 App**。 |
| 2 | 店员 | 换设备：用手机热点，或另一台手机/平板 **同角色登录**。 |
| 3 | 店员 | 仅 Web 失败时：改用 **Android App**（蓝牙打印也需真机）。 |
| 4 | 负责人 | 查看 [Firebase 状态](https://status.firebase.google.com/) — 若 Google 故障：**暂停新单**，纸上记录。 |
| 5 | 店员 | 每位顾客点一次 **创建订单** — 若断网，App **排队**（提示 *"Order queued (N pending)"*），继续纸上接单。 |
| 6 | 负责人 | 恢复后 App **自动同步** 队列（Android/iOS）。在 **订单列表** 核对；纸上-only 订单须手动补录。**勿复用**纸单单号。 |
| 7 | 负责人 | 恢复后从 **销售报表** 导出 **CSV** 对账。 |

**禁止：** 未经技术负责人同意，在 Console 删除 Firestore 订单。

---

## 2. 订单号重复或错误

| 现象 | 可能原因 | 处理步骤 |
|------|----------|----------|
| 两笔订单 **相同 `TFG-…` / `TFG-WI…`** | 极少见并发或 Console 手改 | 1. 在 **订单列表** 记下两笔文档 ID。<br>2. 高峰期 **勿** 在 Console 改 `counter/`。<br>3. 联系技术：`npm run verify:peak`（每家公司计数器文档须存在）。<br>4. 给顾客单据：在 **订单列表 → 打开正确订单** → 重打；以 **该屏** 单号为准。 |
| 单号 **跳号**（如 0005 后直接 0007） | 中途交易失败 | 两笔订单都在则可 **忽略**；序号只增不减。 |
| **零售** 显示 `TFG-YYYY-####` 应为 `TFG-WI####` | 误走配送分支 | 按店规作废；新建订单 → 选品页点 **Retail（零售）** → 重新付款。 |
| `init:counters` 后计数器归零 | 脚本重跑 | 仅 **旺季前** 预期；旺季中发生 **立即联系技术**。 |

**预防：** 每位顾客只由一人点 **创建订单**；进入选品页后再操作。

**技术复核（旺季后）：**

```bash
cd firebase
set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\serviceAccount.json
npm run verify:peak
```

报告中每家公司 `counters.rows` 须 delivery 与 retail 计数器文档均存在（`ready: true`）。两通道序号独立，数值可以不同。

---

## 3. 司机登错账号 / 界面不对

| 现象 | 处理步骤 |
|------|----------|
| 司机看到 **销售仪表盘** | `users/{uid}` 角色错误 → **退出** → 技术执行 `npm run set:user-role --role driver`，或管理员 **注册** 选 Driver。 |
| 司机列表 **为空** | 1. 确认状态：`processing` / `ready_to_delivery` / `out_of_delivery`（司机页芯片）。<br>2. 订单与司机 **同一公司**（superadmin 建测试单前须选公司）。<br>3. 店员：**订单列表** → 打开订单 → 推到 `ready_to_delivery`。 |
| 司机用了 **店员邮箱** | 退出；改用仅司机账号（无仪表盘菜单）。 |
| 店员用 **司机手机** 建单 | 司机退出 → 店员登录 → 在仪表盘继续。 |

**验收：** 司机登录后仅进入 **我的配送**（无法打开 `/salesDashBoard`，App 已拦截）。

**内部测试账号：** 见 WORKFLOW §17 — 使用专用司机邮箱，勿用管理员账号。

---

## 升级联系

| 问题 | 联系人 | 命令 / 文档 |
|------|--------|-------------|
| 规则 / 权限拒绝 | 技术负责人 | 先 `npm run deploy:rules:staging`，再 `deploy:rules:production` · [STAGING.md](STAGING.md) |
| 崩溃 / 建单慢 | 技术负责人 | Firebase **Crashlytics** + **Performance** · [OBSERVABILITY.md](OBSERVABILITY.md) |
| 计数器 / 用户 | 技术负责人 | `npm run init:counters:dry-run` · `npm run fix:user-ids:dry-run` |
| 完整测试记录 | QA | [SMOKE_TEST_LOG.md](SMOKE_TEST_LOG.md) |

*更新日期：2026-06-05*
