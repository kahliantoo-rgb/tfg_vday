import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/company_profile_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CompanyLogoEditor extends StatelessWidget {
  const CompanyLogoEditor({
    super.key,
    required this.logoUrl,
    required this.uploading,
    required this.onPickLogo,
    this.companyId,
    this.onRemoveLogo,
  });

  final String logoUrl;
  final String? companyId;
  final bool uploading;
  final VoidCallback onPickLogo;
  final VoidCallback? onRemoveLogo;

  @override
  Widget build(BuildContext context) {
    final hasLogo = isUsableCompanyLogoUrl(logoUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company Logo',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                color: const Color(0xFF101518),
                letterSpacing: 0.0,
              ),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Upload your full-colour logo (PNG, at least 1200px). Colour is kept for PDF and settings; thermal receipts auto-convert at print time.',
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.inter(),
                color: FlutterFlowTheme.of(context).secondaryText,
                letterSpacing: 0.0,
              ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    width: 112.0,
                    height: 112.0,
                    color: const Color(0xFFEDE8DF),
                    child: hasLogo
                        ? buildCompanyLogoImage(
                            context: context,
                            logoUrl: logoUrl,
                            companyId: companyId,
                            width: 112.0,
                            height: 112.0,
                          )
                        : Icon(
                            Icons.storefront,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 40.0,
                          ),
                  ),
                ),
                if (uploading)
                  Container(
                    width: 112.0,
                    height: 112.0,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: uploading ? null : onPickLogo,
                    icon: const Icon(Icons.upload, size: 18.0),
                    label: Text(hasLogo ? 'Change Photo' : 'Upload Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF507583),
                      side: const BorderSide(color: Color(0xFF507583)),
                    ),
                  ),
                  if (hasLogo && onRemoveLogo != null) ...[
                    const SizedBox(height: 8.0),
                    TextButton(
                      onPressed: uploading ? null : onRemoveLogo,
                      child: Text(
                        'Remove Photo',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
