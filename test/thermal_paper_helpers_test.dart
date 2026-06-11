import 'package:flutter_test/flutter_test.dart';

import 'package:tfg_vday/custom_code/thermal_paper_helpers.dart';

void main() {
  test('ThermalPaperSize maps width to dots and chars', () {
    expect(ThermalPaperSize.mm58.dotsPerLine, 384);
    expect(ThermalPaperSize.mm58.lineWidthChars, 32);
    expect(ThermalPaperSize.mm80.dotsPerLine, 576);
    expect(ThermalPaperSize.mm80.lineWidthChars, 48);
  });

  test('guessPaperSizeFromPrinterName detects 80mm hints', () {
    expect(guessPaperSizeFromPrinterName('POS-80'), ThermalPaperSize.mm80);
    expect(guessPaperSizeFromPrinterName('XP-58IIH'), ThermalPaperSize.mm58);
  });
}
