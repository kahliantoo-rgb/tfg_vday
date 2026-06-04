from pathlib import Path

path = Path(r"c:\Users\USER\Desktop\tfg_vday\lib\pages\order_detail_page\order_detail_page_widget.dart")
text = path.read_text(encoding="utf-8")

if "order_detail_item_tile" not in text:
    text = text.replace(
        "import '/components/update_order_status_widget.dart';",
        "import '/components/update_order_status_widget.dart';\nimport '/components/order_detail_item_tile.dart';",
    )

start = """                                                return Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: List.generate(
                                                    listViewOrderItemRecordList
                                                        .length,
                                                    (listViewIndex) {
                                                    final listViewOrderItemRecord =
                                                        listViewOrderItemRecordList[
                                                            listViewIndex];
                                                    return Container(
                                                      width: 100.0,
                                                      height: 100.0,"""

end = """                                                    );
                                                  },
                                                ),
                                              );
                                              },
                                            ),
                                        ].divide(SizedBox(height: 12.0)),"""

repl = """                                                return OrderDetailItemList(
                                                  items:
                                                      listViewOrderItemRecordList,
                                                );
                                              },
                                            ),
                                        ].divide(SizedBox(height: 12.0)),"""

if start not in text:
    raise SystemExit("start marker not found")
if end not in text:
    raise SystemExit("end marker not found")

i = text.index(start)
j = text.index(end, i)
path.write_text(text[:i] + repl + text[j:], encoding="utf-8")
print("patched order detail items")

# remove empty decoration container if present
text = path.read_text(encoding="utf-8")
empty = """                                          Container(
                                            decoration: BoxDecoration(),
                                          ),
"""
if empty in text:
    path.write_text(text.replace(empty, "", 1), encoding="utf-8")
    print("removed empty container")
