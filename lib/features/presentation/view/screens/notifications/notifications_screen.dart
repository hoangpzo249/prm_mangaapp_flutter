import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/notification_repository.dart';
import '../../../../domain/entities/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = NotificationRepository.instance;
  List<AppNotification> _items = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await _repo.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = result.notifications;
        _unreadCount = result.unreadCount;
      });
    } catch (error) {
      _show('Không thể tải thông báo: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(AppNotification item) async {
    try {
      if (!item.isRead) await _repo.markAsRead(item.id);
      if (!mounted) return;
      if (item.link != null && item.link!.isNotEmpty) {
        Navigator.pushNamed(context, item.link!);
      } else {
        await _load();
      }
    } catch (error) {
      _show('Không thể cập nhật thông báo: $error');
    }
  }

  Future<void> _markAll() async {
    try {
      await _repo.markAllAsRead();
      await _load();
    } catch (error) {
      _show('Không thể đánh dấu đã đọc: $error');
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        foregroundColor: Colors.white,
        title: Text('Thông báo${_unreadCount > 0 ? ' ($_unreadCount)' : ''}'),
        actions: [
          TextButton(
            onPressed: _unreadCount == 0 ? null : _markAll,
            child: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 180),
                      Icon(Ionicons.notifications_off_outline, size: 56, color: AppColors.textDim),
                      SizedBox(height: 12),
                      Center(child: Text('Chưa có thông báo', style: TextStyle(color: AppColors.textDim))),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final item = _items[index];
                      return Material(
                        color: item.isRead ? AppColors.card : AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _open(item),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(_icon(item.type), color: item.isRead ? AppColors.textDim : AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      Text(item.message, style: const TextStyle(color: AppColors.textLight)),
                                      if (item.createdAt != null) ...[
                                        const SizedBox(height: 7),
                                        Text(
                                          DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!.toLocal()),
                                          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (!item.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'NEW_CHAPTER':
        return Ionicons.book_outline;
      case 'REPLY_COMMENT':
        return Ionicons.chatbubble_outline;
      default:
        return Ionicons.information_circle_outline;
    }
  }
}
