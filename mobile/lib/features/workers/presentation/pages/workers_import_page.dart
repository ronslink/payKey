import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/widgets/feature_gate.dart';
import '../../../../main.dart'; // Import AppRoutes

import '../../../../core/utils/download_utils.dart';

class WorkersImportPage extends ConsumerStatefulWidget {
  const WorkersImportPage({super.key});

  @override
  ConsumerState<WorkersImportPage> createState() => _WorkersImportPageState();
}

class _WorkersImportPageState extends ConsumerState<WorkersImportPage> {
  bool _isUploading = false;
  bool _isDownloading = false;
  Map<String, dynamic>? _result;
  String? _error;
  String? _fileName;

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await ApiService().workersConvert.downloadTemplate();
      
      await DownloadUtils.downloadFile(
        filename: 'workers_template.xlsx',
        bytes: bytes,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    } catch (e) {
      if (mounted) _handleError(e);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    setState(() {
      _error = null;
      _result = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, 
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() => _fileName = file.name);

      _uploadFile(file);
    } catch (e) {
      setState(() => _error = 'Error selecting file: $e');
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    setState(() => _isUploading = true);

    try {
      final response = await ApiService().workersConvert.importWorkers(file);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() => _result = response.data);
      } else {
        setState(() => _error = response.data['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) _handleError(e);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _handleError(dynamic error) {
    if (error is ApiException && error.statusCode == 403) {
      _showUpgradeDialog();
    } else {
      setState(() => _error = error.toString());
    }
  }

  void _showUpgradeDialog() {
    showFeatureUpgradeDialog(
      context,
      featureName: 'Bulk Worker Import',
      requiredTier: 'GOLD',
      onUpgrade: () {
        Navigator.of(context).pop();
        context.push(AppRoutes.settingsSubscription);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Workers'),
        actions: [
          if (!_isUploading && !_isDownloading)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download Template',
              onPressed: _downloadTemplate,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructionsCard(),
            const SizedBox(height: 24),
            if (_result == null) _buildUploadSection(),
            if (_fileName != null && _result == null && !_isUploading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Selected: $_fileName', textAlign: TextAlign.center),
              ),
            if (_isUploading || _isDownloading)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_isDownloading ? 'Downloading template...' : 'Uploading file...'),
                    ],
                  ),
                ),
              ),
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Text(_error!, style: TextStyle(color: Colors.red[800])),
              ),
            if (_result != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF6366F1)),
                    SizedBox(width: 8),
                    Text('Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                TextButton.icon(
                  onPressed: _downloadTemplate,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Template'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('1. Download the Excel template.'),
            const Text('2. Fill in worker details (Name, Phone, Salary required).'),
            const Text('3. Use dropdowns for Payment Method, Frequency, etc.'),
            const Text('4. Upload the file here.'),
            const SizedBox(height: 8),
            _buildBullet('Full Name (Required)'),
            _buildBullet('Phone Number (Required)'),
            _buildBullet('Gross Salary (Required)'),
            _buildBullet('Payment Method (M-Pesa, Bank, Cash)'),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      children: [
        InkWell(
          onTap: _pickAndUploadFile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
               color: const Color(0xFFF8FAFC),
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
            ),
             child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   ShaderMask(
                     shaderCallback: (bounds) => const LinearGradient(
                       colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFF8B5CF6)],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                     ).createShader(bounds),
                     child: const Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.white),
                   ),
                   SizedBox(height: 16),
                   Text(
                      'Tap to upload Excel file',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                   ),
                ],
             ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    final success = _result?['success'] ?? 0;
    final failed = _result?['failed'] ?? 0;
    final errors = (_result?['errors'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
             Expanded(
               child: _buildResultCard('Success', success.toString(), Colors.green),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: _buildResultCard('Failed', failed.toString(), const Color(0xFFEF4444)),
             ),
          ],
        ),
        const SizedBox(height: 24),
        if (errors.isNotEmpty) ...[
          const Text('Errors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: errors.length,
            itemBuilder: (context, index) {
              final err = errors[index];
              return Card(
                color: Colors.red[50],
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.red[100]!.withValues(alpha: 0.5))
                ),
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text(err['name'] ?? 'Row ${err['row']}'),
                  subtitle: Text(err['error'] ?? 'Unknown error'),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.pop(true), // Return true to refresh list
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done', style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(String label, String value, Color color) {
    return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
       ),
       child: Column(
          children: [
             Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
             const SizedBox(height: 4),
             Text(label, style: TextStyle(fontSize: 14, color: color)),
          ],
       ),
    );
  }
}
