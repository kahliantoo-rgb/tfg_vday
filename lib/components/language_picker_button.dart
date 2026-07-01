import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/internationalization.dart';
import '/l10n/locale_text.dart';

/// Globe icon — opens language picker (English / 中文 / Bahasa Melayu).
class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({
    super.key,
    this.iconColor,
    this.buttonSize = 40,
  });

  final Color? iconColor;
  final double buttonSize;

  static Future<void> showLanguageSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final current = currentLanguageCode(context);

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  loc(
                    sheetContext,
                    en: 'Language',
                    zh: '语言',
                    ms: 'Bahasa',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final code in supportedAppLanguageCodes)
                ListTile(
                  leading: Icon(
                    current == code
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(languageDisplayName(code)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await FFLocalizations.storeLocale(code);
                    if (context.mounted) {
                      setAppLanguage(context, code);
                    }
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.onSurface;
    return IconButton(
      tooltip: loc(
        context,
        en: 'Language',
        zh: '语言',
        ms: 'Bahasa',
      ),
      icon: Icon(Icons.language, color: color, size: 24),
      iconSize: buttonSize,
      onPressed: () => showLanguageSheet(context),
    );
  }
}

/// White icon variant for primary-coloured app bars.
class LanguagePickerAppBarButton extends StatelessWidget {
  const LanguagePickerAppBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguagePickerButton(
      iconColor: Colors.white,
      buttonSize: 24,
    );
  }
}
