import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/notification.dart' as app;
import '../../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<app.AppNotification> _notifications = [];
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await _apiService.getNotifications();
      setState(() {
        _notifications = response
            .map((json) => app.AppNotification.fromJson(json))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      await _apiService.toggleNotifications(value);
      setState(() {
        _notificationsEnabled = value;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling notifications: $e')),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'connection':
        return Icons.people;
      case 'message':
        return Icons.message;
      case 'meeting':
        return Icons.event;
      case 'post':
        return Icons.article;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'connection':
        return Colors.blue;
      case 'message':
        return Colors.green;
      case 'meeting':
        return Colors.orange;
      case 'post':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Switch(
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _notifications.isEmpty
            ? const Center(
                child: Text('No notifications'),
              )
            : ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getNotificationColor(notification.type),
                        child: Icon(
                          _getNotificationIcon(notification.type),
                          color: Colors.white,
                        ),
                      ),
                      title: Text(notification.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.message),
                          const SizedBox(height: 4),
                          Text(
                            timeago.format(notification.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        // TODO: Handle notification tap based on type and relatedId
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
} 