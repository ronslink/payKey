import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// IntaSend trust badge widget
/// 
/// Displays the IntaSend PCI-DSS security badge with link to security page.
/// Use on payment screens to build user trust.
/// 
/// Usage:
/// ```dart
/// IntaSendTrustBadge()
/// IntaSendTrustBadge(width: 300)
/// ```
class IntaSendTrustBadge extends StatelessWidget {
  final double width;
  final bool showText;

  const IntaSendTrustBadge({
    super.key,
    this.width = 375,
    this.showText = true,
  });

  static const String _securityUrl = 'https://intasend.com/security';
  static const String _assetPath = 
      'assets/images/intasend-trust-badge-no-mpesa-hr-light.png';

  Future<void> _launchSecurityPage() async {
    final uri = Uri.parse(_securityUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _launchSecurityPage,
          child: Image.asset(
            _assetPath,
            width: width,
            semanticLabel: 'IntaSend Secure Payments (PCI-DSS Compliant)',
            errorBuilder: (context, error, stackTrace) {
              // Fallback to text if image fails
              return _buildTextBadge(context);
            },
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _launchSecurityPage,
            child: Text(
              'Secured by IntaSend Payments',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextBadge(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, color: Colors.green[700], size: 20),
          const SizedBox(width: 8),
          Text(
            'Secured by IntaSend',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version of the trust badge for smaller spaces
class IntaSendTrustBadgeCompact extends StatelessWidget {
  const IntaSendTrustBadgeCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntaSendTrustBadge(
      width: 200,
      showText: false,
    );
  }
}
