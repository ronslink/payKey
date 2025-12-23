import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../subscriptions/presentation/providers/subscription_provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

class WorkerImportPage extends ConsumerStatefulWidget {
  const WorkerImportPage({super.key});

  @override
  ConsumerState<WorkerImportPage> createState() => _WorkerImportPageState();
}

class _WorkerImportPageState extends ConsumerState<WorkerImportPage> {
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isDownloading = false;
  Map<String, dynamic>? _importResult;
  String? _error;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _importResult = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick file: $e');
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _selectedFile!.bytes == null) {
      setState(() => _error = 'No file selected');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final api = ApiService();
      final result = await api.uploadWorkerExcel(_selectedFile!.bytes!, _selectedFile!.name);
      
      setState(() {
        _importResult = result;
        _isUploading = false;
      });

      if (result['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${result['importedCount']} workers!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isUploading = false;
      });
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);
    
    try {
      final api = ApiService();
      final bytes = await api.downloadWorkerTemplate();
      
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'employee_import_template.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template downloaded!')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to download template: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(userSubscriptionProvider);
    final tier = subscriptionState.value?.plan.tier ?? 'FREE';
    final hasAccess = tier == 'GOLD' || tier == 'PLATINUM';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF374151)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Import Workers',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: !hasAccess 
        ? _buildUpgradePrompt()
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 20),
                _buildTemplateSection(),
                const SizedBox(height: 20),
                _buildUploadSection(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorCard(),
                ],
                if (_importResult != null) ...[
                  const SizedBox(height: 20),
                  _buildResultsCard(),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildUpgradePrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline, size: 48, color: Colors.amber.shade700),
            ),
            const SizedBox(height: 24),
            const Text(
              'Premium Feature',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Bulk worker import is available for Gold and Platinum subscribers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/settings/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upgrade Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.upload_file, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Import',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Import multiple workers from an Excel file',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Text(
                'Step 1: Download Template',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Download our Excel template with all required fields and instructions.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isDownloading ? null : _downloadTemplate,
              icon: _isDownloading 
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
              label: Text(_isDownloading ? 'Downloading...' : 'Download Template'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_upload_outlined, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Text(
                'Step 2: Upload File',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedFile != null 
                    ? const Color(0xFF10B981) 
                    : Colors.grey.shade300,
                  style: BorderStyle.solid,
                  width: _selectedFile != null ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _selectedFile != null ? Icons.check_circle : Icons.add_circle_outline,
                    size: 48,
                    color: _selectedFile != null 
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selectedFile?.name ?? 'Tap to select Excel file',
                    style: TextStyle(
                      fontWeight: _selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                      color: _selectedFile != null 
                        ? const Color(0xFF1F2937)
                        : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_selectedFile == null || _isUploading) ? null : _uploadFile,
              icon: _isUploading 
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.upload, color: Colors.white),
              label: Text(
                _isUploading ? 'Importing...' : 'Import Workers',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    final success = _importResult!['success'] as bool? ?? false;
    final imported = _importResult!['importedCount'] as int? ?? 0;
    final errors = _importResult!['errorCount'] as int? ?? 0;
    final errorList = (_importResult!['errors'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: success ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.warning_amber,
                color: success ? Colors.green.shade600 : Colors.orange.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                success ? 'Import Complete' : 'Import Completed with Errors',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip('Imported', imported.toString(), Colors.green),
              const SizedBox(width: 12),
              _buildStatChip('Errors', errors.toString(), Colors.red),
            ],
          ),
          if (errorList.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Error Details:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...errorList.take(5).map((err) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• Row ${err['row']}: ${err['field']} - ${err['message']}',
                style: TextStyle(fontSize: 13, color: Colors.red.shade700),
              ),
            )),
            if (errorList.length > 5)
              Text(
                '... and ${errorList.length - 5} more errors',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
