import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Signature lines shown at the bottom of delivery slip previews / prints.
class DeliverySlipSignaturePreview extends StatelessWidget {
  const DeliverySlipSignaturePreview({
    super.key,
    this.textColor = Colors.black,
  });

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _signatureField(label: 'Driver signature:', textColor: textColor),
        const SizedBox(height: 20.0),
        _signatureField(label: 'Customer signature:', textColor: textColor),
      ],
    );
  }

  Widget _signatureField({
    required String label,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 28.0),
        Container(
          height: 1.0,
          color: textColor,
        ),
      ],
    );
  }
}
