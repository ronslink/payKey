import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';

/// In-app account deletion (App Store Review Guideline 5.1.1(v)).
///
/// Calls the authenticated `POST /data-deletion/request/me` endpoint. Users
/// with a password must confirm it; users who signed in with Apple or Google
/// can leave the password empty.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  /// Returns true when the deletion request was accepted.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _confirmed = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter the email address of your account.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final password = _passwordController.text;
      await ApiService().post(
        '/data-deletion/request/me',
        data: {
          'email': email,
          if (password.isNotEmpty) 'password': password,
          'reason': 'Deleted from the mobile app',
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? (data['message'] is List
              ? (data['message'] as List).join('\n')
              : data['message'].toString())
          : 'Could not delete your account. Please try again.';
      setState(() {
        _submitting = false;
        _error = message;
      });
    } catch (_) {
      setState(() {
        _submitting = false;
        _error = 'Could not delete your account. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your PayDome account and all of its '
              'data, including workers, payroll records, properties and '
              'transactions. This cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Account email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                helperText: 'Leave empty if you sign in with Apple or Google',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _confirmed,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _confirmed = v ?? false),
              title: const Text('I understand this cannot be undone'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: (_confirmed && !_submitting) ? _submit : null,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete account'),
        ),
      ],
    );
  }
}
