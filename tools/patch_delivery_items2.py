from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_between(path: Path, start: str, end: str, repl: str) -> None:
    text = path.read_text(encoding="utf-8")
    i = text.index(start)
    j = text.index(end, i)
    path.write_text(text[:i] + repl + text[j:], encoding="utf-8")
    print("patched", path.name)


def add_import(path: Path, import_line: str, after: str) -> None:
    text = path.read_text(encoding="utf-8")
    if import_line in text:
        return
    path.write_text(text.replace(after, after + "\n" + import_line), encoding="utf-8")


# d_o_widget inner return
p2 = ROOT / "lib/d_o/d_o_widget.dart"
s2 = """                                  List<OrderItemRecord>
                                      listViewOrderItemRecordList =
                                      snapshot.data!;

                                  return ListView.builder("""
e2 = """                                  );
                                },
                              ),
                            ),"""
r2 = """                                  return DeliveryOrderItemTable(
                                    items: snapshot.data!,
                                  );
                                },
                              ),
                            ),"""
replace_between(p2, s2, e2, r2)
add_import(p2, "import '/components/delivery_order_item_table.dart';", "import '/index.dart';")

# summary page
p3 = ROOT / "lib/pages/delivery_order_summary_page/delivery_order_summary_page_widget.dart"
replace_between(p3, s2, e2, """                                  return DeliveryOrderItemTable(
                                    items: snapshot.data!,
                                    fontSize: 16.0,
                                  );
                                },
                              ),
                            ),""")
add_import(p3, "import '/components/delivery_order_item_table.dart';", "import '/index.dart';")

print("done")
