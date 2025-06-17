import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final String userId;

  const AnalyticsDashboardScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AnalyticsDashboardScreenState createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final storage = const FlutterSecureStorage();

  int totalProfileViews = 0;
  int totalPostLikes = 0;
  int totalConnections = 0;
  List<Map<String, dynamic>> userPosts = [];
  List<Map<String, dynamic>> recentConnections = [];
  bool _isLoading = true;
  String _errorMessage = '';

  String baseUrl = 'https://yourdomain.com/backend2/api'; // Replace with your Laravel API base URL

  @override
  void initState() {
    super.initState();
    _loadAllAnalytics();
  }

  Future<String?> _getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> _loadAllAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _loadProfileViews(),
        _loadPostLikes(),
        _loadConnections(),
        _loadUserPostsAnalytics(),
        _loadConnectionActivity(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load analytics: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProfileViews() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/profile-views?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      totalProfileViews = data['count'] ?? 0;
    }
  }

  Future<void> _loadPostLikes() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/post-likes?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      totalPostLikes = data['count'] ?? 0;
    }
  }

  Future<void> _loadConnections() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/connections?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      totalConnections = data['count'] ?? 0;
    }
  }

  Future<void> _loadUserPostsAnalytics() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/posts?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      userPosts = List<Map<String, dynamic>>.from(data['posts']);
    }
  }

  Future<void> _loadConnectionActivity() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/recent-connections?user_id=${widget.userId}'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      recentConnections = List<Map<String, dynamic>>.from(data['connections']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text('Error: $_errorMessage'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Metrics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16.0),
                      Card(
                        elevation: 2.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMetricRow('Total Profile Views:', totalProfileViews),
                              _buildMetricRow('Total Post Likes:', totalPostLikes),
                              _buildMetricRow('Total Connections:', totalConnections),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      Text(
                        'Post Engagement',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16.0),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userPosts.length,
                        itemBuilder: (context, index) {
                          final post = userPosts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            elevation: 1.0,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      post['title'] ?? 'Untitled Post',
                                      style: Theme.of(context).textTheme.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.rocket_launch_rounded, size: 18.0, color: Colors.orange[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        post['like_count'].toString(),
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24.0),
                      Text(
                        'Connection Activity',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16.0),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentConnections.length,
                        itemBuilder: (context, index) {
                          final connection = recentConnections[index];
                          final connectedUserName = connection['other_user_name'] ?? 'Unknown User';
                          final connectionDate = DateTime.parse(connection['created_at']).toLocal().toString().split(' ')[0];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            elevation: 1.0,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Connected with $connectedUserName',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    connectionDate,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
} 