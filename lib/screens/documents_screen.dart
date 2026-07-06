import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../services/database_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  int? _userId;
  String _statusMessage = '';
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      setState(() {
        _userId = null;
        _documents = [];
        _statusMessage = 'Please login to view documents.';
      });
      return;
    }

    setState(() {
      _userId = userId;
      _isLoading = true;
      _statusMessage = 'Loading documents...';
    });

    final result = await DatabaseService.getDocuments(userId: userId);
    final data = result['data'];

    setState(() {
      _isLoading = false;
      _statusMessage = result['message'] ?? '';
      _documents = data is List
          ? data
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : [];
    });
  }

  Future<void> _openCreateDialog() async {
    final userId = _userId;
    if (userId == null) {
      _showSnackBar(false, 'Please login first.');
      return;
    }

    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String documentType = 'Receipt';
    String? pickedFileName;
    int? pickedFileSize;
    bool isPicking = false;
    const int maxBytes = 10 * 1024 * 1024; // 10 MB

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.upload_file_outlined, color: Color(0xFF1D4ED8)),
                  SizedBox(width: 8),
                  Text(
                    'Add Document',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          prefixIcon: const Icon(
                            Icons.title,
                            color: Color(0xFF1D4ED8),
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a title'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: documentType,
                        decoration: InputDecoration(
                          labelText: 'Document Type',
                          prefixIcon: const Icon(
                            Icons.category_outlined,
                            color: Color(0xFF1D4ED8),
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Receipt',
                            child: Text('Receipt'),
                          ),
                          DropdownMenuItem(
                            value: 'Invoice',
                            child: Text('Invoice'),
                          ),
                          DropdownMenuItem(
                            value: 'Report',
                            child: Text('Report'),
                          ),
                          DropdownMenuItem(value: 'Form', child: Text('Form')),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setS(() => documentType = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Attach File',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: isPicking
                            ? null
                            : () async {
                                setS(() => isPicking = true);
                                try {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                        type: FileType.custom,
                                        allowedExtensions: [
                                          'pdf',
                                          'doc',
                                          'docx',
                                          'xls',
                                          'xlsx',
                                          'png',
                                          'jpg',
                                          'jpeg',
                                        ],
                                        allowMultiple: false,
                                        withData: false,
                                      );
                                  if (result != null &&
                                      result.files.isNotEmpty) {
                                    final f = result.files.single;
                                    if (f.size > maxBytes) {
                                      setS(() {
                                        pickedFileName = null;
                                        pickedFileSize = null;
                                      });
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'File exceeds 10 MB limit.',
                                            ),
                                            backgroundColor: Color(0xFFDC2626),
                                          ),
                                        );
                                      }
                                    } else {
                                      setS(() {
                                        pickedFileName = f.name;
                                        pickedFileSize = f.size;
                                        if (titleCtrl.text.trim().isEmpty) {
                                          titleCtrl.text = f.name.replaceAll(
                                            RegExp(r'\.[^.]+$'),
                                            '',
                                          );
                                        }
                                      });
                                    }
                                  }
                                } catch (e) {
                                  debugPrint('FilePicker error: $e');
                                } finally {
                                  setS(() => isPicking = false);
                                }
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: pickedFileName != null
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: pickedFileName != null
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFFCBD5E1),
                              width: pickedFileName != null ? 1.5 : 1,
                            ),
                          ),
                          child: isPicking
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Selecting...',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                )
                              : pickedFileName != null
                              ? Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF1D4ED8),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pickedFileName!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F172A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (pickedFileSize != null)
                                            Text(
                                              _formatFileSize(pickedFileSize!),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                      onPressed: () => setS(() {
                                        pickedFileName = null;
                                        pickedFileSize = null;
                                      }),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.upload_file_outlined,
                                      color: Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tap to select file',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'PDF, DOC, DOCX, XLS, PNG, JPG  ·  Max 10 MB',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notes (optional)',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    if (pickedFileName == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a file.'),
                          backgroundColor: Color(0xFFDC2626),
                        ),
                      );
                      return;
                    }
                    Navigator.of(ctx).pop();
                    await _createDocument(
                      userId: userId,
                      title: titleCtrl.text.trim(),
                      documentType: documentType,
                      fileName: pickedFileName!,
                      notes: notesCtrl.text.trim(),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _createDocument({
    required int userId,
    required String title,
    required String documentType,
    required String fileName,
    required String notes,
  }) async {
    setState(() => _isSaving = true);

    final result = await DatabaseService.createDocument(
      userId: userId,
      title: title,
      documentType: documentType,
      fileName: fileName,
      notes: notes,
    );

    setState(() => _isSaving = false);
    _showSnackBar(result['success'] == true, result['message'] ?? '');

    if (result['success'] == true) {
      await _loadDocuments();
    }
  }

  Future<void> _deleteDocument(int documentId) async {
    final result = await DatabaseService.deleteDocument(documentId: documentId);

    if (result['success'] == true) {
      setState(() {
        _documents.removeWhere((item) => item['id'] == documentId);
      });
    }

    _showSnackBar(result['success'] == true, result['message'] ?? '');
  }

  void _showSnackBar(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.isEmpty ? 'Request completed.' : message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadDocuments,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _openCreateDialog,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Document library',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Keep receipts, invoices, reports, and forms in one place.',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            _buildSummaryCard(),
            const SizedBox(height: 18),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_userId == null)
              _buildEmptyState(Icons.lock_outline, _statusMessage)
            else if (_documents.isEmpty)
              _buildEmptyState(
                Icons.folder_open_outlined,
                'No documents yet. Tap Add to create one.',
              )
            else
              ..._documents.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildDocumentCard(item),
                ),
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.folder_copy_outlined,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${_documents.length} document${_documents.length == 1 ? '' : 's'} saved',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> item) {
    final id = int.tryParse(item['id'].toString()) ?? 0;
    final title = item['title']?.toString() ?? 'Document';
    final type = item['document_type']?.toString() ?? 'File';
    final fileName = item['file_name']?.toString() ?? '';
    final notes = item['notes']?.toString() ?? '';
    final createdAt = item['created_at']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEFF6FF),
          child: Icon(_iconForType(type), color: const Color(0xFF1D4ED8)),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$type - $fileName',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(notes, style: const TextStyle(color: Color(0xFF64748B))),
              ],
              if (createdAt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  createdAt,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Delete document',
          onPressed: () => _deleteDocument(id),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Receipt':
        return Icons.receipt_long_outlined;
      case 'Invoice':
        return Icons.request_quote_outlined;
      case 'Report':
        return Icons.analytics_outlined;
      case 'Form':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
