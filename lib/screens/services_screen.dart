import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../services/database_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isSending = false;
  int? _userId;
  String _statusMessage = '';
  List<Map<String, dynamic>> _messages = [];
  Timer? _autoRefreshTimer;

  static const Color _primary = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && !_isSending) {
        _loadMessages(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _userId = null;
        _messages = [];
        _statusMessage = 'Please login to contact support.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _userId = userId;
      if (!silent) {
        _isLoading = true;
      }
    });

    final result = await DatabaseService.getMessages(userId: userId);
    final data = result['data'];

    final rows = data is List
        ? data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    rows.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
      final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return -1;
      if (bDate == null) return 1;
      return aDate.compareTo(bDate);
    });

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _statusMessage = result['message']?.toString() ?? '';
      _messages = rows;
    });
  }

  bool _isUserMessage(Map<String, dynamic> item) {
    final sender = item['sender']?.toString().toLowerCase() ?? '';
    return sender == 'user' || sender.contains('you');
  }

  String _displaySender(Map<String, dynamic> item) {
    if (_isUserMessage(item)) return 'You';
    return item['sender']?.toString().isNotEmpty == true
        ? item['sender'].toString()
        : 'Admin';
  }

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final hour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final meridiem = date.hour >= 12 ? 'PM' : 'AM';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month ${hour.toString().padLeft(2, '0')}:$minute $meridiem';
  }

  Future<void> _sendMessage() async {
    final userId = _userId;
    final text = _messageController.text.trim();

    if (userId == null) {
      _showSnackBar(false, 'Please login first.');
      return;
    }
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    final result = await DatabaseService.sendToAdmin(
      userId: userId,
      message: text,
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    _showSnackBar(
      result['success'] == true,
      result['message']?.toString() ?? '',
    );
    if (result['success'] == true) {
      _messageController.clear();
      await _loadMessages(silent: true);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
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
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMessages,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _userId == null
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildEmptyState(Icons.lock_outline, _statusMessage),
                      ],
                    )
                  : _messages.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildEmptyState(
                          Icons.chat_bubble_outline,
                          'No messages yet. Start by sending a message to admin.',
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final item = _messages[index];
                        return _buildMessageBubble(item);
                      },
                    ),
            ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> item) {
    final isUser = _isUserMessage(item);
    final body = item['body']?.toString() ?? '';
    final subject = item['subject']?.toString() ?? '';
    final timestamp = _formatTimestamp(item['created_at']?.toString());
    final isRead = (item['is_read'] as num?)?.toInt() == 1;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displaySender(item),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isUser ? Colors.white70 : _muted,
              ),
            ),
            if (!isUser && subject.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subject,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : _primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timestamp,
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser ? Colors.white70 : _muted,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 8),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead ? const Color(0xFF22C55E) : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type message to admin...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: _isSending ? null : _sendMessage,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
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
            style: const TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }
}
