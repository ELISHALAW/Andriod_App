import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  int? _userId;
  String _statusMessage = '';
  String _query = '';
  String _filter = 'All';
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      setState(() {
        _userId = null;
        _messages = [];
        _statusMessage = 'Please login to view messages.';
      });
      return;
    }

    setState(() {
      _userId = userId;
      _isLoading = true;
      _statusMessage = 'Loading messages...';
    });

    final result = await DatabaseService.getMessages(userId: userId);
    final data = result['data'];

    setState(() {
      _isLoading = false;
      _statusMessage = result['message'] ?? '';
      _messages = data is List
          ? data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : [];
    });
  }

  List<Map<String, dynamic>> get _visibleMessages {
    return _messages.where((item) {
      final isUnread = item['is_read'].toString() == '0';
      final haystack =
          '${item['sender']} ${item['subject']} ${item['body']}'.toLowerCase();
      final matchesQuery = _query.isEmpty || haystack.contains(_query);
      final matchesFilter = _filter == 'All' || (_filter == 'Unread' && isUnread);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _openCreateDialog() async {
    final userId = _userId;
    if (userId == null) {
      _showSnackBar(false, 'Please login first.');
      return;
    }

    final senderCtrl = TextEditingController(text: 'Support team');
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New message'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: senderCtrl,
                    decoration: const InputDecoration(labelText: 'Sender'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter sender';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bodyCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Message'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter message';
                      }
                      return null;
                    },
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
                  await _createMessage(
                    userId: userId,
                    sender: senderCtrl.text.trim(),
                    subject: subjectCtrl.text.trim(),
                    body: bodyCtrl.text.trim(),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createMessage({
    required int userId,
    required String sender,
    required String subject,
    required String body,
  }) async {
    setState(() => _isSaving = true);

    final result = await DatabaseService.createMessage(
      userId: userId,
      sender: sender,
      subject: subject,
      body: body,
    );

    setState(() => _isSaving = false);
    _showSnackBar(result['success'] == true, result['message'] ?? '');

    if (result['success'] == true) {
      await _loadMessages();
    }
  }

  Future<void> _markAsRead(int messageId) async {
    final result = await DatabaseService.markMessageRead(messageId: messageId);

    if (result['success'] == true) {
      setState(() {
        _messages = _messages.map((item) {
          if (item['id'] == messageId) {
            return {...item, 'is_read': 1};
          }
          return item;
        }).toList();
      });
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    final result = await DatabaseService.deleteMessage(messageId: messageId);

    if (result['success'] == true) {
      setState(() {
        _messages.removeWhere((item) => item['id'] == messageId);
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
    final unreadCount = _messages.where((item) {
      return item['is_read'].toString() == '0';
    }).length;
    final visibleMessages = _visibleMessages;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadMessages,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Catch up with your latest conversations.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'New message',
                  onPressed: _isSaving ? null : _openCreateDialog,
                  icon: const Icon(Icons.add_comment_outlined),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _isLoading ? null : _loadMessages,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSummaryCard(unreadCount),
            const SizedBox(height: 14),
            _buildSearchBox(),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 10),
                _buildFilterChip('Unread'),
              ],
            ),
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
            else if (visibleMessages.isEmpty)
              _buildEmptyState(
                Icons.mail_outline,
                _query.isEmpty ? 'No messages yet.' : 'No matching messages.',
              )
            else
              ...visibleMessages.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMessageCard(item),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int unreadCount) {
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
              Icons.mark_email_unread_outlined,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$unreadCount unread message${unreadCount == 1 ? '' : 's'}',
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

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Color(0xFF94A3B8)),
          hintText: 'Search messages',
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final active = _filter == label;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> item) {
    final id = int.tryParse(item['id'].toString()) ?? 0;
    final isUnread = item['is_read'].toString() == '0';
    final sender = item['sender']?.toString() ?? 'Message';
    final subject = item['subject']?.toString() ?? '';
    final body = item['body']?.toString() ?? '';
    final createdAt = item['created_at']?.toString() ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnread ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        leading: CircleAvatar(
          backgroundColor:
              isUnread ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
          child: Icon(
            isUnread ? Icons.mail_outline : Icons.drafts_outlined,
            color: isUnread ? Colors.white : const Color(0xFF64748B),
          ),
        ),
        title: Text(
          subject,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sender, style: const TextStyle(color: Color(0xFF334155))),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: Color(0xFF64748B))),
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
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'read') _markAsRead(id);
            if (value == 'delete') _deleteMessage(id);
          },
          itemBuilder: (context) => [
            if (isUnread)
              const PopupMenuItem(
                value: 'read',
                child: Text('Mark as read'),
              ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: isUnread ? () => _markAsRead(id) : null,
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
}
