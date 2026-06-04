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

  /// Opens a multi-stop driving route in Google Maps (stops visited in order).
  /// [addresses] should already be sorted (e.g. by delivery date/time).
  static Future<bool> openMultiStopRoute(List<String> addresses) async {
    final stops = addresses
        .map((address) => address.trim())
        .where((address) => address.isNotEmpty)
        .toList();
    if (stops.isEmpty) {
      return false;
    }
    if (stops.length == 1) {
      return openDirections(stops.first);
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&travelmode=driving&dir_action=navigate&destination='
      '${Uri.encodeComponent(stops.last)}'
      '&waypoints=${Uri.encodeComponent(stops.sublist(0, stops.length - 1).join('|'))}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
