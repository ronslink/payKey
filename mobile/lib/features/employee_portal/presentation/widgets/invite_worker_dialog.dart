import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/employee_models.dart';

// ============================================================================
// Constants
// ============================================================================

class _DialogColors {
  static const primary = Color(0xFF6366F1);
  static const secondary = Color(0xFF8B5CF6);
  static const text = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF374151);
  static const whatsApp = Color(0xFF25D366);
}

class _DialogStyles {
  static const borderRadius = 20.0;
  static const containerRadius = 16.0;
  static const buttonRadius = 12.0;
  static const padding = 24.0;
  static const maxWidth = 400.0;
}

// ============================================================================
// Invite Message Builder
// ============================================================================

class _InviteMessageBuilder {
  final String code;
  final String? workerPhone;

  const _InviteMessageBuilder({required this.code, this.workerPhone});

  String build() => '''🎉 Welcome to payDome!

Your employer has invited you to the Worker Portal.

📱 Download the payDome app and use this invite code to set up your account:

🔑 Invite Code: $code

Use your phone number (${workerPhone ?? 'registered with your employer'}) and this code to create your account.

This code expires in 7 days.''';
}

// ============================================================================
// Share Actions Handler
// ============================================================================

class _ShareActionsHandler {
  final BuildContext context;
  final String message;
  final String? phone;
  final String? email;

  const _ShareActionsHandler({
    required this.context,
    required this.message,
    this.phone,
    this.email,
  });

  Future<void> copyToClipboard(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    _showSnackBar('Invite code copied to clipboard!', Colors.green);
  }

  Future<void> sendViaSMS() async {
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('sms:${phone ?? ''}?body=$encodedMessage');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await _shareGeneric();
      }
    } catch (e) {
      _showSnackBar('Could not open SMS: $e');
    }
  }

  Future<void> sendViaWhatsApp() async {
    final cleanPhone = phone?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('WhatsApp is not installed');
      }
    } catch (e) {
      _showSnackBar('Could not open WhatsApp: $e');
    }
  }

  Future<void> sendViaEmail() async {
    final subject = Uri.encodeComponent('Welcome to payDome - Your Invite Code');
    final body = Uri.encodeComponent(message);
    final uri = Uri.parse('mailto:${email ?? ''}?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnackBar('Could not open email app');
      }
    } catch (e) {
      _showSnackBar('Could not open email: $e');
    }
  }

  Future<void> shareGeneric() => _shareGeneric();

  Future<void> _shareGeneric() async {
    // ignore: deprecated_member_use
    await Share.share(message);
  }

  void _showSnackBar(String text, [Color? backgroundColor]) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

// ============================================================================
// Main Dialog Widget
// ============================================================================

class InviteWorkerDialog extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String? workerPhone;
  final String? workerEmail;

  const InviteWorkerDialog({
    super.key,
    required this.workerId,
    required this.workerName,
    this.workerPhone,
    this.workerEmail,
  });

  @override
  State<InviteWorkerDialog> createState() => _InviteWorkerDialogState();
}

class _InviteWorkerDialogState extends State<InviteWorkerDialog> {
  InviteStatus? _inviteStatus;
  InviteCode? _inviteCode;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _checkInviteStatus();
  }

  // --------------------------------------------------------------------------
  // API Methods
  // --------------------------------------------------------------------------

  Future<void> _checkInviteStatus() async {
    _setLoading(true);
    try {
      final response = await ApiService().employeePortal.checkInviteStatus(widget.workerId);
      if (response.statusCode == 200) {
        _inviteStatus = InviteStatus.fromJson(response.data);
      }
    } catch (_) {
      // Silent failure - status check is informational
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _generateInvite() async {
    _setGenerating(true);
    try {
      final response = await ApiService().employeePortal.generateInvite(widget.workerId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _inviteCode = InviteCode.fromJson(response.data));
        await _checkInviteStatus();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to generate invite');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      _setGenerating(false);
    }
  }

  // --------------------------------------------------------------------------
  // State Helpers
  // --------------------------------------------------------------------------

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  void _setGenerating(bool value) {
    if (mounted) setState(() => _isGenerating = value);
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // --------------------------------------------------------------------------
  // Share Actions
  // --------------------------------------------------------------------------

  _ShareActionsHandler get _shareHandler {
    final message = _InviteMessageBuilder(
      code: _inviteCode?.inviteCode ?? '',
      workerPhone: widget.workerPhone,
    ).build();

    return _ShareActionsHandler(
      context: context,
      message: message,
      phone: widget.workerPhone,
      email: widget.workerEmail,
    );
  }

  // --------------------------------------------------------------------------
  // Build Methods
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_DialogStyles.borderRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(_DialogStyles.padding),
        constraints: const BoxConstraints(maxWidth: _DialogStyles.maxWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: _DialogStyles.padding),
              _buildContent(),
              const SizedBox(height: _DialogStyles.padding),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_DialogColors.primary, _DialogColors.secondary],
            ),
            borderRadius: BorderRadius.circular(_DialogStyles.containerRadius),
          ),
          child: const Icon(Icons.person_add, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'Invite ${widget.workerName}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _DialogColors.text,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Allow your worker to access the Worker Portal',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }
    if (_inviteStatus?.hasAccount == true) {
      return _AccountActiveView(workerName: widget.workerName);
    }
    if (_inviteCode != null) {
      return _InviteCodeView(
        inviteCode: _inviteCode!,
        workerName: widget.workerName,
        shareHandler: _shareHandler,
      );
    }
    if (_inviteStatus?.hasInvite == true && !(_inviteStatus?.isInviteExpired ?? true)) {
      return _PendingInviteView(
        inviteStatus: _inviteStatus!,
        onGenerateNew: _generateInvite,
      );
    }
    return _GenerateInviteView(
      workerName: widget.workerName,
      isGenerating: _isGenerating,
      onGenerate: _generateInvite,
    );
  }
}

