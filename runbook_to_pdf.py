#!/usr/bin/env python3
"""Generate Chinese runbook PDF (RUNBOOK_PEAK_OPERATIONS.zh.pdf)."""

from pathlib import Path

try:
    from fpdf import FPDF
except ImportError:
    raise SystemExit("Install: pip install fpdf2")

DOCS = Path(__file__).resolve().parents[1]
OUT_PDF = DOCS / "RUNBOOK_PEAK_OPERATIONS.zh.pdf"
FONT_REGULAR = Path(r"C:\Windows\Fonts\msyh.ttc")
FONT_BOLD = Path(r"C:\Windows\Fonts\msyhbd.ttc")


class RunbookPDF(FPDF):
    def footer(self):
        self.set_y(-12)
        self.set_font("YaHei", size=8)
        self.set_text_color(120, 120, 120)
        self.cell(0, 8, f"TFG VDAY - 高峰运营应急手册 - 第 {self.page_no()} 页", align="C")


def sanitize(text: str) -> str:
    return (
        text.replace("\u2011", "-")
        .replace("\u2013", "-")
        .replace("\u2014", "-")
        .replace("\u00b7", "-")
        .replace("\u2192", "->")
        .replace("\u2026", "...")
    )


def add_section(pdf: RunbookPDF, title_zh: str, body_lines: list[str]):
    w = pdf.epw
    pdf.set_font("YaHeiB", size=12)
    pdf.set_text_color(20, 60, 120)
    pdf.multi_cell(w, 8, sanitize(title_zh))
    pdf.ln(2)
    pdf.set_font("YaHei", size=9)
    pdf.set_text_color(30, 30, 30)
    for line in body_lines:
        pdf.set_x(pdf.l_margin)
        pdf.multi_cell(w, 5, sanitize(line))
    pdf.ln(4)


def main():
    if not FONT_REGULAR.exists():
        raise SystemExit(f"Font not found: {FONT_REGULAR}")

    pdf = RunbookPDF(orientation="P", unit="mm", format="A4")
    pdf.set_margins(18, 18, 18)
    pdf.set_auto_page_break(auto=True, margin=18)
    pdf.add_page()

    pdf.add_font("YaHei", "", str(FONT_REGULAR))
    pdf.add_font("YaHeiB", "", str(FONT_BOLD if FONT_BOLD.exists() else FONT_REGULAR))

    w = pdf.epw
    pdf.set_font("YaHeiB", size=18)
    pdf.set_text_color(0, 0, 0)
    pdf.multi_cell(w, 10, "高峰运营应急手册（单页）")
    pdf.ln(2)
    pdf.set_font("YaHei", size=10)
    pdf.set_text_color(60, 60, 60)
    pdf.multi_cell(
        w,
        6,
        sanitize(
            "情人节高峰 - 值班/一线店员快速处理指引\n"
            "应用: TFG VDAY | Firebase tfg-sales-record"
        ),
    )
    pdf.ln(6)

    add_section(
        pdf,
        "1. 断网 / 应用一直加载",
        [
            "1. 任何人 - 确认 Wi-Fi/移动数据; 关飞行模式, 重开 App.",
            "2. 店员 - 换手机热点或另一设备, 同角色登录.",
            "3. 店员 - 仅 Web 失败: 用 Android App (蓝牙打印需真机).",
            "4. 负责人 - 查 Firebase 状态; Google 故障则暂停新单、纸上记录.",
            "5. 负责人 - 恢复后新建订单(新 ID), 勿复用已打印单号.",
            "6. 负责人 - 从销售报表导出 CSV 对账.",
            "禁止: 未经技术负责人在 Console 删除 Firestore 订单.",
        ],
    )

    add_section(
        pdf,
        "2. 订单号重复或错误",
        [
            "[相同 TFG-/TFG-WI- 两笔单]",
            "  - 订单列表记下两笔文档 ID; 高峰勿改 counter/.",
            "  - 联系技术: npm run verify:peak; 在正确订单屏重打.",
            "[跳号 如 0005->0007] 两笔都在则可忽略.",
            "[零售误为 YYYY 格式] 按店规作废, 新建并点 Retail 分支.",
            "[旺季中计数器归零] 立即联系技术.",
            "预防: 每客一人点创建订单, 等进入选品页.",
            "旺季后: cd firebase + verify:peak, 每公司 delivery=retail.",
        ],
    )

    add_section(
        pdf,
        "3. 司机登错账号 / 界面不对",
        [
            "[看到销售仪表盘] 退出; 改 role=driver 或管理员注册 Driver.",
            "[配送列表为空] 查状态芯片 processing/ready_to_delivery/out_of_delivery;",
            "  订单须同公司; 店员推到 ready_to_delivery.",
            "[司机用店员邮箱] 退出, 仅用司机账号.",
            "[店员用司机手机] 司机退出, 店员登录仪表盘.",
            "验收: 登录后仅「我的配送」, 不能进 /salesDashBoard.",
            "内部测试: WORKFLOW 17 - 专用司机邮箱.",
        ],
    )

    add_section(
        pdf,
        "升级联系",
        [
            "规则/权限拒绝 -> 技术: firebase deploy --only firestore:rules",
            "计数器/用户 -> 技术: init:counters:dry-run, fix:user-ids:dry-run",
            "完整测试 -> QA: SMOKE_TEST_LOG.md",
        ],
    )

    pdf.set_font("YaHei", size=8)
    pdf.set_text_color(120, 120, 120)
    pdf.cell(0, 8, "更新日期: 2026-06-03", align="R")

    pdf.output(str(OUT_PDF))
    print(f"Wrote {OUT_PDF}")


if __name__ == "__main__":
    main()
