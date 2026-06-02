import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps (app or browser) for route planning. No API key required.
class GoogleMapsService {
  GoogleMapsService._();

  /// Opens directions to [address] in Google Maps.
  static Future<bool> openDirections(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${Uri.encodeComponent(trimmed)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