// ============================================================================
// Content Views
// ============================================================================

class _AccountActiveView extends StatelessWidget {
  final String workerName;

  const _AccountActiveView({required this.workerName});

  @override
  Widget build(BuildContext context) {
    return _StatusContainer(
      color: Colors.green,
      icon: Icons.check_circle,
      title: 'Account Active',
      subtitle: '$workerName already has access to the Worker Portal.',
    );
  }
}

class _PendingInviteView extends StatelessWidget {
  final InviteStatus inviteStatus;
  final VoidCallback onGenerateNew;

  const _PendingInviteView({
    required this.inviteStatus,
    required this.onGenerateNew,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatusContainer(
          color: Colors.amber,
          icon: Icons.pending,
          title: 'Invite Pending',
          subtitle: inviteStatus.inviteExpiry != null
              ? 'Expires: ${_formatDateTime(inviteStatus.inviteExpiry!)}'
              : null,
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onGenerateNew,
          icon: const Icon(Icons.refresh),
          label: const Text('Generate New Code'),
        ),
      ],
    );
  }
}

class _GenerateInviteView extends StatelessWidget {
  final String workerName;
  final bool isGenerating;
  final VoidCallback onGenerate;

  const _GenerateInviteView({
    required this.workerName,
    required this.isGenerating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Generate an invite code for $workerName to access the Worker Portal.',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: isGenerating ? null : onGenerate,
          icon: isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send),
          label: Text(isGenerating ? 'Generating...' : 'Generate Invite Code'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _DialogColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_DialogStyles.buttonRadius),
            ),
          ),
        ),
      ],
    );
  }
}

class _InviteCodeView extends StatelessWidget {
  final InviteCode inviteCode;
  final String workerName;
  final _ShareActionsHandler shareHandler;

  const _InviteCodeView({
    required this.inviteCode,
    required this.workerName,
    required this.shareHandler,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCodeDisplay(),
        const SizedBox(height: 20),
        const Text(
          'Send invite via:',
          style: TextStyle(fontWeight: FontWeight.w600, color: _DialogColors.textSecondary),
        ),
        const SizedBox(height: 12),
        _buildShareButtons(),
        const SizedBox(height: 16),
        _buildCopyButton(),
        const SizedBox(height: 16),
        _buildInfoBox(),
      ],
    );
  }

  Widget _buildCodeDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _DialogColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_DialogStyles.buttonRadius),
      ),
      child: Column(
        children: [
          const Text(
            'Invite Code',
            style: TextStyle(color: _DialogColors.primary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: inviteCode.inviteCode.split('').map(_buildCodeDigit).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Expires: ${_formatDateTime(inviteCode.expiresAt)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeDigit(String digit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _DialogColors.primary),
      ),
      child: Text(
        digit,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: _DialogColors.primary,
        ),
      ),
    );
  }

  Widget _buildShareButtons() {
    final buttons = [
      _ShareButtonData(Icons.message, 'SMS', Colors.blue, shareHandler.sendViaSMS),
      _ShareButtonData(Icons.chat, 'WhatsApp', _DialogColors.whatsApp, shareHandler.sendViaWhatsApp),
      _ShareButtonData(Icons.email, 'Email', Colors.red, shareHandler.sendViaEmail),
      _ShareButtonData(Icons.share, 'Other', Colors.grey[700]!, shareHandler.shareGeneric),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons.map((data) => _ShareButton(data: data)).toList(),
    );
  }

  Widget _buildCopyButton() {
    return OutlinedButton.icon(
      onPressed: () => shareHandler.copyToClipboard(inviteCode.inviteCode),
      icon: const Icon(Icons.copy, size: 18),
      label: const Text('Copy Code'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _DialogColors.primary,
        side: const BorderSide(color: _DialogColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$workerName can use their phone number and this code to set up their account.',
              style: const TextStyle(fontSize: 12, color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Reusable Components
// ============================================================================

class _StatusContainer extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;

  const _StatusContainer({
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(_DialogStyles.buttonRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButtonData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButtonData(this.icon, this.label, this.color, this.onTap);
}

class _ShareButton extends StatelessWidget {
  final _ShareButtonData data;

  const _ShareButton({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(_DialogStyles.buttonRadius),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Utilities
// ============================================================================

String _formatDateTime(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

// ============================================================================
// Public API
// ============================================================================

/// Helper function to show the invite dialog
Future<void> showInviteWorkerDialog(
  BuildContext context, {
  required String workerId,
  required String workerName,
  String? workerPhone,
  String? workerEmail,
}) {
  return showDialog(
    context: context,
    builder: (context) => InviteWorkerDialog(
      workerId: workerId,
      workerName: workerName,
      workerPhone: workerPhone,
      workerEmail: workerEmail,
    ),
  );
}