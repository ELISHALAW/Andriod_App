import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/database_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _titleCtrl = TextEditingController();
  final _categories = const ['Receipt', 'Invoice', 'Form', 'Report', 'Other'];

  int? _userId;
  bool _isLoading = false;
  bool _isUploading = false;
  String _category = 'Receipt';
  List<Map<String, dynamic>> _documents = [];
  final Set<int> _downloadingIds = <int>{};
  final Set<int> _openingIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _userId = null;
        _documents = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _userId = userId;
    });

    final result = await DatabaseService.getDocuments(userId: userId);
    final data = result['data'];

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _documents = data is List
          ? data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : [];
    });
  }

  Future<void> _pickAndUpload() async {
    final userId = _userId;
    if (userId == null) {
      _showSnack(false, 'Please login to upload documents.');
      return;
    }

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showSnack(false, 'Please enter a title.');
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showSnack(false, 'Could not read selected file.');
      return;
    }

    setState(() => _isUploading = true);

    final result = await DatabaseService.uploadDocument(
      userId: userId,
      title: title,
      category: _category,
      fileName: file.name,
      fileBytes: bytes,
    );

    if (!mounted) return;

    setState(() => _isUploading = false);
    _showSnack(
      result['success'] == true,
      result['message']?.toString() ?? 'Done',
    );

    if (result['success'] == true) {
      _titleCtrl.clear();
      await _loadDocuments();
    }
  }

  String _buildDocumentUrl(String fileName, {bool download = false}) {
    final cleanBase = DatabaseService.baseUrl.endsWith('/')
        ? DatabaseService.baseUrl.substring(
            0,
            DatabaseService.baseUrl.length - 1,
          )
        : DatabaseService.baseUrl;
    final encodedName = Uri.encodeQueryComponent(fileName);
    final mode = download ? 'download' : 'inline';
    return '$cleanBase/download_document.php?file=$encodedName&mode=$mode';
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  String _formatDate(String? raw) {
    final dt = _parseDate(raw);
    if (dt == null) return 'Unknown date';
    final local = dt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '${local.year}-$mm-$dd';
  }

  IconData _iconForFile(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg')) {
      return Icons.image_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Future<bool> _launchDocumentUrl({
    required String fileName,
    bool download = false,
  }) async {
    final cleanName = fileName.trim();
    if (cleanName.isEmpty) return false;

    final uri = Uri.parse(_buildDocumentUrl(cleanName, download: download));

    if (kIsWeb) {
      return launchUrl(uri, webOnlyWindowName: '_blank');
    }

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _previewDocument(Map<String, dynamic> item) async {
    final docId = int.tryParse(item['id']?.toString() ?? '') ?? 0;
    final fileName = (item['file_name']?.toString() ?? '').trim();
    if (docId <= 0 || fileName.isEmpty) {
      _showSnack(false, 'Invalid document file info.');
      return;
    }

    setState(() => _openingIds.add(docId));
    try {
      final launched = await _launchDocumentUrl(fileName: fileName);
      if (!launched) {
        _showSnack(false, 'Unable to open document.');
        return;
      }

      _showSnack(true, 'Opened $fileName');
    } catch (e) {
      _showSnack(false, 'Preview failed: $e');
    } finally {
      if (mounted) {
        setState(() => _openingIds.remove(docId));
      }
    }
  }

  Future<void> _downloadDocument(Map<String, dynamic> item) async {
    final docId = int.tryParse(item['id']?.toString() ?? '') ?? 0;
    final fileName = (item['file_name']?.toString() ?? '').trim();
    if (docId <= 0 || fileName.isEmpty) {
      _showSnack(false, 'Invalid document file info.');
      return;
    }

    setState(() => _downloadingIds.add(docId));
    try {
      final launched = await _launchDocumentUrl(
        fileName: fileName,
        download: true,
      );

      if (!launched) {
        _showSnack(false, 'Unable to start download.');
        return;
      }

      _showSnack(
        true,
        kIsWeb
            ? 'Download started in a new tab.'
            : 'Download opened in your browser/app.',
      );
    } catch (e) {
      _showSnack(false, 'Download failed: $e');
    } finally {
      if (mounted) {
        setState(() => _downloadingIds.remove(docId));
      }
    }
  }

  Future<void> _deleteDocument(Map<String, dynamic> item) async {
    final userId = _userId;
    final documentId = int.tryParse(item['id']?.toString() ?? '') ?? 0;
    if (userId == null || documentId <= 0) {
      _showSnack(false, 'Invalid document data.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await DatabaseService.deleteDocument(
      userId: userId,
      documentId: documentId,
    );

    if (!mounted) return;
    _showSnack(
      result['success'] == true,
      result['message']?.toString() ?? 'Done',
    );

    if (result['success'] == true) {
      await _loadDocuments();
    }
  }

  void _showSnack(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDocuments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Upload New Document',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _category = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isUploading ? null : _pickAndUpload,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_outlined),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Select PDF / Image',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Your Documents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${_documents.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_userId == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Please login to view your documents.'),
              )
            else if (_documents.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No documents uploaded yet.'),
              )
            else
              ..._documents.map((doc) {
                final docId = int.tryParse(doc['id']?.toString() ?? '') ?? 0;
                final title = doc['title']?.toString() ?? 'Untitled';
                final fileName = doc['file_name']?.toString() ?? 'Unknown';
                final docType = doc['document_type']?.toString() ?? 'Other';
                final createdAt = _formatDate(doc['created_at']?.toString());
                final isDownloading = _downloadingIds.contains(docId);
                final isOpening = _openingIds.contains(docId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: isOpening ? null : () => _previewDocument(doc),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _iconForFile(fileName),
                                color: const Color(0xFF3730A3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _Pill(
                                        text: docType,
                                        icon: Icons.category_outlined,
                                      ),
                                      _Pill(
                                        text: createdAt,
                                        icon: Icons.calendar_today_outlined,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  tooltip: 'Download',
                                  onPressed: isDownloading
                                      ? null
                                      : () => _downloadDocument(doc),
                                  icon: isDownloading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.download_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteDocument(doc),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF334155)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
