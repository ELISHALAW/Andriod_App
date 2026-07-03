import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final fileNameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String documentType = 'Receipt';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add document'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter document title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: documentType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(value: 'Receipt', child: Text('Receipt')),
                          DropdownMenuItem(value: 'Invoice', child: Text('Invoice')),
                          DropdownMenuItem(value: 'Report', child: Text('Report')),
                          DropdownMenuItem(value: 'Form', child: Text('Form')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => documentType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: fileNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'File name',
                          hintText: 'example.pdf',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter file name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Optional',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(context).pop();
                      await _createDocument(
                        userId: userId,
                        title: titleCtrl.text.trim(),
                        documentType: documentType,
                        fileName: fileNameCtrl.text.trim(),
                        notes: notesCtrl.text.trim(),
                      );
                    }
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
