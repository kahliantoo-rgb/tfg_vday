import 'package:flutter_test/flutter_test.dart';

import 'package:tfg_vday/custom_code/esc_pos_text_helpers.dart';

void main() {
  test('escPosDisplayWidth counts CJK as double width', () {
    expect(escPosDisplayWidth('AB'), 2);
    expect(escPosDisplayWidth('太阳花'), 6);
    expect(escPosDisplayWidth('Rose 太阳'), 9);
  });

  test('escPosWrapLines wraps mixed text', () {
    final lines = escPosWrapLines('太阳花礼盒 Premium Box', width: 16);
    expect(lines.length, greaterThan(1));
    for (final line in lines) {
      expect(escPosDisplayWidth(line), lessThanOrEqualTo(16));
    }
  });

  test('escPosTwoColumn aligns price column', () {
    final line = escPosTwoColumn('Qty 1 x \$68.00', '\$68.00', width: 32);
    expect(escPosDisplayWidth(line), 32);
    expect(line.trimRight().endsWith('\$68.00'), isTrue);
  });
}
