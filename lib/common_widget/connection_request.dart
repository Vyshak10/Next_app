import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectionRequest extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final String targetUserName;
  final String? targetUserAvatar;
  final String? targetUserType;

  const ConnectionRequest({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserAvatar,
    this.targetUserType,
  });

  @override
  State<ConnectionRequest> createState() => _ConnectionRequestState();
}

class _ConnectionRequestState extends State<ConnectionRequest> {
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    setState(() => _isLoading = true);
    try {
      // Check if there's an existing connection
      final connection = await supabase
          .from('connections')
          .select()
          .or('(user_id.eq.${widget.currentUserId},connected_user_id.eq.${widget.targetUserId}),' +
              '(user_id.eq.${widget.targetUserId},connected_user_id.eq.${widget.currentUserId})')
          .maybeSingle();

      if (connection != null) {
        setState(() {
          _connectionStatus = connection['status'];
        });
      }
    } catch (e) {
      print('Error checking connection status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendConnectionRequest() async {
    setState(() => _isLoading = true);
    try {
      // Create connection request
      await supabase.from('connections').insert({
        'user_id': widget.currentUserId,
        'connected_user_id': widget.targetUserId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Create notification for the target user
      await supabase.from('notifications').insert({
        'user_id': widget.targetUserId,
        'title': 'New Connection Request',
        'body': '${widget.targetUserName} wants to connect with you',
        'type': 'connection_request',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _connectionStatus = 'pending';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send connection request: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptConnectionRequest() async {
    setState(() => _isLoading = true);
    try {
      // Update connection status
      await supabase
          .from('connections')
          .update({'status': 'accepted'})
          .eq('user_id', widget.targetUserId)
          .eq('connected_user_id', widget.currentUserId);

      // Create notification for the requester
      await supabase.from('notifications').insert({
        'user_id': widget.targetUserId,
        'title': 'Connection Accepted',
        'body': '${widget.targetUserName} accepted your connection request',
        'type': 'connection_accepted',
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _connectionStatus = 'accepted';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request accepted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept connection request: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectConnectionRequest() async {
    setState(() => _isLoading = true);
    try {
      // Delete the connection request
      await supabase
          .from('connections')
          .delete()
          .eq('user_id', widget.targetUserId)
          .eq('connected_user_id', widget.currentUserId);

      setState(() {
        _connectionStatus = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject connection request: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeConnection() async {
    setState(() => _isLoading = true);
    try {
      // Delete the connection
      await supabase
          .from('connections')
          .delete()
          .or('(user_id.eq.${widget.currentUserId},connected_user_id.eq.${widget.targetUserId}),' +
              '(user_id.eq.${widget.targetUserId},connected_user_id.eq.${widget.currentUserId})');

      setState(() {
        _connectionStatus = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove connection: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (_connectionStatus) {
      case 'pending':
        if (widget.currentUserId == widget.targetUserId) {
          return const Text('Pending', style: TextStyle(color: Colors.orange));
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _acceptConnectionRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Accept'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _rejectConnectionRequest,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Reject'),
            ),
          ],
        );

      case 'accepted':
        return OutlinedButton.icon(
          onPressed: _removeConnection,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Connected'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green,
            side: const BorderSide(color: Colors.green),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );

      default:
        return ElevatedButton.icon(
          onPressed: _sendConnectionRequest,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Connect'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
    }
  }
} 