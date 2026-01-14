import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/worker_document_model.dart';
import '../../../../core/network/api_service.dart';

/// Provider to fetch documents for a worker
final workerDocumentsProvider = FutureProvider.autoDispose.family<List<WorkerDocument>, String>((ref, workerId) async {
  final response = await ApiService().workers.getDocuments(workerId);
  final List<dynamic> data = response.data as List<dynamic>;
  return data.map((json) => WorkerDocument.fromJson(json as Map<String, dynamic>)).toList();
});

/// Documents section widget for worker detail page
class DocumentsSection extends ConsumerStatefulWidget {
  final String workerId;

  const DocumentsSection({super.key, required this.workerId});

  @override
  ConsumerState<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends ConsumerState<DocumentsSection> {
  bool _isUploading = false;
  DocumentType _selectedType = DocumentType.other;

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(workerDocumentsProvider(widget.workerId));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.folder_outlined, color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Documents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadDocument,
                icon: _isUploading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload_file, size: 18),
                label: Text(_isUploading ? 'Uploading...' : 'Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Documents list
          documentsAsync.when(
            data: (documents) {
              if (documents.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.folder_open, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No documents uploaded',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap Upload to add ID, contracts, or certificates',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: documents.map((doc) => _DocumentTile(
                  document: doc,
                  onDelete: () => _deleteDocument(doc),
                )).toList(),
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Text('Error loading documents: $e'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument() async {
    // Show type selection dialog first
    final type = await showDialog<DocumentType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Document Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DocumentType.values.map((t) => ListTile(
            leading: Icon(_getDocumentIcon(t)),
            title: Text(t.displayName),
            onTap: () => Navigator.pop(context, t),
          )).toList(),
        ),
      ),
    );

    if (type == null) return;
    _selectedType = type;

    // Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read file')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      await ApiService().workers.uploadDocument(
        widget.workerId,
        file.bytes!,
        file.name,
        type: _selectedType.apiValue,
      );

      ref.invalidate(workerDocumentsProvider(widget.workerId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(WorkerDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${doc.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService().workers.deleteDocument(doc.id);
      ref.invalidate(workerDocumentsProvider(widget.workerId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.idCopy: return Icons.badge;
      case DocumentType.contract: return Icons.description;
      case DocumentType.certificate: return Icons.workspace_premium;
      case DocumentType.taxDocument: return Icons.receipt_long;
      case DocumentType.other: return Icons.attach_file;
    }
  }
}

class _DocumentTile extends StatelessWidget {
  final WorkerDocument document;
  final VoidCallback onDelete;

  const _DocumentTile({required this.document, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTypeColor(document.type).withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getTypeIcon(document.type), color: _getTypeColor(document.type), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(document.type).withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        document.type.displayName,
                        style: TextStyle(fontSize: 10, color: _getTypeColor(document.type), fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (document.fileSize != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatFileSize(document.fileSize!),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.idCopy: return Icons.badge;
      case DocumentType.contract: return Icons.description;
      case DocumentType.certificate: return Icons.workspace_premium;
      case DocumentType.taxDocument: return Icons.receipt_long;
      case DocumentType.other: return Icons.attach_file;
    }
  }

  Color _getTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.idCopy: return const Color(0xFF3B82F6);
      case DocumentType.contract: return const Color(0xFF8B5CF6);
      case DocumentType.certificate: return const Color(0xFFF59E0B);
      case DocumentType.taxDocument: return const Color(0xFF10B981);
      case DocumentType.other: return const Color(0xFF6B7280);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
