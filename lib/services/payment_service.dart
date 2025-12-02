import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Simple Google Pay (UPI) launcher.
/// NOTE: This uses UPI deep links. Replace placeholders with real merchant info.
class PaymentService {
  /// Launches Google Pay UPI intent.
  /// Expects:
  /// - pa: merchant VPA (e.g., yourvpa@bank)
  /// - pn: merchant name
  /// - am: amount as string (e.g., "99.00")
  /// - tn: transaction note
  /// - tid: transaction/order id
  static Future<void> startGPayUpi({
    required BuildContext context,
    required String pa,
    required String pn,
    required String am,
    required String tn,
    required String tid,
    String? currency,
  }) async {
    final params = {
      'pa': pa,
      'pn': pn,
      'am': am,
      'tn': tn,
      'tid': tid,
      'cu': currency ?? 'INR',
      'url': 'https://codesurge.ai/pickoo',
    };
    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final genericUpi = Uri.parse('upi://pay?$query');
    final gpayLegacy1 = Uri.parse('tez://upi/pay?$query');
    final gpayLegacy2 = Uri.parse('googlepay://upi/pay?$query');
    final gpayPlayStore = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.google.android.apps.nbu.paisa.user');

    // Web is not supported for native UPI
    if (kIsWeb) {
      _showSnack(context, 'Payments are not supported on web.');
      return;
    }

    // Try generic UPI first so any available UPI app can handle it.
    if (await _tryLaunchUri(genericUpi)) return;
    // Try legacy Google Pay schemes on some devices
    if (await _tryLaunchUri(gpayLegacy1)) return;
    if (await _tryLaunchUri(gpayLegacy2)) return;

    // As a fallback, open Play Store page for Google Pay
    final openedStore = await launchUrl(gpayPlayStore, mode: LaunchMode.externalApplication);
    if (!openedStore) {
      _showSnack(context, 'No UPI app found. Please install Google Pay.');
    }
  }

  static Future<bool> _tryLaunchUri(Uri uri) async {
    try {
      final can = await canLaunchUrl(uri);
      if (!can) return false;
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return ok;
    } catch (_) {
      return false;
    }
  }

  static void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
