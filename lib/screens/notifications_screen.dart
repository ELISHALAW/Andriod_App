import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;
  bool _isGenerating = false;
  String _statusMessage = '';
  int? _userId;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      setState(() {
        _userId = null;
        _notifications = [];
        _statusMessage = 'Please login to view notifications.';
      });
      return;
    }

    setState(() {
      _userId = userId;
      _isLoading = true;
      _statusMessage = 'Loading notifications...';
    });

    final result = await DatabaseService.getNotifications(userId: userId);
    final data = result['data'];

    setState(() {
      _isLoading = false;
      _statusMessage = result['message'] ?? '';
      _notifications = data is List
          ? data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : [];
    });
  }

  Future<void> _markAsRead(int notificationId) async {
    final result = await DatabaseService.markNotificationRead(
      notificationId: notificationId,
    );

    if (result['success'] == true) {
      setState(() {
        _notifications = _notifications.map((item) {
          if (item['id'] == notificationId) {
            return {...item, 'is_read': 1};
          }
          return item;
        }).toList();
      });
    }

    _showSnackBar(result);
  }

  Future<void> _deleteNotification(int notificationId) async {
    final result = await DatabaseService.deleteNotification(
      notificationId: notificationId,
    );

    if (result['success'] == true) {
      setState(() {
        _notifications.removeWhere((item) => item['id'] == notificationId);
      });
    }

    _showSnackBar(result);
  }

  Future<void> _generateRandomAlert() async {
    final userId = _userId;
    if (userId == null) {
      _showSnackBar({
        'success': false,
        'message': 'Please login to generate an alert.',
      });
      return;
    }

    setState(() => _isGenerating = true);

    final result = await DatabaseService.generateRandomNotification(
      userId: userId,
    );
    final data = result['data'];

    if (result['success'] == true && data is Map) {
      setState(() {
        _notifications.insert(0, Map<String, dynamic>.from(data));
      });
    }

    setState(() => _isGenerating = false);
    _showSnackBar(result);
  }

  void _showSnackBar(Map<String, dynamic> result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Request completed.'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((item) {
      return item['is_read'].toString() == '0';
    }).length;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadNotifications,
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
                        'Alerts',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Track updates from your account.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _isLoading ? null : _loadNotifications,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSummaryCard(unreadCount),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _userId == null || _isGenerating
                    ? null
                    : _generateRandomAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.shuffle, color: Colors.white),
                label: const Text(
                  'Generate Random Alert',
                  style: TextStyle(color: Colors.white),
                ),
              ),
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
              _buildEmptyState(
                icon: Icons.lock_outline,
                title: 'Login required',
                message: _statusMessage,
              )
            else if (_notifications.isEmpty)
              _buildEmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications',
                message: 'You are all caught up.',
              )
            else
              ..._notifications.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNotificationCard(item),
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
              Icons.notifications_active_outlined,
              color: Color(0xFF1D4ED8),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
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

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final id = int.tryParse(item['id'].toString()) ?? 0;
    final isUnread = item['is_read'].toString() == '0';
    final title = item['title']?.toString() ?? 'Notification';
    final message = item['message']?.toString() ?? '';
    final type = item['type']?.toString() ?? 'info';
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor:
              isUnread ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
          child: Icon(
            _iconForType(type),
            color: isUnread ? Colors.white : const Color(0xFF64748B),
          ),
        ),
        title: Text(
          title,
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
              Text(message, style: const TextStyle(color: Color(0xFF64748B))),
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
            if (value == 'delete') _deleteNotification(id);
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
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
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
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
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'profile':
        return Icons.person_outline;
      default:
        return Icons.info_outline;
    }
  }
}
