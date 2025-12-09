import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/employee_models.dart';

/// Dialog for employers to invite workers to the worker portal
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

  String get _inviteMessage {
    final code = _inviteCode?.inviteCode ?? '';
    return '''🎉 Welcome to PayKey!

Your employer has invited you to the Worker Portal.

📱 Download the PayKey app and use this invite code to set up your account:

🔑 Invite Code: $code

Use your phone number (${widget.workerPhone ?? 'registered with your employer'}) and this code to create your account.

This code expires in 7 days.''';
  }

  Future<void> _checkInviteStatus() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService().employeePortal.checkInviteStatus(widget.workerId);
      if (response.statusCode == 200) {
        setState(() {
          _inviteStatus = InviteStatus.fromJson(response.data);
        });
      }
    } catch (e) {
      // Error handling - could add error state if needed
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateInvite() async {
    setState(() => _isGenerating = true);

    try {
      final response = await ApiService().employeePortal.generateInvite(widget.workerId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _inviteCode = InviteCode.fromJson(response.data);
        });
        await _checkInviteStatus();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to generate invite');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _copyInviteCode() {
    if (_inviteCode == null) return;
    
    Clipboard.setData(ClipboardData(text: _inviteCode!.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _sendViaSMS() async {
    if (_inviteCode == null) return;
    
    final phone = widget.workerPhone ?? '';
    final message = Uri.encodeComponent(_inviteMessage);
    final uri = Uri.parse('sms:$phone?body=$message');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        // Fallback to share
        await Share.share(_inviteMessage);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open SMS: $e')),
      );
    }
  }

  Future<void> _sendViaWhatsApp() async {
    if (_inviteCode == null) return;
    
    final phone = widget.workerPhone?.replaceAll(RegExp(r'[^\d+]'), '') ?? '';
    final message = Uri.encodeComponent(_inviteMessage);
    
    // Try WhatsApp URL scheme
    final whatsappUrl = Uri.parse('https://wa.me/$phone?text=$message');
    
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open WhatsApp: $e')),
      );
    }
  }

  Future<void> _sendViaEmail() async {
    if (_inviteCode == null) return;
    
    final email = widget.workerEmail ?? '';
    final subject = Uri.encodeComponent('Welcome to PayKey - Your Invite Code');
    final body = Uri.encodeComponent(_inviteMessage);
    final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open email: $e')),
      );
    }
  }

  Future<void> _shareViaOther() async {
    if (_inviteCode == null) return;
        await Share.share(_inviteMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Invite ${widget.workerName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Allow your worker to access the Worker Portal',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Content based on status
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_inviteStatus?.hasAccount == true)
                _buildHasAccountView()
              else if (_inviteCode != null)
                _buildInviteCodeView()
              else if (_inviteStatus?.hasInvite == true && !(_inviteStatus?.isInviteExpired ?? true))
                _buildHasPendingInviteView()
              else
                _buildGenerateInviteView(),
              
              const SizedBox(height: 24),
              
              // Close button
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

  Widget _buildHasAccountView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${widget.workerName} already has access to the Worker Portal.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeView() {
    return Column(
      children: [
        // Code Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'Invite Code',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _inviteCode!.inviteCode.split('').map((digit) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6366F1)),
                    ),
                    child: Text(
                      digit,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Expires: ${_formatDateTime(_inviteCode!.expiresAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Share Options Title
        const Text(
          'Send invite via:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Share Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildShareButton(
              icon: Icons.message,
              label: 'SMS',
              color: Colors.blue,
              onTap: _sendViaSMS,
            ),
            _buildShareButton(
              icon: Icons.chat,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: _sendViaWhatsApp,
            ),
            _buildShareButton(
              icon: Icons.email,
              label: 'Email',
              color: Colors.red,
              onTap: _sendViaEmail,
            ),
            _buildShareButton(
              icon: Icons.share,
              label: 'Other',
              color: Colors.grey[700]!,
              onTap: _shareViaOther,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Copy Button
        OutlinedButton.icon(
          onPressed: _copyInviteCode,
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy Code'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6366F1),
            side: const BorderSide(color: Color(0xFF6366F1)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Info Box
        Container(
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
                  '${widget.workerName} can use their phone number and this code to set up their account.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
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

  Widget _buildHasPendingInviteView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.pending, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invite Pending',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                    if (_inviteStatus?.inviteExpiry != null)
                      Text(
                        'Expires: ${_formatDateTime(_inviteStatus!.inviteExpiry!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _generateInvite,
          icon: const Icon(Icons.refresh),
          label: const Text('Generate New Code'),
        ),
      ],
    );
  }

  Widget _buildGenerateInviteView() {
    return Column(
      children: [
        Text(
          'Generate an invite code for ${widget.workerName} to access the Worker Portal.',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _isGenerating ? null : _generateInvite,
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send),
          label: Text(_isGenerating ? 'Generating...' : 'Generate Invite Code'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

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
