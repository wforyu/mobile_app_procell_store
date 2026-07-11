import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../helpers/theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _api = ApiService();
  List<AppNotification> _notifications = [];
  bool _loading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final res = await _api.get('/notifications');
      if (!mounted) return;
      final data = (res['data'] as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      final unreadRes = await _api.get('/notifications/unread-count');
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _unreadCount = unreadRes['count'] as int? ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _api.post('/notifications/$id/read');
      _loadNotifications();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _api.post('/notifications/read-all');
      _loadNotifications();
    } catch (_) {}
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'OrderStatusChanged':
        return Icons.receipt_long;
      case 'PaymentUploaded':
        return Icons.payments;
      case 'ReturnSubmitted':
        return Icons.assignment_return;
      case 'ReturnStatusChanged':
        return Icons.verified;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'OrderStatusChanged':
        return AppColors.primary;
      case 'PaymentUploaded':
        return Colors.green;
      case 'ReturnSubmitted':
        return Colors.orange;
      case 'ReturnStatusChanged':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifikasi'),
            if (_unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Semua Dibaca', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty
            ? const Center(child: Text('Belum ada notifikasi'))
            : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
                      sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final n = _notifications[i];
                              return Column(
                                children: [
                                  if (i > 0)
                                    const Divider(height: 1),
                                  ListTile(
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: _notificationColor(n.type).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_notificationIcon(n.type), color: _notificationColor(n.type)),
                                    ),
                                    title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (n.body.isNotEmpty)
                                          Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                        const SizedBox(height: 2),
                                        Text(_formatDate(n.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                      ],
                                    ),
                                    trailing: n.isRead ? null : Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                    onTap: () => _markAsRead(n.id),
                                  ),
                                ],
                              );
                            },
                            childCount: _notifications.length,
                          ),
                        ),
                      ),
                    ],
              ),
            ));
          }
        }
        
