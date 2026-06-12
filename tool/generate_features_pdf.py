#!/usr/bin/env python3
"""Generate Arabic promotional PDF for Emad Fawzy Pharmacy app features."""

from __future__ import annotations

import os
from pathlib import Path

import arabic_reshaper
from bidi.algorithm import get_display
from reportlab.lib import colors
from reportlab.lib.enums import TA_RIGHT, TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    HRFlowable,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "Emad_Fawzy_Pharmacy_Features.pdf"
FONT_PATH = Path(os.environ.get("WINDIR", r"C:\Windows")) / "Fonts" / "tahoma.ttf"
FONT_BOLD_PATH = Path(os.environ.get("WINDIR", r"C:\Windows")) / "Fonts" / "tahomabd.ttf"


def ar(text: str) -> str:
    if not text.strip():
        return text
    return get_display(arabic_reshaper.reshape(text))


def build_story():
    styles = getSampleStyleSheet()
    title = ParagraphStyle(
        "TitleAr",
        parent=styles["Title"],
        fontName="Tahoma",
        fontSize=22,
        leading=28,
        alignment=TA_CENTER,
        textColor=colors.HexColor("#006994"),
        spaceAfter=14,
    )
    subtitle = ParagraphStyle(
        "SubtitleAr",
        parent=styles["Normal"],
        fontName="Tahoma",
        fontSize=13,
        leading=20,
        alignment=TA_CENTER,
        textColor=colors.HexColor("#444444"),
        spaceAfter=20,
    )
    h1 = ParagraphStyle(
        "H1Ar",
        parent=styles["Heading1"],
        fontName="TahomaBold",
        fontSize=16,
        leading=24,
        alignment=TA_RIGHT,
        textColor=colors.HexColor("#006994"),
        spaceBefore=16,
        spaceAfter=8,
    )
    h2 = ParagraphStyle(
        "H2Ar",
        parent=styles["Heading2"],
        fontName="TahomaBold",
        fontSize=13,
        leading=20,
        alignment=TA_RIGHT,
        textColor=colors.HexColor("#008AC7"),
        spaceBefore=10,
        spaceAfter=6,
    )
    body = ParagraphStyle(
        "BodyAr",
        parent=styles["Normal"],
        fontName="Tahoma",
        fontSize=11,
        leading=18,
        alignment=TA_RIGHT,
        textColor=colors.HexColor("#222222"),
        spaceAfter=6,
    )
    bullet = ParagraphStyle(
        "BulletAr",
        parent=body,
        leftIndent=0,
        bulletIndent=12,
        spaceAfter=4,
    )
    quote = ParagraphStyle(
        "QuoteAr",
        parent=body,
        fontSize=12,
        leading=20,
        textColor=colors.HexColor("#006994"),
        backColor=colors.HexColor("#EAFBFF"),
        borderPadding=10,
        spaceBefore=12,
        spaceAfter=12,
    )

    story = []

    story.append(Paragraph(ar("Emad Fawzy Pharmacy"), title))
    story.append(
        Paragraph(
            ar("نظام إدارة صيدليات متكامل — من الشيفت إلى المرتب في تطبيق واحد"),
            subtitle,
        )
    )
    story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor("#006994")))
    story.append(Spacer(1, 0.4 * cm))

    story.append(Paragraph(ar("لماذا هذا النظام؟"), h1))
    story.append(
        Paragraph(
            ar(
                "لأن إدارة سلسلة صيدليات ليست مجرد مبيعات — بل ورديات، طلبات، تقارير، "
                "مرتبات، صيانة، مشتريات، وأهداف شهرية. يجمع التطبيق كل ذلك في منصة "
                "ذكية على الجوال، مربوطة بـ Firebase، مع صلاحيات حسب الدور وإشعارات فورية."
            ),
            body,
        )
    )

    story.append(Paragraph(ar("الأدوار والصلاحيات"), h1))
    roles_data = [
        [ar("الدور"), ar("الصلاحيات")],
        [ar("موظف (Staff)"), ar("تقارير شيفت، طلبات، صيانة، مرتب، لوحة تحكم")],
        [ar("نائب مدير"), ar("مشتريات الفرع + إدارة الطلبات (اختياري)")],
        [ar("مدير"), ar("موافقات، تقارير، إصلاحات، مرتبات، مستخدمين")],
        [ar("أدمن"), ar("كل صلاحيات المدير + رفع Excel للمرتبات والحوافز")],
    ]
    t = Table(roles_data, colWidths=[4.5 * cm, 12 * cm])
    t.setStyle(
        TableStyle(
            [
                ("FONTNAME", (0, 0), (-1, -1), "Tahoma"),
                ("FONTSIZE", (0, 0), (-1, -1), 10),
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#006994")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("ALIGN", (0, 0), (-1, -1), "RIGHT"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F6F8FF")]),
                ("TOPPADDING", (0, 0), (-1, -1), 8),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
            ]
        )
    )
    story.append(t)
    story.append(Spacer(1, 0.3 * cm))

    sections = [
        (
            "1. تسجيل الدخول والأمان",
            [
                "دخول آمن عبر البريد وكلمة المرور (Firebase Authentication).",
                "منع دخول الحسابات المعطّلة تلقائياً.",
                "تحديث إجباري للتطبيق عند وجود نسخة قديمة.",
                "اختيار الفرع للإدارة قبل العمليات اليومية.",
                "تبديل الفرع تلقائياً عند تغطية وردية معتمدة.",
            ],
        ),
        (
            "2. لوحة التحكم (Dashboard)",
            [
                "بطاقة الهوية: الاسم، الفرع، الصورة، الملف الشخصي.",
                "تحقيق الهدف الشهري: مبيعات مقابل التارجت + المشتريات للنائب.",
                "إحصائيات: رصيد الإجازات، الساعات الإضافية، الطلبات المعلقة.",
                "فرص العمل والتقديم من التطبيق.",
                "إنشاء ومتابعة الطلبات + سحب للتحديث.",
            ],
        ),
        (
            "3. نظام الطلبات — 6 أنواع",
            [
                "إجازة سنوية — اختيار فترة التاريخ.",
                "إجازة مرضية — رفع روشتة طبية إلزامياً.",
                "ساعات إضافية — تاريخ وعدد الساعات (1–12).",
                "تغطية وردية — فرع + موظف مع التحقق من الإجازات.",
                "نسيان بصمة — خلال آخر 30 يوماً.",
                "إذن انصراف مبكر — تاريخ + ساعات.",
                "للإدارة: قبول/رفض + إشعار فوري للموظف.",
            ],
        ),
        (
            "4. تقارير الشيفت",
            [
                "ورديات: ميدنايت، صباحي، ظهر، مسائي.",
                "مبيعات، مصروفات، عجز/زيادة كمبيوتر، دفع إلكتروني.",
                "تعديل التقارير من الإدارة مع إشعار.",
                "تقارير موحدة: يومي، شهري، مدى مخصص، أهداف الفروع.",
            ],
        ),
        (
            "5. الصيانة والإصلاحات",
            [
                "تسجيل عطل جهاز + ملاحظات من الفرع.",
                "مراجعة إصلاحات كل الفروع للإدارة.",
                "إشعار عند تقرير إصلاح جديد.",
            ],
        ),
        (
            "6. المرتبات والحوافز",
            [
                "عرض المرتب الشهري بتفاصيل كاملة للموظف.",
                "الحوافز الربع سنوية حسب الفترات.",
                "رفع مرتبات الشهر من Excel (أدمن).",
                "رفع الحوافز الربع سنوية من Excel (أدمن).",
                "إشعار: مرتب شهر [X] متاح.",
            ],
        ),
        (
            "7. البنك المركزي (Vault)",
            [
                "رصيد حي ومتابعة الحركات لكل الفروع.",
                "إيداعات: Dr Emad، مرحّل، أخرى.",
                "سحوبات: إيداع، مخزن، شركة، صيانة، أخرى.",
                "مرفقات للمعاملات + إشعار تحصيل الأرباح.",
            ],
        ),
        (
            "8. مشتريات الفرع",
            [
                "تسجيل مشتريات الفرع شهرياً (نائب المدير).",
                "رفع فواتير ومقارنة مع التارجت.",
                "ظهور نسبة المشتريات في لوحة التحكم.",
            ],
        ),
        (
            "9. أهداف الفروع",
            [
                "تارجت مبيعات شهري لكل فرع.",
                "متابعة التحقيق من اللوحة والتقارير.",
                "إدارة الأهداف من شاشة المستخدمين.",
            ],
        ),
        (
            "10. إدارة المستخدمين",
            [
                "إضافة وتعديل الموظفين والفروع والأدوار.",
                "صلاحية إدارة الطلبات لنائب المدير.",
                "تفعيل/تعطيل الحسابات والملف الشخصي.",
            ],
        ),
        (
            "11. فرص العمل",
            [
                "نشر وظائف شاغرة من الإدارة.",
                "تصفح والتقديم من لوحة التحكم.",
                "إشعار عند فرصة عمل جديدة.",
            ],
        ),
        (
            "12. الإشعارات الذكية",
            [
                "Firebase Cloud Messaging — إشعارات فورية.",
                "موظف: قرارات الطلبات + توفر المرتب.",
                "نائب مدير: تقارير شيفت في فرعه.",
                "مدير/أدمن: طلبات، تقارير، إصلاحات، أرباح.",
            ],
        ),
        (
            "13. تجربة الاستخدام",
            [
                "واجهة Material 3 بهوية الصيدلية.",
                "شريط تنقل زجاجي وانتقالات سلسة.",
                "دعم الويب مع بدائل مستقرة.",
            ],
        ),
    ]

    for heading, items in sections:
        story.append(Paragraph(ar(heading), h1))
        for item in items:
            story.append(Paragraph(ar(f"• {item}"), bullet))

    story.append(Spacer(1, 0.5 * cm))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#008AC7")))
    story.append(Spacer(1, 0.3 * cm))
    story.append(Paragraph(ar("الخلاصة"), h1))
    story.append(
        Paragraph(
            ar(
                "Emad Fawzy Pharmacy هو غرفة عمليات رقمية لسلسلة صيدليات: "
                "الطلبات تُرفع من الجوال، التقارير تُسجّل بعد كل شيفت، المرتبات تصل "
                "بإشعار، والإدارة ترى الصورة الكاملة لكل فرع — يومياً، شهرياً، وربع سنوياً."
            ),
            quote,
        )
    )
    story.append(Spacer(1, 0.5 * cm))
    story.append(
        Paragraph(
            ar(f"إصدار التطبيق: 1.1.2 | تم إنشاء هذا المستند تلقائياً"),
            ParagraphStyle(
                "Footer",
                parent=body,
                fontSize=9,
                alignment=TA_CENTER,
                textColor=colors.grey,
            ),
        )
    )
    return story


def main():
    if not FONT_PATH.exists():
        raise SystemExit(f"Font not found: {FONT_PATH}")

    OUT.parent.mkdir(parents=True, exist_ok=True)

    pdfmetrics.registerFont(TTFont("Tahoma", str(FONT_PATH)))
    if FONT_BOLD_PATH.exists():
        pdfmetrics.registerFont(TTFont("TahomaBold", str(FONT_BOLD_PATH)))
    else:
        pdfmetrics.registerFont(TTFont("TahomaBold", str(FONT_PATH)))

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        rightMargin=2 * cm,
        leftMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
        title="Emad Fawzy Pharmacy - Features",
        author="Emad Fawzy Pharmacy",
    )
    doc.build(build_story())
    print(f"PDF created: {OUT}")


if __name__ == "__main__":
    main()
