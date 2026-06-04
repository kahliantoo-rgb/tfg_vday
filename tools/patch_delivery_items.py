from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def patch_file(path: Path, start: str, end: str, repl: str) -> None:
    text = path.read_text(encoding="utf-8")
    i = text.index(start)
    j = text.index(end, i)
    path.write_text(text[:i] + repl + text[j:], encoding="utf-8")
    print("patched", path.name)


def add_import(path: Path, import_line: str, after: str) -> None:
    text = path.read_text(encoding="utf-8")
    if import_line in text:
        return
    text = text.replace(after, after + "\n" + import_line)
    path.write_text(text, encoding="utf-8")


# delivery_order_print
p1 = ROOT / "lib/delivery/delivery_order_print/delivery_order_print_widget.dart"
start1 = """                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),"""
end1 = """                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 16.0),
                      child: Container(
                        width: double.infinity,
                        height: 2.0,"""
repl1 = """                    StreamBuilder<List<OrderItemRecord>>(
                      stream: queryOrderItemRecord(
                        queryBuilder: (orderItemRecord) =>
                            orderItemRecord.where(
                          'orderRef',
                          isEqualTo: widget!.orderRef,
                        ),
                      ),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: SizedBox(
                              width: 50.0,
                              height: 50.0,
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return DeliveryOrderItemTable(
                          items: snapshot.data!,
                          fontSize: 18.0,
                          headerFontSize: 18.0,
                        );
                      },
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 16.0),
                      child: Container(
                        width: double.infinity,
                        height: 2.0,"""
patch_file(p1, start1, end1, repl1)
add_import(
    p1,
    "import '/components/delivery_order_item_table.dart';",
    "import '/components/home_nav_button.dart';",
)

# d_o_widget
p2 = ROOT / "lib/d_o/d_o_widget.dart"
start2 = """                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(0.0),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1.0,
                                ),
                              ),
                              child: StreamBuilder<List<OrderItemRecord>>("""
end2 = """                            ),
                          ],
                        ),
                      ),
                      Divider(
                        thickness: 2.0,
                        color: Colors.black,
                      ),"""
repl2 = """                            StreamBuilder<List<OrderItemRecord>>(
                              stream: queryOrderItemRecord(
                                queryBuilder: (orderItemRecord) =>
                                    orderItemRecord.where(
                                  'orderRef',
                                  isEqualTo: widget!.orderRef,
                                ),
                              ),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: SizedBox(
                                      width: 50.0,
                                      height: 50.0,
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return DeliveryOrderItemTable(
                                  items: snapshot.data!,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        thickness: 2.0,
                        color: Colors.black,
                      ),"""
patch_file(p2, start2, end2, repl2)
add_import(
    p2,
    "import '/components/delivery_order_item_table.dart';",
    "import '/index.dart';",
)

# delivery_order_summary_page - replace inner ListView row section
p3 = ROOT / "lib/pages/delivery_order_summary_page/delivery_order_summary_page_widget.dart"
start3 = """                            Container(
                              decoration: BoxDecoration(),
                              child: StreamBuilder<List<OrderItemRecord>>("""
# find end - need to read file for unique end marker after streambuilder
text3 = p3.read_text(encoding="utf-8")
idx = text3.index(start3)
# find closing after streambuilder - look for pattern after item list
end3 = """                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: FFButtonWidget("""
repl3 = """                            StreamBuilder<List<OrderItemRecord>>(
                              stream: queryOrderItemRecord(
                                queryBuilder: (orderItemRecord) =>
                                    orderItemRecord.where(
                                  'orderRef',
                                  isEqualTo: widget!.orderRef,
                                ),
                              ),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: SizedBox(
                                      width: 50.0,
                                      height: 50.0,
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return DeliveryOrderItemTable(
                                  items: snapshot.data!,
                                  fontSize: 16.0,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(20.0),
                    child: FFButtonWidget("""
if start3 in text3 and end3 in text3:
    patch_file(p3, start3, end3, repl3)
    add_import(
        p3,
        "import '/components/delivery_order_item_table.dart';",
        "import '/index.dart';",
    )
else:
    print("skip summary page - markers not found")

print("done")
