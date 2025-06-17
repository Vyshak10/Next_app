import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


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
  final String baseUrl = "https://indianrupeeservices.in/NEXT/backend/api";
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
      final response = await http.get(Uri.parse(
        "$baseUrl/connection-status?user_id=${widget.currentUserId}&target_user_id=${widget.targetUserId}",
      ));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _connectionStatus = data['status'];
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
      final response = await http.post(
        Uri.parse("$baseUrl/send-connection-request"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.currentUserId,
          'target_user_id': widget.targetUserId,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _connectionStatus = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send connection request: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptConnectionRequest() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/accept-connection-request"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.currentUserId,
          'target_user_id': widget.targetUserId,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _connectionStatus = 'accepted');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request accepted')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept connection request: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectConnectionRequest() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/reject-connection-request"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.currentUserId,
          'target_user_id': widget.targetUserId,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _connectionStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request rejected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject connection request: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeConnection() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/remove-connection"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.currentUserId,
          'target_user_id': widget.targetUserId,
        }),
      );
      if (response.statusCode == 200) {
        setState(() => _connectionStatus = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection removed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove connection: $e')),
      );
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