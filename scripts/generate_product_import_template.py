#!/usr/bin/env python3
"""Generate TFG import templates (.xlsx + .csv) on the user's Desktop."""

from __future__ import annotations

import csv
import zipfile
from pathlib import Path

DESKTOP = Path.home() / "Desktop"

PRODUCT_HEADERS = ["Name", "SKU", "Price", "Category", "Active", "Image"]
PRODUCT_ROWS = [
    ["Rose Bouquet", "RB-01", "88.50", "Hand Bouquet", "yes", ""],
    ["Wreath Classic", "WR-02", "120", "Wreath", "yes", ""],
    ["Opening Stand Deluxe", "OS-03", "250", "Opening Stand", "yes", ""],
    ["Table Arrangement", "", "65", "Table arrangement", "yes", ""],
]

CUSTOMER_HEADERS = [
    "Name",
    "Phone",
    "Billing address",
    "UEN",
    "Credit customer",
    "Credit term",
]
CUSTOMER_ROWS = [
    ["Alice Tan", "91234567", "123 Orchard Road #01-01", "201912345A", "yes", "30"],
    ["Bob Lee Florist", "81234567", "45 Jurong West St 42", "", "no", ""],
    ["Corporate Gifts Pte Ltd", "62345678", "1 Marina Blvd", "201888888A", "yes", "COD"],
]


def write_csv(path: Path, headers: list[str], rows: list[list[str]]) -> None:
    with path.open("w", newline="", encoding="utf-8-sig") as handle:
        writer = csv.writer(handle)
        writer.writerow(headers)
        writer.writerows(rows)


def _shared_strings_xml(values: list[str]) -> str:
    items = "".join(f"<si><t>{_escape(value)}</t></si>" for value in values)
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        f'count="{len(values)}" uniqueCount="{len(values)}">{items}</sst>'
    )


def _sheet_xml(rows: list[list[str]], string_index: dict[str, int]) -> str:
    sheet_rows = []
    for row_number, row in enumerate(rows, start=1):
        cells = []
        for column_index, value in enumerate(row):
            column = _column_letter(column_index)
            ref = f"{column}{row_number}"
            if value == "":
                continue
            if isinstance(value, (int, float)) and not isinstance(value, bool):
                cells.append(f'<c r="{ref}"><v>{value}</v></c>')
            else:
                index = string_index[str(value)]
                cells.append(f'<c r="{ref}" t="s"><v>{index}</v></c>')
        sheet_rows.append(f'<row r="{row_number}">{"".join(cells)}</row>')
    body = "".join(sheet_rows)
    return (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        f"<sheetData>{body}</sheetData></worksheet>"
    )


def _column_letter(index: int) -> str:
    result = ""
    current = index
    while True:
        result = chr(65 + (current % 26)) + result
        current = current // 26 - 1
        if current < 0:
            break
    return result


def _escape(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def write_xlsx(path: Path, headers: list[str], rows: list[list[str]]) -> None:
    all_rows = [headers, *rows]
    flat_strings: list[str] = []
    string_index: dict[str, int] = {}

    def add_string(value: str) -> int:
        if value not in string_index:
            string_index[value] = len(flat_strings)
            flat_strings.append(value)
        return string_index[value]

    normalized_rows: list[list[str | float]] = []
    for row in all_rows:
        normalized: list[str | float] = []
        for column_index, value in enumerate(row):
            if column_index == 2 and row is not headers and value:
                try:
                    normalized.append(float(value))
                    continue
                except ValueError:
                    pass
            add_string(value)
            normalized.append(value)
        normalized_rows.append(normalized)

    content_types = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>"""

    rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>"""

    workbook = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
 xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Products" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>"""

    workbook_rels = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>"""

    styles = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="1"><fill><patternFill patternType="none"/></fill></fills>
  <borders count="1"><border/></borders>
  <cellStyleXfs count="1"><xf/></cellStyleXfs>
  <cellXfs count="1"><xf/></cellXfs>
</styleSheet>"""

    shared_strings = _shared_strings_xml(flat_strings)
    sheet = _sheet_xml(normalized_rows, string_index)

    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("[Content_Types].xml", content_types)
        archive.writestr("_rels/.rels", rels)
        archive.writestr("xl/workbook.xml", workbook)
        archive.writestr("xl/_rels/workbook.xml.rels", workbook_rels)
        archive.writestr("xl/worksheets/sheet1.xml", sheet)
        archive.writestr("xl/sharedStrings.xml", shared_strings)
        archive.writestr("xl/styles.xml", styles)


def write_template(basename: str, headers: list[str], rows: list[list[str]]) -> None:
    csv_path = DESKTOP / f"{basename}.csv"
    xlsx_path = DESKTOP / f"{basename}.xlsx"
    write_csv(csv_path, headers, rows)
    write_xlsx(xlsx_path, headers, rows)
    print(f"Created: {csv_path}")
    print(f"Created: {xlsx_path}")


def main() -> None:
    DESKTOP.mkdir(parents=True, exist_ok=True)
    write_template("TFG_Product_Import_Template", PRODUCT_HEADERS, PRODUCT_ROWS)
    write_template("TFG_Customer_Import_Template", CUSTOMER_HEADERS, CUSTOMER_ROWS)


if __name__ == "__main__":
    main()
