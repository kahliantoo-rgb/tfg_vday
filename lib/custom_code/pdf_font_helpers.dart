import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// PDF theme with Simplified Chinese + Latin glyphs (Noto Sans SC).
Future<pw.ThemeData> loadPdfThemeWithCjk() async {
  final base = await PdfGoogleFonts.notoSansSCRegular();
  final bold = await PdfGoogleFonts.notoSansSCBold();
  return pw.ThemeData.withFont(base: base, bold: bold);
}
